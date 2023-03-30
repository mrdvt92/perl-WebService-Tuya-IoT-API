#!/usr/bin/perl
use strict;
use warnings;
require Data::Dumper;
use Getopt::Std;
use WebService::Tuya::IoT::API;

my $syntax        = "$0 [-d] -i client_id -s client_secret deviceid [...]\n";
my $opt           = {};
getopts('ds:i:', $opt);
my $debug         = $opt->{'d'};
my $client_id     = $opt->{'i'} or die($syntax);
my $client_secret = $opt->{'s'} or die($syntax);

my $ws            = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret) or die;

foreach my $deviceid (@ARGV) {
  my $r = $ws->device_status($deviceid);

#{
#  'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
#  'tid' => '63653efbcf2e11ed9c106a2c61a2ec08',
#  't' => '1680203366165',
#  'result' => [
#    {
#      'value' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
#      'code' => 'switch_1'
#    },
#    {
#      'value' => 0,
#      'code' => 'countdown_1'
#    }
#  ]
#}

  if ($r->{'success'} and ref($r->{'result'}) eq 'ARRAY') {
    foreach my $entry (@{$r->{'result'}}) {
      printf "Device: %s, Code: %s, Value: %s\n", $deviceid, $entry->{'code'}, $entry->{'value'};
    }
  }
  if ($debug) {
    local $Data::Dumper::Indent = 1; #smaller index
    local $Data::Dumper::Terse  = 1; #remove $VAR1 header
    print Data::Dumper::Dumper($r);
  }
}

if ($debug) {
  local $Data::Dumper::Indent = 1; #smaller index
  local $Data::Dumper::Terse  = 1; #remove $VAR1 header
  print Data::Dumper::Dumper($ws);
}
