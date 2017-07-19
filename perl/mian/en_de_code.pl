#!/usr/bin/perl -w

use strict;

my $enstr="24ab_2t2";
my $lg = length $enstr;
my $destr="";
while ($lg){
	$lg--;
	$destr .= "_";
	if ($enstr =~ /^(\d)$/){
		$destr .= $1;
		last;
	}elsif($enstr =~ /^(\d)(.)/){
		$destr .= "$2" x ($1 + 1);
		$enstr =~ s/^$1//;
		next;
	}elsif ($enstr =~ /^_/){
		$destr .= "\\UL";
		$enstr =~ s/^_//g;
		next;
	}elsif ($enstr =~ /^(\w)/){
		$destr .= $1;
		$enstr =~ s/^$1//g;
		next;
	}

}
$destr =~ s/^_|_$//;
print $destr."\n";
