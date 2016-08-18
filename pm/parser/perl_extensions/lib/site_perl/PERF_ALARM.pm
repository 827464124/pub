#
#-------------------------------------------------------------------------------
# @(#) PERF_ALARM.pm 
#-------------------------------------------------------------------------------
# 主要完成从PIF文件中按照设置的规则判断产生告警
#
#   Copyright (C) LCLG 2005
#
# Written by zhung on 2005-12-30
#-------------------------------------------------------------------------------
#
package PERF_ALARM;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.01';

#use diagnostics;
use GenUtils;
use File::Basename;
use PIF_Handler;
use LIF_Writer;
use AudLog;
use IO::Socket;
use Time::Local;

sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	# These two variables should be set to true of false
	# depending on whether or not the desired type of output file
	# is wanted
	$self->{"PRODUCE_PIF"} = 0;
	$self->{"PRODUCE_LIF"} = 0;
	$self->{"keep_files"} = "True";
	$self->{"debug"} = "True";
	$self->{"PRODUCE_CAUSE"} = "UNKNOWN";
	$self->{"TREND_INFO"} = "moreSevere";
	$self->{"ALARM_DATA_TIME_START"} = "00:00";
	$self->{"ALARM_DATA_TIME_END"} = "23:00";
	$self->{"ALARM_TYPE"} = "qualityOfService";
	$self->{"NPR_ALARM"} = 0;
	bless ($self, $class);
}

sub load_config {
	my $self = shift;
	($self->{keep_files}, $self->{debug}, $self->{'__config__'}) = @_;
	
	my (@thresholdAlarm,@breakAlarm,$subKey);
	my ($sTemp,$hSelf,$sKey,$num_errors,$thSelf);
	# Inserting all the configuration information into the objects records
	my $key;
	
	my (@aTemp);
	foreach $key ( keys %{$self->{'__config__'}} ) {
		$self->{$key} = $self->{'__config__'}->{$key};
	}
	
	#Judge Primary Keys exists and OK
	$num_errors=0;
	#Alarm Ne
	if (! $self->{ALARM_NE}){
		LogMess("PERF_ALARM Initialisation: no ALARM_NE specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Alarm Object
	if (! $self->{ALARM_OBJECT}){
		LogMess("PERF_ALARM Initialisation: no ALARM_OBJECT specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Alarm OBJECT_CLASS
	if (! $self->{OBJECT_CLASS}){
		LogMess("PERF_ALARM Initialisation: no OBJECT_CLASS specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Alarm Data Date ALARM_DATA_DATE
	if (! $self->{ALARM_DATA_DATE}){
		LogMess("PERF_ALARM Initialisation: no ALARM_DATA_DATE specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Alarm Data Time ALARM_DATA_TIME
	if (! $self->{ALARM_DATA_TIME}){
		LogMess("PERF_ALARM Initialisation: no ALARM_DATA_TIME specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Data File COLUMN_LIST
	if (! $self->{COLUMN_LIST}){
		LogMess("PERF_ALARM Initialisation: no COLUMN_LIST specified in rule!(UserConfig.pm)",1);
		$num_errors++;
	}
	#THRESHOLD_ALARM & BREAK_ALARM All no exists then error，至少设置一种告警
	if ( (!exists($self->{THRESHOLD_ALARM}) && !exists($self->{BREAK_ALARM})) &&
	     (! $self->{THRESHOLD_ALARM} && ! $self->{BREAK_ALARM})) {
		LogMess("PERF_ALARM Initialisation: must exist THRESHOLD_ALARM or BREAK_ALARM!(UserConfig.pm)",1);
		$num_errors++;
	}
	#Judge SOCKET 
	if( exists($self->{SOCKET_SERVER_IP}) && $self->{SOCKET_SERVER_IP} ) {
		if( !exists($self->{SOCKET_PORT}) || !$self->{SOCKET_PORT} ) {
			LogMess('PERF_ALARM Initialisation: SOCKET_PORT_IP must be supplied when SOCKET_SERVER is specified', 1);
			$num_errors++;
		}
	}

	if( exists($self->{SOCKET_PORT}) && $self->{SOCKET_PORT} ) {
		if( !exists($self->{SOCKET_SERVER_IP}) || !$self->{SOCKET_SERVER_IP} ) {
			LogMess('PERF_ALARM Initialisation: SOCKET_SERVER must be supplied when SOCKET_PORT is specified', 1);
			$num_errors++;
		}
	}
	#Judge :when LIF or PIF Produce,must OUTPUT_BLOCK_NAME setup
	if ( exists($self->{PRODUCE_PIF}) && $self->{PRODUCE_PIF}) {
		if ((uc($self->{PRODUCE_PIF}) eq "TRUE") && 
		    (!exists($self->{OUTPUT_BLOCK_NAME}) || !$self->{OUTPUT_BLOCK_NAME} )) {
		     	LogMess('PERF_ALARM Initialisation:when PRODUCE_PIF setup True,OUTPUT_BLOCK_NAME and FILENAME_COLUMN must setup',1);
		     	$num_errors++;
		}
	}
	if ( exists($self->{PRODUCE_LIF}) && $self->{PRODUCE_LIF}) {
		if ((uc($self->{PRODUCE_PIF}) eq "TRUE") && 
		    (!exists($self->{OUTPUT_BLOCK_NAME}) || !$self->{OUTPUT_BLOCK_NAME} )) {
		     	LogMess('PERF_ALARM Initialisation:when PRODUCE_LIF setup True,OUTPUT_BLOCK_NAME and FILENAME_COLUMN must setup',1);
		     	$num_errors++;
		}
	}
	#判断设置的门限告警信息
	if (exists($self->{THRESHOLD_ALARM}) && $self->{THRESHOLD_ALARM}) {
		@thresholdAlarm=@{$self->{THRESHOLD_ALARM}};
		foreach $sKey (@thresholdAlarm) {
			$sTemp="THRESHOLD_CONFIG_${sKey}";
			if (!exists($self->{$sTemp}) || !$self->{$sTemp} || ref($self->{$sTemp} ne "HASH")) {
				LogMess("PERF_ALARM Initialisation:$sTemp no exists in UserConfig.pm or setup error!",1);
				$num_errors++;
			} else {
				$hSelf=$self->{$sTemp};
				if (!exists($hSelf->{ALARM_TITLE}) || !$hSelf->{ALARM_TITLE}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_TITLE $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{ALARM_TEXT}) || !$hSelf->{ALARM_TEXT}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_TEXT $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{ALARM_VAL}) || !$hSelf->{ALARM_VAL}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_VAL $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				foreach $subKey (keys %$hSelf) {
					next if ((uc($subKey) eq "ALARM_TITLE") || (uc($subKey) eq "ALARM_TEXT") || (uc($subKey) eq "ALARM_VAL"));
					
					$thSelf=$hSelf->{$subKey};
					if (!exists($thSelf->{THRESHOLD_TIME}) || !$thSelf->{THRESHOLD_TIME}) {
					LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_TIME Setup",1);
						$num_errors++;
					}
					if (!exists($thSelf->{THRESHOLD_EXPRESSION}) || !$thSelf->{THRESHOLD_EXPRESSION}) {
						LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_EXPRESSION Setup",1);
						$num_errors++;
					}
					
					if (!exists($thSelf->{THRESHOLD_EXPRESSION_INFO}) || !$thSelf->{THRESHOLD_EXPRESSION_INFO}) {
						LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_EXPRESSION_INFO Setup",1);
						$num_errors++;
					}
				}	
			}
		}
	}
	#判断设置的突变告警信息
	if (exists($self->{BREAK_ALARM}) && $self->{BREAK_ALARM}) {
		@breakAlarm=@{$self->{BREAK_ALARM}};
		foreach $sKey (@breakAlarm) {
			$sTemp="BREAK_CONFIG_${sKey}";
			if (!exists($self->{$sTemp}) || !$self->{$sTemp} || ref($self->{$sTemp} ne "HASH")) {
				LogMess("PERF_ALARM Initialisation:$sTemp no exists in UserConfig.pm or setup error!",1);
				$num_errors++;
			} else {
				$hSelf=$self->{$sTemp};
				if (!exists($hSelf->{ALARM_TITLE}) || !$hSelf->{ALARM_TITLE}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_TITLE $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{ALARM_TEXT}) || !$hSelf->{ALARM_TEXT}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_TEXT $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{ALARM_VAL}) || !$hSelf->{ALARM_VAL}) {
					LogMess("PERF_ALARM Initialisation:Need Setup AlARM_VAL $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{BREAK_FILENAME}) || !$hSelf->{BREAK_FILENAME}) {
					LogMess("PERF_ALARM Initialisation:Need Setup BREAK_FILENAME $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
				if (!exists($hSelf->{BREAK_COL_LIST}) || !$hSelf->{BREAK_COL_LIST}) {
					LogMess("PERF_ALARM Initialisation:Need Setup BREAK_COL_LIST $sTemp in UserConfig.pm",1);
					$num_errors++;
				}
			
				foreach $subKey (keys %$hSelf) {
					next if ((uc($subKey) eq "ALARM_TITLE") || (uc($subKey) eq "ALARM_TEXT") || (uc($subKey) eq "ALARM_VAL") || (uc($subKey) eq "BREAK_FILENAME") || (uc($subKey) eq "BREAK_COL_LIST"));
					
					$thSelf=$hSelf->{$subKey};
					if (!exists($thSelf->{THRESHOLD_TIME}) || !$thSelf->{THRESHOLD_TIME}) {
						LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_TIME Setup",1);
						$num_errors++;
					}
					if (!exists($thSelf->{THRESHOLD_EXPRESSION}) || !$thSelf->{THRESHOLD_EXPRESSION}) {
						LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_EXPRESSION Setup",1);
						$num_errors++;
					}
					if (!exists($thSelf->{THRESHOLD_EXPRESSION_INFO}) || !$thSelf->{THRESHOLD_EXPRESSION_INFO}) {
						LogMess("PERF_ALARM Initialisation:${subKey} Need THRESHOLD_EXPRESSION_INFO Setup",1);
						$num_errors++;
					}
					
				}					
			}
		}
	}
	return $num_errors;			
}

# Object Methods
sub process {
	my ($self, $in_dir, $in_files, $out_dir) = @_;
	# Declaring variables local to this subroutine
	my ($num_succ_processed, @files, $rule_num);
	my ($pattern, %files_h);
	my (@break_alarm,$sKey,$siKey);

	$num_succ_processed = 0;
	$rule_num++;

	# Get the list of files that are to be processed by this rule.  But first
	# checking if they have provided a list of regular expressions or just
	# one.
	if( ref($self->{INPUT_FILE_DESCRIPTION}) eq "ARRAY" ) {
		foreach $pattern ( @{$self->{INPUT_FILE_DESCRIPTION}} ) {
			push @files, grep /$pattern/, @$in_files;
		}
	}
	else {
		@files = grep /$self->{INPUT_FILE_DESCRIPTION}/, @$in_files;
	}
	# Removing duplicates from the list of files
	@files_h{@files} = ();
	#读入历史数据
	if (exists($self->{BREAK_ALARM}) && $self->{BREAK_ALARM}) {
		@break_alarm=@{$self->{BREAK_ALARM}};
		foreach $siKey (@break_alarm) {
			$sKey="BREAK_CONFIG_${siKey}";
			$self->{$sKey}->{HIS_DATA}=readInfo(%$self->{$sKey});
		}
	}
	# Loop over the list of files to process for this PERF_ALARM rule
	foreach ( keys %files_h ) {
		if( $self->process_a_file($in_dir."/".$_, $out_dir) != 0 ) {
			AudMess("ERROR: processing '$_'");
		}
		$num_succ_processed++;
	}

	return $num_succ_processed;
}

sub process_a_file() {
	my ($self, $in_file, $out_dir) = @_;

	# Declaring variable local to this subroutine
	my ($i_obj, $o_obj, $blk_name, $out_file, $new_pif, $dir);
	my (@names, @values,@aTemp,$sKey,%h_i);
	my (%hData,@baseName,$ErrorMess);
	
	#初始化变量
	$i_obj=-1;
	$o_obj=-1;
	%hData=();
	@baseName=qw(ALARM_NE ALARM_OBJECT OBJECT_CLASS PRODUCE_CAUSE ALARM_DATA_DATE 
	             ALARM_DATA_TIME ALARM_DATA_TIME_START ALARM_DATA_TIME_END TREND_INFO 
	             ALARM_TYPE);
	
	#
	AudMess("Processing '${in_file}'");
	# If the OUTPUT_DIR is specified set the output directory
	# to be OUTPUT_DIR, rather than the one specified on the 
	# command line.  first check that it exists and is writable etc.
	# Otherwise, log and error message and exit this rule.
	if( exists($self->{OUTPUT_DIR}) && $self->{OUTPUT_DIR} ) {
		$dir = $self->{OUTPUT_DIR};
		if( -d $dir && -w $dir && -r $dir && -x $dir ) {
			LogMess("For this rule, output directory set to '".$dir."'", 3);
			$out_dir = $self->{OUTPUT_DIR};
		} else {
			LogMess("ERROR: Output directory '".$dir."' has incorrect permissions", 1);
			return -1;
		}
	}

	$i_obj = PIF_Handler->New();
	$i_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $i_obj->Read_Names(\@names);
	$i_obj->Read_Values(\@values);
 	@h_i{@names} = @values;
 	# Creating the output filename
	$out_file = basename($in_file);
	$out_file =~ s/\.pif$/-#-$self->{OUTPUT_BLOCK_NAME}-#-A.pt/;

	$new_pif = dirname($in_file)."/".$out_file;

	if( $self->{PRODUCE_PIF} ) {
		$i_obj->Open_PIF_Write($new_pif);
		$i_obj->PIF_Write("HEADER", \%h_i);
	}

	AudMess("Output file: '${out_file}'");

	if( $self->{PRODUCE_LIF} ) {
		$o_obj = LIF_Writer->New();
		$o_obj->Open($out_dir."/".$out_file);

		$o_obj->Open_Block();
		$o_obj->Block_Info(\%h_i);
		$o_obj->WriteToFile();
	}
	# Looping over all the data blocks in the file
	while( $blk_name = $i_obj->Read_Names(\@names) ) {
		# Setting the output block name to be the blk_name from
		# the PIF file if an output block name is not specified
		# in the UserConfig.pm
		if( exists($self->{"OUTPUT_BLOCK_NAME"}) &&
			$self->{"OUTPUT_BLOCK_NAME"}) {
			$blk_name = $self->{"OUTPUT_BLOCK_NAME"};
		}
		#判断设置的几个关键字段是否存在文件中，如果不存在则提示错误并返回不处理
		#判断内容有ALARM_NE/ALARM_OBJECT/ALARM_DATA_DATE/ALARM_DATA_TIME 以及 COLUMN_LIST的内容
		%hData=%h_i;
		@hData{@names}=();
		@aTemp=keys %hData;
		$ErrorMess="";
		$ErrorMess=$ErrorMess."$self->{'ALARM_NE'}--Column Name not exists in ${in_file}\n" if (!exists($hData{$self->{"ALARM_NE"}}));
		$ErrorMess=$ErrorMess."$self->{'ALARM_OBJECT'}--Column Name not exists in ${in_file}\n" if (!exists($hData{$self->{"ALARM_OBJECT"}}));		
		$ErrorMess=$ErrorMess."$self->{'ALARM_DATA_DATE'}--Column Name not exists in ${in_file}\n" if (!exists($hData{$self->{"ALARM_DATA_DATE"}}));
		$ErrorMess=$ErrorMess."$self->{'ALARM_DATA_TIME'}--Column Name not exists in ${in_file}\n" if (!exists($hData{$self->{"ALARM_DATA_TIME"}}));	
		@aTemp=@{$self->{"COLUMN_LIST"}};
		foreach $sKey (@aTemp) {
			$ErrorMess=$ErrorMess."${sKey}--Column Name not exists in ${in_file}\n" if (!exists($hData{$sKey}));	
		}
		if (length($ErrorMess)>0) {
			LogMess("PERF_ALARM:-1-Data File No Exists\n ${ErrorMess}",1);
			return -1;
		}
		# Looping over all the Data lines in this block
		while ( $i_obj->Read_Values(\@values) ) {
			%hData=();
			#头信息附加到数据行上
			%hData=%h_i;
			#存储数值
			@hData{@names}=@values;
			#判断是否属于告警数据范围内	
			next if (($hData{$self->{"ALARM_DATA_TIME"}} lt $self->{"ALARM_DATA_TIME_START"}) || ($hData{$self->{"ALARM_DATA_TIME"}} gt $self->{"ALARM_DATA_TIME_END"}));		
			#门限告警
			ThresholdAlarm($i_obj,$o_obj,$blk_name,$self,\%hData,\@baseName) if (exists($self->{"THRESHOLD_ALARM"}) && $self->{"THRESHOLD_ALARM"});
			#突变告警
			BreakAlarm($i_obj,$o_obj,$blk_name,$self,\%hData,\@baseName) if (exists($self->{"BREAK_ALARM"}) && $self->{"BREAK_ALARM"});
		}
	}

	# Closing the Output file and renaming the completed output file to
	# end in the appropriate extension
	if( $self->{PRODUCE_LIF} ) {
		$o_obj->Close();
		store_processed_file($self->{keep_files}, 0, $self->{debug}, rename_completed_file(".pt", ".lif", $out_dir."/".$out_file));
	}
	if( $self->{PRODUCE_PIF} ) {
		$i_obj->Close_PIF_Write();
		rename_completed_file(".pt", ".pif", $new_pif);
	}

	return 0;
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
	return $myString;
}
##################################################################
# Subroutine name:  VarReplaceVal
#
# Description:      change vars to vals
#
# Arguments:        $sExpression--待处理的字符串；$self--配置信息句柄;$hData--数据句柄
#			
# Returns:          $myString--处理后的标量
#
#
sub VarReplaceVal {
	my ($sExpression,$self,$hData)=@_;
	
	my (@aCol,$iCount,$sKey);
	
	$sExpression=uc($sExpression);
	@aCol=@{$self->{"COLUMN_LIST"}};
	foreach $sKey (@aCol) {
		if (exists($hData->{$sKey})) {
			$sExpression =~ s/$sKey/$hData->{$sKey}/ig ;
		} else {
			LogMess("PERF_ALARM:-2-Function-VarReplaceVal no found ${sKey}",1);
			return "";
		}
	}
	return $sExpression;
}	
##################################################################
# Subroutine name:  VarReplaceFileVal
#
# Description:      change vars to vals
#
# Arguments:        $sExpression--待处理的字符串；$self--配置信息句柄;$hData--数据句柄
#			
# Returns:          $myString--处理后的标量
#
#
sub VarReplaceFileVal {
	my ($sExpression,$self,$hData)=@_;
	
	my (@aCol,$iCount,$sKey);
	
	$sExpression=uc($sExpression);
	@aCol=@{$self->{"BREAK_COL_LIST"}};
	foreach $sKey (@aCol) {
		if (exists($hData->{$sKey})) {
			$sExpression =~ s/OC_$sKey/$hData->{$sKey}/ig ;
		} else {
			LogMess("PERF_ALARM:-3-Function-VarReplaceFileVal no found ${sKey}",1);
			return "";
		}
	}
	return $sExpression;
}	
##################################################################
# Subroutine name:  ThresholdAlarm
#
# Description:      Produce Threshold Alarm
#
# Arguments:        i_obj pif 文件句柄
#                   o_obj lif 文件句柄
#                   blk_name  块名
#                   self      配置信息句柄
#                   hData     当前行数据句柄
#                   baseName  输出信息中的基本信息集合
#			
# Returns:          无。产生告警信息到端口
#
#
sub ThresholdAlarm {
	my ($i_obj,$o_obj,$blk_name,$self,$hData,$baseName)=@_;
	
	my (%hAlarm,$sThKey,$sTemp,%hThreshold,$subSelf);
	my (@infoAlarm,$siKey,$sKey,%hThreInfo,@aTemp,$sDiv);
	
	@infoAlarm=@{$self->{"THRESHOLD_ALARM"}};
	foreach $siKey (@infoAlarm) {
		#清空上次的赋值
		%hAlarm=();
		$sThKey="THRESHOLD_CONFIG_${siKey}";
		#给本次门限告警赋值
		@hAlarm{@$baseName}=@$self{@$baseName};
		$subSelf=$self->{$sThKey};
		$hAlarm{"ALARM_TITLE"}=$subSelf->{"ALARM_TITLE"};
		$hAlarm{"ALARM_TEXT"}=$subSelf->{"ALARM_TEXT"};
		$hAlarm{"ALARM_NE"}=$hData->{$self->{"ALARM_NE"}};
		$hAlarm{"ALARM_OBJECT"}=$hData->{$self->{"ALARM_OBJECT"}};
		$hAlarm{"ALARM_DATA_TIME"}=TimeFormat($hData->{$self->{"ALARM_DATA_TIME"}});
		$hAlarm{"ALARM_DATA_DATE"}=DateFormat($hData->{$self->{"ALARM_DATA_DATE"}});

		#替换并求值
		$sTemp=VarReplaceVal($subSelf->{"ALARM_VAL"},$self,$hData);
		next if ($sTemp eq "");
		if (index($sTemp,"/")>0) {
				@aTemp=split("/",$sTemp);
				$sDiv=$aTemp[1];
				$sDiv=substr($sDiv,1) if (index($sDiv,"(") == 0);
				$sDiv=substr($sDiv,0,index($sDiv,")")) if (index($sDiv,")"));
				LogMess("PERF_ALARM:-4-1-temp=$sTemp-div=$sDiv",4);
				if (eval($sDiv) != 0) {
					$hAlarm{"ALARM_VAL"}=eval($sTemp);
					if ($@ ne "") {
						LogMess("PERF_ALARM:-4-$sTemp error ,error info $@",1);
						next;
					}
				} else {
					$hAlarm{"ALARM_VAL"}=0;
				}
		} else {
			$hAlarm{"ALARM_VAL"}=eval($sTemp);
			if ($@ ne "") {
				LogMess("PERF_ALARM:-4-$sTemp error ,error info $@",1);
				next;
			}
		}
		#判断门限并输出信息
		foreach $sKey (keys %$subSelf) {
			#如果不是门限设置则跳过
			next if ((uc($sKey) eq "ALARM_TITLE") || (uc($sKey) eq "ALARM_TEXT") || (uc($sKey) eq "ALARM_VAL"));
			#读取设置的门限
			@{hThreshold{@{$subSelf->{$sKey}->{"THRESHOLD_TIME"}}}}=@{$subSelf->{$sKey}->{"THRESHOLD_EXPRESSION"}};
			@{hThreInfo{@{$subSelf->{$sKey}->{"THRESHOLD_TIME"}}}}=@{$subSelf->{$sKey}->{"THRESHOLD_EXPRESSION_INFO"}};
			if (exists($hThreshold{$hData->{$self->{"ALARM_DATA_TIME"}}})) {
				$sTemp=$hThreshold{$hData->{$self->{"ALARM_DATA_TIME"}}};
				$hAlarm{"ALARM_THRE_INFO"}=$hThreInfo{$hData->{$self->{"ALARM_DATA_TIME"}}};
			} else {
				$sTemp=$hThreshold{"ALL"};
				$hAlarm{"ALARM_THRE_INFO"}=$hThreInfo{"ALL"};
			}
			$hAlarm{"ALARM_EXPRESSION"}=$sTemp;
			#判断是否满足门限，产生告警
			$sTemp=VarReplaceVal($sTemp,$self,$hData);
			LogMess("PERF_ALARM:-5-expression is -$sTemp-",4);
			$hAlarm{"ALARM_EXPRESSION_VAL"}=$sTemp;
			next if ($sTemp eq "");
			$hAlarm{"ALARM_GRADE"}=$sKey;
			if (index($sTemp,"/")>0) {
				@aTemp=split("/",$sTemp);
				$sDiv=$aTemp[1];
				$sDiv=substr($sDiv,1) if (index($sDiv,"(") == 0);
				$sDiv=substr($sDiv,0,index($sDiv,")")) if (index($sDiv,")"));
				LogMess("PERF_ALARM:-5-1-expression is $sTemp,judge is $sDiv",4);
				if (eval($sDiv) != 0) {
					if (eval($sTemp)) {
						WriteAlarm($i_obj,$o_obj,$blk_name,\%hAlarm,$self);
						last;
					}
				}
			} else {
				if (eval($sTemp)) {
					WriteAlarm($i_obj,$o_obj,$blk_name,\%hAlarm,$self);
					last;
				}
			}
				
		}
	}
}
##################################################################
# Subroutine name:  BreakAlarm
#
# Description:      Produce Break Alarm
#
# Arguments:        i_obj pif 文件句柄
#                   o_obj lif 文件句柄
#                   blk_name  块名
#                   self      配置信息句柄
#                   hData     当前行数据句柄
#                   baseName  输出信息中的基本信息集合
#			
# Returns:          无。产生告警信息到端口
#
#
sub BreakAlarm {
	my ($i_obj,$o_obj,$blk_name,$self,$hData,$baseName)=@_;
	
	my (%hAlarm,$sThKey,$sTemp,%hThreshold,$subSelf);
	my (@infoAlarm,$siKey,$sTmp,%hThreInfo,$sKey);
	
	my (@aTemp);
	@infoAlarm=@{$self->{"BREAK_ALARM"}};
	foreach $siKey (@infoAlarm) {
		#清空上次的赋值
		%hAlarm=();
		$sThKey="BREAK_CONFIG_${siKey}";
		$subSelf=$self->{$sThKey};
		#如果历史数据不完整，则此告警不做处理
		next if ($subSelf->{"HIS_DATA"} == -1);
		#给本次门限告警赋值
		@hAlarm{@$baseName}=@$self{@$baseName};
		$hAlarm{"ALARM_TITLE"}=$subSelf->{"ALARM_TITLE"};
		$hAlarm{"ALARM_TEXT"}=$subSelf->{"ALARM_TEXT"};
		$hAlarm{"ALARM_NE"}=$hData->{$self->{"ALARM_NE"}};
		$hAlarm{"ALARM_OBJECT"}=$hData->{$self->{"ALARM_OBJECT"}};
		$hAlarm{"ALARM_DATA_TIME"}=TimeFormat($hData->{$self->{"ALARM_DATA_TIME"}});
		$hAlarm{"ALARM_DATA_DATE"}=DateFormat($hData->{$self->{"ALARM_DATA_DATE"}});
		#替换并求值
		$sTemp=VarReplaceVal($subSelf->{"ALARM_VAL"},$self,$hData);
		$sTmp=join('-',trimSpace($hAlarm{"ALARM_NE"}),trimSpace($hAlarm{"ALARM_OBJECT"}),trimSpace($hAlarm{"ALARM_DATA_DATE"}),trimSpace($hAlarm{"ALARM_DATA_TIME"}));
		$sTemp=VarReplaceFileVal($sTemp,$subSelf,$subSelf->{HIS_DATA}->{$sTmp});
		next if ($sTemp eq "");
		$hAlarm{"ALARM_VAL"}=eval($sTemp);
		if ($@ ne "") {
			LogMess("PERF_ALARM:-6-$sTemp error ,error info $@",1);
			next;
		}
	
		#判断门限并输出信息
		foreach $sKey (keys %$subSelf) {
			#如果不是门限设置则跳过
			next if ((uc($sKey) eq "ALARM_TITLE") || (uc($sKey) eq "ALARM_TEXT") || (uc($sKey) eq "ALARM_VAL") || (uc($sKey) eq "BREAK_FILENAME") || (uc($sKey) eq "BREAK_COL_LIST") || (uc($sKey) eq "HIS_DATA"));
			#读取设置的门限
			@{hThreshold{@{$subSelf->{$sKey}->{"THRESHOLD_TIME"}}}}=@{$subSelf->{$sKey}->{"THRESHOLD_EXPRESSION"}};
			@{hThreInfo{@{$subSelf->{$sKey}->{"THRESHOLD_TIME"}}}}=@{$subSelf->{$sKey}->{"THRESHOLD_EXPRESSION_INFO"}};
			if (exists($hThreshold{$hData->{$self->{"ALARM_DATA_TIME"}}})) {
				$sTemp=$hThreshold{$hData->{$self->{"ALARM_DATA_TIME"}}};
				$hAlarm{"ALARM_THRE_INFO"}=$hThreInfo{$hData->{$self->{"ALARM_DATA_TIME"}}};
			} else {
				$sTemp=$hThreshold{ALL};
				$hAlarm{"ALARM_THRE_INFO"}=$hThreInfo{"ALL"};
			}
			$hAlarm{"ALARM_EXPRESSION"}=$sTemp;
			#判断是否满足门限，产生告警
			$sTemp=VarReplaceVal($sTemp,$self,$hData);
			#替换历史数据
			#历史数据不存在则跳过
			$sTmp=join('-',trimSpace($hAlarm{"ALARM_NE"}),trimSpace($hAlarm{"ALARM_OBJECT"}),trimSpace($hAlarm{"ALARM_DATA_DATE"}),trimSpace($hAlarm{"ALARM_DATA_TIME"}));
			LogMess("--Data Key--$sTmp--",5);
			@aTemp=keys %{$subSelf->{HIS_DATA}};
			LogMess("---his_data---@aTemp--",5);			
			next if (!exists($subSelf->{HIS_DATA}->{$sTmp}));
			$sTemp=VarReplaceFileVal($sTemp,$subSelf,$subSelf->{HIS_DATA}->{$sTmp});
			next if ($sTemp eq "");
			$hAlarm{"ALARM_GRADE"}=$sKey;
			$hAlarm{"ALARM_EXPRESSION_VAL"}=$sTemp;
			@aTemp=values %hAlarm;
			LogMess("---hAlarm---@aTemp--",5);
			WriteAlarm($i_obj,$o_obj,$blk_name,\%hAlarm,$self) if (eval($sTemp));
		}
	}
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
sub connect_server {
	my ($self)=@_;
	my ($alarmsocket);
	my $hostip=$self->{"SOCKET_SERVER_IP"};
	my $hostport=$self->{"SOCKET_PORT"};
	#创建要发送告警信息的连接
	$alarmsocket=IO::Socket::INET->new(
	            PeerAddr=>$hostip,
				PeerPort=>$hostport,
				Proto =>'udp',
				Type =>SOCK_DGRAM,
				Timeout=>20,
				);
	LogMess("alarmsocket:$alarmsocket",1);
	LogMess("PERF_ALARM:-7-Function-connect_server:Create Socket Fail!",1) if ( $alarmsocket<=0 );
	return $alarmsocket;
}
#************************************************
#	功能：	
#		得到当前系统时间
#	输入：
#	返回：
#		当前系统时间 YYYY-mm-dd HH:MM:SS
#	例如：2005-07-21 18:30:00
#************************************************
sub nowtime {
	my @list=localtime;
        my %MONTH_NAMES = ( '1'=>'Jan','2'=>'Feb','3'=>'Mar',
					'4'=>"Apr",'5'=>'May', '6'=>'Jun',
					'7'=>'Jul','8'=>'Aug', '9'=>'Sep',
					'10'=>'Oct','11'=>'Nov', '12'=>'Dec');
						
	$list[5]+=1900;
	$list[4]+=1;
	my $result_time=sprintf("%02d:%02d %02d-%03s-%04d",$list[2],$list[1],$list[3],$MONTH_NAMES{int($list[4])},$list[5]);

	return $result_time;
}
##################################################################
# Subroutine name:  WriteAlarm
#
# Description:      Write Alarm Info to Port
#
# Arguments:        i_obj pif 文件句柄
#                   o_obj lif 文件句柄
#                   blk_name  块名
#                   self      配置信息句柄
#                   sAlarm    告警数据句柄
#                   self      配置信息句柄
#			
# Returns:          失败-- -1 ，成功0
#
#
sub WriteAlarm {
	my ($i_obj,$o_obj,$blk_name,$sAlarm,$self)=@_;

	my ($alarmSocket,$sendAlarmMess,$sKey,%MONTH,$CreateDate,@list,$now_time);
	#Writing the Block into the LIF file
	$o_obj->Create_Block($blk_name, $sAlarm) if $self->{PRODUCE_LIF};
	# Writing the block into the new PIF file
	$i_obj->PIF_Write($blk_name, $sAlarm) if $self->{PRODUCE_PIF};
	
	%MONTH= ( 'Jan'=>'01','Feb'=>'02','Mar'=>'03',
					'Apr'=>"04",'May'=>'05', 'Jun'=>'06',
					'Jul'=>'07','Aug'=>'08', 'Sep'=>'09',
					'Oct'=>'10','Nov'=>'11', 'Dec'=>'12');
		
		#将2013-Dec-12 改成 2013-12-12		
		if ($sAlarm->{"ALARM_DATA_DATE"} =~ m/(\d\d\d\d)\-(\D\D\D)\-(\d\d)/) 
		{
			$CreateDate=join('-',$1,$MONTH{$2},$3);
		}
		
	if (exists($self->{"SOCKET_SERVER_IP"}) && $self->{"SOCKET_SERVER_IP"}) {
		$alarmSocket=connect_server($self);
		return -1 if ($alarmSocket<=0);
		@list=localtime;
		$now_time=sprintf("%04d-%02d-%02d %02d:%02d:%02d",$list[5]+1900,$list[4]+1,$list[3],$list[2],$list[1],$list[0]); 
		$sAlarm->{"ALARM_SEND_TIME"}=$now_time;

		$sendAlarmMess = join(';',$sAlarm->{"OBJECT_CLASS"},$sAlarm->{"ALARM_NE"},$sAlarm->{"ALARM_OBJECT"},$sAlarm->{"ALARM_TYPE"},trimSpace($CreateDate).' '.$sAlarm->{"ALARM_DATA_TIME"} . ':00',
		                          $sAlarm->{"PRODUCE_CAUSE"},$sAlarm->{"ALARM_TITLE"},$sAlarm->{"ALARM_GRADE"},$sAlarm->{"TREND_INFO"},$sAlarm->{"ALARM_THRE_INFO"},$$,'',
		                          $sAlarm->{"ALARM_EXPRESSION"},$sAlarm->{"ALARM_VAL"},$sAlarm->{"ALARM_TEXT"},$sAlarm->{"ALARM_SEND_TIME"});
              
		#把描述中的值进行替换
		foreach $sKey (keys %{$sAlarm}) {
			$sendAlarmMess =~ s/{$sKey}/$sAlarm->{$sKey}/ig;
		}
		LogMess("PERF_ALARM:-8-alarm info are $sendAlarmMess",4);
		#创建失败则返回
		if ( $sendAlarmMess ) {
			if ( ! $alarmSocket->printf("$sendAlarmMess\n") ) {
				LogMess("PERF_ALARM:-9-Function-WriteAlarm:Write Alarm Message to SERVER-PORT Fail",1);
				return -1;
			}
		}
	}
	
	if (exists($self->{"NPR_ALARM"}) && $self->{"NPR_ALARM"}  eq "TRUE") {
		$sAlarm->{"ALARM_SEND_TIME"}=nowtime();
		
		$sendAlarmMess="/metrica/npr/bin/npralarm -target cheelooTCP -objectClass \"".$sAlarm->{'OBJECT_CLASS'}."\" -objectName \"".$sAlarm->{'ALARM_NE'}.'"';
		$sendAlarmMess=$sendAlarmMess." -date ".$sAlarm->{'ALARM_DATA_DATE'}." -time \"".$sAlarm->{'ALARM_DATA_TIME'}."\" -cause \"".$sAlarm->{'PRODUCE_CAUSE'}.'"';
 		$sendAlarmMess=$sendAlarmMess." -name \"".$sAlarm->{'ALARM_TITLE'}."\" -severity \"".$sAlarm->{'ALARM_GRADE'}."\" -text \"".$sAlarm->{'ALARM_TEXT'}.'"';
 		$sendAlarmMess=$sendAlarmMess." -trend \"".$sAlarm->{'TREND_INFO'}."\" -pred \"".$sAlarm->{'ALARM_THRE_INFO'}."\" -colname \"".$sAlarm->{'ALARM_EXPRESSION'}.'"';
		$sendAlarmMess=$sendAlarmMess." -colval ".$sAlarm->{'ALARM_VAL'};

		#把描述中的值进行替换
		foreach $sKey (keys %{$sAlarm}) {
			$sendAlarmMess =~ s/{$sKey}/$sAlarm->{$sKey}/ig;
		}
     	        
      		if (system($sendAlarmMess)) {
      			LogMess("PERF_ALARM:-10-Use npralarm Send Alarm fail",1);
      			return -1;
      		}    
	}
	return 0;
}
##################################################################
# Subroutine name:  readInfo
#
# Description:      Read InfoFile History Data to Hash
#
# Arguments:        self    此告警信息的配置句柄
#			
# Returns:          失败-- -1 ，成功0
#
#
sub readInfo {
	my ($self)=@_;
	
	my (@aTemp,@aLine,$iCount,@repCol,$sKey);
	my (@repdCol,$infoFile,%bamInfo);
	my ($line,$jCount,$recKey,$sTemp);
	my ($LineNum,@colName,@colVal,$ErrorMess);

	#因为这几个变量在load_config部分做了判断，所以此处不再判断是否存在
	#数据文件的格式 
	#告警网元!告警对象!日期!时间!列名1!列名2!列名3
	#数值行
	#其中前4列固定，不做列名称的判断，从第4列开始存储数据
	#数据形式为$self->{告警设置项}->{NE-OBJECT-DATE-TIME}->{列名}
	#此处返回{NE-OBJECT-DATE-TIME}->{列名}的地址赋值给$self->{告警设置项}->{HIS_DATA}
	#访问时$his_data=$self->{告警设置项}->{HIS_DATA},$his_data->{NE-OBJECT-DATE-TIME}->{列名}
	$infoFile=$self->{'BREAK_FILENAME'};
	%bamInfo=();
	$LineNum=1;
	$recKey={};
	if (-e $infoFile) {
		if (open(inFile,"${infoFile}")) {
			while (defined($line=<inFile>)) {
				chomp($line);
				$line=uc($line);
				@aLine=split('!',$line);
				if ($#aLine > 3) {
					#列名
					if ($LineNum == 1) {
						@colName=@aLine;
						$LineNum=2;
						#判断数据是否都存在，如不存在则返回-1，突变告警不处理
						@$recKey{@colName}=();
						@aTemp=@{$self->{"BREAK_COL_LIST"}};
						foreach $sTemp (@aTemp) {
							$ErrorMess=$ErrorMess."column ${sTemp}-no exists in histroy data file" if (!exists($recKey->{$sTemp}));
						}
						
						if (length($ErrorMess)>0) {
							LogMess("PERF_ALARM:-11-Function-readInfo ${ErrorMess}",1);
							return -1;
						}						
					} else {
						$recKey={};
						$sKey=join('-',trimSpace($aLine[0]),trimSpace($aLine[1]),trimSpace(DateFormat($aLine[2])),trimSpace(TimeFormat($aLine[3])));
						$bamInfo{$sKey}=$recKey;
						@$recKey{@colName}=@aLine;
					}
				} else {
					LogMess("PERF_ALARM:-12-Can not find ${sKey}--${infoFile} Info",1);
				}
			}
			close inFile;
		} else {
			LogMess("PERF_ALARM:-13-Can not open ${infoFile},pls check UserConfig.pm-BREAK_FILENAME option",1);
			return -1;
		}
	} else {
		LogMess("PERF_ALARM:-14-filename ${infoFile} not exists",1);
		return -1;
	}
	return \%bamInfo;
}
###################################################################
##
##	格式一共有如下几种: 25/12/05 25Dec05 25-12-05
##      输出：25-Dec-2005，要求历史数据中的格式与输入此相同
##      注意：年份统一要求为4位
sub DateFormat {
	my ($oldDate)=@_;

        my %MONTH_NAMES = ( '1'=>'Jan','2'=>'Feb','3'=>'Mar',
					'4'=>"Apr",'5'=>'May', '6'=>'Jun',
					'7'=>'JUL','8'=>'Aug', '9'=>'Sep',
					'10'=>'Oct','11'=>'Nov', '12'=>'Dec');
	my ($newDate,$sYear);
	#PIF中数据日期格式已经转换为日/月/年的格式，为了与历史数据统一，此处进行日期格式的转化
	#把格式转化为dd-mm-yyyy的格式
	if ($oldDate =~ m/(\d\d)(\D\D\D)(\d\d.*)/ ) {
		$sYear=$3;
		$sYear="20${sYear}" if (length($sYear) == 2);
		$newDate=join('-',$sYear,$2,$1);		
	}	
	if ($oldDate =~ m/(\d\d)\/(\d\d)\/(\d\d.*)/) {
		$sYear=$3;
		$sYear="20${sYear}" if (length($sYear) == 2);
		$newDate=join('-',$1,$MONTH_NAMES{int($2)},$sYear);
	}
	if ($oldDate =~ m/(\d\d)\-(\d\d)\-(\d\d.*)/) {
		$sYear=$3;
		$sYear="20${sYear}" if (length($sYear) == 2);
		$newDate=join('-',$1,$MONTH_NAMES{int($2)},$sYear);
	}

	return $newDate;		
}	
########################################################################
##
## 把时间格式化为HH:MM的形式
##
##
sub TimeFormat {
	my ($oldTime)=@_;
	
	my ($newTime);
	$newTime=$oldTime;

	$newTime=substr($oldTime,0,5) if (length($oldTime)>5);
	
	return $newTime;
}	
1; # So the use or require succeeds
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

PERF_ALARM - A Perl extension that PERF_ALARMs counters across multiple
              records in a Parser Intermediate file.

=head1 SYNOPSIS

  use PERF_ALARM;

  $obj_id = PERF_ALARM->New();

  $obj_id->load_config( $keep_files, $debug, \%config )

  $obj_id->process( $in_dir, \@in_files, $out_dir )

=head1 DESCRIPTION

  There are three entry points to this object.  The first 'New' creates the
  ibject and stores the identifier in the scalar varaible '$objid'.  The second
  'load_config' allows the user to configure the object to run as they desire.
  The third 'process' goes through and processes the files in the input directory
  '$in_dir' as defined by the configuration information.  The output
  of the process is output into the directory '$out_dir'.

=head1 AUTHOR

B. Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
