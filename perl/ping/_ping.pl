#!/usr/bin/perl

use strict;
use Net::Ping;

my $ping_object = new Net::Ping("tcp");

if ($ping_object->ping("12.0.3.1")){
	print "ping Ok\n";
}
