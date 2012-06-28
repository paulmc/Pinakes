#!/usr/bin/perl 
use strict;
use warnings;
use v5.10;

use Geo::IPfree;

my $geo = Geo::IPfree->new;
my( $code1, $name1 ) = $geo->LookUp( '208.80.194.29');
say "$code1 , $name1";


# use memory to speed things up
$geo->Faster;

# lookup by hostname
my( $code2, $name2, $ip2 ) = $geo->LookUp( 'www.s1homes.com' );
say "$code2 , $name2, $ip2";
say $geo->LookUp( 'www.s1homes.com' );
