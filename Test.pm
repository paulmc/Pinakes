package Pinakes::Test;
use strict;
use warnings;

#use Apache::Constants qw(:common);
use CGI;
use Data::Dumper;

use v5.10;

handler() if -t and !caller();

sub handler
{
    my $r = shift;

    MAIN:
    {
        my $q = CGI->new;
        say $q->header('text/html'), " Hello ";
    }
    return "OK";
}

1;

