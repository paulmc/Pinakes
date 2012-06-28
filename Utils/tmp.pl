#!/usr/bin/perl;

use strict;
use warnings;
use 5.10.1;
use Data::Dumper;



 use Pinakes::Utils::ImageProcessor;

 my $img = q[/tmp/test.jpg];
 my $image = Pinakes::Utils::ImageProcessor->new(filename => $img);

for my $size (qw(800x600 640x480 1024x768))
{
    $image->resize(geometry => $size);
    $image->save("/tmp/photo-$size.jpg");
}


 # or get its data for saving myself, or for serving in a web request etc
