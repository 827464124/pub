#!/usr/bin/perl

use strict;

my @g_arr = qw/this is a test about arr/;

#pop  : get and cut the last value ;

my $pop_value = pop @g_arr ;

print $pop_value ."\n";

print "-------------------------------------------\n\n\n";
#push : insert into a value at tail of arr;

push @g_arr , "new_word";

print "push result: ";
for (my $i = 0 ; $i < @g_arr ;$i++){
	print $g_arr[$i]."    ";
}
print "\n-------------------------------------------\n\n\n";

#shift : get and cut the first value

my $shift_value = shift @g_arr ;
print $shift_value."\n";
print "-------------------------------------------\n\n\n";

#unshift : insert into the value at head of arr;

unshift  @g_arr ,"new_shift";

print  "unshift  result : ";
for (my $i = 0 ; $i < @g_arr ;$i++){
	print $g_arr[$i]."   ";
}
print "\n-------------------------------------------\n\n\n";


#splice : get and cut a value  at any postion of array ;
#param :
#	1. array;
#	2.start positon;
#	3.length; not must,default:max
#	4.switch data; not must;

@g_arr = qw/this is a test about arr/;
my @tmp_arr = splice @g_arr,1;

print "tmp_arr : ";
for(my $i = 0; $i < @tmp_arr ;$i++){
	print $tmp_arr[$i]."   ";
}
print "\n========================\n";
print "g_arr : ";
for (my $i = 0; $i < @g_arr ;$i ++ ){
		print $g_arr[$i]."   ";
}
print "\n========================\n";
#now tmp_arr : is a test about arr;
#    g_arr : this;

@tmp_arr = splice @g_arr ,0,1,qw/this is a test about arr/;
print "tmp_arr : ";
for(my $i = 0; $i < @tmp_arr ;$i++){
	    print $tmp_arr[$i]."   ";
}   
print "\n========================\n";
print "g_arr : ";
for (my $i = 0; $i < @g_arr ;$i ++ ){
	        print $g_arr[$i]."   ";
}
print "\n========================\n";




