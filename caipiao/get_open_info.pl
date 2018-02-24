#!/usr/bin/perl

use strict;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
my $cqssc_file = "./cqssc_tmp.xml";
my $xml = new XML::Simple;
print `date`;
#`wget http://f.apiplus.cn/cqssc-1.xml -o$cqssc_file >/dev/null`;
my $g_expect = "";

my $record_file = "./record.txt";
my $file_str = `tail -n2 $record_file`;
my @tmp_ar = split /,/,$file_str;
$g_expect = $tmp_ar[1];
$g_expect =~ s/^\s+|\s+$//g;
&store_info;
sub store_info 
{
	while (1){
		my $context = get ('http://f.apiplus.cn/cqssc-1.xml');
		if (!defined $context || $context eq "" ){
			sleep 10;
			next;
		}
		my $xml2hash = $xml->XMLin ($context);
		my $caipiao_num = $$xml2hash{'row'}{'opencode'};
		my $caipiao_expect = $$xml2hash{'row'}{'expect'};
		my $caipiao_time = $$xml2hash{'row'}{'opentime'};
		
		if($g_expect eq $caipiao_expect ){
			sleep 60;
		}else{
			open fp_STORE ,">>","$record_file";
			print fp_STORE "$caipiao_num               $caipiao_expect \n\n";
			close fp_STORE;
			$g_expect = $caipiao_expect;
			print "第一位数：\n";
			&parser_info ($caipiao_num,$caipiao_expect,1);
			print "第二位数：\n";
			&parser_info ($caipiao_num,$caipiao_expect,2);
			print "第三位数：\n";
			&parser_info ($caipiao_num,$caipiao_expect,3);
			print "第四位数：\n";
			&parser_info ($caipiao_num,$caipiao_expect,4);
			print "第五位数：\n";
			&parser_info ($caipiao_num,$caipiao_expect,5);

			print "__________________________________________________________\n";
			sleep 60;
		}
	}
}

sub parser_info 
{
	my ($num,$expect,$pos) = @_;
	my @num_arr = split /,/,$num;
	my $last_num = $num_arr[$pos-1];
	my $expect_num = $expect % 1000 ;
	my $out_str  = $expect_num."   ".$num;
	if (($last_num % 2 ) == 1) {
		$out_str .= "    单";
	}else{
		$out_str .= "    双";
	}
	print $out_str."\n";
	$out_str = "";
	my $single_num = 0;
	my $double_num = 0;
	my $max_sub_num = 0;
	my $double_rate = "";
	my $single_rate = "";
	my $serial_double_num = 0;
	my $serial_single_num = 0;
	my $max_serial_double_num = 0;
	my $max_serial_single_num = 0;
	my $d_s_flag  = 0;
	open fp_STORE, "<","$record_file";
	while (my $line = <fp_STORE> ) {
		if ($line =~ /(\S+)\s+(\S+)/) {
			my $tmp_num = "$1";
			my $tmp_ept = "$2";
			my $tmp_last_num = "";
			$tmp_last_num = "$1" if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)$/  && $pos == 1);
			$tmp_last_num = "$2" if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)$/  && $pos == 2);
			$tmp_last_num = "$3" if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)$/  && $pos == 3);
			$tmp_last_num = "$4" if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)$/  && $pos == 4);
			$tmp_last_num = "$5" if ($tmp_num =~ /(\d+),(\d+),(\d+),(\d+),(\d+)$/  && $pos == 5);
			if ( ($tmp_last_num %2 ) == 1 ){
				$single_num ++;
				$d_s_flag = 1;
				$serial_double_num = 0;
			}else{
				$double_num ++;
				$d_s_flag = 0;
				$serial_single_num = 0;
			}
			if ($d_s_flag ){
				$serial_single_num ++;
			}else{
				$serial_double_num ++;
			}
			my $sub_num = do { if (($single_num - $double_num) eq 0){ $single_num -$double_num}else{$double_num - $single_num}};
			$max_serial_double_num = $serial_double_num if ($serial_double_num > $max_serial_double_num);
			$max_serial_single_num = $serial_single_num if ($serial_single_num > $max_serial_single_num);
			$max_sub_num = $sub_num if ($sub_num > $max_sub_num);
			
		}
	}
	$double_rate = ($double_num)/($single_num + $double_num);
	$single_rate = ($single_num )/($single_num + $double_num);
	close fp_STORE;
	print "双总数 : " .$double_num . "   单总数 :  " .$single_num."\n";
	print "双最大连续个数 : $max_serial_double_num     单最大连续个数 : $max_serial_single_num \n";
	print "最大相差个数： $max_sub_num\n";
	print "双数概率：$double_rate         单数概率：$single_rate\n";
	print "---------------------------------------------------------------\n\n";
}

=pod
open FP , "<","$cqssc_file" || die "open $cqssc_file failed";

while (my $line = <FP> ) {
	print $line ;
}

close FP ;
`rm -rf $cqssc_file`;
=cut
