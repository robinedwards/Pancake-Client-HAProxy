package Pancake::Client::HAProxy::TaskManager;
use 5.012;
use Moose::Role;
use POE 'Component::Client::HTTP';
use namespace::autoclean;

has timeout => (is => 'ro', isa => 'Int');

sub task_complete {
    my ($self, $status) = @_;

    state $failed = 0;
    state $succeeded = 0;
    $status ? $succeeded++ : $failed++;

    exit $failed
        if (scalar (@{$self->service_url}) == ($failed + $succeeded));
}

sub _setup_agent {
    POE::Component::Client::HTTP->spawn(
        Agent     => 'Pancake::HAProxy::Client',
        Alias     => 'useragent',
        Timeout   => $_[0]->useragent_timeout,
    );
}

sub execute {
    my ($self) = @_;

    if (0) {
        POE::Session->create(
            inline_states => {
                _start => sub {
                    POE::Kernel->delay_set(timeout => $self->timeout)
                },
                timeout => sub {
                    say "ERROR: disabling servers timed out";
                    exit 255;
                }
            }
        );
    }


    POE::Kernel->run
}

1;
