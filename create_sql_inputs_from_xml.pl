#!/usr/bin/perl -CS --

use strict;
use warnings;
use XML::Simple;

# create object
my $xml = new XML::Simple;

# read XML file
my $data = $xml->XMLin("mtg_scraper_output.xml");

foreach my $card (@{$data->{card}}){
   my $insert = 'INSERT INTO collection (';
   my $keys = 'card_quantity,';
   my $values = '0,';
   store_string_value($card->{cardName},'card_name',$keys,$values);
   store_string_value($card->{cardText},'card_text',$keys,$values);
   store_string_value($card->{card_color},'card_color',$keys,$values);
   store_string_value($card->{rarity},'card_rarity',$keys,$values);
   store_string_value($card->{expansion},'card_expansion',$keys,$values);
   store_string_value($card->{types},'card_type',$keys,$values);
   store_string_value($card->{artist},'card_artist',$keys,$values);
   store_string_value($card->{flavorText},'card_flavor_text',$keys,$values);
   store_int_value($card->{convertedManaCost},'card_cmc',$keys,$values);
   store_int_value(find_multiverse_id($card->{card_link}),'card_multiverse_id',$keys,$values);
 #  card_multiverse_id)values (";
   $insert .= strip_trailing_comma($keys);
   $insert .= ')VALUES(';
   $insert .= strip_trailing_comma($values);
   $insert .= ');';
   print "$insert\n";
}

sub find_multiverse_id {
   $_[0] =~ s/.*?(\d+)$/$1/;
   return $_[0];
}

sub store_string_value {
   my ($inputValue, $inputName, $keys, $values) = (@_);
   if (is_valid($inputValue)){
      my $name = trim($inputValue);
      $name =~ s/"/'/g;
      $_[2] .= "$inputName,";
      $_[3] .= "\"$name\",";
   }
}

sub store_int_value {
   my ($inputValue, $inputName, $keys, $values) = (@_);
   if (is_valid($inputValue)){
      my $name = trim($inputValue);
      $_[2] .= "$inputName,";
      $_[3] .= "$name,";
   }
}

sub is_valid {
   my $input = $_[0];
   if (!ref($input) && defined($input)) {
      return 1;
   }
   return 0;
}

sub strip_trailing_comma {
   my $input = $_[0];
   $input =~ s/\,$//g;
   return $input;
}

sub trim{
   my $input = $_[0];
   $input =~ s/^\s+|\s+$//g;
   return $input;
}
