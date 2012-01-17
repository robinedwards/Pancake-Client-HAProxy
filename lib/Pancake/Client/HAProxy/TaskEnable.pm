package Pancake::Client::HAProxy::TaskEnable;
use 5.012;
use Moose;
use JSON;
use URI;
use POE;
use HTTP::Request;
use Try::Tiny;
use Data::Dump 'pp';
use namespace::autoclean;

has service_url        => (is => 'ro', isa => 'Str',    required => 1);
has svname             => (is => 'ro', isa => 'Str',    required => 1);
has pxname             => (is => 'ro', isa => 'Str',    required => 1);
has manager            => (is => 'ro', isa => 'Object', required => 1);
has skip_status_check  => (is => 'ro', isa => 'Int');

sub BUILD {
    my ($self) = @_;

    POE::Session->create(
        object_states => [
            $self => {
                _start => 'start',
                enable_server => '_enable_server_response',
                status_response  => '_status_response',
                status_request   => '_status_request',
            },
        ]
    );
}

sub start {
    my ($self) = @_;
    my $uri = URI->new($self->service_url.'/enable_server');
    $uri->query_form(pxname => $self->pxname, svname => $self->svname);

    say 'DEBUG: about to get '. $uri;

    POE::Kernel->post(
        'useragent',
        request => 'enable_server',
        HTTP::Request->new(GET => $uri)
    );
}

# handles response from request to enable  a server
sub _enable_server_response {
    my ($self, $heap, $resp) = @_[0, HEAP, ARG1];
    my $r = $resp->[0];

    unless ($r->is_success) {
        die "ERROR: failed to enable server " . $self->_failure_text($r);
    }

    say 'SUCCESS enabled ' . $self->pxname . '/' . $self->svname
        . ' on ' . $self->service_url;

    $self->skip_status_check ?  $self->manager->task_complete(1)
        : $self->_status_request;
}

sub _status_request {
    my ($self) = @_;

    my $uri = URI->new($self->service_url.'/stats');
    $uri->query_form(pxname => $self->pxname, svname => $self->svname);

    say 'DEBUG: about to get '. $uri;
    POE::Kernel->post(
        'useragent',
        request => 'status_response',
        HTTP::Request->new(GET => $uri)
    );
}

sub _failure_text {
    $_[0]->pxname . '/' .$_[0]->svname . " \n\turl: " . $_[1]->request->uri
    ."\n\tstatus: " . $_[1]->status_line . "\n\treason: ".$_[1]->decoded_content."\n"
}

# handles response from request of status
sub _status_response {
    my ($self, $heap, $resp) = @_[0, HEAP, ARG1];
    my $r = $resp->[0];

    die "ERROR: getting status failed for ". $self->_failure_text($r) 
        unless $r->is_success;

    my $stats;

    try { $stats = decode_json($r->content); } 
    catch { die "Invalid JSON from (" . $r->request->uri . ") : $_"; };

    unless(ref ($stats) eq 'HASH' && exists $stats->{scur}) {
        die 'Invalid structure from ('.$r->request->uri.') :'.pp($stats);
    }

    if ($stats->{status} ne 'MAINT') {
        say 'SUCCESS: server enabled '. $self->pxname .'/'.$self->svname
            .' on '.$self->service_url;
        $self->manager->task_complete(1);
    }
    else {
        say 'ERROR: server still in maintenance mode '. $self->pxname .'/'.$self->svname
            .' on '.$self->service_url;

        $self->manager->task_complete(0);
    }
}

1;
