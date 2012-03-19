#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;


# This is the URL we're going to scrape for data
my $url1 = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?page=0&sort=cn+&output=checklist&action=advanced&set=+%5b%22Dark+Ascension%22%5d';

#for(my $x=0; $x<=1; $x++){
#   print('Address is: ', $url1, $x, $url2, "\n");
#}

#instantiate the scraper
my $cardsData=scraper {
   process "tr.cardItem", 'cardRow[]' => scraper {
      process "td.number", number => 'TEXT';
      process "td.name > a.nameLink", name => 'TEXT';
      process "td.artistName", artist => 'TEXT';
   };
};

#scrape the site
my $res = $cardsData->scrape(URI->new($url1));

#loop through the hits
for my $i (@{$res->{cardRow}}) {
   print "$i->{number} $i->{name} by $i->{artist}\n";
}
