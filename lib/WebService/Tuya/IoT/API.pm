package WebService::Tuya::IoT::API;
use strict;
use warnings;
require Time::HiRes;
require Digest::SHA;
require Data::UUID;
require JSON::XS;
require HTTP::Tiny;

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

WebService::Tuya::IoT::API - Perl library to access the Tuya API

=head1 SYNOPSIS

  use WebService::Tuya::IoT::API;
  my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
  my $access_token   = $ws->access_token;
  my $device_status  = $ws->device_status($deviceid);
  my $response       = $ws->device_commands($deviceid, {code=>'switch_1', value=>$boolean ? \1 : \0});

=head1 DESCRIPTION

This Perl package controls and reads state of Tuya compatible Smart Devices (Plugs, Switches, Lights, Window Covers, etc.) using the TuyaCloud API.

=head1 CONSTRUCTORS

=head2 new
 
  my $ws = WebService::Tuya::IoT::API->new;
 
=cut
 
sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;
  %$self    = @_ if @_;
  return $self;
}

=head1 PROPERTIES

=head2 http_hostname

  $ws->http_hostname("openapi.tuyacn.com");

default: openapi.tuyaus.com

=cut

sub http_hostname {
  my $self            = shift;
  $self->{'http_hostname'} = shift if @_;
  $self->{'http_hostname'} = 'openapi.tuyaus.com' unless defined $self->{'http_hostname'};
  return $self->{'http_hostname'};
}

=head2 client_id

Sets and returns the client_id found on https://iot.tuya.com/ project overview page.

=cut

sub client_id {
  my $self             = shift;
  $self->{'client_id'} = shift if @_;
  $self->{'client_id'} = die("Error: property client_id required") unless $self->{'client_id'};
  return $self->{'client_id'};
}

=head2 client_secret

Sets and returns the client_secret found on https://iot.tuya.com/ project overview page.

=cut

sub client_secret {
  my $self             = shift;
  $self->{'client_secret'} = shift if @_;
  $self->{'client_secret'} = die("Error: property client_secret required") unless $self->{'client_secret'};
  return $self->{'client_secret'};
}

=head2 api_version

Sets and returns the API version string used in the URL in the API calls.

  my $api_version = $ws->api_version;

default: v1.0

=cut

sub api_version {
  my $self             = shift;
  $self->{'api_version'} = shift if @_;
  $self->{'api_version'} = 'v1.0' unless $self->{'api_version'};
  return $self->{'api_version'};
}

=head1 METHODS

=head2 api

This is a Tuya IoT API Request method which handles access token and web request signatures

  my $response = $ws->api(GET  => 'token?grant_type=1');                                                             #get access token
  my $response = $ws->api(GET  => "iot-03/devices/$deviceid/status");                                                #get status of $deviceid
  my $response = $ws->api(POST => "iot-03/devices/$deviceid/commands", {commands=>[{code=>'switch_1', value=>\0}]}); #set switch_1 off on $deviceid

References:
  - https://developer.tuya.com/en/docs/iot/new-singnature?id=Kbw0q34cs2e5g
  - https://github.com/jasonacox/tinytuya/blob/ffcec471a9c4bba38d5bf224608e20bc148f1b86/tinytuya/Cloud.py#L130

=cut

# Thanks to Jason Cox at https://github.com/jasonacox/tinytuya
# Copyright (c) 2022 Jason Cox - MIT License

sub api {
  my $self             = shift;
  my $http_method      = shift;
  my $api_destination  = shift;                                                                                    #TODO: sort query parameters alphabetically
  my $input            = shift; #or undef
  my $content          = defined($input) ? JSON::XS::encode_json($input) : '';                                     #Note: empty string stringifies to "" in JSON
  my $is_token         = $api_destination =~ m/\Atoken\b/ ? 1 : 0;
  my $access_token     = $is_token ? undef : $self->access_token;                                                  #Note: recursive call
  my $http_path        = sprintf('/%s/%s', $self->api_version, $api_destination);
  my $url              = sprintf('https://%s%s', $self->http_hostname, $http_path);                                #e.g. "https://openapi.tuyaus.com/v1.0/token?grant_type=1"
  my $nonce            = Data::UUID->new->create_str;                                                              #Field description - nonce: the universally unique identifier (UUID) generated for each API request.
  my $t                = int(Time::HiRes::time() * 1000);                                                          #Field description - t: the 13-digit standard timestamp.
  my $content_sha256   = Digest::SHA::sha256_hex($content);                                                        #Content-SHA256 represents the SHA256 value of a request body
  my $headers          = '';                                                                                       #signature headers
  $headers             = sprintf("secret:%s\n",  $self->client_secret) if $is_token;                               #TODO: add support for area_id and request_id
  my $stringToSign     = join("\n", $http_method, $content_sha256, $headers, $http_path);
  my $str              = join('',  $self->client_id, ($is_token ? () : $access_token), $t, $nonce, $stringToSign); #Signature algorithm - str = client_id + [access_token]? + t + nonce + stringToSign
  my $sign             = uc(Digest::SHA::hmac_sha256_hex($str, $self->client_secret));                             #Signature algorithm - sign = HMAC-SHA256(str, secret).toUpperCase()
  my $options          = {
                          headers => {
                                      'Content-Type' => 'application/json',
                                      'client_id'    => $self->client_id,
                                      'sign'         => $sign,
                                      'sign_method'  => 'HMAC-SHA256',
                                      't'            => $t,
                                      'nonce'        => $nonce,
                                     },
                          content => $content,
                         };
  if ($is_token) {
    $options->{'headers'}->{'Signature-Headers'} = 'secret';
    $options->{'headers'}->{'secret'}            = $self->client_secret;
  } else {
    $options->{'headers'}->{'access_token'}      = $access_token;
  }
  my $response         = $self->ua->request($http_method, $url, $options);
  my $status           = $response->{'status'};
  die("Error: Web service request unsuccessful - status: $status\n") unless $status eq '200';                     #TODO: better error handeling
  my $response_content = $response->{'content'};
  local $@;
  my $response_decoded = eval{JSON::XS::decode_json($response_content)};
  my $error            = $@;
  die("Error: API returned invalid JSON - content: $response_content\n") if $error;
  die("Error: API returned unsuccessful - content: $response_content\n") unless $response_decoded->{'success'};
  return $response_decoded
}

=head2 access_token

Wrapper around api which calls and caches the token web service for a temporary access token to be used for subsequent web service calls.

=cut

sub access_token {
  my $self            = shift;
  if (defined $self->{'_access_token_data'}) {
    delete($self->{'_access_token_data'}) if Time::HiRes::time() > $self->{'_access_token_data'}->{'expire_time'};
  }
  unless (defined $self->{'_access_token_data'}) {
    my $api_destination           = 'token?grant_type=1';
    my $output                    = $self->api(GET => $api_destination);

#{
#  "success":true,
#  "t":1678245450431,
#  "tid":"c2ad0c4abd5f11edb116XXXXXXXXXXXX"
#  "result":{
#    "access_token":"34c47fab3f10beb59790XXXXXXXXXXXX",
#    "expire_time":7200,
#    "refresh_token":"ba0b6ddc18d0c2eXXXXXXXXXXXXXXXXX",
#    "uid":"bay16149755RXXXXXXXX"
#  },
#}

    my $response_time             = $output->{'t'};                       #UOM: milliseconds from epoch
    my $expire_time               = $output->{'result'}->{'expire_time'}; #UOM: seconds ref https://bestlab-platform.readthedocs.io/en/latest/bestlab_platform.tuya.html
    $output->{'expire_time'}      = $response_time/1000 + $expire_time; #TODO: Account for margin of error
    $self->{'_access_token_data'} = $output;
  }
  my $access_token = $self->{'_access_token_data'}->{'result'}->{'access_token'} or die("Error: access_token not set");
  return $access_token;
}

=head2 device_status

Wrapper around api method and the device status api destination.

  my $device_status = $ws->device_status($deviceid);

=cut

sub device_status {
  my $self            = shift;
  my $deviceid        = shift;
  my $api_destination = "iot-03/devices/$deviceid/status";
  return $self->api(GET => $api_destination);
}

=head2 device_commands

Wrapper around api method and the device commands api destination.

  my $switch   = 'switch_1';
  my $value    = $boolean ? \1 : \0;
  my $response = $ws->device_commands($deviceid, {code=>$switch, value=>$value});

=cut

sub device_commands {
  my $self            = shift;
  my $deviceid        = shift;
  my @commands        = @_; #each command must be a hash reference
  my $api_destination = "iot-03/devices/$deviceid/commands";
  return $self->api(POST => $api_destination, {commands=>\@commands});
}

=head1 ACCESSORS

=head2 ua

Returns an L<HTTP::Tiny> web client user agent

=cut

sub ua {
  my $self = shift;
  unless ($self->{'ua'}) {
    my %settinges = (
                     keep_alive => 0,
                     agent      => "Mozilla/5.0 (compatible; $PACKAGE/$VERSION; See rt.cpan.org 35173)",
                    );
    $self->{'ua'} = HTTP::Tiny->new(%settinges);
  }
  return $self->{'ua'};
}

=head1 SEE ALSO

https://iot.tuya.com/, https://apps.apple.com/us/app/smart-life-smart-living/id1115101477, 

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

LICENSE MIT

Copyright (C) 2023 by Michael R. Davis

=cut

1;
