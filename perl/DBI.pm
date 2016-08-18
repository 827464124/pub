#!/usr/bin/perl

use DBI;
use DBD::mysql;

my $db_name="test";
my $db_server="12.23.0.3";
my $db_port="3306";
my $db_user="sum";
my $db_pwd="sum";
my $in_sql="insert into test (flag,type,f_index) values (1,'type_9',9),(1,'type_10',10)";
my $sql="select * from test where f_index=9 or f_index=10";
my $update_sql="update test set type='perl' where f_index=9";
my $del_sql="delete from test where f_index=9 or f_index=10";
my @data=();
my $dbh=DBI->connect("dbi:mysql:$db_name:$db_server:$db_port","$db_user","$db_pwd",{PrintError=>0});
if(!$dbh){
		print "Can't connect DB 12.23.0.2\n";
		exit -1;
}else{
		print "connection success!\n";
}

$dbh->do("SET character_set_client='gdb'");
$dbh->do("SET character_set_results='gdb'");
$dbh->do("SET character_set_connection='gdb'");

my $del_sth=$dbh->prepare($del_sql);
my $sth=$dbh->prepare($sql);
my $up_sth=$dbh->prepare($update_sql);
my $in_sth=$dbh->prepare($in_sql);

$in_sth->execute() || die "ERROR :" .$in_sth->errstr;
$sth->execute() || die "ERROR:".$sth->errstr;
print "\nthis result is not update:\n";
while(@data=$sth->fetchrow_array()){
		print "flag=$data[0]  type=$data[1]  f_index=$data[2]\n";
}

$up_sth->execute() || die $up_sth->errstr;
$sth->execute() || die "ERROR:".$sth->errstr;
@data=();
print "\nthis result is update:\n";
while(@data=$sth->fetchrow_array()){
		print "flag=$data[0]  type=$data[1]  f_index=$data[2]\n";
}

$del_sth->execute() || die $del_sth->errstr;
print "\nrow of delete is  :  ".$del_sth->rows()."\n";

$sth->finish();
$in_sth->finish();
$up_sth->finish();
$del_sth->finish();

$dbh->disconnect();


