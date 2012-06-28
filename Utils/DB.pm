package Pinakes::Utils::DB;

use DBIx::Simple;


sub create_connection
{
    my $self = shift;

    my $user                     = "web";
    my $password                 = "l3tt3rs";
# Connecting to a MySQL database
    my $db = DBIx::Simple->connect(
            'DBI:mysql:database=world',     # DBI source specification
            $user , $password,                      # Username and passwordt
            { RaiseError => 1 }                 # Additional options
    );
}
1;
