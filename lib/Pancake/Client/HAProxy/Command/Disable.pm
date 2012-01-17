package Pancake::Client::HAProxy::Command::Disable;
use 5.012;
use Moose;
extends 'MooseX::App::Cmd::Command';
with 'Pancake::Client::HAProxy::Params';
with 'Pancake::Client::HAProxy::TaskManager';
use POE;
use Pancake::Client::HAProxy::TaskDisable;
use namespace::autoclean;

has force => (is => 'ro', isa => 'Bool', default => 0);

sub BUILD {
    my ($self) = @_;

    $self->_setup_agent;

    for my $url ($self->service_urls) {
        Pancake::Client::HAProxy::TaskDisable->new(
            service_url        => $url,
            manager            => $self,
            skip_session_check => $self->force,
            svname             => $self->svname,
            pxname             => $self->pxname,
        )
    }
}

1;


