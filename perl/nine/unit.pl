#!/usr/bin/perl

use strict;
use Data::Dumper;

my @A=qw/1 2 4/;
my @B=1..9;
my @C;









my @unit1=qw/0 1 5 0 0 0 2 8 0/;
my @unit2=qw/6 0 0 4 0 7 0 0 3/;
my @unit3=qw/2 0 7 0 1 0 6 0 4/;
my @unit4=qw/0 7 0 0 0 0 0 2 0/;
my @unit5=qw/0 0 6 0 5 0 4 0 0/;
my @unit6=qw/0 5 0 0 0 0 0 3 0/;
my @unit7=qw/7 0 9 0 8 0 3 0 1/;
my @unit8=qw/5 0 0 1 0 3 0 0 9/;
my @unit9=qw/0 6 1 0 0 0 8 4 0/;


for (my $idx = 1; $idx < 10 ; $idx ++){
	my $tmp = eval '\@'."unit$idx";
	for (my $c_idx = 0; $c_idx < 9 ; $c_idx ++){
	my @sub_unit = &get_sub_unit($idx,$c_idx);
	my @unused_arr = &get_unused_num(@$tmp,@sub_unit);
		
		

		if (!$$tmp[$c_idx] ){
			my @tmp_col_arr = &get_column_arr($c_idx);
			foreach my $num (@unused_arr){
				if (  grep {$_ == $num} @tmp_col_arr ){#|| grep {$_ == $num} @sub_unit){
					next;
				}else{
					$$tmp[$c_idx] = $num;
					last;
				}
			}
		}
	}

	print "@$tmp\n";
				
	
}



sub get_sub_unit{
	my ($row,$col) = @_;
	my @tmp = ();

	return &cal_sub_unit(3,2) if ($row < 4 && $col < 3);
	return &cal_sub_unit(3,5) if ($row < 4 && $col >= 3 && $col <6);
	return &cal_sub_unit(3,8) if ($row < 4 && $col >=6 &&  $col <9);
	return &cal_sub_unit(6,2) if ($row < 4 && $col < 3);
	return &cal_sub_unit(6,5) if ($row < 4 && $col >= 3 &&  $col <6);
	return &cal_sub_unit(6,8) if ($row < 4 && $col >= 6 &&  $col <9);
	return &cal_sub_unit(9,2) if ($row < 4 && $col < 3);
	return &cal_sub_unit(9,5) if ($row < 4 && $col >=6 &&  $col <6);
	return &cal_sub_unit(9,8) if ($row < 4 && $col >=6 &&  $col <9);

}
sub cal_sub_unit{
	my ($row,$col) = @_;
	my @tmp = ();
	my $t_r = 0;
	my $t_c = 0;
	for(my $row_idx = $row ; $t_r < 3; $row_idx --,$t_r++){
		$t_c = 0;
		for (my $col_idx = $col; $t_c < 3;$col_idx --,$t_c++){
				push @tmp , eval '$'."unit$row_idx"."[$col_idx]";
		}
	}

	return wantarray?@tmp:\@tmp;
}

sub get_column_arr{
	my @tmp = ();
	my $column_num = shift;
	for (my $idx = 1; $idx <10 ;$idx++){
		push @tmp ,eval '$'."unit$idx"."[$column_num]";
	}
	return wantarray ? @tmp:\@tmp;
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
