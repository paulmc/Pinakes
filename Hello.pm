package Pinakes::Hello;
use strict;
use warnings;
use Data::Dumper;

use v5.10;

sub new {
    my $self = {};
    $self->{greeting} = 'hello'; 
    bless $self;
    return $self;
}

sub greetUser
{
    my $self =shift;
    if(@_) { $self->{greeting} .= shift }
    return $self->{greeting};
}

sub processParams
{
    my $self =shift;
    my ($params) = @_;
    my %hash = %$params;
    while ( my($key,$value) = each %hash) 
    {
        $hash{$key} = "processed $value"; 
    }
    return \%hash;
}
1;

