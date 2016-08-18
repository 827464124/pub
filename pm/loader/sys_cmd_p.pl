use strict;
#system ("ls -1F");
#my $cmd;
#$cmd=`ls -1F &`;
#print "............\n$cmd\n.......";


#my $file;
#$file="myfile.txt";
#system("sort $file | lpr");




#!

use strict;
my($dirs,$sizes,$total);

while(<STDIN>){
	chomp;
	$total++;
	if(-d $_){
		$dirs++;
		print "$_\n";
		next;
	}
	$sizes+=(stat($_))[7];
	print "$_\n";
}
print "$total files,$dirs directores\n";
print "Average file size:",$sizes/($total-$dirs),"\n";

