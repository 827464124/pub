#!/usr/bin/perl
use Net::SMTP;

# mail_user should be your_mail@163.com
sub send_mail{
    my $to_address  = shift;
    my $mail_user   = 'zh_wenxing@163.com';
    my $mail_pwd    = 'zwx123';
    my $mail_server = 'smtp.163.com';

    my $from    = "From: $mail_user\n";
    my $subject = "Subject: here comes the subject\n";

    my $message = <<CONTENT; 
    **********************
    here comes the content
    **********************
CONTENT

    my $smtp = Net::SMTP->new($mail_server);

    $smtp->auth($mail_user, $mail_pwd) || die "Auth Error! $!";
    $smtp->mail($mail_user);
    $smtp->to($to_address);

    $smtp->data();             # begin the data
    $smtp->datasend($from);    # set user
    $smtp->datasend($subject); # set subject
    $smtp->datasend($message); # set content
    $smtp->dataend() || die "dataend ".$smtp->message()."\n";

    $smtp->quit();
}

&send_mail('827464124@qq.com');