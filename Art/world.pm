package Pinakes::Art::world; 
use strict;
use warnings;

#use Apache::Constants qw(:common);
use DBIx::Simple;
use CGI;
use Data::Dumper;

use Pinakes::Utils::DB;
use aliased 'Pinakes::Utils::CountryInfo';
use v5.10;
use Tenjin;
$Tenjin::USE_STRICT = 1;        # use strict in the embedded Perl inside
#$Tenjin::ENCODING = "UTF-8";    # set the encoding of your template files


handler() if -t and !caller();

sub handler
{
    my $r = shift;

    MAIN:
    {
        my $user                     = "root";
        my $password                 = "mysql";
        my %values = ();
        my @two_letter_country_codes;
        my @geo_status;

        my $q = CGI->new;
        my $db = Pinakes::Utils::DB->create_connection;

        my $country = CountryInfo->new(
                taste  => 'DELICIOUS.',
                brand  => 'SWEET-TREATZ',
                pounds => 10,
                );

        $values{title} = q[Tenjin Example];
        @two_letter_country_codes   = return_country_codes_array($db);
        $values{geo_arrayref}       = return_country_geo_stats($db);
        my @countries               = return_country_names_by_isocode_hash($db);
        $db->disconnect();
        my %options = ( 'cache' => 0 );
        my $engine = Tenjin->new(\%options);
        #my $context = { title => 'Tenjin Example', items => @$geo_arrayref, title };
#        my $context = { title => 'Tenjin Example', items => \@geo_arrayref };
        my $context = \%values;

        my $filename = '/home/paul/public_html/art.datacreations.co.uk/public/file.html';
        my $output = $engine->render($filename, $context);
        print $output;
        last MAIN;
    }
    return "OK";
}

sub return_country_names_by_isocode_hash
{
    my ($db) = @_;
    my @countries;
    for my $row ( $db->query('select iso_code, Name from Country')->hashes )
    {
        push(@countries, $row);
    }
    return @countries;
}

sub return_country_codes_array
{
    my ($db) = @_;
    return my @names = $db->query("SELECT iso_code FROM Country WHERE Name != ''")->flat;
}
  
sub return_country_geo_stats
{
    my ($db) = @_;
    my @geos;

    for my $row ( $db->query('select iso_code, box_north, box_south, box_west, box_east,  AsText(latlong) as points from Country')->hashes )
    {
        push(@geos, $row);
    }
    return \@geos;
}
1;
