#!/usr/bin/perl

use strict;

my $prev = 0;
my $cur;
for ($cur = 1; $cur < 100 ; )
{
	print "$cur\n";
	$cur = $prev + $cur;
	$prev = $cur - $prev;
}
