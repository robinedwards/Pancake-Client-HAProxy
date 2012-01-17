package Pancake::Client::HAProxy::Params;
use 5.012;
use Moose::Role;
with 'MooseX::ConfigFromFile';

sub get_config_from_file { Config::JFDI->open($_[1]) }

has pxname                  => (is => 'ro', isa => 'Str', required => 1);
has svname                  => (is => 'ro', isa => 'Str', required => 1);
has useragent_timeout       => (is => 'ro', isa => 'Int', default => 10);

has service_url => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    traits   => ['Array'],
    handles  => { 'service_urls' => 'elements' }
);

1;
