#! /usr/bin/perl -w
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
#              浪潮乐金NMS
###################################################################################
$LogLevel=3;

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
#     名称：DiffDateTime(当前时间,时间差)
#     描述：获得当前时间的上一个时间和下一个时间
#     参数：当前时间格式yyyymmddhhmm不足的补0
#           时间差按分记,+为当前时间的下一个时间,-为当前时间的上一个时间，如果没有标记则默认为加
#           可以用表达式的形式如 1440*10就是10天，60*24就是一天
#     返回：返回值与传入参数相同格式的日期时间字符串
###############################################################################################
sub DiffDateTime {
	my ($strDateTime,$diffMinutes)=@_;
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
	$iDay=$iDay-0;
	$iFlag=0;
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
