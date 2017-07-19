#!/usr/bin/perl5
#
use strict ;

my @g_arr = 1..5;



#reverse   :  reverse the arr

my @r_g_arr = reverse @g_arr;

foreach my $idx (0..$#r_g_arr){
	print " reverse result:  $idx  =  $r_g_arr[$idx] \n";
}

# sort : sort the arr 

my @s_g_arr = sort @r_g_arr;

foreach my $idx (0..$#s_g_arr){
	print "sort result : $idx = $s_g_arr[$idx] \n";
}
