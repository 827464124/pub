#!/usr/bin/perl -w
use strict;
use DBI;

################################################################################
# Subroutine name:  GetDBResult()
#
# Description:      从数据库获取结果集函数
#
# Arguments:        
# Returns:          存有hash引用的结果集数组

sub GetDBResult
{
	
	my $strsql=shift;
	my($dbcon,$sth,$item);
	my %results=();
	my @arrayres=();
	#配置数据库连接
	$dbcon = DBI ->connect ('DBI:mysql:host=10.0.209.172;database=ioss;user=nuoen;password=nuoen')  or die "can't preapare sql statement".DBI -> errstr;

	#设置字符集
	$dbcon->do("SET character_set_client='gbk'");
	$dbcon->do("SET character_set_connection='gbk'");
	$dbcon->do("SET character_set_results='gbk'");

	#准备sql查询
	$sth = $dbcon -> prepare($strsql) || die "Can't prepare statement: $DBI::errstr";
	#执行
	$sth -> execute() || die "Can't execute statement: $DBI::errstr";
	
	#字段数
	#print "Query will return $sth->{NUM_OF_FIELDS} fields.\n\n";
	#字段名称
	#print "field names :@{$sth->{NAME}}\n";
	my $rowcount=0;	
	#循环取值	
	while (my $rows = $sth->fetchrow_hashref())
	{
		$arrayres[$rowcount]=$rows;
		$rowcount++;
	}
	
	#释放返回的结果对象
	$sth -> finish();
	#断开连接
	$dbcon -> disconnect();
	
	return @arrayres;
}

################################################################################
# Subroutine name:  GetDataLine()
#
# Description:      将从数据库获取的参数配置转化为配置文件所需格式
#
# Arguments:        
# Returns:          配置文件输入内容的引用

sub GetDataLine
{
	my($limitsql,$levelsql,$sqllimit,@arrayres);
	my(@head,@thershold,$alamhead,$alambody);
	
	$alamhead="ALARM_";
	$alambody="THERSHOLD_";
	
	
	$limitsql="A.PALARMID,A.ATITLE,A.ATEXT,A.AEXPR";
	$levelsql="B.LEVELID,B.LEVELTIME,B.LIMITMAX,B.LIMITMIX,B.LEVELNAME";
	#拼接完整的sql查询语句
	$sqllimit="SELECT ".$limitsql.", ".$levelsql." FROM FPERFLIMIT A,FPERFLEVEL B	WHERE A.PALARMID =B.PALARMID";

	#拆分字符串
	@head =split(/,/,$limitsql);
	@thershold =split(/,/,$levelsql);
	@head =grep {$_ ne "A.PALARMID"} @head;
	@thershold =grep {$_ ne "B.LEVELID"} @thershold;#移除掉LEVELID
	

	#调用函数，返回结果引用的数组，即数组中存放的为hash引用
	@arrayres=GetDBResult($sqllimit);
	
	my %hash=();
	my $tmpalamid="";
	
	for (my $i = 0; $i < @arrayres; $i++) 
	{	
		#告警标题获取
		if($tmpalamid ne $arrayres[$i]->{PALARMID})
		{
				$hash{$arrayres[$i]->{PALARMID}} .="\'$arrayres[$i]->{PALARMID}\' =>{\n";
				foreach my $itemhead(@head)
				{
					my $items= substr($itemhead,2);
					$hash{$arrayres[$i]->{PALARMID}} .="\t\'$alamhead$items\' => \'$arrayres[$i]->{$items}\',\n";
				}	
		}
			$tmpalamid=$arrayres[$i]->{PALARMID};
		#门限部分
		$hash{$arrayres[$i]->{PALARMID}} .="\t'$arrayres[$i]->{LEVELID}\' => {\n";
		
		foreach my $ithershold(@thershold)
		{	
			my $itemther=substr($ithershold,2);
			
			if(!grep /LIMITMAX|LIMITMIX|LEVELNAME/i,$itemther)
			{	
				$hash{$arrayres[$i]->{PALARMID}} .="\t\'$alambody$itemther\' => [\"$arrayres[$i]->{$itemther}\"],\n";
			}
		}
		
		#处理门限最大最小值
		#取整数，去掉小数点后的数字
		my $maxlimit= sprintf("%.f",$arrayres[$i]->{LIMITMAX});
		my $mixlimt= sprintf("%.f",$arrayres[$i]->{LIMITMIX});	
		my $therexpression="\t\'THRESHOLD_EXPRESSION\' => [\"($arrayres[$i]->{AEXPR})>=$mixlimt && ($arrayres[$i]->{AEXPR})<=$maxlimit\"],\n";
		$hash{$arrayres[$i]->{PALARMID}} .=$therexpression;
		
		#门限信息描述
		my $therinfo="\t\'THRESHOLD_EXPRESSION_INFO\' => [\"$arrayres[$i]->{LEVELNAME}:$arrayres[$i]->{ATEXT}>=$mixlimt\"],\n";
		$hash{$arrayres[$i]->{PALARMID}} .=$therinfo;
		#插入换行
		$hash{$arrayres[$i]->{PALARMID}} .= "\t},\n";
	}
	return \%hash;
}	
################################################################################
# Subroutine name:  OutPutLine()
#
# Description:      生成配置文件
#
# Arguments:        
# Returns:          

sub OutPutLine
{	
		my $refhash=&GetDataLine;
		my $configfile="./testconfig.cf";
		#打开文件
		open(OUT,">$configfile") || die "This file open $!"; 
		
		#开始写内容
		print OUT "##START ALARM##\n";
		foreach my $output(keys %$refhash)
		{
#			print "$$refhash{$output}\n},\n";
			print  OUT "$$refhash{$output}\n},\n";
		}
		print OUT "##END ALARM##\n";
}	

#执行程序，程序入口
&OutPutLine;