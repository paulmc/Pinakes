package Pinakes::Art::revolting; 
use strict;
use warnings;

#use Apache::Constants qw(:common);
use DBIx::Simple;
use CGI;
use Data::Dumper;

use Pinakes::Utils::DB;
use aliased 'Pinakes::Models::CountryInfo';
use v5.10;
use Tenjin;

handler() if -t and !caller();

sub handler
{
    my $r = shift;

    MAIN:
    {

        my $two_letter_country_codes_arrayref;
        my $latlong_coords_hashref;
        my $latlong_coords_posxnegy_hashref;
        my $geobox_coords_hashref;
        my $country_names_hashref;
        my $surface_area_hashref;
        my $scale  = 5;
        my $width  = 1920;
        my $height =  960;
        my $earth_surface_area = 510072000; # KM2
        my $earth_surface_area = $width*$height; # KM2

        my %country_hash2 = ();
        my %values;

        my $q = CGI->new;
        my $db = Pinakes::Utils::DB->create_connection;

        if($q->param('latlong'))
        {
            $values{latlong} = 1;
        }
        $two_letter_country_codes_arrayref  = return_country_codes_array($db);
        $latlong_coords_hashref             = return_country_latlong($db, 1, $width, $height);
        $latlong_coords_posxnegy_hashref    = return_country_latlong_posxnegy($db, 1, $width, $height, $scale);
        $geobox_coords_hashref              = return_country_geobox_posxnegy($db, 1, $width, $height, $scale);
        $country_names_hashref              = return_country_names($db);
        $surface_area_hashref               = return_country_surface_area($db);

        foreach my $cc (@$two_letter_country_codes_arrayref)
        {
            $country_hash2{$cc} = CountryInfo->new(
                    #surface area as percentage
                    'surface_area'            => $surface_area_hashref->{$cc}/$earth_surface_area*30, 
                    'country_name'            => $country_names_hashref->{$cc},
                    'latlong_coords_posxnegy' => $latlong_coords_posxnegy_hashref->{$cc},
                    'latlong'                 => $latlong_coords_hashref->{$cc},
                    'square_coords'           => $geobox_coords_hashref->{$cc},
                    );
        }
        $values{country_hash} = \%country_hash2;
        $db->disconnect();


        my $output = do{
            my %options = ( 'cache' => 0 );
            my $engine = Tenjin->new(\%options);
            my $context = \%values;
            my $filename = '/home/paulmc/websites/paulpmcnally.co.uk/revolt.tt';
            $engine->render($filename, $context);
        };
        print $q->header('text/html'),  $output;
    }
    return "OK";
}

sub return_country_surface_area
{
    my ($db) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT `SurfaceArea`, `code2` FROM Country WHERE latlong != ''")->hashes) 
    {
        next if $row->{code2} eq '';
        $return_hash{$row->{code2}} = $row->{surfacearea};
    }
    return \%return_hash;
}

sub return_country_names
{
    my ($db) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT  `code2`, `name` FROM Country WHERE latlong != ''")->hashes) 
    {
        next if $row->{code2} eq '';
        $return_hash{$row->{code2}} = $row->{name};
    }
    return \%return_hash;
}

sub return_country_codes_array
{
    my ($db) = @_;
    my @codes = $db->query("SELECT Code2 FROM Country WHERE latlong != ''")->flat;
    return \@codes;
}

sub return_country_latlong_posxnegy
{
    my ($db, $wholeNums, $width, $height, $scale) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT  `code2`, AsText(`latlong`) as latlong FROM Country WHERE latlong != '' ")->hashes) 
    {
        next if $row->{code2} eq '';
        next if $row->{latlong} eq '';
        $row->{latlong} =~ s/[A-Z]+//;
        $row->{latlong} =~ s/\.[0-9]+//g if defined($wholeNums);
        my ($x, $y) = split(' ', $row->{latlong});
        $x =~ s/\(//;
        $y =~ s/\)//;
        $x *= $scale;
        $y *= $scale;
        $x += $width / 2 ;
        $y -= $height / 2 ;
        $y *= -1 if $y < 1;#always positive for the monitor

        $return_hash{$row->{code2}} = qq[$x, $y];
    }
    return \%return_hash;
}

sub return_country_latlong
{
    my ($db, $wholeNums) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT  `code2`, AsText(`latlong`) as latlong FROM Country WHERE latlong != '' ")->hashes) 
    {
        next if $row->{code2} eq '';
        next if $row->{latlong} eq '';
        $row->{latlong} =~ s/[A-Z]+//;
        $row->{latlong} =~ s/ /,/;
        $row->{latlong} =~ s/\.[0-9]+//g if defined($wholeNums);
        $return_hash{$row->{code2}} = $row->{latlong};
    }
    return \%return_hash;
}

sub return_country_geobox
{
    my ($db, $wholeNums) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT `code2`, `box_east`, `box_north`, `box_west`, `box_south` FROM Country WHERE latlong != ''")->hashes) 
#for my $row ($db->query("SELECT `code2`, AsText(`latlong`) AS `latlong`, `box_north`, `box_west`, `box_south`, `box_east` FROM Country WHERE latlong != ''")->hashes) 
    {
        next if $row->{code2} eq '';
        for ($row->{box_west}, $row->{box_north}, $row->{box_east},  $row->{box_south}) { s/\.[0-9]+//g } #if defined($wholeNums);

    }

    return \%return_hash;
}

# translate the geobox to posx negy (a standard monitor starts from top left)
sub return_country_geobox_posxnegy
{
    my ($db, $wholeNums, $width, $height, $scale) = @_;
    my %return_hash = ();
    for my $row ($db->query("SELECT `code2`, `box_west`, `box_north`, `box_south`, `box_east` FROM Country WHERE latlong != ''  ")->hashes) 
    {
       
        foreach ($row->{box_west}, $row->{box_north}, $row->{box_east},  $row->{box_south}) { s/\.[0-9]+//g } #if defined($wholeNums);
        ($row->{box_west}, $row->{box_north}, $row->{box_east},  $row->{box_south}) = map {  $_*= $scale; }   ($row->{box_west}, $row->{box_north}, $row->{box_east},  $row->{box_south}) ;
        ($row->{box_south}, $row->{box_north}) = map { $_ -= $height/2;}  ($row->{box_south}, $row->{box_north});
        ($row->{box_west}, $row->{box_east}) = map { $_ += $width/2;}  ($row->{box_west}, $row->{box_east});
        foreach ($row->{box_west}, $row->{box_north}, $row->{box_east},  $row->{box_south}) { s/-//g } #if defined($wholeNums);
        $row->{box_east} -= $row->{box_west};
        $row->{box_north} -= $row->{box_south};
#
        $return_hash{$row->{code2}} = join(',',  $row->{box_west}, $row->{box_south}, $row->{box_east}, $row->{box_north});
    }

    return \%return_hash;
}
1;
