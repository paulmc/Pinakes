package Pinakes::MooseTest;
use strict;
use warnings;

use Moose;

has 'name' => ( is => 'rw', isa => 'Str' );
has 'age' =>  ( is => 'rw', isa => 'Int' );

#use Class::XSAccessor
#    getters      => {
#        get_name => 'name', # 'name' is the hash key to access
#        get_age  => 'age',
#    },
#    setters      => {
#        set_name => 'name',
#        set_age  => 'age',
#    },
#    accessors    => {
#        name     => 'name',
#        age      => 'age',
#    },
#    predicates   => {
#        has_name => 'name',
#        has_age  => 'age',
#    },
# true  => [ 'is_token', 'is_whitespace' ],
#         false => [ 'significant' ];
#  
#
1;
