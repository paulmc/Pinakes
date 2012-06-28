#!/usr/bin/perl 
use strict;
use warnings;
use v5.10;

use Pinakes::Cat::Food;

my $full = Pinakes::Cat::Food->new(
        taste  => 'DELICIOUS.',
        brand  => 'SWEET-TREATZ',
        pounds => 10,
        );

$full->feed_lion;

say $full->pounds(14);
say $full->taste;
say $full->brand('SWEET-TREATZ');
