#!/usr/bin/perl

use Net::Telnet;
use strict;

my $telnet = new Net::Telnet(Timeout =>60,Prompt=>'/[\#>%\$] $/');
print  "new  ok \n";
$telnet->open(Host => '127.0.0.1') or print STDOUT "open wrong \n";
print  "open ok \n";
$telnet->login('xing', '1qazXSW@') ==1 or print "login wrong \n";
print "login ok \n";
$telnet->cmd(string => "/home/xing/t/cp.sh",timeout => 10) ==1 or print "failed\n";
print "cmd ok \n";
