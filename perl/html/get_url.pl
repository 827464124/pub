#!/usr/bin/perl

use Data::Dumper;

#my @ua=split("\n",`elinks --dump http://blog.csdn.net/zh_wenxing163com/article/month/2016/09`);

my $source=`elinks --dump http://blog.csdn.net/zh_wenxing163com/article/month/2016/09`;
#print Dumper(@ua);
$source=~s/\ //g;
print $source."\n";

while (my $line = shift @ua ){
		#if($line=~m/^(.*)http(.*)#comments$/){
				#print $line.";\n";
		#}
		next if ($line == "");
		print "aaaa\n";
}
