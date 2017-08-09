#!/usr/bin/perl

use strict;

use Net::SSH::Expect;

my $ssh ;
my $line;
eval {
	$ssh = new Net::SSH::Expect (
		'host' => '127.0.0.1',
		'user' =>'root',
		'password' => '1qazXSW@',
		'port' => 22,
		'timeout' =>1,
		'raw_pty' => 1);
	
	if ($ssh->login() =~ /Password/i){
		print "password  is  wrong !\n";
		exit -1;
	}
};

$ssh->send("cat  /home/xing/all_bak/y.txt\n");
$ssh->waitfor ('[\$%#>]\s*(\\033\[0m)?$')  ?  print "waitfor  Ok\n"  : die "waitfor  failed";
print "peek : ".$ssh->peek(0) ."\n";
$line = $ssh->before();
print "before :  $line \n";


$ssh->send("cat  /home/xing/all_bak/y.txt\n");
#$ssh->waitfor ('[\$%#>]\s*(\\033\[0m)?$')  ?  print "waitfor  Ok\n"  : die "waitfor  failed";

print "read_all : \n";
print $ssh->read_all() ."\n";
print "read_all over \n";

$ssh->send("cat  /home/xing/all_bak/y.txt\n");
#$ssh->waitfor ('[\$%#>]\s*(\\033\[0m)?$')  ?  print "waitfor  Ok\n"  : die "waitfor  failed";

print "eat test: --------------------------------\n";
$ssh->eat($ssh->peek(0));
print $ssh->peek(0) ."\n";


my $ret = $ssh->read_all();
print $ret."\n";
$ret=~s/\r\n/\n/g;
my @arr=split /\n/,$ret;
print "eat test over ----------------------------\n";


$ssh->send("cat  /home/xing/all_bak/y.txt\n");
#$ssh->waitfor ('[\$%#>]\s*(\\033\[0m)?$')  ?  print "waitfor  Ok\n"  : die "waitfor  failed";
print "after ; ---------------------------------\n";
$ssh->read_line();
$ssh->read_line();
print $ssh->after() ."\n";
print "after over -----------------------------\n";




$ssh->close();

