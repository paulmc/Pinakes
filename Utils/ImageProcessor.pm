package Pinakes::Utils::ImageProcessor;
use strict;
use warnings;
use 5.10.1;

use Moo;

has 'width'             => (is   => 'rw');
has 'height'            => (is   => 'rw');
has 'blob'              => (is   => 'rw');
has 'filename'          => (is   => 'rw');

has 'imageObj'  => ( is => 'ro', );
has 'sizes'     => ( is => 'ro');
has 'imagePath' => ( is => 'ro'  );

has 'source_width'      => (is   => 'rw');
has 'source_height'     => (is   => 'rw');
has 'source_blob'       => (is   => 'rw');
has 'source_filename'   => (is   => 'rw');

has 'output_format'     => (is   => 'rw');

has 'magick'            => (is => 'rw');

use Image::Magick;
use Data::Dumper;
use Image::Magick;
use Carp;
use File::Path  qw(mkpath);
use File::Temp  qw(tempfile);
use File::Copy  qw(copy);


eval 'use File::Slurp' ;
our $has_file_slurp = ! $@;


my ($self, $imageObj, $imagePath, $sizes)  = map{ undef } 1..4;
sub BUILD
{
    my $self = shift;

    $self->magick(Image::Magick->new(magick=> $self->output_format)) if ! $self->magick;

    if (my $filename = $self->filename)
    {
        my ($w,$h,$s,$f) = map {undef} 1..4;

        if (0 and $filename =~ /\s/) # image magick won't read it if it has a space, so copy it temporarily just to read it
        {
            my $fh = File::Temp->new(SUFFIX => '.' . $self->output_format);
            close $fh;
            copy($filename, $fh->filename);

            ($w,$h,$s,$f) = $self->magick->Ping($fh->filename);

            unlink $fh->filename;
        }
        else
        {
            ($w,$h,$s,$f) = $self->magick->Ping($filename);
        }

        if ($w && $h)
        {
            $self->width($w);       $self->source_width($w);
            $self->height($h);      $self->source_height($h);
        }

        $self->source_filename($filename);
    }
    elsif (my $blob = $self->blob)
    {
        $self->magick->BlobToImage($blob);

        my $width   = $self->magick->Get('width');
        my $height  = $self->magick->Get('height');

        $self->width($width);    $self->source_width($width);
        $self->height($height);  $self->source_height($height);

        $self->source_blob($blob);
    }

    return $self;
}

sub save
{
    my $self     = shift;
    my $filename = $self->filename || shift or return;
    my $dir = $filename;
    $dir =~ s/\/[^\/]+$//s;

    if (! -d $dir)
    {
        mkpath $dir or die "$dir: $!";
    }

    if ($has_file_slurp) # preferred
    {
#print Dumper($filename, $has_file_slurp, $self->blob, $self->width);last;
        return write_file($filename, {binmode => ':raw'}, $self->blob);
# return write_file($filename, {binmode => ':raw'}, $self->blob);
    }
    else
    {
        open my $out, ">", $filename or croak "$filename: $!";
        print $out $self->blob;
        return close $out;
    }
}


sub resize
{
    my $self     = shift;
    my %options  = (bgcolor => 'white', geometry => undef, @_);

    my $geometry = $options{geometry} || sprintf("%dx%d", $options{width} || $self->width,
            $options{height} || $self->height);

    substr($geometry, 0, 1) =~ /^\d+$/ or croak "No dimensions in '$geometry' to resize to";

    $geometry =~ tr/ //sd; # remove spaces, so we can do geometry => '100 x 200' ok

        my $cm = Image::Magick->new(magick => $self->output_format); # container image
        $cm->Set(size => $geometry);
    $cm->ReadImage("xc:$options{bgcolor}");

    my ($width, $height) = split 'x', $geometry;

    $self->width($width);
    $self->height($height);

    my $portrait         = $height > $width; # otherwise landscape

        source_image:
        {
            my $m = Image::Magick->new(); # was: magick => 'jpg'; now this supports non-jpg source images

                my ($source_width, $source_height, $size, $format) = map {undef} 1..4;

            if (my $filename = $options{filename} || $self->source_filename) # options{filename} is for backward-compatibility
            {
                if (-r($filename))
                {
                    if ($filename =~ /\s/) # image magick won't read it if it has a space, so copy it temporarily just to read it
                    {
                        my $fh = File::Temp->new(SUFFIX => '.' . $self->output_format);
                        close $fh;
                        copy($filename, $fh->filename);

                        ($source_width, $source_height, $size, $format) = $m->Ping($fh->filename);
                        $m->Read($fh->filename);

                        unlink $fh->filename;
                    }
                    else
                    {
                        ($source_width, $source_height, $size, $format) = $m->Ping($filename);
                        $m->Read($filename);
                    }
                }
            }
            elsif (my $blob = $self->source_blob)
            {
                $m->BlobToImage($blob);

                ($source_width, $source_height, $size, $format) = ($m->Get('width'), $m->Get('height'), length($blob), undef);
            }
            else { croak "Please provide a blob or a filename" }

            my ($new_width, $new_height)       = (undef,undef);
            $m->Set(colorspace => 'RGB');
            $m->Profile(profile => "");

            my $source_portrait = $source_height > $source_width;

            if ( ! $portrait and ! $source_portrait ) # one landscape image going into another
            {
                my $calc = $width / ($source_width || 1);

                ($new_width, $new_height) = map {int()} ($width, ($source_height * $calc));
            }
            elsif (! $portrait and $source_portrait) # a source portrait image going into a landscape image
            {
                my $calc = $height / ($source_height || 1);

                ($new_width, $new_height) = map {int()} ($source_width * $calc, $height);
            }
            elsif ($portrait and $source_portrait) # portrait image going into a portrait image
            {
                my $calc = $width / ($source_width || 1);

                ($new_width, $new_height) = map {int()} ($width, ($source_height * $calc));
            }
            elsif ($portrait and ! $source_portrait) # landscape image going into a portrait image
            {
                my $calc = $width / ($source_width || 1);

                ($new_width, $new_height) = map {int()} ($width, ($source_height * $calc));
            }
            else { die }

            if ($new_width > $source_width)
            {
                $new_width  = $source_width;
                $new_height = $source_height;
            }
            if ($new_height > $source_height)
            {
                $new_height = $source_height;
                $new_width  = $source_width;
            }

            for (my $counter = 1;
                    $counter < 1_000_000
                    and
                    ($new_width > 0 and $new_height > 0
                     and
                     ($new_width > $width or $new_height > $height));
                    ++$counter)
            {
                ($new_width, $new_height) = map {$_ - (int($_ * 0.01) || 1)} ($new_width, $new_height);
            }

            my $new_geometry = sprintf("%dx%d", $new_width, $new_height);

            $m->Resize(geometry => $new_geometry);

            $cm->Composite(gravity => 'center', image => $m);
        }
    if ($options{annotate}) # this is a trial, font/colour/background would need fixed/set
    {
        $cm->Annotate(fill => 'green', pointsize => 20, geometry => sprintf("%dx0",$width),
                gravity => 'NorthEast',
                font => '/usr/share/imlib2/data/fonts/notepad.ttf',
                text => $options{annotate});
    }
    $cm->Set(colorspace => 'RGB');
    $cm->Profile(profile => "");

    $self->magick($cm);

    return $self->blob(($cm->ImageToBlob())[0]);
}
#sub process{
#    $self = shift;
#
#    foreach my $size (@{$self->sizes})
#    {
#        my $im = Image::Magick->new;
#
#        my $x = $im->Read($self->imageObj);
#
#        $x = $im->Write($self->imagePath."$size.jpg");
#    } 
#    return 1;
#}

1;

=head1 NAME

C<Pinakes::Utils::ImageProcessor> - Datacreations .....................................

=head1 SYNOPSIS


    #!/usr/bin/perl;
    use strict;
    use warnings;
    use 5.10.1;
    use Data::Dumper;
    
    require Pinakes::Utils::ImageProcessor;
    
    my $image = q[/home/paulmc/sedb_school03.jpg];
    my $libraryPath = q[/home/paulmc/PictureLibrary/]; 
    my $sizes = ['100x75', '200x150']; 
    
    my $ip = Pinakes::Utils::ImageProcessor->new(
            imageObj => $image,
            imagePath => $libraryPath,
            sizes => $sizes,
            );
    
    $ip->process;
    my $array_ref = $ip->sizes;

#has width => (
#        is => 'ro',
#        isa => sub { die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  },
#    );
#
#has height=> (
#        is => 'ro',
#        isa => sub { die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  },
#);

=head1 DESCRIPTION

A generic OO library for creating multiple image files. The OO aspect of the file is handled my Moo.

=head1 COPYRIGHT

Copyright 2012 Datacreations.

=cut

