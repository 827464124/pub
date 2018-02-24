#!/usr/bin/perl -w
package send_mail;
use strict;
use Data::Dumper;

sub new
{
	my $this = shift;
	my $class = ref ($this) || $this;
	my $self = {};
	($self->{'server'} )  = @_;
	die " config file is not exist"if ((! -f $self->{'server'} )&& (! -f $self->{'mail_cfg'} ));
	bless $self , $class;
	$self;
}


sub send_mail
{
	my $self = shift;
	my $user = `cat $self->{'server'}  | grep USER | awk -F ':' '{print \$2}'`;
	my $password = `cat  $self->{'server'} | grep PW | awk -F ':' '{print \$2}'`;
	my $smtp_server = `cat $self->{'server'}  | grep SERVER | awk -F ':' '{print \$2}'`;
	
	chomp $user;
	chomp $password;
	chomp $smtp_server;
	
	my $mail_cfg = &read_mail_cfg("$self->{'mail_cfg'}");
	print Dumper($mail_cfg);
	
	my $smtpHost = $smtp_server;
	my $smtpPort = '25';
	my $sslPort = '465';
	my $username = $user;
	my $from = $user;
	my $to=$$mail_cfg{'TO'};
	my $subject = $$mail_cfg{'SUBJECT'};
	
	chomp $subject;
	chomp $to;
	
	#设置邮件header
	my $header = << "MAILHEADER";
From:$from
To:$to
Subject:$subject
Mime-Version:1.0
Content-Type:text/plain;charset="UTF-8"
Content-Trensfer-Encoding:7bit
MAILHEADER
	my $message = "\n" . $$mail_cfg{'CONTENT'};
	my @helo = split /\@/,$from;
	use Net::SMTP::TLS;
	my $smtp = Net::SMTP::TLS->new(
	"$smtpHost:$smtpPort",
	User=>$username,
	Password=>$password,
	Hello=>$helo[1],
	Timeout=>30
	) or die "Error:通过TLS连接到$smtpHost 失败！";
	
	#发送邮件
	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();
	$smtp->datasend($header);
	$smtp->datasend($message);
	$smtp->dataend();
	$smtp->quit();
	print "OK\n";

}

sub read_mail_cfg()
{
	my $mail_file = shift;
	open my $m_fd,"<","$mail_file" || return "open mail_file failed";
	my $attr = "";
	my %mail_cfg_hash = ();
	while (my $line = <$m_fd>){
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

1;
