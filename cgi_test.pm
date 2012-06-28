package Pinakes::cgi_test; 
use strict;
use warnings;

#use Apache::Constants qw(:common);
use CGI;
use Data::Dumper;
use v5.10;

sub handler
{
    my $r = shift;
    MAIN:
    {
        my $q = CGI->new;
        
        print_this("hello");
    }
    return "OK";
}

sub print_this
{
    my ($string) = @_;
    printf("the string arg is :%s", $string);
}
1;
