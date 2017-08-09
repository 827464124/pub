#!/usr/bin/perl

use strict;
use IO::Socket;

my $remote_host="127.0.0.1";
my $remote_port=8809;
my $socket=IO::Socket::INET->new(PeerAddr => $remote_host,
								PeerPort => $remote_port,
								Proto => "tcp",
								Reuse => 1,
								Type => SOCK_STREAM) or die "create client failed! $! \n";
print $socket "hello , I'm coming\n"  or die "send msg failed! $!\n";

#print $socket "success\n";

while (my $msg=<STDIN>){
	print $socket "$msg";
	last if($msg=~ /^close$/);
}
my $answer = <$socket>;
print $answer;
close $socket;
