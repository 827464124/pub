#----------------------------------------------------------------
# @(#) SNMP parsers snmp_pub.pm
#----------------------------------------------------------------
# This takes RAW snmp CELL Files, and converts them to PIF file types.
#
# This program relies EngineConfig.pm Files.
# Follow:
#---------------------------------------------------------------
# written by Zhung on 2007-01-10
#          LC-LG NMS
#----------------------------------------------------------------

package SNMP_PUB;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use AudLog;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(init_file write_array_data write_scalar_data convert_date_snmp trimSpace trimLine convert_time_snmp DiffDateTime DiffMinute);
$VERSION = '1.00';

##################################################################
# Subroutine name:  init_file()
#
# Description:      Create PIF filename 
#
# Arguments:        blockname (scalar)- the block name of the data blocks
#					self (scalar) - a reference to object's config hash
#                   $h_ref (scalar) - a reference to the header_info hash
# Returns:          Object reference
#
#
sub init_file{
        my ($filename)=@_;
	
	my ($ret);
	$ret=open(outFile,">$filename");
	if ($ret) {
		print outFile "## SNMP File Parser Intermediate file\n";
		print outFile "##START|HEADER\n";
		close outFile;
		return 1;
	} else {
		LogMess("SNMP_PUB:init_file --Can not open ${filename} to write",1);
		return -1;
	}
}
sub write_array_data{
	my ($filename,@data)=@_;
	my ($outData);
	
	$outData=join("|",@data);
	
	#����ֵ�������Ϊ0
	$outData=~s/\|\|/\|0\|/g;
	
	open(outFile,">>$filename") || LogMess("SNMP_PUB:write_array_data --Can not open ${filename} to write",1);
	print outFile "${outData}\n";
	close outFile;
}
sub write_scalar_data{
	my ($filename,$outData)=@_;
	
	open(outFile,">>$filename") || LogMess("SNMP_PUB:write_scalar_data --Can not open ${filename} to write",1);
	print outFile "${outData}\n";
	close outFile;
}
# convert snmp date format yyyymmddhhmm To ddMMMyyyy
sub convert_date_snmp {
	my ($oldDate)=@_;
	my ($newDate,$tYear,$tMonth,$tDay);
        my %MONTH_NAMES = ( '1' => "Jan", '2' => "Feb", '3' => "Mar",
					'4' => "Apr", '5' => "May", '6' => "Jun",
					'7' => "Jul", '8' => "Aug", '9' => "Sep",
					'10' => "Oct", '11' => "Nov", '12' => "Dec" );
					
	$tYear=substr($oldDate,0,4);
	$tMonth=substr($oldDate,4,2);
	$tDay=substr($oldDate,6,2);
	

	# Creating the new date string
	$newDate= $tDay.$MONTH_NAMES{int($tMonth)}.$tYear;
	return $newDate;
}
# convert snmp date format yyyymmddhhmm To hh:mm
sub convert_time_snmp {
	my ($oldDate)=@_;
	my ($newTime,$tHour,$tMinute);
 
					
	$tHour=substr($oldDate,8,2);
	$tMinute=substr($oldDate,10,2);

	# Creating the new time string
	$newTime= $tHour.':'.$tMinute;
	return $newTime;
}

##################################################################
# Subroutine name:  trimSpace
#
# Description:      Delete Space&TAB from the scalar
#
# Arguments:        $myString--����
#			
# Returns:          $myString--�����ı���
#
#
sub trimSpace
{
	my ($myString) = @_;
	$myString =~ s/^\s+//;
	$myString =~ s/\s+$//;
	$myString =~ s/^\t+//;
	$myString =~ s/\t+$//;
	return $myString;
}
sub trimLine {
	my ($line)=@_;
	my (@aTemp,$iCount);
	
	@aTemp=split("!",$line);
	for ($iCount=1;$iCount<=$#aTemp;$iCount++) {
		$aTemp[$iCount]=trimSpace($aTemp[$iCount]);
	}
	
	return join("!",@aTemp);
}
##################################################################################
# ���ú�����
#----------------------------------------------------------------------------------
# �޶���
#     1 ��д
#     2 �޸Ĵ�ĳ���01010000��ǰ��һСʱ���01002300�Ĵ���
#       ף�˹� 2003-12-30
#----------------------------------------------------------------------------------
# ��д��
#     ף�˹�
#         2003-12-30
###################################################################################
my $LogLevel=3;

#���������־
sub outerr($$$)
{
	my ($errText,$lLevel,$sProName)=@_;
	my ($sec, $min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)  = localtime(time);
	$year=$year+1900;
	$mon=$mon+1;
	if ($LogLevel>=$lLevel)
	{
		print "($year-$mon-$mday $hour:$min:$sec)[${sProName}]$errText\n";
	}
}	
#�����ˮ��־
sub outaudit($$$)
{
	my ($errText,$lLevel,$sProName)=@_;
	my ($sec, $min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)  = localtime(time);
	$year=$year+1900;
	$mon=$mon+1;
	if ($LogLevel>=$lLevel)
	{
		print "($year-$mon-$mday $hour:$min:$sec)[${sProName}]$errText\n";
	}
}	
###############################################################################################
# ���ƣ�DiffMinute(����ʱ��1������ʱ��2��ʱ��1-ʱ��2
# ������������������ʱ��Ĳ�ֵ���Է���Ϊ��λ
# ��������ʽΪyyyymmddhhmm
# ���أ��Է���Ϊ��λ�Ĳ�ֵ�����ʱ��1С��ʱ��2�򷵻ظ�ֵ
#       ��������Ҫʹ��time::local����ʹ���ڲ�����timelocalת��Ϊ��Ԫ��
###############################################################################################
sub DiffMinute {
	my ($strDT1,$strDT2)=@_;
	
	my ($iMinute,$strMax,$strMin,$iMaxMin,$iMinMin,$iFlag);
	my ($maxMinute,$maxHour,$maxDay,$maxMonth,$maxYear);
	my ($minMinute,$minHour,$minDay,$minMonth,$minYear);
	my ($iTemp);
	
	if ($strDT1 eq $strDT2) {
		return 0;
	} elsif ($strDT1 lt $strDT2) {
		$strMax=$strDT2;
		$strMin=$strDT1;
		$iFlag=0 - 1 ;
	} else {
		$strMax=$strDT1;
		$strMin=$strDT2;
		$iFlag=1;
	}
	
	#�������
	$maxYear=substr($strMax,0,4);
	$maxMonth=substr($strMax,4,2);
	$maxDay=substr($strMax,6,2);
	$maxHour=substr($strMax,8,2);
	$maxMinute=substr($strMax,10,2);

	$minYear=substr($strMin,0,4);
	$minMonth=substr($strMin,4,2);
	$minDay=substr($strMin,6,2);
	$minHour=substr($strMin,8,2);
	$minMinute=substr($strMin,10,2);

	#�Ȱ�ÿ������ת��Ϊ����ĵڼ��죬�����Ա��꿪ʼ�ķ�����
	$iMaxMin=$maxHour*60 + $maxMinute;
	$iMaxMin=$iMaxMin+(GetDays($maxYear,$maxMonth,$maxDay) - 1) * 1440;
	
	$iMinMin=$minHour*60+$minMinute;
	$iMinMin=$iMinMin+(GetDays($minYear,$minMonth,$minDay) - 1) * 1440;
	
	if ($maxYear eq $minYear) {
		$iMinute=$iMaxMin - $iMinMin;
	} else {
		$iTemp=$maxYear;
		while ($iTemp > $minYear) {
			$iTemp=$iTemp - 1;
			$iMaxMin=$iMaxMin+GetYearDays($iTemp) * 1440;
		}
		$iMinute=$iMaxMin - $iMinMin;
	}
	
	return $iMinute * $iFlag;
		
}
###############################################################################################
#     ���ƣ�DiffDateTime(��ǰʱ��,ʱ���)
#     ��������õ�ǰʱ�����һ��ʱ�����һ��ʱ��
#     ��������ǰʱ���ʽyyyymmddhhmm����Ĳ�0
#           ʱ���ּ�,+Ϊ��ǰʱ�����һ��ʱ��,-Ϊ��ǰʱ�����һ��ʱ�䣬���û�б����Ĭ��Ϊ��
#           �����ñ��ʽ����ʽ�� 1440*10����10�죬60*24����һ��
#     ���أ�����ֵ�봫�������ͬ��ʽ������ʱ���ַ���
###############################################################################################
sub DiffDateTime {
	my ($strDateTime,$diffMinutes)=@_;
	
	my ($tYear,$tMonth,$tDay,$tHour,$tMinute,$iMyDays,$iMyMinute,$iInMinute);
	my ($iTemp,$iDays,$tFlag,$iRetHour,$iRetMinute,$sMonthDay,$sLeap,@aMonthDay);
	my $strReturn="ERROR";
	my $iMinute=0;
	my $iYearDays=0;
	my $sRetHour="";
	my $sRetMinute="";
	#��������ʹ�ã�����yyyymmddhhmm��ʽ���ʲ���������ʽ���ݴ��жϡ�
	if (length($strDateTime)==12) {
		$tYear=substr($strDateTime,0,4);
		$tMonth=substr($strDateTime,4,2);
		$tDay=substr($strDateTime,6,2);
		$tHour=substr($strDateTime,8,2);
		$tMinute=substr($strDateTime,10,2);
		#��ǰ�����ڱ����е�����
		$iDays=GetDays($tYear,$tMonth,$tDay);
		#�������ּ��㣬�ȼ��㵱�յ����Ƿ񹻣������������裬һ����24*60=1440��
		#�ȼ��㴫��������ֳ�ȥ����ʣ������ݣ����ڲ���ת��Ϊ���ӣ���0��0�ֿ�ʼ�ƣ�������ٸ�ԭΪ���ڵ�ʱ��
		#ȡ��������ķ�����
		$tFlag=substr($diffMinutes,0,1);
		if (($tFlag eq "+") || ($tFlag eq "-")) {
			$iMinute=substr($diffMinutes,1);
		} else {
			$tFlag="+";
			$iMinute=$diffMinutes;
		}
		#���㴫������ķ������м�������
		$iMyDays=int($iMinute/1440);
		$iMyMinute=$iMinute % 1440;
		#ת����������е����ڲ���Ϊ������
		$iInMinute=$tHour*60+$tMinute;
		if ($tFlag eq "+") {
			#�ܵĴ��������
			$iTemp=$iMyMinute+$iInMinute;
			#�õ�Ӧ�ô��������
			$iMyDays=$iMyDays+int($iTemp/1440);
			#ʣ�������
			$iMyMinute=$iTemp % 1440;
			#����ֵ�е�Сʱ�ͷ���
			$iRetHour=int($iMyMinute/60);
			if ($iRetHour < 10) {
				$sRetHour="0".$iRetHour;
			} else {
				$sRetHour=$iRetHour;
			}
			$iRetMinute=$iMyMinute % 60;
			if ($iRetMinute < 10) {
				$sRetMinute="0".$iRetMinute;
			} else {
				$sRetMinute=$iRetMinute;
			}
			#������
			$iDays=$iDays+$iMyDays;
			#��ĳ�ʼ����
			$iYearDays=GetYearDays($tYear);
			while ($iYearDays < $iDays) {
				$iDays=$iDays-$iYearDays;
				$tYear=$tYear+1;
				$iYearDays=GetYearDays($tYear);
			}
		} else {
			#�����������������������з���������ʣ������������1��Ϊ1440����
			if ( $iInMinute < $iMyMinute ) {
				$iTemp=1440+$iInMinute-$iMyMinute;
				$iMyDays=$iMyDays+1;
			} else {
				$iTemp=$iInMinute-$iMyMinute;
			}
			#����ֵ�е�Сʱ�ͷ���
			$iRetHour=int($iTemp/60);
			if ($iRetHour < 10) {
				$sRetHour="0".$iRetHour;
			} else {
				$sRetHour=$iRetHour;
			}
			$iRetMinute=$iTemp % 60;
			if ($iRetMinute < 10) {
				$sRetMinute="0".$iRetMinute;
			} else {
				$sRetMinute=$iRetMinute;
			}
			#��ĳ�ʼ����
			if ($iDays <= $iMyDays) {
				$iMyDays=$iMyDays-$iDays;
				$tYear=$tYear-1;
				$iYearDays=GetYearDays($tYear);
				while ($iYearDays < $iMyDays) {
					$iMyDays=$iMyDays-$iYearDays;
					$tYear=$tYear-1;
					$iYearDays=GetYearDays($tYear);
				}
				$iDays=$iYearDays-$iMyDays;
			} else {
				$iDays=$iDays-$iMyDays;
			}
		}
		#����� ��
		$sMonthDay=GetMonthDay($tYear,$iDays);
		#��װ����ֵ
		$strReturn=$tYear.$sMonthDay.$sRetHour.$sRetMinute;
	}
	return $strReturn;
}
##########################################################################
# ���ƣ�GetYearDays(��)
# ��������ô��������
# �������꣬��ʽYYYY
# ���أ����������
##########################################################################
sub GetYearDays {
	my ($iYear)=@_;
	
	my ($sLeap);
	my $iMyYearDays=0;
	$sLeap=GetLeapYear($iYear);
	if ($sLeap eq "YES") {
		$iMyYearDays=366;
	} else {
		$iMyYearDays=365;
	}
	return $iMyYearDays;
}
##########################################################################
# ���ƣ�GetLeapYear(��)
# �������жϴ����Ƿ�����
# �������꣬��ʽyyyy
# ���أ���� YES-������ NO-��������
##########################################################################
sub GetLeapYear {
	my ($iYear)=@_;
	my $strReturn="";
	if ((($iYear % 4)==0 && ($iYear % 100) !=0) || ($iYear % 400) ==0) {
		$strReturn="YES";
	} else {
		$strReturn="NO";
	}
	return $strReturn;
}
############################################################################
# ���ƣ�GetDays(�꣬�£��գ�
# ��������ô˲��������ڱ���ĵ�X�죬�Ա����1��1������
# �������꣬��ʽYYYY���£���
# ���أ���1��1�����ڱ���ĵڼ���
#############################################################################
sub GetDays {
	my ($iYear,$iMonth,$iDay)=@_;
	
	my (@aMonthDay);
	my $sLeap="NO";
	my $iReturn=0;
	$sLeap=GetLeapYear($iYear);
	@aMonthDay=();
	#ȡ�����ƽ���ÿ�µ�����
	if ($sLeap eq "YES") {
		@aMonthDay=(31,29,31,30,31,30,31,31,30,31,30,31);
	} else {
		@aMonthDay=(31,28,31,30,31,30,31,31,30,31,30,31);
	}
	$iReturn=0;
	$iMonth=$iMonth-1;
	my $iFlag=0;
	while ($iFlag != $iMonth && $iFlag<12) {
		$iReturn=$iReturn+$aMonthDay[$iFlag];
		$iFlag=$iFlag+1;
	}
	$iReturn=$iReturn+$iDay;
	return $iReturn;
}
############################################################################
# ���ƣ�GetMonthDay(�꣬������
# ��������ô���������ڴ�����º���
# �������꣬��ʽYYYY������������
# ���أ��ַ���MMDD
############################################################################
sub GetMonthDay {
	my ($iYear,$iMyDays)=@_;
	
	my ($iDay,$iMonth,$iCount);
	my $sLeap="NO";
	my $sReturn="";
	my @aMonthDay=();
	$sLeap=GetLeapYear($iYear);
	if ($sLeap eq "YES") {
		@aMonthDay=(31,29,31,30,31,30,31,31,30,31,30,31);
	} else {
		@aMonthDay=(31,28,31,30,31,30,31,31,30,31,30,31);
	}
	$iCount=0;
	$iMonth=0;
	$iDay=0;
	while ($aMonthDay[$iCount]<$iMyDays && $iCount<12) {
		$iMyDays=$iMyDays-$aMonthDay[$iCount];
		$iCount=$iCount+1;
	}
	$iMonth=$iCount+1;
	$iDay=$iMyDays;
	if ($iMonth < 10) {
		$sReturn="0".$iMonth;
	} else {
		$sReturn=$iMonth;
	}
	if ($iDay < 10 ) {
		$sReturn=$sReturn."0".$iDay;
	} else {
		$sReturn=$sReturn.$iDay;
	}
	return $sReturn;
}

1;