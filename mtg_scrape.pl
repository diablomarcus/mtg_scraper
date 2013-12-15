#!/usr/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;
use IO::File;
use XML::Writer;
use Encode;


#Define our output container
my $OUTPUT = IO::File->new(">/tmp/mtg_scraper_output.xml");
#Define our XML writer
my $writer = XML::Writer->new(OUTPUT=>$OUTPUT, NEW_LINES=>1,
   DATA_MODE=>1, DATA_INDENT=>1);

#Define our hash of valid fields for detailed read
my %valid_fields=( #These are the fields we'll read
   ' Card Name:' => 'cardName',
   ' Converted Mana Cost:', => 'convertedManaCost',
   ' Card #:' => 'cardNumber', 
   ' Rarity:' => 'rarity',
   ' Expansion:' => 'expansion',
   ' Types:' => 'types',
#TODO: Get the card text from the Text Spoiler since it doesn't have pictures
   ' Card Text:' => 'cardText',
   ' Flavor Text:' => 'flavorText',
   ' P/T:' => 'powerToughness',
   ' Loyalty:' => 'loyalty',
   ' Artist:' => 'artist');

my %scraped_cards=();

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
         process "td.name > a.nameLink", name => 'TEXT';
         process "td.name > a.nameLink", link => '@href';
         process "td.color", color => 'TEXT';
      };
   };
   return $compactScraper;
};

# This subroutine contains a scraper for all card_details
# of a card gleaned from the card's full listing on Gatherer
sub detailed_scraper {
   #Instantiate the scraper object
   my $scraper=scraper {
      #Loop through each row of the detailed page
      process "div.row", 'infoRows[]' => scraper {
         process "div.label", label => 'TEXT';
         process "div.value", value => 'TEXT';
      };
   };
   return $scraper;
};

sub getCardDetail {
   my $address=$_[0];#Address of individual card
   my %cardDetail; #Return object w/ info about card
   my $results=detailed_scraper()->scrape(URI->new($address));

   for my $detail (@{$results->{infoRows}}) {
      if (isFieldScrapable($detail->{label})) {

         #Grab hash value for label
         my $varName= $valid_fields{$detail->{label}};

         #Store the info we just gleaned
         $cardDetail{$varName}=encode('utf8', $detail->{value}); #Had to ensure utf8
      }
   }
   return %cardDetail;
}


# This is the URL we're going to scrape for data
#my $address='http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&action=advanced&rarity=|[M]|[R]|[U]|[C]|[L]|[S]|[P]';
#More sane default
my $address='http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&action=advanced&rarity=|[M]';


#scrape the site
my $results=compact_scraper()->scrape(URI->new($address));

#Add a tag to the start of our XML file so we don't inadvertently close it
$writer->startTag("cards");
#loop through the hits
for my $card (@{$results->{cardRows}}) {

   if (exists $scraped_cards{$card->{link}}){
      print "Skipping $card->{name} since we've already seen it\n";
   } else {
      sleep 1; #Try not to look like we're DoSing WotC

      #Grab detailed card info
      my %cardInfo=getCardDetail($card->{link});
      
      $writer->startTag('card'); #Open card xml

      #Store basic elements
      $writer->dataElement('card_link', "$card->{link}");
      $writer->dataElement('card_color', "$card->{color}");

      #Loop through each detailed element
      foreach my $key (sort(keys %cardInfo)) {
         $writer->dataElement($key, $cardInfo{$key}); #Write the element
      }

      $writer->endTag('card'); #Close card xml

      #Store that we have seen this card
      $scraped_cards{$card->{link}}='';
      
      print "Finished $card->{name}\n"; #Give status update
   }
}

$writer->endTag("cards");

$writer->end(); #close our writer class
