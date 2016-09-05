#!/usr/bin/perl

use Net::SMTP;

sub send_mail()
{
		my $to_addr=shift;
		my $user='zh_wenxing@qq.com';
		my $pass='zwx123..';
		my $smtp_server='smtp.qq.com';

		my $from="From: $user\n";
		my $subject="Subject: 会议\n";
		my $content= "快过来开会\n ";
		my $smtp=Net::SMTP->new($smtp_server);
		$smtp->auth($user,$pass) || die "auth failed! ".$smtp->message()."\n";
		$smtp->mail($user);
		$smtp->to($to_addr) || die "to".$smtp->message()."\n";
		$smtp->data() || die "data failed ".$smtp->message()."\n";
		$smtp->datasend($from);
		$smtp->datasend($subject);
		$smtp->datasend($content) || "datasend ".$smtp->message()."\n";
		$smtp->dataend() || die "dataend ".$smtp->message()."\n";

		$smtp->quit();
}

&send_mail('zh_wenxing@163.com');
		
		
		

		
