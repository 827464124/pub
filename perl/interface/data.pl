
#!/usr/bin/perl

use strict;
use LWP::UserAgent;

use Data::Dumper;

my $ua = LWP::UserAgent->new();
$ua->timeout(10);


#&get_info ('sh601009');
&get_info ('sh600756');
sub get_info 
{

	my $data_name=shift;
	my $app_key="cb59fe4800ea015921b3b0b354db7ab9";
	my $data_interface='http://web.juhe.cn:8080/finance/stock/hs?gid='.$data_name.'&key='.$app_key;
	
	my $result="";
	my $data_hash="";
	my $response = $ua->get($data_interface);
	
	if ( $response->is_success ){
		$result =  $response->content;
	}else{
		print  $response->status_line;
	}

	$result =~ s/:/=>/g;
#print $result;
	$data_hash = eval $result;

print $data_hash->{'error_code'};
	print Dumper($data_hash);
	my $data_info = $data_hash->{'result'}[0];

	print "买一：  价格：$data_info->{'data'}{'buyOnePri'}       \t数量： $data_info->{'data'}{'buyOne'}\n";
	print "买二：  价格：$data_info->{'data'}{'buyTwoPri'}       \t数量： $data_info->{'data'}{'buyTwo'}\n";
	print "买三：  价格：$data_info->{'data'}{'buyThreePri'}     \t数量： $data_info->{'data'}{'buyThree'}\n";
	print "买四：  价格：$data_info->{'data'}{'buyFourPri'}      \t数量： $data_info->{'data'}{'buyFour'}\n";
	print "买五：  价格：$data_info->{'data'}{'buyFivePri'}      \t数量： $data_info->{'data'}{'buyFive'}\n";
print "===========================================================================================\n";
	print "卖一：  价格：$data_info->{'data'}{'sellOnePri'}      \t数量： $data_info->{'data'}{'sellOne'}\n";
	print "卖二：  价格：$data_info->{'data'}{'sellTwoPri'}      \t数量： $data_info->{'data'}{'sellTwo'}\n";
	print "卖三：  价格：$data_info->{'data'}{'sellThreePri'}    \t数量： $data_info->{'data'}{'sellThree'}\n";
	print "卖四：  价格：$data_info->{'data'}{'sellFourPri'}     \t数量： $data_info->{'data'}{'sellFour'}\n";
	print "卖五：  价格：$data_info->{'data'}{'sellFivePri'}     \t数量： $data_info->{'data'}{'sellFive'}\n";

}






