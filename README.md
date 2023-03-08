# NAME

WebService::Tuya::IoT::API - Perl library to access the Tuya API

# SYNOPSIS

    use WebService::Tuya::IoT::API;
    my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
    my $access_token   = $ws->access_token;
    my $device_status  = $ws->device_status($deviceid);
    my $response       = $ws->device_commands($deviceid, {code=>'switch_1', value=>$boolean ? \1 : \0});

# DESCRIPTION

This Perl package controls and reads state of Tuya compatible Smart Devices (Plugs, Switches, Lights, Window Covers, etc.) using the TuyaCloud API.

# CONSTRUCTORS

## new

     my $ws = WebService::Tuya::IoT::API->new;
    

# PROPERTIES

## http\_hostname

    $ws->http_hostname("openapi.tuyacn.com");

default: openapi.tuyaus.com

## client\_id

Sets and returns the client\_id found on https://iot.tuya.com/ project overview page.

## client\_secret

Sets and returns the client\_secret found on https://iot.tuya.com/ project overview page.

## api\_version

Sets and returns the API version string used in the URL in the API calls.

    my $api_version = $ws->api_version;

default: v1.0

# METHODS

## api

This is a Tuya IoT API Request method which handles access token and web request signatures

    my $response = $ws->api(GET  => 'token?grant_type=1');                                                             #get access token
    my $response = $ws->api(GET  => "iot-03/devices/$deviceid/status");                                                #get status of $deviceid
    my $response = $ws->api(POST => "iot-03/devices/$deviceid/commands", {commands=>[{code=>'switch_1', value=>\0}]}); #set switch_1 off on $deviceid

References:
  - https://developer.tuya.com/en/docs/iot/new-singnature?id=Kbw0q34cs2e5g
  - https://github.com/jasonacox/tinytuya/blob/ffcec471a9c4bba38d5bf224608e20bc148f1b86/tinytuya/Cloud.py#L130

## access\_token

Wrapper around api which calls and caches the token web service for a temporary access token to be used for subsequent web service calls.

## device\_status

Wrapper around api method and the device status api destination.

    my $device_status = $ws->device_status($deviceid);

## device\_commands

Wrapper around api method and the device commands api destination.

    my $switch   = 'switch_1';
    my $value    = $boolean ? \1 : \0;
    my $response = $ws->device_commands($deviceid, {code=>$switch, value=>$value});

# ACCESSORS

## ua

Returns an [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) web client user agent

# SEE ALSO

https://iot.tuya.com/, https://apps.apple.com/us/app/smart-life-smart-living/id1115101477, 

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

LICENSE MIT

Copyright (C) 2023 by Michael R. Davis
