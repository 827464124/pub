#!/usr/bin/perl

use strict;

my @q = (1,2,3,4,5,6,7,5);
my @p = sort {$b <=> $a} @q;

print "@p\n";
