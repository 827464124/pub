#!/usr/bin/perl 

use strict ;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

my $response = $ua->get("http://game2.hslguoji58.com/resources/lib/jquery.min.map");
if ($response -> is_success){
	print $response ->content;
}else{
	print $response ->status_line;
}
