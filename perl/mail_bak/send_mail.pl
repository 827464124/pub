#!/usr/bin/perl

use Net::SMTP;
use Data::Dumper;


my $user = `cat /home/xing/mail.cfg | grep USER | awk -F ':' '{print \$2}'`;
my $password = `cat /home/xing/mail.cfg | grep PW | awk -F ':' '{print \$2}'`;
my $smtp_server = `cat /home/xing/mail.cfg | grep SERVER | awk -F ':' '{print \$2}'`;

chomp $user;
chomp $password;
chomp $smtp_server;

print "$user $password $smtp_server \n ";



sub send_mail()
{
		my $tmp_mail_cfg = &read_mail_cfg("./pool/test1.cfg");
		print Dumper($tmp_mail_cfg);

		my $to_addr="$$tmp_mail_cfg{'TO'}\n";
		
		my $from="From: $user";
		my $subject="Subject: $$tmp_mail_cfg{'SUBJECT'}\n";
		my $content= "$$tmp_mail_cfg{'CONTENT'}\n ";
		my $smtp=Net::SMTP->new($smtp_server);
		$smtp->auth($user,$password) || die "auth failed! ".$smtp->message()."\n";
		$smtp->mail($user);
		$smtp->to($to_addr) || die "to".$smtp->message()."\n";
		$smtp->data() || die "data failed ".$smtp->message()."\n";
		$smtp->datasend($from);
		$smtp->datasend($subject);
		$smtp->datasend($content) || "datasend ".$smtp->message()."\n";
		$smtp->dataend() || die "dataend ".$smtp->message()."\n";

		$smtp->quit();
}

&send_mail();


sub read_mail_cfg()
{
	my $mail_file = shift;
	open my $m_fd,"<","$mail_file";
	my $attr = "";
	my %mail_cfg_hash = ();
	while (my $line = <$m_fd>){
		chomp $line;
		if ($line =~ /^>>>>>(\w+)/){
				$attr = $1;
				next;
		}
		if ($attr !~ /^$/){
			$mail_cfg_hash{$attr} .= $line;
			next;
		}
	}
	close $m_fd;
	return \%mail_cfg_hash;
}





		
		


		
