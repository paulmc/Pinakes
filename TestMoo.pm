package Pinakes::TestMoo;

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

has width => (
        is => 'ro',
        #isa => sub { die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  },
        isa => quote_sub q{  die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  }, #potentially fatal;
    );

has height=> (
        is => 'ro',
        #isa => sub { die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  },
        isa => quote_sub q{  die "This value '$_[0]' is not a whole number!" if $_[0] =~ /[^0-9]+/;  }, #potentially fatal;
    );

has brand => (
        is  => 'ro',
        isa => sub {
            die "Only SWEET-TREATZ ".$_[0]."supported!" unless $_[0] eq 'SWEET-TREATZ'
        },
);

has pounds => (
        is  => 'rw',
        isa => quote_sub q{ die "$_[0] is too much cat food!" unless $_[0] < 15 }, #potentially fatal;
        );
1;
