#!/usr/bin/perl -w

require "/ioss/pm/collect/public_func.pm";
$value=shift;
$period=shift;
my $strrr=DiffDateTime($value,$period);
print "$strrr\n";
