#!/usr/bin/perl

use strict;
use warnings;

my @of = split("\n",`free -m`);
while( my $line = shift @of ){
		if($line=~m/^Mem:(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s*)$/ ){

			print $line."\n";
			print "tatol 	:$2\n";
			print "used 	:$4\n";
			print "free 	:$6\n";
			print "shared 	:$8\n";
			print "buffer	:$10\n";
			print "cached 	:$12\n";
		}
}
