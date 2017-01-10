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

$ssh->send("cat  /home/xing/all_bak/y.txt");
$ssh->waitfor ("\$\>\%\#");
print "peek : ------------------------------------\n";
print $ssh->peek(0) ."\n";
print "peek over  --------------------------------\n";
print "read_line : -------------------------------\n";
while($line = $ssh->read_line()){
	print $line."\n";
}
print "read_line  over --------------------------\n";

$ssh->send("cat  /home/xing/all_bak/y.txt");
$ssh->waitfor ("\$\>\%\#");

print "read_all : -------------------------------\n";
print $ssh->read_all() ."\n";
print "read_all over ---------------------------\n";

$ssh->send("cat  /home/xing/all_bak/y.txt");
$ssh->waitfor ("\$\>\%\#");

print "eat test: --------------------------------\n";
$ssh->eat($ssh->peek(0));
print $ssh->peek(0) ."\n";
print $ssh->read_all() ."\n";
print "eat test over ----------------------------\n";


$ssh->send("cat  /home/xing/all_bak/y.txt");
$ssh->waitfor ("\$\>\%\#");
print "after ; ---------------------------------\n";
$ssh->read_line();
$ssh->read_line();
print $ssh->after() ."\n";
print "after over -----------------------------\n";




$ssh->close();

