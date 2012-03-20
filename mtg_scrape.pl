#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;

sub grab_page {
   my $address = $_[0];
};

# This is the URL we're going to scrape for data
my $url1 = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?page=';
my $url2 = '&sort=cn+&output=checklist&action=advanced&set=+%5b%22Dark+Ascension%22%5d';
my $x=0; #For now, we're only using the first page

my $address=grab_page("$url1$x$url2");

#instantiate the scraper
my $cardsData=scraper {
   #Loop through each row of the checklist page
   process "tr.cardItem", 'cardRow[]' => scraper {
      #These should be self-explanatary
      process "td.number", number => 'TEXT';
      process "td.name > a.nameLink", name => 'TEXT';
      process "td.artist", artist => 'TEXT';
      process "td.color", color => 'TEXT';
      process "td.rarity", rarity => 'TEXT';
   };
};

#scrape the site
my $res = $cardsData->scrape(URI->new($address));

#loop through the hits
for my $i (@{$res->{cardRow}}) {
   #Print the results
   print "$i->{number} $i->{name} $i->{color} $i->{rarity} by $i->{artist}\n";
}
