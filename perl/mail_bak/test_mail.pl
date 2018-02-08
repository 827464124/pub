#!/usr/bin/perl

use send_mail;




my @file_arr = split /\n/,`find pool/ -type f`;


my $sm = new send_mail("/home/xing/mail.cfg");
for (my $idx = 0; $idx < @file_arr ; $idx ++){
$sm->{"mail_cfg"} = $file_arr[$idx] ;
$sm->send_mail();

`mv $file_arr[$idx] ./bak`;

}


