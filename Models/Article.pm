package Pinakes::Models::Article;

use Moo;
use Sub::Quote;
use Pinakes::Utils::DB;
#create table `articles` ( article_id INT UNSIGNED NOT NULL AUTO_INCREMENT, title varchar(64) NOT NULL default '', client varchar(12) NOT NULL default 'datacreation', article_text text, PRIMARY KEY (article_id) ) ENGINE=MyISAM;
my $db = Pinakes::Utils::DB->create_connection;

has article_id => (
        is  => 'rw',
);
has title => (
        is  => 'ro',
);

has client => (
        is  => 'ro',
);

has article_text => (
    is  => 'ro',
);

1;
