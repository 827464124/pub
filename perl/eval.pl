#!/usr/bin/perl

my $name="print 'this is a element\n'";
eval($name);

sub T_print()
{
		print "this is T function\n";
}

sub R_print()
{
		print "this is R function\n";
}

my $h='T';
eval($h."_print()")
