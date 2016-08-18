#!/usr/bin/perl
#用于实现特殊处理的一些功能函数定义

#****************************************************
# 日期转换，输出为 '2005-07-21 18:30:00'
# 参数：
# 1、日期  21Jul05 , 21Jul2005
# 2、时间  18:30:00 , 18:30
# 3、时间间隔（秒） 1800 , -1800
# 注意：目前不能处理2000年以前的日期
#****************************************************
sub change_time () {
	my $sub_date = shift;
	my $sub_time = shift;
	my $sub_interval = int(shift);
	#
	my %month_lib = (
		'Jan' => '01',
		'Feb' => '02',
		'Mar' => '03',
		'Apr' => '04',
		'May' => '05',
		'Jun' => '06',
		'Jul' => '07',
		'Aug' => '08',
		'Sep' => '09',
		'Oct' => '10',
		'Nov' => '11',
		'Dec' => '12'
	);
	#
	#得到年月日
	my $sub_year = substr( $sub_date, length($sub_date)-2 ) + 100;
	my $sub_month = $month_lib{substr($sub_date,2,3)} - 1;
	my $sub_day = substr( $sub_date, 0, 2 );
	#
	my @sub_arrtime = split( /\:/, $sub_time );
	#转换成秒
	my $sub_timesec = timegm ( $sub_arrtime[2], $sub_arrtime[1], $sub_arrtime[0], $sub_day, $sub_month, $sub_year );
	$sub_timesec = $sub_timesec + $sub_interval;
	my @result_arrtime = gmtime ( $sub_timesec );
	$result_arrtime[5]+=1900;
	$result_arrtime[4]+=1;
	my $result_time = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d", 
		$result_arrtime[5],$result_arrtime[4],$result_arrtime[3],
		$result_arrtime[2],$result_arrtime[1],$result_arrtime[0] ) ;
		
	return $result_time;
}

sub change_day () {
	my $sub_date = shift;
	my $sub_interval = int(shift);
	#
	my %month_lib = (
		'Jan' => '01',
		'Feb' => '02',
		'Mar' => '03',
		'Apr' => '04',
		'May' => '05',
		'Jun' => '06',
		'Jul' => '07',
		'Aug' => '08',
		'Sep' => '09',
		'Oct' => '10',
		'Nov' => '11',
		'Dec' => '12'
	);
	#
       my $sub_year = substr( $sub_date, 5,4 ) ;
       my $sub_month = $month_lib{substr($sub_date,2,3)};
       my $sub_day = substr( $sub_date, 0, 2 );
	#
	my $result_time = sprintf ( "%04d-%02d-%02d",$sub_year,$sub_month,$sub_day);
		
	return $result_time;
}

#****************************************************
# 把参数串成字符串返回
# 第一个参数为连接字符，其余为连接内容
#####################################################
sub strjoin () {
	my ($linkch,@linkstr)=@_;
	
	return join($linkch,@linkstr);
}
#****************************************************
# 数据相除时，分母不能为零的比较
# 参数：
# 1、分子
# 2、分母
# 3、当分母为零时的取值
#****************************************************
sub division () {
	my $sub_numerator = shift;
	my $sub_denominator = shift;
	my $sub_result = shift;
	if ( $sub_result eq "" ) {
		$sub_result = 0;
	}
	if ( ! $sub_denominator == 0  ) {
		$sub_result = $sub_numerator/$sub_denominator;
	}
	return $sub_result;
}
#****************************************************
# 数据相除时，分母不能为零的比较
# 参数：
# 1、分子
# 2、分母
# 3、当分母为零时的取值
#****************************************************
sub pcentok () {
	my $sub_numerator = shift;
	my $sub_denominator = shift;
	my $sub_result = shift;
	if ( $sub_result eq "" ) {
		$sub_result = 1;
	}
	if ( ! $sub_denominator == 0  ) {
		$sub_result = $sub_numerator/$sub_denominator;
	}
	return $sub_result*100;
}
sub pcentfail () {
	my $sub_numerator = shift;
	my $sub_denominator = shift;
	my $sub_result = shift;
	if ( $sub_result eq "" ) {
		$sub_result = 0;
	}
	if ( ! $sub_denominator == 0  ) {
		$sub_result = $sub_numerator/$sub_denominator;
	}
	return $sub_result*100;
}

#****************************************************
# 数据相除时，分母不能为零的比较
# 参数：
# 1、分子
# 2、分母
# 3、当分母为零时的取值
#****************************************************
sub division () {
	my $sub_numerator = shift;
	my $sub_denominator = shift;
	my $sub_result = shift;
	if ( $sub_result eq "" ) {
		$sub_result = 0;
	}
	if ( ! $sub_denominator == 0  ) {
		$sub_result = $sub_numerator/$sub_denominator;
	}
	return $sub_result;
}

#****************************************************
# 实现Perl调用系统substr的功能
# 参数：
# 1、同substr
#****************************************************
sub lsubstr () {
	my $sub_string = shift;
	my $sub_begin = shift;
	my $sub_length = int(shift);
	if ( $sub_length>0 ) {
		return substr( $sub_string, $sub_begin, $sub_length );
	} else {
		return substr( $sub_string, $sub_begin );
	}
}

#****************************************************
# 实现Perl调用系统index的功能
# 参数：
# 1、同index
#****************************************************
sub lindex () {
	my $sub_string1 = shift;
	my $sub_string2 = shift;
	return index($sub_string1, $sub_string2);
}

#****************************************************
# 实现Perl调用系统rindex的功能
# 参数：
# 1、同rindex
#****************************************************
sub lrindex () {
	my $sub_string1 = shift;
	my $sub_string2 = shift;
	return rindex($sub_string1, $sub_string2);
}

#****************************************************
# 实现Perl调用系统length的功能
# 参数：
# 1、同length
#****************************************************
sub llength () {
	my $sub_string = shift;
	return length($sub_string);
}
sub trimSpace
{
       my ($myString) = @_;
	      $myString =~ s/^\s+//;
	      $myString =~ s/\s+$//;
       return $myString;
}


1;

