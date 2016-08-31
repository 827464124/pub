#!/usr/bin/perl

use strict;
use IO::Socket;

my $port = 8809;
my $server=IO::Socket::INET->new(LocalPort=>$port,
								Type=>SOCK_STREAM,
								Reuse=>1,
								Listen=>10
								)or die "create server failed!\n";
my $socket = $server->accept();

while(<$socket>){
		my $cnt = $_;
		print $cnt;
		if ($cnt eq "success\n"){ 
				$socket->send("Goodbye!\n");
				last;}
}

close $server;
