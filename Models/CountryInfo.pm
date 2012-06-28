package Pinakes::Models::CountryInfo;

use Moo;
use Sub::Quote;
use DBIx::Simple;

#sub feed_lion {
#    my $self = shift;
#    my $amount = shift || 1;
#
#    $self->pounds( $self->pounds - $amount );
#}

has latlong => (
        is  => 'ro',
);
has latlong_coords_posxnegy => (
        is  => 'ro',
);

has surface_area => (
        is  => 'ro',
);

has country_name => (
        is  => 'ro',
);

has square_coords => (
    is  => 'ro',
);

has square_coords_posxnegy => (
    is  => 'ro',
);

has square_coords_wholeNum => (
    is  => 'ro',
);
1;
