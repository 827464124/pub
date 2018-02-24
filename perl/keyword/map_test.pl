#!/usr/bin/perl;

use strict;
use Data::Dumper;

my %tmp = ();

my @tmp_arr = qw(one two three);

%tmp = map {$_,1} grep {1} @tmp_arr;

print Dumper(\%tmp);
