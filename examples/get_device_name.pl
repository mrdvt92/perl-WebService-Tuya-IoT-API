#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use WebService::Tuya::IoT::API;

my $syntax         = "$0 [-d] -i client_id -s client_secret deviceid [...]\n";
my $opt            = {};
getopts('ds:i:', $opt);
my $debug          = $opt->{'d'};
my $client_id      = $opt->{'i'} or die($syntax);
my $client_secret  = $opt->{'s'} or die($syntax);

my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret) or die;

die($syntax) unless @ARGV;

foreach my $deviceid (@ARGV) {
  my $r = $ws->device_information($deviceid);
  if ($debug)   {
    require Data::Dumper;
    local $Data::Dumper::Indent = 1; #smaller index
    local $Data::Dumper::Terse  = 1; #remove $VAR1 header
    print Data::Dumper::Dumper($r);
  }
  my $name = $r->{'result'}->{'name'};
  printf "Device: %s, Name: %s\n", $deviceid, $name;
}
