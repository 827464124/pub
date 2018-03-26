#!/usr/bin/perl

use strict;
use Shell;
use Expect;


my $exp = Expect->spawn("bash","./test.sh");
$exp->expect(5,["no"]);
$exp->send("yes\n");
$exp->expect(5,'#$');
#print $exp->before();
