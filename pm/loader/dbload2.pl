#!/usr/local/bin/perl
###############################################################################
#
#  @(#) Perl Program: dbload.pl
#
#  Copyright(C) 2001-2005 LANGCHAOLG Overseas R&D Center, All Rights Reserved
#
#  Edition: V1.6
#
#  Command Line: dbload.pl
#                [-once]
#                [-wakeup] <interval in seconds>
#                -loaddir <data loaddir>
#                -dbserver <DB server machine>
#                -databasedb <PMDATA DB name>
#                -databasead <PMADMIN DB name>
#                -username <DB username>
#                -password <DB password>
#                -ruleset <vendor code>
#                -hostip <hostip>
#                [-valuetest]
#                -logfile <file>
#                [-loglevel] < 0 | 1 | 2 | 3 | 4 >
#                [-pmmess]
#                [-datamess]
#                [-filemess]
#                [-nemess]
#                [-pmalarm]
#                -taskid	<taskid>
#                [-backupdir] <backupdir>
#
#  Author(s): Zhangming
#
#  Creation Date: Jul. 30, 2005
#
#  Description: Load the normative files into database and send the message of PM data.
#
###############################################################################
#现在表的入库信息插入的是db库，以后根据需要修改

use strict;
use Data::Dumper;
use Getopt::Long;
use IO::Socket;
use DBI;
use DBD::mysql;
use Time::Local;
use Time::HiRes;  #为了得到毫秒的数据
#use diagnostics;

#调用特殊功能函数
require $ENV{"PMLIBDIR"}."/function.pm";
#
my $hostip = "";
my $mess_outport = 22001;
my $alarm_outport = 22002;
my $timeout = 20;
my $outsocket;
my $alarmsocket;
#当前进程号
my $pid = $$;
#运行标志文件
my $sub_runpid=".dbload2.pid";
#
#设置信号，在有下列信号时，退出程序，同时断开数据库的连接
$SIG{'INT'}=\&catch_sign("INT");
$SIG{'KILL'}=\&catch_sign("KILL");
$SIG{'QUIT'}=\&catch_sign("QUIT");
$SIG{'TERM'}=\&catch_sign("TERM");
#退出的信号标致
my $exitsign=0;
#默认变量
#****************************************
#ruleset:表示设备商的编号，一般用一位数字表示
#taskid:定义的执行任务号，注每个load的task号不能相同，
#	一般任务号的值为ruleset+1...9的两位整数
#****************************************
my $once = 0;
my $wakeup = 3;
my $loaddir = "";
my $dbserver = "";
my $databasedb = "";
my $databasead = "";
my $username = "";
my $password = "";
my $ruleset = 0;
my $valuetest = 0;
my $logfile = "";
my $loglevel = 2;
my $pmmess = 0;
my $datamess = 0;
my $filemess = 0;
my $nemess = 0;
my $backupdir = "";
my $namesort = 0;
my $timesort = 1;
my $reversesort = 0;
my $pmalarm = 0;
my $taskid = 0;
#
#分析输入参数
if ( &analyse_parameter() ) {
	print "Usage: $0\n";
	print "\t[-once]                         (执行一次退出)\n";
	print "\t[-wakeup] <interval in seconds> (每次扫描指定目录文件的间隔)\n";
	print "\t-loaddir <data loaddir>         (每次扫描的目录)\n";
	print "\t-dbserver <DB server machine>   (数据库Server名)\n";
	print "\t-databasedb <PMDATA DB name>    (PM数据库名称)\n";
	print "\t-databasead <PMADMIN DB name>   (PM管理库名称)\n";
	print "\t-username <DB username>         (数据库用户名)\n";
	print "\t-password <DB password>         (数据库password)\n";
	print "\t-ruleset <vendor code>          (入库编号)\n";
	print "\t-hostip <hostip>                (要连接的主机地址)\n";
	print "\t[-valuetest]                    (该功能只针对含有+-*/的表达式起作用，当某个Counter的值为空时：该Counter数据为0，还是该项表达式的值为空)\n";
	print "\t-logfile <file>                 (日志文件)\n";
	print "\t[-loglevel] < 0|1|2|3|4 >       (日志等级)\n";
	print "\t[-pmmess]                       (发送性能数据)\n";
	print "\t[-datamess]                     (发送文件BLOCK信息)\n";
	print "\t[-filemess]                     (发送文件入库信息)\n";
	print "\t[-nemess]                       (产生网元入库信息)\n";
	print "\t[-pmalarm]                      (发送性能告警信息)\n";
	print "\t-taskid <taskid>                (执行的流水号)\n";
	print "\t[-backupdir] <backupdir>        (数据的备份目录)\n";
	exit 1;
}

#loadmap信息
my %loadmap=();
#网元入库信息
my %loadflag=();
#网元对应关系字典信息
my %hierinfo=();
#网元对应关系与字典表的对应关系
my %hiertab=();
#pm_alarm信息
my %pm_alarm=();
#装载历史网元告警信息
my %alarmmess=();
#告警编号
my $alarmid=0;
#返回结果值
my $ret=0;

#判断目录是否存在
#入库文件目录
if ( ! -e $loaddir ) {
	my $logmess = "(Error:13001) Can not exists the Load direction $loaddir !";
	&writelog ( \$logmess, 1, 2 );
	exit 1;
}

#在Load目录里检查是否有其他Load运行，没有则创建运行标志，有则退出
if ( &check_loaddir($loaddir) ) {
	my $logmess = "(Message:13002) Other Load is running in $loaddir !";
	&writelog ( \$logmess, 1, 2 );
	&writelog ( \$logmess, 1, 1 );
	exit 1;
}
#备份文件目录
if ( $backupdir ne "" ) {
	if ( ! -e $backupdir ) {
		my $logmess = "(Error:13003) Can not exists the Load direction $backupdir !";
		&writelog ( \$logmess, 1, 2 );
		exit 1;
	}
}

#连接PM数据库
my $dbh=DBI->connect("dbi:mysql:$databasedb:$dbserver:3306","$username","$password",{PrintError => 0});
if(!$dbh)
{
  my $logmess = "(Error:13004) Can not Connect to the database $databasedb of dbserver $dbserver !";
  &writelog ( \$logmess, 1, 2 );
  exit 1;
} else {
	my $logmess = "(Info:13004) Connect to the database $databasedb of dbserver $dbserver !--OK";
  &writelog ( \$logmess, 1, 1 );  
}
$dbh->do("SET character_set_client='gbk'");
$dbh->do("SET character_set_connection='gbk'");
#连接PM管理库
my $adh=DBI->connect("dbi:mysql:$databasead:$dbserver:3306","$username","$password",{PrintError => 0});
if(!$adh)
{
  my $logmess = "(Error:13005) Can not connect to the database $databasead of dbserver $dbserver !";
  &writelog ( \$logmess, 1, 2 );
  &exitload;
} else {
	my $logmess = "(Info:13004) Connect to the database $databasead of dbserver $dbserver !--OK";
  &writelog ( \$logmess, 1, 1 );  
}
$adh->do("SET character_set_client='gbk'");
$adh->do("SET character_set_connection='gbk'");
#加载LOADMAP,增加表里面是否有对应的字段的判断
$ret = &upload_loadmap( \%loadmap, \%loadflag, $ruleset );
if( $ret ) {
	my $logmess = "(Error:13006) Error in load the loadmap of ruleset $ruleset!";
	&writelog ( \$logmess, 1, 2 );
	&exitload;
}

#加载HIERINFO
$ret = &upload_hierinfo( \%hierinfo, \%hiertab, $ruleset );
if( $ret ) {
	my $logmess = "(Error:13007) Error in load the hierinfo of ruleset $ruleset !";
	&writelog ( \$logmess, 1, 2 );
	&exitload;
}

#加载性能告警的信息
if ( $pmalarm ) {
	#加载性能告警的门限设置信息
	$ret = &upload_pm_alarm( \%pm_alarm, $ruleset );
	if( $ret ) {
		my $logmess = "(Error:13101) Error in load the PM alarm Threshold message of ruleset $ruleset !";
		&writelog ( \$logmess, 1, 2 );
		&exitload;
	}
	#加载历史性能告警信息
	$ret = &upload_alarmmess();
	if( $ret ) {
		my $logmess = "(Error:13102) Error in load the historical PM alarm of Task $taskid !";
		&writelog ( \$logmess, 1, 2 );
		&exitload;
	}
}

#数据文件名称
my $filename;
while ( 1==1 ) {
	#socket连接，通过判断 $outsocket 是否大于 0 来判断是否连接成功
	&connect_server();
	#查找指定指定目录下的数据文件
	unless ( opendir(INPUTDIR,"$loaddir") ) {
		my $logmess = "(Error:13008) Can not read any files from the Load direction $loaddir !";
		&writelog ( \$logmess, 1, 2 );
		
		&exitload;
	}
	while( $filename = readdir INPUTDIR ) {
		#当发出退出信号时执行相关关闭操作后程序退出
		&exitload if ( $exitsign );
		if ( -f "$loaddir/$filename" ) {
			if ( ! ( $filename =~ /\.bad$/ || $filename =~ /\.pt$/ || $filename =~ /^\./ ) ) {
				my $logmess = "(Message:13009) Begin load file $loaddir/$filename !";
				&writelog ( \$logmess, 1, 1 );
				#得到要入库的数据文件
				$ret = &load_file2db( "$loaddir/$filename" );
				#一个文件入完库之后的分析操作
				#判断是否正常入库。非正常，则更改为“.bad”文件
				if( $ret ) {
					my $logmess = "(Error:13010) The file $loaddir/$filename is loaded error and renamed bad !";
					&writelog ( \$logmess, 1, 2 );
					&writelog ( \$logmess, 1, 1 );
					if ( ! rename ( "$loaddir/$filename", "$loaddir/$filename\.bad" ) ) {
						my $logmess = "(Error:13011) Error in rename bad of the file $loaddir/$filename !";
						&writelog ( \$logmess, 1, 2 );
					}
					next;
				#文件备份
				} elsif ( $backupdir ) {
					if  ( ! rename ( "$loaddir/$filename", "$backupdir/$filename" ) ) {
						my $logmess = "(Error:13012) Error in remove $loaddir/$filename to $backupdir !";
						&writelog ( \$logmess, 1, 2 );
					}
				#文件删除
				} else {
					if  ( ! unlink ( "$loaddir/$filename") ) {
						my $logmess = "(Error:13013) Error in delete $loaddir/$filename !";
						&writelog ( \$logmess, 1, 2 );
					}
					
				}
				
				my $logmess = "(Message:13014) End load file $loaddir/$filename !";
				&writelog ( \$logmess, 1, 1 );
			}
		}
	}
	#关闭打开的目录
	closedir (INPUTDIR);
	#如果是一次执行就退出
	if ( $once ) {
		my $logmess = "(Message:13077) Complete Load the files !";
		&writelog ( \$logmess, 1, 1 );
		&exitload;
	}
	#
	#针对LOAD循环执行的情况
	#将目前历史告警的信息保存到文件
	&write_alarmmess() if ( $pmalarm ) ;
	#断开发送PM数据socket连接
	if ( $outsocket > 0 ) {
		close($outsocket);
		$outsocket = 0;
	}
	#断开发送PM告警socket连接
	if ( $alarmsocket > 0 ) {
		close($alarmsocket);
		$alarmsocket = 0;
	}
	sleep $wakeup;
}
exit 0;

#************************************************
#	功能：	
#		更改退出信号的变量 exitsign 的值为 1
#	输入：
#		
#	输出：
#		
#************************************************
sub catch_sign {
	my $intType=shift;
	my $logmess = "(Message:13015) Receive a signal and the Load will be exit ! from $intType to exit load";
	&writelog ( \$logmess, 1, 1 );
	&writelog ( \$logmess, 1, 2 );
	$exitsign = 1;
	return 0;
}

#************************************************
#	功能：	
#		程序退出时相应的关闭操作
#	输入：
#		
#	输出：
#		
#************************************************
sub exitload {
	close($outsocket) if ( $outsocket>0 );
	close($alarmsocket) if ( $alarmsocket>0 );
	$dbh->disconnect if ( $adh );
	$adh->disconnect if ( $adh );
	#保存告警的信息
	&write_alarmmess() if ( $pmalarm ) ;
	#删除LOAD的运行标致文件
	if  ( ! unlink ( "$loaddir/$sub_runpid") ) {
		my $logmess = "(Error:13078) Error in delete $loaddir/$sub_runpid !";
		&writelog ( \$logmess, 2, 2 );
	}
	
	my $logmess = "(Message:13076) The Load exit !";
	&writelog ( \$logmess, 1, 1 );
	&writelog ( \$logmess, 1, 2 );

	exit 0;
}

#************************************************
#	功能：	
#		分析输入参数，同时判断参数合法性
#	输入：
#		
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub analyse_parameter {
	my $result = GetOptions(
	"once!" => \$once,
	"wakeup=i" => \$wakeup,
	"loaddir=s" => \$loaddir,
	"dbserver=s" => \$dbserver,
	"databasedb=s" => \$databasedb,
	"databasead=s" => \$databasead,
	"username=s" => \$username,
	"password=s" => \$password,
	"ruleset=i" => \$ruleset,
	"hostip=s" => \$hostip,
	"valuetest!" => \$valuetest,
	"logfile=s" => \$logfile,
	"loglevel=s" => \$loglevel,
	"pmmess!" => \$pmmess,
	"datamess!" => \$datamess,
	"filemess!" => \$filemess,
	"nemess!" => \$nemess,
	"pmalarm!" => \$pmalarm,
	"taskid=i" => \$taskid,
	"backupdir=s" => \$backupdir);
	#判断有效性
	if ( $loaddir eq "" ) {
		return 1;
	} elsif ( $ruleset <= 0 ) {
		return 1;
	} elsif ( $wakeup <= 0 ) {
		return 1;
	} elsif ( $logfile eq "" ) {
		return 1;
	} elsif ( $hostip eq "" ) {
		return 1;
	} elsif ( $dbserver eq "" ) {
		return 1;
	} elsif ( $databasedb eq "" ) {
		return 1;
	} elsif ( $databasead eq "" ) {
		return 1;
	} elsif ( $username eq "" ) {
		return 1;
	} elsif ( $password eq "" ) {
		return 1;
	} elsif ( $taskid <= 0 ) {
		return 1;
	}
	return 0;
}

#************************************************
#	功能：	
#		在Load目录里检查是否有其他Load运行，没有则创建运行标志
#	输入：
#		1. 入库的目录的路径
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub check_loaddir() {
	my $sub_loaddir = shift;
	#判断目录的存在
	if ( ! -e $sub_loaddir ) {
		my $logmess = "(Error:13016) Can not exists the Load direction $sub_loaddir !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	#检查目录是否有运行标志文件，没有则表示没有其他Load运行
	if ( -f "$sub_loaddir/$sub_runpid" ) {
		#检查Load是否真正运行
		unless ( open(SUB_RUNPID, "<$sub_loaddir/$sub_runpid" ) ) {
			my $logmess = "(Error:13017) Can not open the runpid file $sub_loaddir/$sub_runpid !";
			&writelog ( \$logmess, 2, 2 );
			return 1;
		}
		my $sub_loadpid = <SUB_RUNPID>;
		#检查当前目录下的LOAD进程是否存在
		my $sub_pst = `ps -ef|grep $0|grep $sub_loadpid|grep -v grep`;
		if ( $sub_pst ) {
			my $logmess = "(Message:13018) Load Message: $sub_pst ";
			&writelog ( \$logmess, 3, 2 );
			return 1;
		} else {
			my $logmess = "(Message:13019) The $sub_loadpid Load is not running ";
			&writelog ( \$logmess, 3, 2 );
		}
		close (SUB_RUNPID);
	}
	#将当前进程ID写入运行标志文件
	unless ( open(SUB_RUNPID, ">$sub_loaddir/$sub_runpid" ) ) {
		my $logmess = "(Error:13020) Can not create the runpid file $sub_loaddir/$sub_runpid !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	print SUB_RUNPID "$pid" ;
	close (SUB_RUNPID);
	return 0;
}

#************************************************
#	功能：
#		加载LOADMAP，同时检查LOADMAP中字段的合法性
#	输入：
#		1. 要存入LOADMAP的哈希数组的引用
#		2. 入库的设备厂商编号
#	输出：
#		1. LOADMAP信息
#	返回值：
#		0 正常
#************************************************
sub upload_loadmap {
	my $sub_loadmap = shift;
	my $sub_loadflag = shift;
	my $sub_ruleset = shift;
	#从管理库里读取对应的数据库表是:loadmap
	#原理是读取字段 ruleset = $$sub_ruleset 中的数据。
	my $logmess = "(Message:13022) ---Start load loadmap----";
	&writelog ( \$logmess, 2, 1 );	
	my $sql_get_loadmap = "select tabname,colname,block,expression,default_val,validity,primkey,nemess,sendinfo from cloadmap where ruleset = $sub_ruleset";
	my $sth_get_loadmap = $dbh->prepare($sql_get_loadmap)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if ( $r ) {
		my $logmess = "(Error:13021) Error in prepare loadmap SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13022) The SQL: $sql_get_loadmap !";
		&writelog ( \$logmess, 2, 1 );
		return 1;
	}
	$sth_get_loadmap->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if ( $r ) {
		my $logmess = "(Error:13023) Error in execute loadmap SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13024) The SQL: $sql_get_loadmap !";
		&writelog ( \$logmess, 2, 1 );
		return 1;
	}
	#loadmap的信息全部在$data中
	my $data=$sth_get_loadmap->fetchall_arrayref;
	#得到目前所用到的表
	my %sub_loadmap_tab;
	my $i = 0;
	while ( exists($data->[$i]) ) {
		$sub_loadmap_tab{ lc($data->[$i]->[0]) } = 1;
		$i++;
	}
	#得到目前所用到表的字段信息
	my %sub_table_colm;
	foreach my $sub_table_name ( keys %sub_loadmap_tab ) {
		my $sql_get_target_columns="select lower(column_name) from information_schema.columns  where lower(table_name)='" . lc($sub_table_name) . "'";
		my $sth_get_target_columns = $dbh->prepare($sql_get_target_columns)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
		if($r) {
			my $logmess = "(Error:13025) Error in prepare table message SQL, DB Message:$str !";
			&writelog ( \$logmess, 2, 2 );
			my $logmess = "(Message:13026) The SQL: $sql_get_target_columns !";
			&writelog ( \$logmess, 2, 1 );
			return 1;
		}
		$sth_get_target_columns->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
		if($r) {
			my $logmess = "(Error:13027) Error in execute table message SQL, DB Message:$str !";
			&writelog ( \$logmess, 2, 2 );
			my $logmess = "(Message:13028) The SQL: $sql_get_target_columns !";
			&writelog ( \$logmess, 2, 1 );
			return 1;
		}
		my $sub_colm ;
		while( $sub_colm = $sth_get_target_columns->fetchrow_array() ) {
			$sub_table_colm{lc($sub_table_name)}{lc($sub_colm)}=1 if ( $sub_colm ne "" ) ;
		}
	}
	#加载Loadmap同时判断用的表和字段的是否有效
	my $i = 0;
	while ( exists($data->[$i]) ) {
		$data->[$i]->[3] =~ s/^ +//g;
		$data->[$i]->[3] =~ s/ +$//g;
		$data->[$i]->[5] =~ s/^ +//g;
		$data->[$i]->[5] =~ s/ +$//g;

		#将表和字段转换为小写
		$data->[$i]->[0] = lc($data->[$i]->[0]);
		$data->[$i]->[1] = lc($data->[$i]->[1]);
		#判断用的表和字段的是否有效
		if ( ! exists($sub_table_colm{$data->[$i]->[0]}{$data->[$i]->[1]}) ) {
			my $logmess = "(Error:13029) Error in load Loadmap, the $data->[$i]->[1] of $data->[$i]->[0] is not exist !";
			&writelog ( \$logmess, 2, 2 );
			return 1;
		}
		#存储的格式是：$sub_loadmap->{块名}->{表名}->{字段}->{规则标致} = 规则信息
		$sub_loadmap->{$data->[$i]->[2]}->{$data->[$i]->[0]}->{$data->[$i]->[1]} =
			{
				EXPRESSION=>$data->[$i]->[3],
				DEFAULT_VAL=>$data->[$i]->[4],
				VALIDITY=>$data->[$i]->[5],
				PRIMKEY=>$data->[$i]->[6],
				NEMESS=>$data->[$i]->[7],
				SENDINFO=>$data->[$i]->[8]
			};
		#查找发送网元信息的字段
		#$sub_loadflag存储要发送的网元标志信息
		#存储的格式是：$sub_loadflag->{块名}->{表名}->{标志信息} = 对应字段
		#网元字段
		if ( $data->[$i]->[7] == 1 ) {
			$sub_loadflag->{$data->[$i]->[2]}->{$data->[$i]->[0]}->{ "NEID" } = $data->[$i]->[1];
		}
		#开始时间字段
		if ( $data->[$i]->[7] == 2 ) {
			$sub_loadflag->{$data->[$i]->[2]}->{$data->[$i]->[0]}->{ "STARTTIME" } = $data->[$i]->[1];
		}
		#结束时间字段
		if ( $data->[$i]->[7] == 3 ) {
			$sub_loadflag->{$data->[$i]->[2]}->{$data->[$i]->[0]}->{ "ENDTIME" } = $data->[$i]->[1];
		}
		$i++;
	}
	my $logmess = "(Message:13022) ---complete load loadmap----";
	&writelog ( \$logmess, 2, 1 );	
	
	return 0;
}

#************************************************
#	功能：	
#		根据网元关系加载网元数据，读取表hierinfo中字段
#		ruleset = $$sub_ruleset 或者是 0 的数据。
#	输入：
#		1. 要存入网元对应关系的哈希数组引用
#		2. 字典表信息
#		3. 入库的设备厂商编号
#	输出：
#		1. 网元对应关系
#		2. 字典表信息
#	返回值：
#		0 正常
#************************************************
sub upload_hierinfo {
	my $sub_hierinfo = shift;
	my $sub_hiertab = shift;
	my $sub_ruleset = shift;
	my $logmess = "(Message:13022) ---start load hierinfo----";
	&writelog ( \$logmess, 2, 1 );		
	##从管理库里读取要加载的规则数据
	my $sql_get_hierinfo = "select expression, tabname, sourcene, targetne from chierinfo where ruleset = $sub_ruleset or ruleset = 0";
	my $sth_get_hierinfo = $dbh->prepare($sql_get_hierinfo)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if($r) {
		my $logmess = "(Error:13030) Error in prepare hierinfo SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13031) The SQL: $sql_get_hierinfo !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	$sth_get_hierinfo->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if($r) {
		my $logmess = "(Error:13032) Error in execute hierinfo SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13033) The SQL: $sql_get_hierinfo !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	my $hierinfo_data=$sth_get_hierinfo->fetchall_arrayref;
	my $i = 0;
	while ( exists($hierinfo_data->[$i]) ) {
		#网元对应关系与字典表的对应关系
		$sub_hiertab->{$hierinfo_data->[$i]->[0]}->{'TABNAME'} = $hierinfo_data->[$i]->[1];
		$sub_hiertab->{$hierinfo_data->[$i]->[0]}->{'SOURCENE'} = $hierinfo_data->[$i]->[2];
		$sub_hiertab->{$hierinfo_data->[$i]->[0]}->{'TARGETNE'} = $hierinfo_data->[$i]->[3];
		##从数据库里读取要加载的网元对应关系数据
		my $sql_get_hierinfo = "select $hierinfo_data->[$i]->[2], $hierinfo_data->[$i]->[3] from $hierinfo_data->[$i]->[1]";
		
		my $sth_get_hierinfo = $adh->prepare($sql_get_hierinfo)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
		if($r) {
			my $logmess = "(Error:13034) Error in prepare load ne message SQL, DB Message:$str !";
			&writelog ( \$logmess, 2, 2 );
			my $logmess = "(Message:13035) The SQL: $sql_get_hierinfo !";
			&writelog ( \$logmess, 2, 2 );
			return 1;
		}
		$sth_get_hierinfo->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
		if($r) {
			my $logmess = "(Error:13036) Error in execute load ne message SQL, DB Message:$str !";
			&writelog ( \$logmess, 2, 2 );
			my $logmess = "(Message:13037) The SQL: $sql_get_hierinfo !";
			&writelog ( \$logmess, 2, 2 );
			return 1;
		}
		my $nemap_data=$sth_get_hierinfo->fetchall_arrayref;
		my $j = 0;
		#防止在字典表里没有数据时，
		#无法判断该网元对应规则是没有数据还是规则没有定义，
		#因此在这里先给这规则赋一个空值。
	#	$sub_hierinfo->{$hierinfo_data->[$i]->[0]}->{""} = "";#	print Dumper (\%alarmmess);
		#循环加载网元对应关系数据
    my $varid;
    my $varname;
		while ( exists($nemap_data->[$j]) ) {
	    $varid=trimSpace($nemap_data->[$j]->[0]);
	    $varname=trimSpace($nemap_data->[$j]->[1]);
	    
		  $sub_hierinfo->{$hierinfo_data->[$i]->[0]}->{$varid} = $varname;
			
			$j++;
		}
		$i++;
	}
	my $logmess = "(Message:13022) ---end load hierinfo----";
	&writelog ( \$logmess, 2, 1 );		
	return 0;
}

#************************************************
#	功能：	
#		创建Socket连接
#	输入：
#		
#	输出：
#		1. 生成Socket连接的套接字，全局变量
#	返回值：
#		0 正常
#************************************************
sub connect_server () {
	#创建要发送PM信息的连接
	$outsocket=IO::Socket::INET->new( PeerAddr=>$hostip,
				PeerPort=>$mess_outport,
				Timeout=>$timeout,
				) if ( $outsocket <= 0 && $pmmess );
	if ( $outsocket<=0 && $pmmess ) {
		my $logmess = "(Error:13038) Error in connect server($hostip:$mess_outport) and can not send Load message !";
		&writelog ( \$logmess, 1, 2 );
		&writelog ( \$logmess, 1, 1 );
	}
	#创建要发送告警信息的连接
	$alarmsocket=IO::Socket::INET->new( PeerAddr=>$hostip,
				PeerPort=>$alarm_outport,
				Timeout=>$timeout,
				) if ( $alarmsocket <= 0 && $pmalarm );
	if ( $alarmsocket<=0 && $pmalarm ) {
		my $logmess = "(Error:13103) Error in connect server($hostip:$alarm_outport) and can not send PM alarm message !";
		&writelog ( \$logmess, 1, 2 );
		&writelog ( \$logmess, 1, 1 );
	}
	return 0;
}

#************************************************
#	功能：	
#		文件入库，同时发送相关数据信息
#	输入：
#		1. 入库的文件名
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub load_file2db {
	#数据数据文件名
	my $input_datafile = shift ;
	#文件的头信息
	my %headmess;
	#BLOCK 的名称
	my $blockname;
	#BLOCK的信息
	my %blockmess;
	#网元入库信息
	my %loadnemess;

	#开始分析文件
	unless ( open(INPUT_DATAFILE,"<$input_datafile") ) {
		my $logmess = "(Error:13039) Can not open the data file $input_datafile !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	#读取文件头部分
	%headmess = ();
	$blockname = "";
	$ret = &read_datahead( \%headmess, \$blockname );
	if( $ret ) {
		my $logmess = "(Error:13040) Error in read the head of data file $input_datafile !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	#读取BLOCKNAME
	while ( $blockname ne "" ) {
		#判断是否有表使用
		my $i=0;
		#根据当前的blockname找对应的tablename
		foreach my $tablename ( keys %{$loadmap{$blockname}} ) {
			if ( $i==0 ) {
				#第一次的时候加载BLOCK的字段信息，依次读取BLOCK的内容
				%blockmess = ();
				$ret = &read_blockmess( \%blockmess );
				if( $ret ) {
					my $logmess = "(Error:13041) Error in read the $blockname message of file $input_datafile and the data will be ignored !";
					&writelog ( \$logmess, 2, 2 );
					#退出 foreach my $tablename 循环，继续处理下一个BLOCK
					last;
				}
				#将头信息复制到BLCOK里面
				@blockmess{keys( %headmess )} = values( %headmess );
				$i++;
			}
			#
			#表数据信息
			my %col_data=();
			#采用数组方式的存放，解决字符串内容增加的时间消耗
			#性能数据的信息头
			my $pmdata_mess_head;
			#性能数据的信息体
			my @pmdata_mess_body;
			#
			#SQL语句部分的变量
			#SQL语句的字段信息
			my $sql_cols;
			#SQL语句的值信息
			my $sql_value;
			#update SQL语句的where 条件
			my $sql_where;
			#用来输出数据的标致变量
			my $n = 0;
			my $m = 0;
			my $sub_flag="";

			#向表中写入数据
			#从LOADMAP中获得该表的字段信息引用
			my $tablecol_mess=$loadmap{$blockname}->{$tablename};
			#准备每一个字段的数值，同时准备 PM数据、文件入库信息、SQL语句的部分信息
			foreach my $col_name ( keys %{$tablecol_mess} ) {
				#入库规则表达式
				my $expression = $tablecol_mess->{$col_name}->{'EXPRESSION'};
				#默认值
				my $default_val = $tablecol_mess->{$col_name}->{'DEFAULT_VAL'};
				#入库的条件判断
				my $validity = $tablecol_mess->{$col_name}->{'VALIDITY'};
				#该字段是否是主键
				my $primkey = $tablecol_mess->{$col_name}->{'PRIMKEY'};
				#该字段是否发送
				my $sendinfo = $tablecol_mess->{$col_name}->{'SENDINFO'};
				#准备数据，同时将计算好3的数据返回给$expression
				$ret = &expression_prepare( \$expression, \%blockmess, \%hierinfo );
				if( $ret ) {
					my $logmess = "(Error:13042) Error in prepare the $col_name value of table $tablename from the block $blockname of the file $input_datafile !";
					&writelog ( \$logmess, 2, 2 );
				}
				#如果函数运算的结果为空，则取默认值
			
				if ( $expression eq  "") {
				 	$expression = $default_val;
				}
				#如果入库的条件判断不为空的时候需要判断是否满足条件表达式
				if ( $validity ne "" ) {
					# $v 用户用来表示结果数据的标准变量
					$validity =~ s/\$v/\"$expression\"/g;
					if ( ! eval($validity) ) {
						#字段为空，不向数据库中写入该字段的数据
						my $logmess = "(Message:13043) The $col_name of $tablename value is $expression and is not validity in the $validity, the data will be ignored !";
						&writelog ( \$logmess, 3, 1 );
						#该行数据直接跳过，不向数据库中写入
						goto rtab;
					}
				}
				#保存计算的返回值
				$col_data{ $col_name }= $expression;
				#
				#如果返回的数据不是空值的时候，才进行入库、发送性能数据等操作
				if ( $expression ne "" ) {
					#如果是主键字段为空的话，则丢掉该条记录
					if ( $n > 0 ) {
						$sub_flag = "," ;
					}
					#得到SQL语句的字段信息
					$sql_cols = $sql_cols . "$sub_flag $col_name ";
					#得到SQL语句的数值信息
					$sql_value = $sql_value . "$sub_flag '$expression' ";
					if ( $primkey ) {
						#根据主键，得到SQL语句的WHERE条件
						if ( $m > 0 ) {
							$sql_where = $sql_where . " and $col_name = '$expression' ";
						} else {
							$sql_where = $sql_where . " $col_name = '$expression' ";
						}
						$m++;
					}
					if ( $sendinfo ) {
						#准备发送的性能数据信息
						push @pmdata_mess_body, "<DataItem><Name>$col_name</Name><Value>$expression</Value></DataItem>\n";
					}
					$n++;
				} elsif ( $primkey ) {
					#主键字段为空，该行数据直接跳过，不向数据库中写入
					my $logmess = "(Error:13044) The $col_name of $tablename is primkey and value is null, the data will be ignored !";
					&writelog ( \$logmess, 2, 2 );
					goto rtab;
				} else {
					#字段为空，不向数据库中写入该字段的数据
					my $logmess = "(Message:13045) The $col_name value of $tablename in block $blockname file $input_datafile is null !";
					&writelog ( \$logmess, 3, 2 );
				}
			}

			#将要发送的数据组织成XML消息发送
			if ( $pmmess ) {
				$pmdata_mess_head="<MsgID>1</MsgID><Ruleset>$ruleset</Ruleset><Filename>$input_datafile</Filename><Block>$blockname</Block><Table>$tablename</Table>";
				$ret = &send_pmdata( \$pmdata_mess_head, \@pmdata_mess_body );
				if( $ret ) {
					my $logmess = "(Error:13046) Error in send pmdata of $tablename !";
					&writelog ( \$logmess, 2, 2 );
				}
			}
			#生成insert SQL进行数据插入，如果失败进行Update
			$ret = &insert_pmdata( \$sql_cols, \$sql_value, \$sql_where, $tablename, $dbh );
			if( $ret ) {
				my $logmess = "(Error:13047) Error in insert pmdata of $tablename Error !\n";
				&writelog ( \$logmess, 1, 2 );
			} elsif ( $nemess ) {
				#监测网元的入库情况，必须是数据正确的插入输入数据库之后，才能准备网元的入库信息
				#网元的值
				my $sub_neid = $loadflag{$blockname}->{$tablename}->{"NEID"};
				#开始时间的值
				my $sub_starttime = $loadflag{$blockname}->{$tablename}->{"STARTTIME"};
				#结束时间的值
				my $sub_endtime = $loadflag{$blockname}->{$tablename}->{"ENDTIME"};
				#累加每次的记录数
				#如果关于该表没有配置发送信息条件，则$loadnemess的内容为空，也就不会有信息插入到入库信息表中
				if ( $sub_neid ne "" && $sub_starttime ne "" && $sub_endtime ne "" ) {
					$loadnemess{$blockname}->{$tablename}->{$col_data{$sub_neid}}->{$col_data{$sub_starttime}}->{$col_data{$sub_endtime}}++;
				}
			}
			#
			#判断并发送性能告警，使用表的字段部分
			if ( $pmalarm ) {
				$ret = &generation_pmalarm( \%col_data, $blockname, $tablename );
				if( $ret ) {
					my $logmess = "(Error:13122) Error in generation PM ALARM !\n";
					&writelog ( \$logmess, 1, 2 );
				}
			}
rtab:	}
		#发送该BLOCK的数据信息
		if ( $datamess ) {
			my $loaddata_mess_head = "<MsgID>2</MsgID><Ruleset>$ruleset</Ruleset><Filename>$input_datafile</Filename><Block>$blockname</Block><Table></Table>";
			$ret = &send_blockdata( \$loaddata_mess_head, \%blockmess );
			if( $ret ) {
				my $logmess = "(Error:13048) Error in send data of block $blockname !";
				&writelog ( \$logmess, 2, 2 );
			}
		}
		#判断并发送性能告警，使用BLOCK字段部分
		if ( $pmalarm ) {
			$ret = &generation_pmalarm( \%blockmess, $blockname, "" );
			if( $ret ) {
				my $logmess = "(Error:13123) Error in generation PM ALARM !\n";
				&writelog ( \$logmess, 1, 2 );
			}
		}
		#读取下一个BLOCK名称
		$blockname = "";
		&read_blockname( \$blockname );
	}

	#发送该文件数据入库消息
	if ( $filemess ) {
		#性能处理情况的信息头
		my $loadfile_mess_head = "<MsgID>3</MsgID><Ruleset>$ruleset</Ruleset><Filename>$input_datafile</Filename><Block></Block><Table></Table>";
		#性能处理情况的信息体
		my $loadfile_mess_body;
		$ret = &send_filemess( \$loadfile_mess_head, \$loadfile_mess_body );
		if( $ret ) {
			my $logmess = "(Error:13049) Error in send load $input_datafile message !";
			&writelog ( \$logmess, 2, 2 );
		}
	}
	#监测网元的入库情况，将网元的入库信息插入数据库
	if ( $nemess ) {
		foreach my $blockname ( keys %loadnemess ) {
			foreach my $tablename ( keys %{$loadnemess{$blockname}} ) {
				foreach my $neid ( keys %{$loadnemess{$blockname}->{$tablename}} ) {
					foreach my $starttime ( keys %{$loadnemess{$blockname}->{$tablename}->{$neid}} ) {
						foreach my $endtime ( keys %{$loadnemess{$blockname}->{$tablename}->{$neid}->{$starttime}} ) {
							my $nums = $loadnemess{$blockname}->{$tablename}->{$neid}->{$starttime}->{$endtime};
							my $nowtime = Time::HiRes::time+14*3600; #毫秒级数字格式的时间，主要是为了作为唯一主键使用，不知道为什么和实际差14小时
							#准备SQL语句信息
							my $sql_cols = "neid, blockname, tablename, starttime, endtime, inserttime, filename, nums, state";
							my $sql_value = "'$neid', '$blockname', '$tablename', '$starttime', '$endtime', '$nowtime', '$input_datafile', '$nums', '0'";
							my $sql_where = "neid='$neid' and blockname='$blockname' and tablename='$tablename' and starttime='$starttime' and endtime='$endtime'";
							my $tablename = "load_message";
							$ret = &insert_pmdata( \$sql_cols, \$sql_value, \$sql_where, $tablename, $adh );
							if( $ret ) {
								my $logmess = "(Error:13047) Error in insert load message of file $input_datafile !\n";
								&writelog ( \$logmess, 1, 2 );
							}
						}
					}
				}
			}
		}
	}
	#
	close (INPUT_DATAFILE);
	return 0;
}

#************************************************
#	功能：	
#		读取输入的标准格式数据文件的头信息和Blockname
#	输入：
#		1. 要存放文件头信息的哈希数组引用
#		2. 要存放文件BLOCKNAME的变量引用
#	输出：
#		1. 文件头信息
#		2. BLOCKNAME
#	返回值：
#		0 正常
#************************************************
sub read_datahead() {
	#
	my $sub_headmess = shift;
	my $sub_blockname = shift;
	#
	while(<INPUT_DATAFILE>) {
		#过虑掉头信息
		next if (/^#/ || /^\s*\{/);

		#找到BLOCKNAME退出
		#BLOCK 开始的情况必须是 "XXXXXX {"
		if (/^\s*(\w+)\s+\{/) {
			$$sub_blockname=$1;
			return 0;
		} elsif ( /^\s*\}/ ) {
			#该文件可能是空文件，不需要处理
			return 0;
		}
		#匹配数据项信息
		#需要增加特殊情况判断?????????????????????
		$_ =~ /^\s*(\w+)\s+(.*)\n$/;
		my $sub_blockvalue = $2;
		$sub_blockvalue =~ s/^"//;
		$sub_blockvalue =~ s/"$//;
		$sub_headmess->{$1}=$sub_blockvalue;
	}
	#该文件可能是空文件，不需要处理
	return 0;
}

#************************************************
#	功能：	
#		读取输入的标准格式数据文件的BOLCK信息
#	输入：
#		1. 要存放文件BLCOK信息的哈希数组引用
#	输出：
#		1. 文件BLCOK信息
#	返回值：
#		0 正常
#************************************************
sub read_blockmess() {
	#
	my $sub_blockmess = shift;

	while(<INPUT_DATAFILE>) {
		#过虑掉头信息
		next if (/^#/ || /^\s*\{/);

		#找到BLOCKNAME退出
		#BLOCK 开始的情况必须是 "}"
		if ( /^\s*\}$/ ) {
			return 0;
		}
		#匹配数据项信息
		#需要增加特殊情况判断?????????????????????
		$_ =~ /^\s*(\w+)\s+(.*)\n$/;
		my $sub_blockvalue = $2;
		$sub_blockvalue =~ s/^"//;
		$sub_blockvalue =~ s/"$//;
		$sub_blockmess->{$1}=$sub_blockvalue;
	}
	return 0;
}

#************************************************
#	功能：	
#		读取输入的标准格式数据文件的BLOCKNAME
#	输入：
#		1. 要存放文件BLOCKNAME的变量引用
#	输出：
#		1. BLOCKNAME
#	返回值：
#		0 正常
#************************************************
sub read_blockname() {
	my $sub_blockname = shift;
	$$sub_blockname = "";
	while(<INPUT_DATAFILE>) {
		#找到BLOCKNAME退出
		#BLOCK 开始的情况必须是 "XXXXXX {"
		#需要增加特殊情况判断?????????????????????
		if (/^\s*(\w+)\s+\{/) {
			$$sub_blockname=$1;
			return 0;
		}
		next;
	}
	return 0;
}

#************************************************
#	功能：	
#		表达式的数据计算
#	输入：
#		1. 要计算的表达式的引用
#		2. Block信息
#		3. 字典表信息的引用
#	输出：
#		1. 表达式的计算结果
#	返回值：
#		0 正常
#	功能描述：
#		1. 表达式解析，所支持的特殊字符是：“+-*/,()&%{}$.”
#		2. 特殊计算可以通过函数的表示方法实现
#		3. Lookup使用，网元对应的所属关系，同时更新字典表信息
#		4、默认值处理
#		5、分母是零值或者是空值的处理，目前是通过函数来实现
#		6、字符或者数字常量的处理
#	注意事项：
#		1. 字符常量里面不能包含有 “+-*/,()&%{}$.” 字符
#			如果需要是用，通过定义函数来实现
#		2. 数字不能是小数，如果是小数可以使用除法运算来代替
#		3. 注意分母不能为零，本程序没有判断
#			在使用需确认分母不能为0，或者通过调用函数division判断
#		4. 表达的书写一定要符合运算规则，否则计算出错
#			该项数据结果为0，并且会增加	LOAD内存使用的开销
#		5. 不能够直接使用Perl自带的函数，只能够使用在Function.pm里
#			定义的函数，否则出错
#************************************************
sub expression_prepare () {
	my $sub_expression = shift;
	my $sub_blockmess = shift;
	my $sub_hierinfo = shift;

	#保存最后结果
	my $sub_value ;
	my $sub_tmpstr ;
	#
	$$sub_expression =~ s/^ +//g;
	$$sub_expression =~ s/ +$//g;
	#字符串的长度
	my $sub_strlong = length($$sub_expression);
	if ( $sub_strlong == 0 ) {
		$$sub_expression = "";
		return 0;
	}
	my $i;
	#临时保存哈希数组，用来检查哈希数组的数据
	my @sub_nehier;
	#
	my $sub_flag = 0;
	#判断是否是数字的表达式
	#原理式判断是否含有 +-*/ 这些运算符
	if ( $$sub_expression =~ /\+|\-|\*|\// ) {
		$sub_flag = 1;
	}
	for ( $i=0; $i<$sub_strlong; $i++ ) {
		my $sub_char = substr($$sub_expression, $i, 1);
		if ( $sub_char =~ /\+|\-|\*|\/|\(|\)|\.|\,|\{|\}|\>|\<|\=/ || $i==($sub_strlong-1) ) {
			#最终表达式存储
			if ( ( ! ($sub_char =~ /\+|\-|\*|\/|\(|\)|\.|\,|\{|\}|\>|\<|\=/) ) && $i==($sub_strlong-1) ) {
				$sub_tmpstr = $sub_tmpstr . $sub_char;
				$sub_char = "";
			}
			#去掉前后空格
			$sub_tmpstr =~ s/^ +//;
			$sub_tmpstr =~ s/ +$//;

			#函数的情况
			if ( $sub_tmpstr =~ /\&(.+)/ ) {
				#判断表达式是否正确
				if ( $sub_char ne "(" ) {
					my $logmess = "(Error:13050) Function in $$sub_expression is error, please check the expression !";
					&writelog ( \$logmess, 2, 2 );
					return 1;
				}
			}
			#哈希数组情况
			elsif ( $sub_tmpstr =~ /\%(.+)/ ) {
				#判断表达式是否正确
				if ( $sub_char ne "{" ) {
					my $logmess = "(Error:13051) Hash in $$sub_expression is error, please check the expression !";
					&writelog ( \$logmess, 2, 2 );
					return 1;
				}
				#本处只处理哈希数组的转换和网元对应关系
				#得到关系ID
				$sub_tmpstr = substr($sub_tmpstr,1);
				#判断是否有该种类型的网元对应关系
				if ( ! exists($sub_hierinfo->{$sub_tmpstr}) ) {
					my $logmess = "(Error:13052) The rule $sub_tmpstr is not exist !";
					&writelog ( \$logmess, 2, 2 );
					&writelog ( \$logmess, 2, 1 );
					#网元对应关系不存在，丢掉数据
					$$sub_expression = "";
					return 0;
				} else {
					#将该网元对应关系放入数组，通过判断是否有数值，来发现是否有新的网元
					push @sub_nehier,$sub_tmpstr;
					#最终的解释信息
					$sub_tmpstr = "\$sub_hierinfo\-\>\{\"$sub_tmpstr\"\}\-\>";
				}
			}
			#?????????????????该处需要增加判断,目前哈希数组嵌套的情况，不判断网元的关系的有效性
			#网元对应关系哈希数组读取结束标识符
			#通过判断是否有数值，来发现是否有新的网元
			elsif ( $sub_char eq "}" ) {
				#检查是否是新增的网元
				my $sub_arraynum = @sub_nehier;

				#属于哈希数组嵌套的情况，目前不判断网元的关系的有效性
				if ( $sub_tmpstr ne "" ) {
					#得到网元名称
					$sub_tmpstr = $sub_blockmess->{$sub_tmpstr};
					if ( ! exists($sub_hierinfo->{$sub_nehier[$sub_arraynum-1]}->{$sub_tmpstr} ) ) {
						#改网元信息可能是新增的
						my $logmess = "(Message:13053) Maybe $sub_tmpstr is a New NE in $sub_nehier[$sub_arraynum-1]. Num=$sub_arraynum !";
						&writelog ( \$logmess, 2, 2 );
						&writelog ( \$logmess, 2, 1 );
#该功能基本与Metrica的LOAD更新字典表数据功能相同，但是当网元信息不是要更新表的唯一主键时，会出错！
						#更新字典数据
						#用户可以通过查看对应关系的字典表，来发现是否用新增的网元。
						&update_hierinfo( $sub_nehier[$sub_arraynum-1], $sub_tmpstr );
						$sub_hierinfo->{$sub_nehier[$sub_arraynum-1]}->{$sub_tmpstr}="";
					}
					$sub_tmpstr = "\"" . $sub_tmpstr . "\"";
				}
				delete $sub_nehier[$sub_arraynum-1];
			}
			#数字情况
			elsif ( $sub_tmpstr =~ /^\d+$/ ) {
				$sub_tmpstr = "\"" . $sub_tmpstr . "\"";
			}
			#字符情况
			elsif ( $sub_tmpstr =~ /^\".+\"$/ ) {

			}
			#其他情况
			else {
				#解析得到Counter的数值
				if ( $sub_tmpstr eq "" ) {

				} elsif ( ! exists($sub_blockmess->{$sub_tmpstr}) ) {
					my $logmess = "(Error:13054) The counter $sub_tmpstr is not exist !";
					&writelog ( \$logmess, 3, 2 );
					#当Counter的值为空的时候的判断
					if ( $sub_flag==1 ) {
						#数字的表达式
						if ( $valuetest==1 ) {
							#如果表达式中是数据计算的，有一个Counter为空，则直接整个返回空
							$$sub_expression = "";
							return 0;
						} else {
							$sub_tmpstr = "\"0\"";
						}
					} else {
						#非数字的表达式
						$sub_tmpstr="\"\"";
					}
				} else {
					$sub_tmpstr = "\"" . $sub_blockmess->{$sub_tmpstr} . "\"";
				}
			}
			$sub_value = $sub_value . $sub_tmpstr . $sub_char;
			$sub_tmpstr = "";
		} else {
			$sub_tmpstr = $sub_tmpstr . $sub_char;
		}
	}
	#得到结果数据zhung
					my $logmess = "====$sub_value- !";
					&writelog ( \$logmess, 2, 2 );
	
	my $sub_endvalue = eval ( $sub_value );
	#判断运算的表达式是否正确运算
	if ( $@ ) {
		my $logmess = "(Error:13055) Error:$@ Message:expression=$$sub_expression,value_str=$sub_value,value=$sub_endvalue";
		&writelog ( \$logmess, 2, 2 );
	}
	$$sub_expression = $sub_endvalue;
	return 0;
}

#************************************************
#	功能：	
#		当有新网元时，在字典表添加更改网元信息
#	输入：
#		1. 网元系统关系的哈希数组引用
#		2. 网元名称
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub update_hierinfo() {
	my $sub_hierinfo = shift;
	my $sub_nename = shift;

	my $sub_sql_cols = "$hiertab{$sub_hierinfo}->{'SOURCENE'}";
	my $sub_sql_value = "\'$sub_nename\'";
	my $sub_sql_where = " $hiertab{$sub_hierinfo}->{'SOURCENE'} = \'$sub_nename\' ";

	$ret = &insert_pmdata( \$sub_sql_cols, \$sub_sql_value, \$sub_sql_where, $hiertab{$sub_hierinfo}->{'TABNAME'}, $dbh );
	if( $ret ) {
		my $logmess = "(Error:13056) Error in insert $sub_nename of $hiertab{$sub_hierinfo}->{'TABNAME'} !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13057) Error SQL meassge:[$sub_sql_cols][$sub_sql_value][$sub_sql_where]!";
		&writelog ( \$logmess, 4, 2 );
	}
	return 0;
}

#************************************************
#	功能：	
#		向数据库中写入数据
#	输入：
#		1. SQL的字段名
#		2. SQL的对应字段的数值
#		3. SQL的对应WHERE条件
#		4. SQL的TABLENAME
#		5. 数据库连接的句柄
#	输出：
#		
#	返回值：
#		0 正常
#	功能描述：
#		1. 对数据先执行Insert操作，如果索引重复执行Update
#		2. 在执行Insert和Update表锁时，能够重新执行该操作，
#			但是连续锁一定次数，将导致整个LOAD程序的退出。
#			可以通过修改 sub_lockmax
#			来更改连续锁的最大次数
#		3. Lookup使用，网元对应的所属关系，同时更新字典表信息
#		4、默认值处理
#		5、分母是零值或者是空值的处理，目前是通过函数来实现
#		6、字符或者数字常量的处理
#	注意事项：
#		1. 如果执行过程中比较慢，请尝试作表的update statistics
#************************************************
sub insert_pmdata() {
	my $sub_sql_cols=shift;
	my $sub_sql_value=shift;
	my $sub_sql_where=shift;
	my $sub_tablename=shift;
	my $sub_dbh=shift;
	my (@aCols,@aValues,$sSql,$iCol);
	#表锁次数的判断
	#如果在向表插入或更改数据的时候，表处于 锁 状态的话，则重新该操作。
	#但是连续锁表的次数大于$sub_lockmax，可能数据存在严重错误。
	my $sub_locknum=0;
	my $sub_lockmax=10;

	#组成最终的sql语句，执行
Tryinsert:	my $sql_insert_newobj_to_change = "insert into $sub_tablename (" . $$sub_sql_cols . ") values (" . $$sub_sql_value . ")" ;
	my $sth_insert_newobj_to_change = $sub_dbh->prepare($sql_insert_newobj_to_change)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if($r)
	{
		my $logmess = "(Error:13058) Error in prepare insert data to $sub_tablename, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13059) The SQL: $sql_insert_newobj_to_change !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}

		my $logmess = "(Message:13059) The SQL: $sql_insert_newobj_to_change !";
		&writelog ( \$logmess, 1, 2 );

	$sth_insert_newobj_to_change->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if($r)
	{
		#该数据表中可能已经存在
		if( $r==-268 || $r==-239 || $r==1062 ) {
			my $logmess = "(Message:13060) The data already in DB and will be updated !";
			&writelog ( \$logmess, 4, 2 );
		  @aCols=split(',',$$sub_sql_cols);
			@aValues=split(',',$$sub_sql_value);
			for ($iCol=0;$iCol<=$#aCols;$iCol++) {
				if ($iCol == 0) {
					$sSql=$aCols[$iCol]."=".$aValues[$iCol];
				} else {
					$sSql=$sSql.",".$aCols[$iCol]."=".$aValues[$iCol];
				}
			}
Tryupdate:	my $sql_update_target="update $sub_tablename set ".$sSql." where ".$$sub_sql_where ;
			my $sth_update_target = $sub_dbh->prepare($sql_update_target)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
			if($r) {
				my $logmess = "(Error:13061) Error in prepare update data to $sub_tablename, DB Message:$str !";
				&writelog ( \$logmess, 2, 2 );
				my $logmess = "(Message:13062) The SQL: $sql_update_target !";
				&writelog ( \$logmess, 2, 2 );
				return 1;
			}
			$sth_update_target->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
			if( $r ) {
				#锁表情况
				if( $r==-244 ) {
					$sub_locknum++;
					#update操作时，出现严重锁表情况，程序退出
					if ( $sub_locknum > $sub_lockmax ) {
						my $logmess = "(Error:13063) Critical error in update the $sub_tablename, the table is locked more than $sub_locknum times !";
						&writelog ( \$logmess, 1, 2 );
						&exitload;
					}
					my $logmess = "(Error:13064) Error in update the $sub_tablename, the table is locked, try again !";
					&writelog ( \$logmess, 3, 2 );
					#清除错误号
					$r=0;
					goto Tryupdate;
				} else {
					my $logmess = "(Error:13065) Error in execute update the $sub_tablename, DB Message:$str !";
					&writelog ( \$logmess, 2, 2 );
					my $logmess = "(Message:13066) The SQL: $sql_update_target !";
					&writelog ( \$logmess, 2, 2 );
					return 1;
				}
			} else {
				my $logmess = "(Message:13067) execute the update SQL of $sub_tablename OK !";
				&writelog ( \$logmess, 4, 1 );
			}
		#锁表情况
		} elsif ( $r==-244 ) {
			$sub_locknum++;
			#insert操作时，出现严重锁表情况，程序退出
			if ( $sub_locknum > $sub_lockmax ) {
				my $logmess = "(Error:13068) Critical error in insert the $sub_tablename, the table is locked more than $sub_locknum times !";
				&writelog ( \$logmess, 1, 2 );
				&exitload;
			}
			my $logmess = "(Error:13069) Error in insert the $sub_tablename, the table is locked, try again !";
			&writelog ( \$logmess, 3, 2 );
			$r=0;
			goto Tryinsert;
		} else {
			my $logmess = "(Error:13070) Error in execute insert the $sub_tablename, DB Message:$str !";
			&writelog ( \$logmess, 2, 2 );
			my $logmess = "(Message:13071) The SQL: $sql_insert_newobj_to_change !";
			&writelog ( \$logmess, 2, 2 );
			return 1;
		}
	} else {
		my $logmess = "(Message:13072) execute the insert SQL of $sub_tablename OK !";
		&writelog ( \$logmess, 4, 1 );
	}
	return 0;
}

#************************************************
#	功能：	
#		发送性能数据
#	输入：
#		1. 性能数据的头信息，变量的引用
#		2. 性能数据消息体，数组的引用
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub send_pmdata() {
	my $sub_pmdata_mess_head = shift;
	my $sub_pmdata_mess_body = shift;
	#准备性能数据头信息
	my $sub_pmdata_mess = "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n<Message>\n<Head>\n";
	$sub_pmdata_mess = $sub_pmdata_mess . $$sub_pmdata_mess_head . "\n</Head>\n<Boby>\n". join("", @$sub_pmdata_mess_body) . "</Boby>\n</Message>\n";
	if ( $outsocket > 0 ) {
		if ( ! $outsocket->printf($sub_pmdata_mess) ) {
			my $logmess = "(Error:13073) Error in send PM message, Please check host server !";
			&writelog ( \$logmess, 3, 2 );
			return 1;
		}
	}
	return 0;
}

#************************************************
#	功能：	
#		发送BLOCK的原始数据信息
#	输入：
#		1. 原始数据信息数据的头信息，变量的引用
#		2. 原始数据信息数据消息体，哈希数组的引用
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub send_blockdata() {
	my $sub_loaddata_mess_head = shift;
	my $sub_blockmess = shift;
	#准备原始数据头信息
	my $sub_loaddata_mess = "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n<Message>\n<Head>\n";
	#准备原始数据信息体
	my @sub_loaddata_mess_body;
	my $sub_blockname;
	my $sub_blockvalue;
	while ( ($sub_blockname, $sub_blockvalue) = each( %$sub_blockmess ) ) {
  		push @sub_loaddata_mess_body, "<DataItem><Name>$sub_blockname</Name><Value>$sub_blockvalue</Value></DataItem>\n";
	}
	$sub_loaddata_mess = $sub_loaddata_mess . $$sub_loaddata_mess_head . "\n</Head>\n<Boby>\n". join("", @sub_loaddata_mess_body) . "</Boby>\n</Message>\n";
	if ( $outsocket > 0 ) {
		if ( ! $outsocket->printf($sub_loaddata_mess) ) {
			my $logmess = "(Error:13074) Error in send data message, Please check host server !";
			&writelog ( \$logmess, 3, 2 );
			return 1;
		}
	}
	return 0;
}

#************************************************
#	功能：	
#		发送文件入库情况
#	输入：
#		1. 文件入库情况的头信息，变量的引用
#		2. 文件入库情况消息体，变量的引用
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub send_filemess() {
	my $sub_loadfile_mess_head = shift;
	my $sub_loadfile_mess_body = shift;
	#准备性能文件入库情况头信息
	my $sub_loadfile_mess = "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n<Message>\n<Head>\n";
	$sub_loadfile_mess = $sub_loadfile_mess . $$sub_loadfile_mess_head . "\n</Head>\n<Boby>\n". $$sub_loadfile_mess_body . "</Boby>\n</Message>\n";
	if ( $outsocket > 0 ) {
		if ( ! $outsocket->printf($sub_loadfile_mess) ) {
			my $logmess = "(Error:13075) Error in send Load file message, Please check host server !";
			&writelog ( \$logmess, 3, 2 );
			return 1;
		}
	}
	return 0;
}

#************************************************
#	功能：	
#		加载PM_ALARM的性能告警配置信息
#	输入：
#		1. 要存入PM_ALARM的哈希数组的引用
#		2. 入库的设备厂商编号
#	输出：
#		1. PM_ALARM信息
#	返回值：
#		0 正常
#	注意：
#		1. 表名和文件的块名尽量不能包含"."，否则有规则昏乱的可能
#		2. 规则表达式一定不能有错误，建议测试正确以后再使用
#************************************************
sub upload_pm_alarm {
	my $sub_pm_alarm = shift;
	my $sub_ruleset = shift;
	#从管理库里读取对应的数据库表是:PM_ALARM
	#原理是读取字段 ruleset = $$sub_ruleset 中的数据。
	my $sql_get_pm_alarm = "select alarmname, alarmtext, alarmtype, alarmcause, objclass, objnamedby, alarmtime, blockname, tablename, criticalpred, majorpred, minorpred, warnpred, clearpred, alarmscope, useclearance, reportvalue from pm_alarm where ruleset = $sub_ruleset and alarmenabled='1'";
	my $sth_get_pm_alarm = $adh->prepare($sql_get_pm_alarm)||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if ( $r ) {
		my $logmess = "(Error:13104) Error in prepare load PM alarm Message SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13105) The SQL: $sql_get_pm_alarm !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	$sth_get_pm_alarm->execute||((my $r=$DBI::err)&&(my $str=$DBI::errstr));
	if ( $r ) {
		my $logmess = "(Error:13106) Error in execute load PM alarm Message SQL, DB Message:$str !";
		&writelog ( \$logmess, 2, 2 );
		my $logmess = "(Message:13107) The SQL: $sql_get_pm_alarm !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	#pm_alarm的信息全部在$data中
	my $data=$sth_get_pm_alarm->fetchall_arrayref;
	#加载pm_alarm
	my $i = 0;
	while ( exists($data->[$i]) ) {
		#去掉尾空格
		$data->[$i]->[5] =~ s/ +$//g;
		$data->[$i]->[6] =~ s/ +$//g;
		$data->[$i]->[9] =~ s/ +$//g;
		$data->[$i]->[10] =~ s/ +$//g;
		$data->[$i]->[11] =~ s/ +$//g;
		$data->[$i]->[12] =~ s/ +$//g;
		$data->[$i]->[13] =~ s/ +$//g;
		$data->[$i]->[14] =~ s/ +$//g;
		$data->[$i]->[16] =~ s/ +$//g;
		#此处将需要使用到的块名和表名用“.”进行相连
		$sub_pm_alarm->{ $data->[$i]->[7]. "\." . lc($data->[$i]->[8]) }->{$data->[$i]->[0]} =
			{
				ALARMTEXT=>$data->[$i]->[1],
				ALARMTYPE=>$data->[$i]->[2],
				ALARMCAUSE=>$data->[$i]->[3],
				OBJCLASS=>$data->[$i]->[4],
				OBJNAMEDBY=>$data->[$i]->[5],
				ALARMTIME=>$data->[$i]->[6],
				CRITICALPRED=>$data->[$i]->[9],
				MAJORPRED=>$data->[$i]->[10],
				MINORPRED=>$data->[$i]->[11],
				WARNPRED=>$data->[$i]->[12],
				CLEARPRED=>$data->[$i]->[13],
				ALARMSCOPE=>$data->[$i]->[14],
				USECLEARANCE=>$data->[$i]->[15],
				REPORTVALUE=>$data->[$i]->[16]
			};
		$i++;
	}
	return 0;
}

#************************************************
#	功能：	
#		加载历史性能告警信息
#	输入：
#
#	输出：
#		1. PM_ALARM信息
#	返回值：
#		0 正常
#************************************************
sub upload_alarmmess {
	#********************************************
	#历史告警网元信息保存的时间，目前设置为15天。
	#如果15天内，该网元的数据没有更新，
	#那么在加载告警历史信息的时，将丢掉，
	#清除历史告警网元信息中，退网网元的信息
	#********************************************
	my $sub_keeptime = 3600*24*15;
	my $sub_nowtime = &time2unix(&nowtime());
	#********************************************
	#为了保证alarmid不会无限的增大，同时又不会经常的从头开始计数。
	#因此需要设置一个最大值，而这个最大值必须能够满足10天以上的
	#告警发送的要求。
	#********************************************
	my $sub_maxalarmid = 1000000;
	#打开保存的历史性能告警信息文件
	unless ( open(ALARM_MESS,"<$ENV{\"PMBINDIR\"}/.$taskid") ) {
		my $logmess = "(Error:13108) Can not open the data file $ENV{\"PMBINDIR\"}/.$taskid !";
		&writelog ( \$logmess, 2, 2 );
		return 0;
	}
	
	#读取上次的分配的告警号
	$alarmid = <ALARM_MESS>;
	$alarmid =~ s/\n$//g;
	$alarmid = 0 if ( $alarmid>$sub_maxalarmid ) ;
	
	#装载历史性能告警信息
	while ( <ALARM_MESS> ) {
		$_ =~ s/\n$//g;
		my @sub_messarr = split( /;/, $_ );
		if ( $sub_messarr[4] > $sub_nowtime - $sub_keeptime ) {
			$alarmmess{$sub_messarr[0]}->{$sub_messarr[1]}->{"ALARMSTATE"}=$sub_messarr[2];
			$alarmmess{$sub_messarr[0]}->{$sub_messarr[1]}->{"ALARMID"}=$sub_messarr[3];
			$alarmmess{$sub_messarr[0]}->{$sub_messarr[1]}->{"ALARMTIME"}=$sub_messarr[4];
		} else {
			my $logmess = "(Message:13109) Old PM alarm message:$_ !";
			&writelog ( \$logmess, 4, 2 );
		}
	}
	close (ALARM_MESS);
#	print Dumper (\%alarmmess);
	return 0;
}

#************************************************
#	功能：	
#		写入历史性能告警信息
#	输入：
#
#	输出：
#		1. PM_ALARM信息
#	返回值：
#		0 正常
#************************************************
sub write_alarmmess {
	#打开保存的历史性能告警信息文件
	unless ( open(ALARM_MESS,">$ENV{\"PMBINDIR\"}/.$taskid.pt") ) {
		my $logmess = "(Error:13110) Can not create the data file $ENV{\"PMBINDIR\"}/.$taskid.pt !";
		&writelog ( \$logmess, 2, 2 );
		return 1;
	}
	#写入目前分配的告警号
	print ALARM_MESS "$alarmid\n";
	#装载历史性能告警信息
	foreach my $alarmname ( keys %alarmmess ) {
		foreach my $objnamedby ( keys %{$alarmmess{$alarmname}} ) {
			my $alarmstate = $alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"};
			my $sub_alarmid = $alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"};
			my $alarmunixtime = $alarmmess{$alarmname}->{$objnamedby}->{"ALARMTIME"};
			print ALARM_MESS "$alarmname;$objnamedby;$alarmstate;$sub_alarmid;$alarmunixtime\n";
		}
	}
	close (ALARM_MESS);
	if  ( ! rename ( "$ENV{\"PMBINDIR\"}/.$taskid.pt", "$ENV{\"PMBINDIR\"}/.$taskid" ) ) {
		my $logmess = "(Error:13111) Error in remove $taskid.pt to $taskid !";
		&writelog ( \$logmess, 1, 2 );
	}
	return 0;
}

#************************************************
#	功能：	
#		生成并发送性能告警
#	输入：
#		1. 进行替换计算的数组
#		2. BLOCKNAME
#		3. TABLENAME
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub generation_pmalarm {
	my $sub_col_data = shift;
	my $sub_blockname = shift;
	my $sub_tablename = shift;
	#保存找到要使用的告警生成规则
	my %use_pmalarm;
	#生成告警的级别状态
	my $alarmstate=0;
	#告警名称
	my $alarmname;
	#寻找使用该表数据发送告警的告警门限信息
	if ( $sub_tablename ) {
		foreach $alarmname ( keys %{$pm_alarm{"\.$sub_tablename"}} ) {
			$use_pmalarm{ $alarmname } = $pm_alarm{ "\.$sub_tablename" }->{$alarmname};
		}
		if ( $sub_blockname ) {
			foreach $alarmname ( keys %{$pm_alarm{"$sub_blockname\.$sub_tablename"}} ) {
				$use_pmalarm{ $alarmname } = $pm_alarm{ "$sub_blockname\.$sub_tablename" }->{$alarmname};
			}
		}
	#寻找使用该BLOCK数据发送告警的告警门限信息
	} elsif ( $sub_blockname ) {
		foreach $alarmname ( keys %{$pm_alarm{"$sub_blockname\."}} ) {
			$use_pmalarm{ $alarmname } = $pm_alarm{ "$sub_blockname\." }->{$alarmname};
		}
	}
	#
	#分析生成告警
	#依次计算告警门限
	foreach $alarmname ( keys %use_pmalarm ) {
		#数据有效性判断
		my $alarmscope = $use_pmalarm{$alarmname}->{"ALARMSCOPE"};
		if ( $alarmscope ) {
			$ret = &expression_prepare( \$alarmscope, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13112) Error in analyse validity of PM alarm data, expression: $alarmscope";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $alarmscope != 1 ) {
				#不满足数据条件
				next;
			}
		}
		#计算告警对象
		my $objnamedby=$use_pmalarm{$alarmname}->{"OBJNAMEDBY"};
		if ( $objnamedby ) {
			$ret = &expression_prepare( \$objnamedby, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				#告警的网元对象没有找到
				my $logmess = "(Error:13113) Error in account object name of PM alarm, expression: $objnamedby";
				&writelog ( \$logmess, 2, 2 );
				next;
			}
		}
		#计算告警时间
		my $alarmtime=$use_pmalarm{$alarmname}->{"ALARMTIME"};
		if ( $alarmtime ) {
			$ret = &expression_prepare( \$alarmtime, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				#告警的网元对象没有找到
				my $logmess = "(Error:13114) Error in account alarm time, expression: $alarmtime";
				&writelog ( \$logmess, 2, 2 );
				next;
			}
		}
		#判断是否是老数据，针对性能门限告警只发送比当前存储告警时间大的告警。
		my $alarmunixtime=time2unix( $alarmtime );
		if ( $alarmunixtime<=$alarmmess{$alarmname}->{$objnamedby}->{"ALARMTIME"} ) {
			next;
		}
		#计算告警的属性值
		my $reportvalue=$use_pmalarm{$alarmname}->{"REPORTVALUE"};
		if ( $reportvalue ) {
			$ret = &expression_prepare( \$reportvalue, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				#告警的网元对象没有找到
				my $logmess = "(Error:13115) Error in account alarm value, expression: $reportvalue";
				&writelog ( \$logmess, 2, 2 );
				next;
			}
		}
		
		my $logmess = "(Message:13122) Alarm name:$alarmname, Object name:$objnamedby, Alarm time:$alarmtime, Value:$reportvalue";
		&writelog ( \$logmess, 4, 1 );
		
		#门限信息
		my $thresholdmess="";
		#依次计算能够达到的告警级别
		#CRITICALPRED
		my $sub_expression = $use_pmalarm{$alarmname}->{"CRITICALPRED"};
		if ( $sub_expression ) {
			$ret = &expression_prepare( \$sub_expression, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13116) Error in account alarm level in CRITICALPRED, expression: $sub_expression";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $sub_expression == 1 ) {
				$alarmstate = 4;
				$thresholdmess = $use_pmalarm{$alarmname}->{"CRITICALPRED"};
				goto reparealarm;
			}
		}
		#MAJORPRED
		my $sub_expression = $use_pmalarm{$alarmname}->{"MAJORPRED"};
		if ( $sub_expression ) {
			$ret = &expression_prepare( \$sub_expression, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13117) Error in account alarm level in MAJORPRED, expression: $sub_expression";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $sub_expression == 1 ) {
				$alarmstate = 3;
				$thresholdmess = $use_pmalarm{$alarmname}->{"MAJORPRED"};
				goto reparealarm;
			}
		}
		#MINORPRED
		my $sub_expression = $use_pmalarm{$alarmname}->{"MINORPRED"};
		if ( $sub_expression ) {
			$ret = &expression_prepare( \$sub_expression, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13118) Error in account alarm level in MINORPRED, expression: $sub_expression";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $sub_expression == 1 ) {
				$alarmstate = 2;
				$thresholdmess = $use_pmalarm{$alarmname}->{"MINORPRED"};
				goto reparealarm;
			}
		}
		#WARNPRED
		my $sub_expression = $use_pmalarm{$alarmname}->{"WARNPRED"};
		if ( $sub_expression ) {
			$ret = &expression_prepare( \$sub_expression, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13119) Error in account alarm level in WARNPRED, expression: $sub_expression";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $sub_expression == 1 ) {
				$alarmstate = 1;
				$thresholdmess = $use_pmalarm{$alarmname}->{"WARNPRED"};
				goto reparealarm;
			}
		}
		#CLEARPRED
		my $sub_expression = $use_pmalarm{$alarmname}->{"CLEARPRED"};
		if ( $sub_expression ) {
			$ret = &expression_prepare( \$sub_expression, \%{$sub_col_data}, \%hierinfo );
			if( $ret ) {
				my $logmess = "(Error:13120) Error in account alarm level in CLEARPRED, expression: $sub_expression";
				&writelog ( \$logmess, 2, 2 );
			} elsif ( $sub_expression == 1 ) {
				$alarmstate = 0;
				$thresholdmess = $use_pmalarm{$alarmname}->{"CLEARPRED"};
				goto reparealarm;
			}
		}
		#生成告警信息
reparealarm:
		my $sendalarmmess="";
		#有告警产生
		if ( $alarmstate > 0 ) {
			#性能告警号是自增长的alarmid和taskid联合组成的
			$alarmid++;
			my $trend = "notKnown";
			if ( $alarmstate > $alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"} ) {
				$trend = "moreSevere";
			} elsif ( $alarmstate = $alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"}) { 
				$trend = "noChange";
			} else {
				$trend = "lessSevere";
			}
			#***************************************************
			#为了避免在某些告警一直没有清除，导致相关告警号越来越多，最终使内存耗尽
			#因此在当相关告警号达到一定个数的时候，则去掉最前面的相关告警号，
			#同时发送一条告警的清除的信息，信息的内容需要讨论
			#目前相关告警里最多保存10个，超过则发送清除告警清除
			#***************************************************
			my @all_alarmid = split( /,/, $alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"} );
			if ( @all_alarmid > 10 ) {
				$sendalarmmess = $use_pmalarm{$alarmname}->{"OBJCLASS"} . ";" . $objnamedby . ";" .
								$use_pmalarm{$alarmname}->{"ALARMTYPE"} . ";" . $alarmtime . ";" .
								$use_pmalarm{$alarmname}->{"ALARMCAUSE"} . ";" . $alarmname . ";0;notKnown;" . 
								";" . $alarmid . "$taskid;" . $all_alarmid[0]  . ";" . ";" . ";" .
								$use_pmalarm{$alarmname}->{"ALARMTEXT"} . ";" . &nowtime() . "\n" ;
				#得到清除第一个告警后的相关告警号
				$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"} = substr( $alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"}, length($all_alarmid[0])+1 );
				$alarmid++;
			}
			#发送新生成的告警
			$sendalarmmess = $sendalarmmess . $use_pmalarm{$alarmname}->{"OBJCLASS"} . ";" . $objnamedby . ";" . 
							$use_pmalarm{$alarmname}->{"ALARMTYPE"} . ";" . $alarmtime . ";" . 
							$use_pmalarm{$alarmname}->{"ALARMCAUSE"} . ";" . $alarmname . ";" . 
							$alarmstate . ";" . $trend . ";" . $thresholdmess . ";" . $alarmid . "$taskid;" . 
							$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"} . ";" . 
							$use_pmalarm{$alarmname}->{"REPORTVALUE"} . ";" . $reportvalue . ";" . 
							$use_pmalarm{$alarmname}->{"ALARMTEXT"} . ";" . &nowtime();
			#更改状态
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"}=$alarmstate;
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"}=$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"} . $alarmid ."$taskid,";
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMTIME"}=$alarmunixtime;
		#没有告警产生或者是清除告警
		} else {
			#原来存在告警，发送清除告警
			if ( $alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"} > 0 ) {
				$alarmid++;
				$sendalarmmess = $use_pmalarm{$alarmname}->{"OBJCLASS"} . ";" . $objnamedby . ";" .
								$use_pmalarm{$alarmname}->{"ALARMTYPE"} . ";" . $alarmtime . ";" .
								$use_pmalarm{$alarmname}->{"ALARMCAUSE"} . ";" . $alarmname . ";" .
								$alarmstate . ";lessSevere;" . $thresholdmess . ";" . $alarmid . "$taskid;" .
								$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"} . ";" .
								$use_pmalarm{$alarmname}->{"REPORTVALUE"} . ";" . $reportvalue . ";" .
								$use_pmalarm{$alarmname}->{"ALARMTEXT"} . ";" . &nowtime();
			}
			#更改状态
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMSTATE"}=$alarmstate;
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMID"}="";
			$alarmmess{$alarmname}->{$objnamedby}->{"ALARMTIME"}=$alarmunixtime;
		}
		#性能告警信息发送
		if ( $sendalarmmess && $alarmsocket > 0 ) {
			if ( ! $alarmsocket->printf("$sendalarmmess\n") ) {
				my $logmess = "(Error:13121) Error in send PM ALARM, Please check host server !";
				&writelog ( \$logmess, 3, 2 );
				return 1;
			}
		}
	}
	return 0;
}

#****************************************************
# 日期转换，输出为UNIXTIME数字型的时间
# 参数：
# 1、日期  '2005-07-21 18:30:00'
# 注意：目前不能处理2000年以前的日期
#****************************************************
sub time2unix {
	my $sub_datestr = shift;
	my $sub_types = shift;
	#
	my @sub_datearr = split( / /, $sub_datestr );
	#得到年月日
	my @sub_day = split( /\-/, $sub_datearr[0] );
	$sub_day[0] = int(substr( $sub_day[0], length($sub_day[0])-2 )) + 100;
	#得到时分秒
	my @sub_time = split( /\:/, $sub_datearr[1] );
	if ( $sub_types ) {
		$sub_time[2]=0 if ( $sub_types >=1 );
		$sub_time[1]=0 if ( $sub_types >=2 );
		$sub_time[0]=0 if ( $sub_types >=3 );
		$sub_day[2]=1 if ( $sub_types >=4 );
		$sub_day[1]=1 if ( $sub_types >=5 );
		$sub_day[0]=100 if ( $sub_types >=6 );
	}
	#转换成秒
	my $sub_timesec = timegm ( $sub_time[2], $sub_time[1], $sub_time[0], $sub_day[2], $sub_day[1]-1, $sub_day[0] );
	return $sub_timesec;
}

#****************************************************
# 日期转换，输出为'2005-07-21 18:30:00'
# 参数：
# 1、日期  UNIXTIME数字型的时间
# 注意：目前不能处理2000年以前的日期
#****************************************************
sub unix2time () {
	my $sub_unixdate = shift;
	my @result_arrtime = gmtime ( $sub_unixdate );
	$result_arrtime[5]+=1900;
	$result_arrtime[4]+=1;
	my $result_time = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d", 
		$result_arrtime[5],$result_arrtime[4],$result_arrtime[3],
		$result_arrtime[2],$result_arrtime[1],$result_arrtime[0] ) ;
	return $result_time;
}

#************************************************
#	功能：	
#		得到当前系统时间
#	输入：
#	返回：
#		当前系统时间 YYYY-mm-dd HH:MM:SS
#	例如：2005-07-21 18:30:00
#************************************************
sub nowtime () {
	my @list=localtime;
	$list[5]+=1900;
	$list[4]+=1;
	my $result_time=sprintf("%04d-%02d-%02d %02d:%02d:%02d", $list[5],$list[4],$list[3],$list[2],$list[1],$list[0]);
	return $result_time;
}

#************************************************
#	功能：	
#		日志打印
#	输入：
#		1. 日志内容的引用
#		2. 日志的等级( 0|1|2|3|4 )
#		3. sub_logflag 日志的标致(1 流水 2 错误)
#	输出：
#		
#	返回值：
#		0 正常
#************************************************
sub writelog() {
	my $sub_logmess = shift;
	my $sub_loglevel = shift;
	my $sub_logflag = shift;

	#$loglevel = 0 的时候不写日志
	if ( $loglevel != 0 && $sub_loglevel <= $loglevel ) {
		if ( $sub_logflag == 1 ) {
			open(SUB_LOGFILE, ">>$logfile.audit" );
		} else {
			open(SUB_LOGFILE, ">>$logfile.log" );
		}
		printf SUB_LOGFILE ( "(%s) Pid=$pid Rset=%d %s\n", &nowtime(), $ruleset, $$sub_logmess ) ;
		close (SUB_LOGFILE) ;
	}
	return 0;
}
