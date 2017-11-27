#!/usr/bin/perl

use strict;
use single;

{
	my $s1 = single->new();
 $s1->add();
{
 my $s2 = single->new();
$s2->add();
$s2->destroy();
print $s2->{"AAA"}."\n";
}
print $s1->get_instance_num()."\n";
print $s1->get_instance_num()."\n";
 print $s1->{"AAA"}."\n";

 }

my $s3 = single->new();

$s3->add();
my %q={'a'=>1,'b'=>2,'c'=>3};

my $ww =  {keys %q};
print $ww;
#print $s3->{"AAA"}."\n";
