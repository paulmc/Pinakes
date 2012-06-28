#!/usr/bin/perl;
use strict;
use warnings;
use Data::Dumper;
use 5.10.0;
my @kk = (["Hello","Perl"], ["Monks"]);
say scalar(@kk);
foreach my $i(0..$#kk){
     my @test = $kk[$i];
     print Dumper(\@test);
}

