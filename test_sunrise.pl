use Astro::Sunrise;
use Date::Calc qw/Today_and_Now/;
use v5.10;

#use Astro::Sunrise qw(:constants);
my ($y, $m, $d) = Today_and_Now();
my $longitude = 55.878832;
my $latitude  = -4.281262;
my $time_zone = 0;
my $dst         = 0;

my ($sunrise, $sunset) = sunrise($y,$m,$d,$longitude,$latitude,$time_zone,$dst);
say "$sunrise, $sunset ";
#($sunrise, $sunset) = sunrise($y,$m,$d,$longitude,$latitude,Time Zone,DST,ALT);
#($sunrise, $sunset) = sunrise($y,$m,$d,$longitude,$latitude,Time Zone,DST,ALT,inter);
#
#$sunrise = sun_rise($longitude,$latitude);
#$sunset = sun_set($longitude,$latitude);
#
#$sunrise = sun_rise($longitude,$latitude,ALT);
#$sunset = sun_set($longitude,$latitude,ALT);
#
#$sunrise = sun_rise($longitude,$latitude,ALT,day_offset);
#$sunset = sun_set($longitude,$latitude,ALT,day_offset);
