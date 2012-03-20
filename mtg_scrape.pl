#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;
use IO::File;
use XML::Writer;


#Define our output container
my $output = IO::File->new(">output.xml");
#Define our XML writer
my $writer = XML::Writer->new(OUTPUT=>$output, NEW_LINES=>1,
   DATA_MODE=>1, DATA_INDENT=>1);

sub grab_page {
   return $_[0];
};

# This is the URL we're going to scrape for data
my $url1 = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?page=';
my $url2 = '&sort=cn+&output=checklist&action=advanced&set=+%5b%22Dark+Ascension%22%5d';
my $x=0; #For now, we're only using the first page

my $address=grab_page("$url1$x$url2");

#instantiate the scraper
my $compactScraper=scraper {
   #Loop through each row of the checklist page
   process "tr.cardItem", 'cardRows[]' => scraper {
      #These should be self-explanatary
      process "td.number", number => 'TEXT';
      process "td.name > a.nameLink", name => 'TEXT';
      process "td.name > a.nameLink", link => '@href';
      process "td.artist", artist => 'TEXT';
      process "td.color", color => 'TEXT';
      process "td.rarity", rarity => 'TEXT';
   };
};

#scrape the site
my $res = $compactScraper->scrape(URI->new($address));

$writer->startTag("DKA");
#loop through the hits
for my $card (@{$res->{cardRows}}) {
	$writer->startTag($card->{name}); #Open card xml
	$writer->dataElement('card_link', "$card->{link}");
	$writer->dataElement('card_number', "$card->{number}");
	$writer->dataElement('card_rarity', "$card->{rarity}");
	$writer->dataElement('card_color', "$card->{color}");
	$writer->dataElement('card_artist', "$card->{artist}");
	$writer->endTag($card->{name});
}
$writer->endTag("DKA");
$writer->end(); #close our writer class

#instantiate the card_detail scraper
my $cardDetail=scraper {
   #These should be self-explanatary
   process "td.number", number => 'TEXT';
   process "td.name > a.nameLink", name => 'TEXT';
   process "td.name > a.nameLink", link => '@href';
   process "td.artist", artist => 'TEXT';
   process "td.color", color => 'TEXT';
   process "td.rarity", rarity => 'TEXT';
};


#TODO: loop through the rows we have to ping each link
for my $card (@{$res->{cardRows}}) {

}
