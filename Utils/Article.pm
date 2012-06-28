package Pinakes::Utils::Article;
use strict;
use warnings;

use CGI;
use Data::Dumper;

use Pinakes::Utils::DB;
use aliased 'Pinakes::Models::Article';
use v5.10;
use Tenjin;

handler() if -t and !caller();

sub hander
{
    my $r = shift;

    MAIN:
    {

        my $q = CGI->new;
    
        if($q->param('submit'))
        {

            my $article = Article->new(
                'article_id' => $q->param('article_id'),
                'title'      => $q->param('title'),
                'client'     => $q->param('client'),
                'article_text' => $q->param('article_text'),
            ); 
            say $article;
        }
    }
    return "OK";
}
1;
