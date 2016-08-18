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
	
	#把无值数据填充为0
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
# Arguments:        $myString--标量
#			
# Returns:          $myString--处理后的标量
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
# 公用函数：
#----------------------------------------------------------------------------------
# 修订：
#     1 编写
#     2 修改从某年的01010000向前减一小时获得01002300的错误
#       祝乃国 2003-12-30
#----------------------------------------------------------------------------------
# 编写：
#     祝乃国
#         2003-12-30
###################################################################################
my $LogLevel=3;

#输出错误日志
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
#输出流水日志
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
# 名称：DiffMinute(日期时间1，日期时间2）时间1-时间2
# 描述：返回两个日期时间的差值，以分钟为单位
# 参数：格式为yyyymmddhhmm
# 返回：以分钟为单位的差值，如果时间1小于时间2则返回负值
#       本函数需要使用time::local才能使用内部函数timelocal转化为纪元秒
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
	
	#拆分数据
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

	#先把每个日期转换为本年的第几天，计算自本年开始的分钟数
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
#     名称：DiffDateTime(当前时间,时间差)
#     描述：获得当前时间的上一个时间和下一个时间
#     参数：当前时间格式yyyymmddhhmm不足的补0
#           时间差按分记,+为当前时间的下一个时间,-为当前时间的上一个时间，如果没有标记则默认为加
#           可以用表达式的形式如 1440*10就是10天，60*24就是一天
#     返回：返回值与传入参数相同格式的日期时间字符串
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
	#本程序中使用，采用yyyymmddhhmm格式，故不做其他格式及容错判断。
	if (length($strDateTime)==12) {
		$tYear=substr($strDateTime,0,4);
		$tMonth=substr($strDateTime,4,2);
		$tDay=substr($strDateTime,6,2);
		$tHour=substr($strDateTime,8,2);
		$tMinute=substr($strDateTime,10,2);
		#当前日期在本年中的天数
		$iDays=GetDays($tYear,$tMonth,$tDay);
		#分两部分计算，先计算当日的秒是否够，如果不够向天借，一天有24*60=1440分
		#先计算传入参数部分除去整天剩余的数据，天内部分转换为分钟，从0点0分开始计，计算后再复原为日内的时间
		#取传入参数的分钟数
		$tFlag=substr($diffMinutes,0,1);
		if (($tFlag eq "+") || ($tFlag eq "-")) {
			$iMinute=substr($diffMinutes,1);
		} else {
			$tFlag="+";
			$iMinute=$diffMinutes;
		}
		#计算传入参数的分钟中有几个整天
		$iMyDays=int($iMinute/1440);
		$iMyMinute=$iMinute % 1440;
		#转换传入参数中的日内部分为分钟数
		$iInMinute=$tHour*60+$tMinute;
		if ($tFlag eq "+") {
			#总的处理分钟数
			$iTemp=$iMyMinute+$iInMinute;
			#得到应该处理的天数
			$iMyDays=$iMyDays+int($iTemp/1440);
			#剩余分钟数
			$iMyMinute=$iTemp % 1440;
			#返回值中的小时和分钟
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
			#总天数
			$iDays=$iDays+$iMyDays;
			#年的初始天数
			$iYearDays=GetYearDays($tYear);
			while ($iYearDays < $iDays) {
				$iDays=$iDays-$iYearDays;
				$tYear=$tYear+1;
				$iYearDays=GetYearDays($tYear);
			}
		} else {
			#处理分钟数，如果参数日期中分钟数不够剩余分钟数减则借1天为1440分钟
			if ( $iInMinute < $iMyMinute ) {
				$iTemp=1440+$iInMinute-$iMyMinute;
				$iMyDays=$iMyDays+1;
			} else {
				$iTemp=$iInMinute-$iMyMinute;
			}
			#返回值中的小时和分钟
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
			#年的初始天数
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
		#获得月 日
		$sMonthDay=GetMonthDay($tYear,$iDays);
		#组装返回值
		$strReturn=$tYear.$sMonthDay.$sRetHour.$sRetMinute;
	}
	return $strReturn;
}
##########################################################################
# 名称：GetYearDays(年)
# 描述：获得此年的天数
# 参数：年，格式YYYY
# 返回：此年的天数
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
# 名称：GetLeapYear(年)
# 描述：判断此年是否闰年
# 参数：年，格式yyyy
# 返回：标记 YES-是闰年 NO-不是闰年
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
# 名称：GetDays(年，月，日）
# 描述：获得此参数日期在本年的第X天，以本年的1月1日起算
# 参数：年，格式YYYY；月；日
# 返回：从1月1日起在本年的第几天
#############################################################################
sub GetDays {
	my ($iYear,$iMonth,$iDay)=@_;
	
	my (@aMonthDay);
	my $sLeap="NO";
	my $iReturn=0;
	$sLeap=GetLeapYear($iYear);
	@aMonthDay=();
	#取闰年或平年的每月的天数
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
# 名称：GetMonthDay(年，天数）
# 描述：获得此年该天数在此年的月和日
# 参数：年，格式YYYY；天数，整型
# 返回：字符串MMDD
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