#!/usr/bin/perl
use Data::Dumper;
use send_mail;


my $sm = new send_mail;
my $server_file = "/home/xing/mail.cfg";
my $pool_dir = "./pool/";
my $bak_pool = "./bak_pool";
my $failed_pool = "./failed_pool";


$sm->_config_server($server_file);


my @cfg_file = split /\n/, `find  $pool_dir -type f`;
for (my $idx = 0 ; $idx < @cfg_file ;$idx ++){
	$sm->_config_($cfg_file[$idx]);
	 if ($sm->send_mail()) {
		`mv $cfg_file[$idx] $bak_pool`;
	 }else{
		 `mv $cfg_file[$idx] $failed_pool`;
	 }
}

