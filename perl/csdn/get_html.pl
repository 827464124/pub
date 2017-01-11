#!/usr/bin/perl 

use strict ;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

my $response = $ua->get("www.baidu.com");
if ($response -> is_success){
	print $response ->content;
}else{
	print $response ->status_line;
}
