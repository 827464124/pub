#!/usr/bin/perl

use strict;
use warnings;

my $proc_name=shift;
my @pa = split("\n",`ps aux | grep $proc_name | grep -v grep`);
while (my $line=shift @pa ){
		if($line=~m/^(\w+)(\s+)(\d+)(\s+)(.*)/){
				print "a".$3."a\n";
				kill(9,$3);
		}
}
