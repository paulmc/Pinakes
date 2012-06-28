package s1::Models::Image;
use warnings;
use strict;

# s1 Image model

use Moose;

has 'width'             => (is   => 'rw',    isa => 'Int');
has 'height'            => (is   => 'rw',    isa => 'Int');
has 'blob'              => (is   => 'rw',    isa => 'Str');
has 'filename'          => (is   => 'rw',    isa => 'Str');

has 'source_width'      => (is   => 'rw',    isa => 'Int');
has 'source_height'     => (is   => 'rw',    isa => 'Int');
has 'source_blob'       => (is   => 'rw',    isa => 'Str');
has 'source_filename'   => (is   => 'rw',    isa => 'Str');

has 'output_format'     => (is   => 'rw',    isa => 'Str', default => 'jpg');

has 'magick'            => (is => 'rw', isa => 'Image::Magick');

use Data::Dumper;
use Image::Magick;
use Carp;
use File::Path  qw(mkpath);
use File::Temp  qw(tempfile);
use File::Copy  qw(copy);

eval 'use File::Slurp';
our $has_file_slurp = ! $@;

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

sub reset
{
    my $self = shift;

    $self->filename($self->source_filename);
    $self->width(   $self->source_width);
    $self->height(  $self->source_height);
    $self->blob(    $self->source_blob);

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
        return write_file($filename, {binmode => ':raw'}, $self->blob);
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

=head1 NAME

s1::Models::Image - base class for an image object

=head1 SYNOPSIS

 use s1::Models::Image;

 my $image = s1::Models::Image->new(filename => q[/tmp/foo.jpg]);

 # get the dimensions of this image:
 my ($width, $height) = ($image->width, $image->height);

 # resize the image with a black background
 $image->resize(geometry => q[400x200], bgcolor => 'black');

 # give it a new filename
 $image->filename('/tmp/new-image.jpg');

 # and save it to that new filename
 $image->save;

 # or save a copy to an arbitrary filename
 $image->save('/tmp/mynew.jpg');

 # or get its data for saving myself, or for serving in a web request etc
 my $jpeg_data = $image->blob;

 # the width, height, blob, and filename attributes now reflect the
 # new, resized image. however any future resizes will work only on
 # the ORIGINAL image, so multiple versions of the same image can be
 # created easily.
 #
 # calling reset() on the image will force the four attributes above
 # back to their original values.

=head1 ATTRIBUTES

=over

=item width

Width is an integer.

=item height
jjjjj
Height is an integer.

=item blob

Blob holds the current image data for images which exist in memory.

=item filename

Filename holds the name of the file to be read in for new
images. Setting the filename attribute on an existing image object
will cause the save() method to save the image to that filename.

=item source_width

=item source_height

=item source_filename

=item source_blob

The source_width, source_height, source_filename and source_blob
attributes hold the 'original' version of the width, height, filename
and blob, respectively.

=item magick

The semi-private magick attribute holds an Image::Magick object.

=item output_format

Defaults to C<jpg>. Allows one to specify the format the resized image
blob should be in. Valid values are based on L<Image::Magick> formats,
which include C<gif>, C<png> and others. See
L<http://www.imagemagick.org/script/formats.php>.

=back

=head1 METHODS

=over

=item resize

The resize() method takes a geometry (in width x height format) and
creates an image which is the object's source image resized to the
appropriate width and height.

An optional 'bgcolor' attribute can contain a word (e.g. white black)
which determines the background colour for the container image, for
cases where the aspect ratio of the source image does not match the
aspect ratio of the resized image. This defaults to white. The list of
colours which may be used is available at the URL
L<http://www.imagemagick.org/script/color.php>

The width & height of the object reflect the width & height of the
current image, so calling resize() will alter the object's width and
height. (The width & height of the original version of the image are
available under source_width and source_height, if applicable.)
The resize method returns the blob() data for the new image, along
with setting it as the contents for the image's current blob()
attribute.

Multiple resize operations on the same image object will operate on
the 'original' version of the image each time (via the various
'source_*' attributes which are set when the image is created). Thus
it is possible to create an image object from an existing original
image and resize & save it multiple times without successive image
degradation:

 my $image = Image->new(filename => '/tmp/original.jpg');

 for my $size (qw(800x600 640x480 1024x768))
 {
    $image->resize(geometry => $size);
    $image->filename("/tmp/photo-$size.jpg");
    $image->save;
 }

Or even:

 my $image = Image->new(filename => '/tmp/original.jpg');

 for my $size (qw(800x600 640x480 1024x768))
 {
    $image->resize(geometry => $size);
    $image->save("/tmp/photo-$size.jpg");
 }

=item save

The save() method saves the image object's current blob data to the
image's filename (set in the filename attribute) or to an arbitrary
filename provided. The destination directory WILL be created if it
does not already exist.

=item reset

The reset() method forces the image's width, height, blob and filename
attributes back to their original values. This should not be required
in normal operation but may be needed for certain tasks.

=back

=head1 BUGS

The C<Image> object currently works on C<JPEG> images. Support for
other image formats needs to be added.

=head1 COPYRIGHT

Copyright 2010 s1, a division of Newsquest (Herald & Times) Ltd.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

