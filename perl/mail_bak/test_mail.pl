#!/usr/bin/perl

use send_mail;

my $sm = new send_mail("/home/xing/mail.cfg","./pool/test1.cfg");

$sm->send_mail();


