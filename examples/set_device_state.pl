#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use WebService::Tuya::IoT::API;

my $syntax        = "$0 [-d] -i client_id -s client_secret deviceid switch [on|off]\n";
my $opt           = {};
getopts('ds:i:', $opt);
my $debug         = $opt->{'d'};
my $client_id     = $opt->{'i'} or die($syntax);
my $client_secret = $opt->{'s'} or die($syntax);

my $deviceid      = shift or die($syntax);
my $switch        = shift or die($syntax);
my $state         = shift;
my $ws            = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret) or die;


if (defined($state) and $state =~ m/\Aon|off|1|0\Z/i) {
  my $state_boolean = $state =~ m/\A(on|1)\Z/i ? \1 : \0; #note scalar references
  my $response      = $ws->device_command_code_value($deviceid, $switch, $state_boolean);
  my $success       = $response->{'success'};
  if ($debug) {
    require Data::Dumper;
    local $Data::Dumper::Indent = 1; #smaller index
    local $Data::Dumper::Terse  = 1; #remove $VAR1 header
    print Data::Dumper::Dumper($response);
  }
  printf "Device: %s, Switch: %s, State: %s, Success: %s\n", $deviceid, $switch, ($$state_boolean ? 'on' : 'off'), ($success ? 'yes' : 'no');
} else {
  my $value         = $ws->device_status_code_value($deviceid, $switch); #isa JSON Boolean
  printf "Device: %s, Switch: %s, State: %s\n", $deviceid, $switch, ($value ? 'on' : 'off');
}
