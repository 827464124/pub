#!/usr/bin/perl
use Data::Dumper;
my @p=(0,1,2,3,4,5);
my $pp=\@p;

my $t=1;
my $tt=\$t;

my %h=(
		'name'=>'Tom',
		'age'=>'3',
	);
my $hh=\%h;
sub test1()
{
print "pp=$pp\n";
print "tt=$tt\n";
print "hh=$hh\n";
}
sub test2()
{
print "pp=".$pp->[3]."\n";
print "tt=".$$tt."\n";
print "hh=".$hh->{'name'}."\n";
}

print "test1 out:\n";
&test1;
print "test2 out:\n";
&test2;
