
#!/usr/bin/perl

use strict;
use LWP::UserAgent;

use Data::Dumper;

my $ua = LWP::UserAgent->new();
$ua->timeout(10);


#&get_info ('sh601009');
&get_info ('00001');
sub get_info 
{

	my $data_name=shift;
	my $app_key="cb59fe4800ea015921b3b0b354db7ab9";
	my $data_interface='http://web.juhe.cn:8080/finance/stock/hk?num='.$data_name.'&key='.$app_key.'&type=0';
	
	my $result="";
	my $data_hash="";
	my $response = $ua->get($data_interface);
	
	if ( $response->is_success ){
		$result =  $response->content;
	}else{
		print  $response->status_line;
	}

	$result =~ s/:/=>/g;
print $result;
	$data_hash = eval $result;

print $data_hash->{'error_code'};
	Dumper($data_hash);

}
