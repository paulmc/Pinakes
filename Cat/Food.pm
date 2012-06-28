package Pinakes::Cat::Food;

use Moo;
use Sub::Quote;

sub feed_lion {
    my $self = shift;
    my $amount = shift || 1;

    $self->pounds( $self->pounds - $amount );
}

has taste => (
        is => 'ro',
        );

has brand => (
        is  => 'ro',
        isa => sub {
            die "Only SWEET-TREATZ supported!" unless $_[0] eq 'SWEET-TREATZ'
        },
);

has pounds => (
        is  => 'rw',
        isa => quote_sub q{ die "$_[0] is too much cat food!" unless $_[0] < 15 },
);
1;
