#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;
use IO::File;
use XML::Writer;


#Define our output container
my $output = IO::File->new(">/tmp/output.xml");
#Define our XML writer
my $writer = XML::Writer->new(OUTPUT=>$output, NEW_LINES=>1,
   DATA_MODE=>1, DATA_INDENT=>1);


# This subroutine takes a string, looks it up in our enum list of detailed
# information and returns 1 if we want to collect it, 0 if not
#TODO: Make this actually do something
sub enum_detail_key {
}

# This subroutine contains a scraper for the basic details
# of a card gleaned from the compact listing on Gatherer
sub compact_scraper {
   #Instantiate the scraper object
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
   return $compactScraper;
};

# This subroutine contains a scraper for all card_details
# of a card gleaned from the card's full listing on Gatherer
sub detailed_scraper {
   #Instantiate the scraper object
   my $scraper=scraper {
      #Loop through each row of the checklist page
      process "div.row", 'infoRows[]' => scraper {
         process "div.label", label => 'TEXT';
         process "div.value", value => 'TEXT';
      };
   };
   return $scraper;
};


#TODO: Add parsing of page to scan
sub grab_page {
   return $_[0];
};

#TODO: Parse the data returned here
sub hellrider_test {
   my $hellrider_address="http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=226874";
   my $hellrider_results=detailed_scraper()->scrape(URI->new($hellrider_address));

   for my $detail (@{$hellrider_results->{infoRows}}) {
      print("label: $detail->{label}\n");
#TODO: Learn how to deal with weird UTF8 issues
      print("value: $detail->{value}\n");
   }
}


#TODO: Build multi-page scrapes
# This is the URL we're going to scrape for data
my $url1 = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?page=';
my $url2 = '&sort=cn+&output=checklist&action=advanced&set=+%5b%22Dark+Ascension%22%5d';
my $x=0; #For now, we're only using the first page

my $address=grab_page("$url1$x$url2");


hellrider_test(); #Test of detailed scrape

#scrape the site
my $results=compact_scraper()->scrape(URI->new($address));

#Add a tag to the start of our XML file so we don't inadvertently close it
$writer->startTag("cards");
#loop through the hits
for my $card (@{$results->{cardRows}}) {
   $writer->startTag($card->{name}); #Open card xml

   #Store elements
   $writer->dataElement('card_link', "$card->{link}");
   $writer->dataElement('card_number', "$card->{number}");
   $writer->dataElement('card_rarity', "$card->{rarity}");
   $writer->dataElement('card_color', "$card->{color}");
   $writer->dataElement('card_artist', "$card->{artist}");

   $writer->endTag($card->{name}); #Close card xml
}

$writer->endTag("cards");

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
#for my $card (@{$res->{cardRows}}) {

#}
