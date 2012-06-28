package Pinakes::Utils::Upload;
use strict;
use warnings;
use 5.10.1;

use CGI;
use Data::Dumper;
use Pinakes::Utils::ImageProcessor;
use Tenjin;
use CGI::Carp qw ( fatalsToBrowser ); 
use File::Basename;

handler() if -t and !caller();

sub handler
{
    my $r = shift;

   MAIN:
    {
        my $q      = CGI->new;
        my %values = ();
        my $upload_dir = "/home/paulmc/PictureLibrary/upload";

        if(!$q->param)
        {
            $values{title} = 'Upload page';
            my $output = do{
                my %options = ( 'cache' => 0 );
                my $engine = Tenjin->new(\%options);
                my $context = \%values;
                my $filename = '/home/paulmc/websites/handymanservicesglasgow.co.uk/admin/upload.tt';
                $engine->render($filename, $context);
            };
            print $q->header('text/html'),  $output;
            #say $q->header('text/html'), " Hello From the Uploader";
        }
        elsif($ENV{REQUEST_METHOD} == 'POST')
        {
             
            my $image = $q->upload(image);
            my $libraryPath = $q->param(libraryPath);
            my $sizes = $q->param(sizes);

            my $ip = Pinakes::Utils::ImageProcessor->new(
                    imageObj => $image,
                    imagePath => $libraryPath,
                    sizes => $sizes,
            );
            $ip->process;


            $values{title} = 'Upload page with Post';
            $values{success} = 'success';
            $values{sizes} = $ip->sizes;
            $values{comment} = $q->comment(\%values);
            $values{ip} = $ip;
            my $output = do{
                my %options = ( 'cache' => 0 );
                my $engine = Tenjin->new(\%options);
                my $context = \%values;
                my $filename = '/home/paulmc/websites/handymanservicesglasgow.co.uk/admin/upload.tt';
                $engine->render($filename, $context);
            };
            $output .= $q->comment($output);
            print $q->header('text/html'),  $output;
        }
    }
    return "OK";
}
1;


=head1 NAME

C<Pinakes::Util::Upload%> - Datacreations .....................................

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 VALUES PROVIDED TO THE TEMPLATE



=head1 MODELS



=head1 SUBROUTINES



=head1 COPYRIGHT

Copyright 2012 Datacreations.

=cut

