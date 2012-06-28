#!/usr/bin/perl 
use strict;
use warnings;
use v5.10;

use HTML::TreeBuilder;


my $filename = 'test.html';
my $tree = HTML::TreeBuilder->new();

$tree->parse_file($filename);

# Then do something with the tree, using HTML::Element
# methods -- for example:

$tree->dump;

# Finally:

$tree->delete;
