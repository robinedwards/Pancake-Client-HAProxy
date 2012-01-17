package Pancake::Client::HAProxy::Command::Enable;
use 5.012;
use Moose;
extends 'MooseX::App::Cmd::Command';
with 'Pancake::Client::HAProxy::Params';
with 'Pancake::Client::HAProxy::TaskManager';
use POE;
use Pancake::Client::HAProxy::TaskEnable;
use namespace::autoclean;

has force => (is => 'ro', isa => 'Bool', default => 0);

sub BUILD {
    my ($self) = @_;

    $self->_setup_agent;

    for my $url ($self->service_urls) {
        Pancake::Client::HAProxy::TaskEnable->new(
            service_url        => $url,
            manager            => $self,
            skip_status_check  => $self->force,
            svname             => $self->svname,
            pxname             => $self->pxname,
        )
    }
}

1;


