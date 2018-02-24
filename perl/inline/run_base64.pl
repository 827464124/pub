#!/usr/bin/perl -w

use Inline  C=>Config=>LIBS=>'-lbase64';
use Inline C ;
use strict;

my $src_str = "qwe";

my $str =  main_($src_str);


print "$str \n";

__END__
__C__

char *   main_(char  *buf )  
{  
			//char buf[1024] = "qwe";
			ch_to_base64( buf);
                    printf("buf = %s\n",buf);  
					return buf;
} 
