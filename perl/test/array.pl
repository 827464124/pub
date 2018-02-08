#!/usr/bin/perl
#
#

use strict;
use Data::Dumper;
my @a = qw/1 2 3 4 5 6 7/;
my $w = 3;
my $q = 1;
my @b = @a[$q..$w];

print Dumper(\@b);
