#!/usr/bin/perl

use strict;

my $length = 0;

for ($length ; $length < 100 ; $length ++) {
	my $tmp = 2;
	
	for ( $tmp ; $tmp < $length ; $tmp ++){
		if ($length % $tmp == 0){
			last;
		}
	}
	print "$length \n" if ($tmp == $length);
}
