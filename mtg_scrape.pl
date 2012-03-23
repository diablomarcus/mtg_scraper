#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;
use IO::File;
use XML::Writer;
use Encode;


#Define our output container
my $output = IO::File->new(">/tmp/output.xml");
#Define our XML writer
my $writer = XML::Writer->new(OUTPUT=>$output, NEW_LINES=>1,
   DATA_MODE=>1, DATA_INDENT=>1);

#Define our hash of valid fields for detailed read
my %valid_fields=( #These are the fields we'll read
   ' Card Name:' => 'cardName',
   ' Converted Mana Cost:', => 'cmc',
   ' Card #:' => 'cardNumber', 
   ' Rarity:' => 'rarity',
   ' Expansion:' => 'expansion',
   ' Flavor Text:' => 'flavorText',
   ' P/T:' => 'powerToughness',
   ' Artist:' => 'artist');


# This subroutine takes a string, looks it up in our enum list of detailed
# information and returns 1 if we want to collect it, 0 if not
sub isFieldScrapable{

   #Define the field we'll be checking
   my $testValue=$_[0];

   #If testValue is a valid_field
   if (grep {m/^$testValue$/}  keys %valid_fields) {
      return 1; #Success!
   }
   return 0; #Couldn't find it... Boo.
}

# This subroutine contains a scraper for the basic details
# of a card gleaned from the compact listing on Gatherer
sub compact_scraper {
   #Instantiate the scraper object
   my $compactScraper=scraper {
      #Loop through each row of the checklist page
      process 'tr.cardItem', 'cardRows[]' => scraper {
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
sub getCardDetail {
   my $address=$_[0];#Address of individual card
   my %cardDetail; #Return object w/ info about card
   my $results=detailed_scraper()->scrape(URI->new($address));

   for my $detail (@{$results->{infoRows}}) {
#TODO: Learn how to deal with weird UTF8 issues
      if (isFieldScrapable($detail->{label})) {

         #Grab hash value for label
         my $varName= $valid_fields{$detail->{label}};

#TODO: Store the detailed card info in a hash temporarily
         my $value = $detail->{value};
         $value=~ s/[^[:ascii:]]+//g;  # get rid of non-ASCII characters

         #Tell user the info we just gleaned
         print(decode_utf8("$varName: $value\n"));
      }
   }

   return 0;
}


#TODO: Build multi-page scrapes
# This is the URL we're going to scrape for data
my $url1 = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?page=';
my $url2 = '&sort=cn+&output=checklist&action=advanced&set=+%5b%22Dark+Ascension%22%5d';
my $x=0; #For now, we're only using the first page

my $address=grab_page("$url1$x$url2");


getCardDetail('http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=226874'); #Test of detailed scrape


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

#TODO: loop through the rows we have to ping each link
#for my $card (@{$res->{cardRows}}) {

#}
