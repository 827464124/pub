#!/usr/bin/perl

use strict ;

my $str = `tail -n2 ./record.txt`;

my @ar = split /\s+/,$str;
print $ar[1]."\n";
