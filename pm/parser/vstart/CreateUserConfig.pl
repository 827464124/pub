#!/usr/bin/perl -w
use strict;
use DBI;

################################################################################
# Subroutine name:  GetDBResult()
#
# Description:      �����ݿ��ȡ���������
#
# Arguments:        
# Returns:          ����hash���õĽ��������

sub GetDBResult
{
	
	my $strsql=shift;
	my($dbcon,$sth,$item);
	my %results=();
	my @arrayres=();
	#�������ݿ�����
	$dbcon = DBI ->connect ('DBI:mysql:host=10.0.209.172;database=ioss;user=nuoen;password=nuoen')  or die "can't preapare sql statement".DBI -> errstr;

	#�����ַ���
	$dbcon->do("SET character_set_client='gbk'");
	$dbcon->do("SET character_set_connection='gbk'");
	$dbcon->do("SET character_set_results='gbk'");

	#׼��sql��ѯ
	$sth = $dbcon -> prepare($strsql) || die "Can't prepare statement: $DBI::errstr";
	#ִ��
	$sth -> execute() || die "Can't execute statement: $DBI::errstr";
	
	#�ֶ���
	#print "Query will return $sth->{NUM_OF_FIELDS} fields.\n\n";
	#�ֶ�����
	#print "field names :@{$sth->{NAME}}\n";
	my $rowcount=0;	
	#ѭ��ȡֵ	
	while (my $rows = $sth->fetchrow_hashref())
	{
		$arrayres[$rowcount]=$rows;
		$rowcount++;
	}
	
	#�ͷŷ��صĽ������
	$sth -> finish();
	#�Ͽ�����
	$dbcon -> disconnect();
	
	return @arrayres;
}

################################################################################
# Subroutine name:  GetDataLine()
#
# Description:      �������ݿ��ȡ�Ĳ�������ת��Ϊ�����ļ������ʽ
#
# Arguments:        
# Returns:          �����ļ��������ݵ�����

sub GetDataLine
{
	my($limitsql,$levelsql,$sqllimit,@arrayres);
	my(@head,@thershold,$alamhead,$alambody);
	
	$alamhead="ALARM_";
	$alambody="THERSHOLD_";
	
	
	$limitsql="A.PALARMID,A.ATITLE,A.ATEXT,A.AEXPR";
	$levelsql="B.LEVELID,B.LEVELTIME,B.LIMITMAX,B.LIMITMIX,B.LEVELNAME";
	#ƴ��������sql��ѯ���
	$sqllimit="SELECT ".$limitsql.", ".$levelsql." FROM FPERFLIMIT A,FPERFLEVEL B	WHERE A.PALARMID =B.PALARMID";

	#����ַ���
	@head =split(/,/,$limitsql);
	@thershold =split(/,/,$levelsql);
	@head =grep {$_ ne "A.PALARMID"} @head;
	@thershold =grep {$_ ne "B.LEVELID"} @thershold;#�Ƴ���LEVELID
	

	#���ú��������ؽ�����õ����飬�������д�ŵ�Ϊhash����
	@arrayres=GetDBResult($sqllimit);
	
	my %hash=();
	my $tmpalamid="";
	
	for (my $i = 0; $i < @arrayres; $i++) 
	{	
		#�澯�����ȡ
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
		#���޲���
		$hash{$arrayres[$i]->{PALARMID}} .="\t'$arrayres[$i]->{LEVELID}\' => {\n";
		
		foreach my $ithershold(@thershold)
		{	
			my $itemther=substr($ithershold,2);
			
			if(!grep /LIMITMAX|LIMITMIX|LEVELNAME/i,$itemther)
			{	
				$hash{$arrayres[$i]->{PALARMID}} .="\t\'$alambody$itemther\' => [\"$arrayres[$i]->{$itemther}\"],\n";
			}
		}
		
		#�������������Сֵ
		#ȡ������ȥ��С����������
		my $maxlimit= sprintf("%.f",$arrayres[$i]->{LIMITMAX});
		my $mixlimt= sprintf("%.f",$arrayres[$i]->{LIMITMIX});	
		my $therexpression="\t\'THRESHOLD_EXPRESSION\' => [\"($arrayres[$i]->{AEXPR})>=$mixlimt && ($arrayres[$i]->{AEXPR})<=$maxlimit\"],\n";
		$hash{$arrayres[$i]->{PALARMID}} .=$therexpression;
		
		#������Ϣ����
		my $therinfo="\t\'THRESHOLD_EXPRESSION_INFO\' => [\"$arrayres[$i]->{LEVELNAME}:$arrayres[$i]->{ATEXT}>=$mixlimt\"],\n";
		$hash{$arrayres[$i]->{PALARMID}} .=$therinfo;
		#���뻻��
		$hash{$arrayres[$i]->{PALARMID}} .= "\t},\n";
	}
	return \%hash;
}	
################################################################################
# Subroutine name:  OutPutLine()
#
# Description:      ���������ļ�
#
# Arguments:        
# Returns:          

sub OutPutLine
{	
		my $refhash=&GetDataLine;
		my $configfile="./testconfig.cf";
		#���ļ�
		open(OUT,">$configfile") || die "This file open $!"; 
		
		#��ʼд����
		print OUT "##START ALARM##\n";
		foreach my $output(keys %$refhash)
		{
#			print "$$refhash{$output}\n},\n";
			print  OUT "$$refhash{$output}\n},\n";
		}
		print OUT "##END ALARM##\n";
}	

#ִ�г��򣬳������
&OutPutLine;