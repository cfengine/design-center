package DCAPI::Result;

use strict;
use warnings;

use JSON;
use Mo qw/default build builder is required option/;

has api => ( is => 'ro', required => 1 );

has status => ( is => 'ro', default => sub { 1 } );
has success => ( is => 'rw' );
has warnings => ( is => 'ro', default => sub { [] } );
has errors => ( is => 'ro', default => sub { [] } );
has log => ( is => 'ro', default => sub { [] } );
has error_tags => ( is => 'ro', default => sub { {} } );
has tags => ( is => 'ro', default => sub { {} } );
has data => ( is => 'ro', default => sub { {} } );

sub data_dump
{
    my $self = shift @_;
    my $top_key = $self->status() ? 'api_ok' : 'api_error';

    return {
            $top_key =>
            {
             success => ($self->success() ? JSON::PP::true : JSON::PP::false),
             warnings => $self->warnings(),
             errors => $self->errors(),
             log => $self->log(),
             tags => $self->tags(),
             error_tags => $self->error_tags(),
             data => $self->data(),
            }
           };
}

sub to_string
{
    my $self = shift @_;
    return $self->api()->encode($self->data_dump());
}

sub out
{
    my $self = shift @_;
    print $self->to_string(), "\n";
}

sub add_tags
{
    my $self = shift @_;
    my $tags = shift @_;

    $tags = [$tags] if ref $tags ne 'ARRAY';
    $self->tags()->{$_}++ foreach @$tags;
}

sub add_error
{
    my $self = shift @_;
    my $tags = shift @_;
    $self->success(0);
    $tags = [$tags] if ref $tags ne 'ARRAY';
    $self->error_tags()->{$_}++ foreach @$tags;
    push @{$self->errors()}, @_;

    return $self;
}

sub add_warning
{
    my $self = shift @_;
    my $tags = shift @_;

    $self->add_tags($tags);
    push @{$self->warnings()}, @_;

    return $self;
}

sub add_log
{
    my $self = shift @_;
    my $tags = shift @_;

    $self->add_tags($tags);
    push @{$self->log()}, @_;

    return $self;
}

sub add_data_key
{
    my $self = shift @_;
    my $tags = shift @_;
    my $keys = shift @_;
    my $value = shift @_;

    $self->add_tags($tags);

    my $top = $self->data();
    while (my $k = shift @$keys)
    {
        next unless ref $top eq 'HASH';

        if (scalar @$keys)
        {
            $top->{$k} ||= {};
            $top = $top->{$k};
        }
        else
        {
            $top->{$k} = $value;
        }
    }

    return $self;
}

1;
