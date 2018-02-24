#!/usr/bin/perl

use strict;
use Data::Dumper;

my $data_file = "./record.txt";
open fp_DATA, "<","$data_file";

&read_info;

sub read_info
{
	my %s_hash = ();
	while (my $line = <fp_DATA>){
		if ($line =~ /(\S+)(\s+)(\S+)/){
			my $tmp_num = "$1";
			my $tmp_expect = "$2";
			if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)/){
				my $num_1 = "$1";
				my $num_2 = "$2";
				my $num_3 = "$3";
				my $num_4 = "$4";
				my $num_5 = "$5";
				$s_hash{"num_1"}{$num_1} = 0 if (! defined $s_hash{"num_1"}{$num_1});
				$s_hash{"num_2"}{$num_2} = 0 if (! defined $s_hash{"num_2"}{$num_2});
				$s_hash{"num_3"}{$num_3} = 0 if (! defined $s_hash{"num_3"}{$num_3});
				$s_hash{"num_4"}{$num_4} = 0 if (! defined $s_hash{"num_4"}{$num_4});
				$s_hash{"num_5"}{$num_5} = 0 if (! defined $s_hash{"num_5"}{$num_5});
				
				$s_hash{"num_1"}{$num_1} ++;
				$s_hash{"num_2"}{$num_2} ++;
				$s_hash{"num_3"}{$num_3} ++;
				$s_hash{"num_4"}{$num_4} ++;
				$s_hash{"num_5"}{$num_5} ++;
			}
		}
	}
	&calc_rate (\%s_hash,"num_1");
	&calc_rate (\%s_hash,"num_2");
	&calc_rate (\%s_hash,"num_3");
	&calc_rate (\%s_hash,"num_4");
	&calc_rate (\%s_hash,"num_5");
}

sub calc_rate
{
	my ($data_hash,$num_pos) =@_;

	my $num_sum = 0;
	my $out_str = "";
	my $double_num = 0;
	my $single_num = 0;
	
	foreach my $num_key (keys %{$$data_hash{$num_pos}}){
		$num_sum += $$data_hash{$num_pos}{$num_key};
	}
	
	$out_str .= sprintf( "$num_pos  ->  ");
	foreach my $num_key (keys %{$$data_hash{$num_pos}}){
		my $s_rate = $$data_hash{$num_pos}{$num_key} / $num_sum;
		$out_str .= sprintf ( "%d  :  %0.3f   |",$num_key ,$s_rate);  
		if (( $num_key  % 2 ) == 1){
			$single_num += $$data_hash{$num_pos}{$num_key};
		}else{
			$double_num += $$data_hash{$num_pos}{$num_key};
		}
	}
	
	my $single_rate = $single_num / $num_sum ;
	my $double_rate = $double_num / $num_sum ;
	print "$out_str \n\n";
	print "双概率：$double_rate             单概率： $single_rate\n";
}





		





