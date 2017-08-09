#!/usr/bin/perl

use strict;
use IO::Socket;

my $port = 8809;
my $server=IO::Socket::INET->new(LocalPort=>$port,
								Type=>SOCK_STREAM,
								Reuse=>1,
								Listen=>10
								)or die "create server failed! $!\n";

my $idx = 1;
while (my $socket = $server->accept()){
my $pid = fork();

	if ($pid != 0){
	
		while(<$socket>){
				my $cnt = $_;
				print "name>[$idx] : $cnt\n";
				if ($cnt eq "success\n"){ 
						$socket->send("Goodbye!\n");
						exit (0);
				}
		}
		close $server;
	}
	$idx++;
}
