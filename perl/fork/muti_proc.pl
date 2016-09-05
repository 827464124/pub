#!/usr/bin/perl


use strict;
use warnings;
my $i=0;


while( $i < 5 ){
my $pid=fork();
my $var=100;
if($pid == 0){
		print "I'm child proc  ,my pid is  $$  parent pid is ".getppid().", var=".\$var."\n";
		sleep(5);
		exit(0);
}
	$i++;
}
wait();
while(1){}
