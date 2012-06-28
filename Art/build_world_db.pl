use DBI;
use strict;
use warnings;
use 5.10.1;
use LWP::UserAgent;
use IO::Socket::SSL;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Time::HiRes qw(usleep nanosleep);

MAIN:
{
    my @two_letter_country_codes = ();
    my @field_names              = ();
    my $port                     = 3306;
    my $hostname                 = "localhost";
    my $user                     = "root";
    my $password                 = "mysql";
    my $database                 = "world";
    my $country_name;
    my $sth;
    my $tables_created = 0;
    my %info_hash;
    my %md5_field_name = ();

    #db connections
    my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
    my $dbh = DBI->connect( $dsn, $user, $password,
        { raiseError => 1, AutoCommit => 0 } );

  build_array_of_country_codes:
    {
        $sth = $dbh->prepare("SELECT Code2, Name FROM Country WHERE Name != ''");
        $sth->execute();

        while ( my $ref = $sth->fetchrow_hashref() ) {
            push( @two_letter_country_codes, lc( $ref->{'Code2'} ) );
            $country_name = $ref->{'Name'};
        }
    }

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $ua->protocols_allowed( [ 'http', 'https' ] );

    for my $c_code (@two_letter_country_codes) 
    {
        say "processing $c_code" if -t;
        my $url = "https://www.cia.gov/library/publications/the-world-factbook/geos/$c_code.html";
        # $url = "https://www.cia.gov/library/publications/the-world-factbook/geos/countrytemplate_$c_code.html";

        my $response = $ua->get($url);
        if ( !$response->is_success ) 
        {
            say $response->status_line if -t;
            next;
        }
        my $read_in_text = $response->decoded_content;
        my $text;

        my @split = split("<div id=\"CollapsiblePanel1_Intro\" class=\"CollapsiblePanel\" style=\"width:598px; \">",
            $read_in_text
        );
        $text = $split[1];
        @split = ( "<div id=\"backtotop\">", $text );

      create_and_write_data:
        {
            say "create and write data $c_code" if -t;

            #clean up text
            $text =~ s!//var(.*)!!gm;    #remove javascript first
            $text =~ s!var(.*)!!gm;
            $text =~ s/<!--(.*)//gmi;
            $text =~ s/-->//gmi;
            $text =~ s/\/\///gmi;
            $text =~ s/&nbsp;//g;
            #Remove region name
            $text =~ s/<span class=\"region\" style=\"font-weight: normal;\">(?:.*?)<\/span>/\n/g;

            $text =~ s/<em>//gm;         #remove html tags
                                         #FLAG these
                                         # database
            $text =~ s/<span class=\"category\">(.*)/CATEGORY-$1\n/g;
            # db fields
            $text =~ s/title=\"Definitions and Notes\: Background\">/>FIELD-Background</g;  
            $text =~ s/title=\"Definitions and Notes\:(.*)\">/>FIELD_FLAG-$1</g;  
            # FIELD
            $text =~ s/<div class=\"category\">(.*)/\nFIELD-$1/g;    
            $text =~ s/<div class=\"category\" style=\"padding-top\: 2px;\">(.*)/\nFIELD-$1/gm;
            $text =~ s/alt=\"Country comparison to the world\">([0-9])/\>FIELD-country comparison to the world\n\nDATA-$1/gm;

            # db field sub
            $text =~ s/<div class=\"category_data\" style=\"padding-top: 3px;\">(.*)/\n/g;    
            $text =~ s/<span class=\"category_data\" style=\"font-weight:normal; vertical-align:top;\">(.*)</\nDATA-$1\n</g;
            $text =~ s/<div class=\"category_data\">(.*)<\/div>/DATA-$1/g;
            # data info
            $text =~ s/>([0-9+])<\/a>/>\nDATA-$1\n</g;    

            $text =~ s/<(?:.*?)>/\n/g;    #remove html tags
            $text =~ s/\cM\n//g;          #remove bastard ^M char
            $text =~ s/\s+[\n+]/\n/gsi;
            $text =~ s/\t+//g;
            $text =~ s/\n +/\n/g;
            $text =~ s/- +/-/g;
            $text =~ s/ -/-/g;
            $text =~ s/(country comparison to the world):\n(.*)/\nFIELD-$1\n\nDATA-$2/gm;
            $text =~ s/^?\s[\s|:]+\n/\n/gm;
            $text =~ s/^([0-9])/\n\nDATA-$1/g;
            $text =~ s/\n+/\n/gs;

            @split = split( "Expand All", $text );
            $text = $split[0];

            open( my $fh, ">", 'data.txt' );

            print $fh $text;
            close($fh);
        }

        # move all data from the data.txt to an info_hash
        my $current_db_table;
        my $current_key;
        my $current_value;

        open( CHECKBOOK, "data.txt" );

        my $sub_flag;
        while ( my $record = <CHECKBOOK> ) {
            next if $record eq "";
            if ( $record =~ m/^CATEGORY/ ) {
                $current_db_table = &cleanup_name($record);
                next;
            }
            if ( $record =~ m/^FIELD_FLAG/ ) {
                $current_key = &cleanup_name($record);
                $sub_flag    = $current_key;
                next;
            }

            if ( $record =~ m/^FIELD-/ ) {
                my $word = &cleanup_name($record);
                $current_key = lc($sub_flag) . "_" . $word;
            }

            if ( $record =~ m/^DATA-/ ) {
                $current_value = db_compat($record);
            }

            if (    ($current_db_table)
                and ( defined($current_key)   and $current_key   ne '' )
                and ( defined($current_value) and $current_value ne "" ) )
            {
                $info_hash{$current_db_table}->{ $current_key } =
                  $current_value;
            }
        }
        close(CHECKBOOK);

      BUILD_LOOKUP_TABLES:
        {
            say "populating lookup tables" if -t;
            my $table_sql = "";
            foreach my $item ( keys %info_hash ) {
                $table_sql = " INSERT IGNORE INTO field_name_lookups (`md5_data`, `field_name`, `table_name`) VALUES ";
                foreach my $iteminitem ( keys %{ $info_hash{$item} } ) {
                    my $field_name = md5_hex($iteminitem);
                    $table_sql .= "('$field_name', '$iteminitem', '$item'), ";
                }
                $table_sql =~ s/, $/;/g;
                $sth = $dbh->prepare($table_sql);
                $sth->execute() or die "Cannot execute: " . $sth->errstr();
            }
        }
        sleep(2);
    }

  CREATE_TABLE:
    {
        # saves examining the data and creating the db tables manually
        next if $tables_created == 1;
        say "Creating tables" if -t;

        foreach my $item ( keys %info_hash ) 
        {
            $sth = $dbh->prepare(
                    "SELECT table_name 
                    FROM information_schema.tables
                    WHERE table_schema = 'world'
                    AND table_name = '$item';"
                    );

            $sth->execute();
            my $ref = $sth->fetchrow_hashref();
            next CREATE_TABLE if defined( $ref->{table_name} );

            my $create_table .=
                "CREATE TABLE $item (`code` CHAR(3) NOT NULL, `entry_date` DATE NOT NULL, ";
            foreach my $iteminitem ( keys %{ $info_hash{$item} } ) 
            {
                my $length = length( $info_hash{$item}{$iteminitem} );
                $length = 25  if ( $length < 25 );
                $length = 150 if ( $length < 150 and $length > 25 );
                $length = 255 if ( $length < 255 and $length > 150 );
                my $column_type = " VARCHAR ($length) NOT NULL ";
                $column_type = " TEXT " if ( length( $info_hash{$item}{$iteminitem} ) > 200 );
                my $field_name = md5_hex($iteminitem);
                $create_table .= "`" . $field_name . "` $column_type, ";
                $md5_field_name{$field_name} = { $iteminitem, $item };
            }
            $create_table .= " PRIMARY KEY ( `code`, `entry_date` ) ";
            $create_table .= ");\r\r";

            open( my $sql_out, '>', 'out.sql' );
            print $sql_out $create_table;
            close($sql_out);
            $sth = $dbh->prepare($create_table);
            $sth->execute()
                or die "Cannot execute: "
                . $sth->errstr() . " "
                . $create_table;
            $sth->finish();
        }
        $tables_created = 1;
    }

    $dbh->disconnect();
}

sub db_compat {

#return if !defined ($@) or $@ eq '' ;
    my ($line) = @_;
    return if $line eq '';
    $line =~ s/DATA-//g;    # remove flags
        $line =~ s/'/\\'/g;     # replace spaces with underscores
        $line =~ s/\n//g;       # remove line breaks
        return $line;
}

sub cleanup_name {

#    return if !defined ($@) or $@ eq '' ;
    my ($line) = @_;
    $line =~ s/(?:CATEGORY-|FIELD_FLAG-|FIELD-|DATA-)//g;    # remove flags
        $line =~ s/(^\s|\s$)//g; # remove trailing / leading spaces
        $line =~ s/ ?- ?/_/g;    # replace spaces/dash combinations with underscores
        $line =~ s/\s+/_/g;      # replace spaces with underscores
        $line =~ s/[,']//g;         #remove commas
        $line =~ s/ or //g;     
        $line =~ s/ consists of the following parties / /g;     
        $line =~ s/:$//g;        #remove trailing colon

#$line =~ s/per_capita/p_cap/g;      #remove trailing colon
#        $line =~ s/country_comparison_to_the_world/CCTTW/g;      #remove trailing colon
#        $line =~ s/internally_displaced_persons/IDP/g;
#$line =~ s/country_of_origin/CoO/g;

#$line =~ s/\s/_/g;      # replace spaces with underscores
            $line =~ s/[()]//g;      # remove parenthesis
            $line =~ lc($line);      # lower case
            return $line;
}
1;

=head1 NAME

C<s1::s1homes2009::%> - S1 .....................................

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 VALUES PROVIDED TO THE TEMPLATE



=head1 MODELS



=head1 SUBROUTINES



=head1 COPYRIGHT

Copyright 2010 paulmcnally.

=cut

