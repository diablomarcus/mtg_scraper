#!/usr/bin/perl
use warnings;
use strict;
use URI;
use Web::Scraper;

open FILE, ">file.txt" or die $!;

# website to scrape
my $urlToScrape = "http://www.uciprotour.com/templates/UCI/UCI2/layout.asp?MenuId=MTU4MzI&LangId=1";

# prepare data
my $teamsdata = scraper {
 # we will save the urls from the teams
 process "table#UCITeamList > tr > td > a", 'urls[]' => '@href';
 # we will save the team names
# process "table#UCITeamList > tr > td > a", 'teams[]' => 'TEXT';
 process "a", 'teams[]' => 'TEXT';
};
# scrape the data
my $res = $teamsdata->scrape(URI->new($urlToScrape));

# print the second field (the teamname)
for my $i (0 .. $#{$res->{teams}}) {
# if ($i%3 != 0 && $i%3 != 2) {
 print $res->{teams}[$i];
 print "\n";
 print FILE $res->{teams}[$i];
 print FILE "\n";
# }
}

print FILE "\n";

__END__
# loop over every team url and take all scrape all the riders from each team
for my $i ( 0 .. $#{$res->{urls}}) {
 if ($i%3 != 0 && $i%3 != 2) {
 print "\n\n";
 print $res->{teams}[$i];
 print "\n------------------\n";
 print FILE "\n\n";
 print FILE $res->{teams}[$i];
 print FILE "\n------------------\n";

 # prepare data
 my $rennersdata = scraper {
 # rider name
 process "table#TeamRiders > tr > td.RiderCol > a", 'renners[]' => 'TEXT';
 # rider country
 process "table#TeamRiders > tr > td.CountryCol > a", 'landrenner[]' => 'TEXT';
 # rider birthdate
 process "table#TeamRiders > tr > td.DOBCol > a", 'geboortedatums[]' => 'TEXT';
 # team address
 process "table#TeamLeft > div.AddLine", 'AddressLines[]' => 'TEXT';
 };
 # scrape
 my $res2 = $rennersdata->scrape(URI->new($res->{urls}[$i]));


 for my $j (0 .. $#{$res2->{renners}}) {
 # print rider name
 print $res2->{renners}[$j];
 print "\n";
 print FILE $res2->{renners}[$j];
 print FILE "\n";

 }
 }
 # DONT FORGET THIS, this will make your script slow
 # but if it's not there you will be "attacking" the webserver and they don't like that
 sleep(3);
}

# close the file
close FILE;
