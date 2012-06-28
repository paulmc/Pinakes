package Pinakes::Form::User;
use strict;
use warnings;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';

# Associate this form with a DBIx::Class result class
# Or 'item_class' can be passed in on 'new', or you
# you can always pass in a row object
has '+item_class' => ( default => 'User' );

# Define the fields that this form will operate on
# Field names are usually column, accessor, or relationship names in your
# DBIx::Class result class. You can also have fields that don't exist
# in your result class.

has_field 'name'    => ( type => 'Text', label => 'Username', required => 1,
        required_message => 'You must enter a username', unique => 1,
        unique_message => 'That username is already taken' );

# the css_class, title, and widget attributes are for use in templates
has_field 'age'     => ( type => 'PosInteger', required => 1, css_class => 'box',
                         title => 'User age in years', widget => 'age_text', range_start => 18 );
has_field 'sex'     => ( type => 'Select', label => 'Gender', required => 1 );
# a customized field class
has_field 'birthdate' => ( type => '+MyApp::Field::Date' );
has_field 'hobbies' => ( type => 'Multiple', size => 5 );
has_field 'address' => ( type => 'Text' );
has_field 'city'    => ( type => 'Text' );
has_field 'state'   => ( type => 'Select' );

has '+dependency' => ( default => sub {
        [
            ['address', 'city', 'state'],
        ],
    }
);

no HTML::FormHandler::Moose;
1;

