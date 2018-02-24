#!/usr/bin/perl

use strict;
use Data::Dumper;

my @A=qw/1 2 4/;
my @B=1..9;
my @C;









my @unit1=qw/0 0 0 0 0 0 0 0 0/;
my @unit2=qw/0 0 0 0 0 0 0 0 0/;
my @unit3=qw/0 0 0 0 0 0 0 0 0/;
my @unit4=qw/0 0 0 0 0 0 0 0 0/;
my @unit5=qw/0 0 0 0 5 0 0 0 0/;
my @unit6=qw/0 0 0 0 0 0 0 0 0/;
my @unit7=qw/0 0 0 0 0 0 0 0 0/;
my @unit8=qw/0 0 0 0 0 0 0 0 0/;
my @unit9=qw/0 0 0 0 0 0 0 0 0/;




for (my $idx = 1; $idx < 10 ; $idx ++){
	my @tmp = eval '@'."unit$idx";
	my @ret = &get_unused_num(@tmp);
	print &cal_unit(@tmp) . "\n";
}




sub get_unused_num{

	my @tmp_=();
	my @input=@_;
	for (my $idx = 0; $idx < @B ; $idx ++){
		if (!grep {$_ == $B[$idx]} @input ){
			push @tmp_ , $B[$idx];
		}
	}
	wantarray ? @tmp_:\@tmp_;
}


sub cal_unit
{
		my @nine_unit = @_;
		if (@nine_unit != 9){
				print "nine is @nine_unit\n";
		}
		my $str_sum = join '+' ,@nine_unit;
		return eval join '+' ,@nine_unit;
}
