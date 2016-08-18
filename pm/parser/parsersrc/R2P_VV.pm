#----------------------------------------------------------------
# @(#) SNMP R2P_VV.pm
#----------------------------------------------------------------
# This takes RAW SNMP CELL Files, and converts them to PIF file types.
#
# This program relies EngineConfig.pm Files.
# Follow:
# UDP-MIB::udpInDatagrams.0 = Counter32: 46385
#---------------------------------------------------------------
# written by Zhung on 2007-01-10
# update by lqzh on 2013-12-11  因修改文件名去掉CUSTOMID	
#----------------------------------------------------------------
# 增加对一个文件中有单行和多行数据的处理
#   written by zhung 2013-08-02
#-----------------------------------------------------------------

package R2P_VV;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use AudLog;
use File::Basename;
use SNMP_PUB;
use Data::Dumper;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '1.00';

################################################################################
# Subroutine name:  New()
#
# Description:      Object initialisation routine
#
# Arguments:        None
#
# Returns:          Object reference
#
sub New {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    # These variables should be set to true of false
    # depending on whether or not the desired type of output file
    # is wanted,bless 把 referent 变成object

    bless ($self, $class);
}

################################################################################
# Subroutine name:  load_config()
#
# Description:      Object configuration loading routine
#
# Arguments:        keep_input_dir(scalar) - indicating where to store input file 
#                                         once it has been processed (if defined). 
#                   debug (scalar) - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          0 for success,
#                   the number of errors found for failure
#
sub load_config {
    my $self = shift;
    ($self->{keep_input_dir}, $self->{debug}, $self->{'__config__'}) = @_;

    # Inserting all the configuration information into the object's records
    my ($key, $num_errors,%oidname,$pLine,@aTemp);
    my ($sKey,$sVal);
    foreach $key ( keys %{$self->{'__config__'}} ) {
        $self->{$key} = $self->{'__config__'}->{$key};
    }
    #print Dumper $self;
    $num_errors=0;

    # Now check for the mandatory configuration options specific to
	# this interface.
	#FileName Format
	if (! $self->{FILENAME_FORMAT}){
		LogMess("R2P_VV Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
#2013-12-11 因修改文件名去掉CUSTOMID	
#    if (! $self->{CUSTOMID}){
#		LogMess("R2P_VV Initialisation: no CUSTOMID specified in rule!",1);
#		$num_errors++;
#	}

	if (! $self->{EQUIPID}){
		LogMess("R2P_VV Initialisation: no EQUIPID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{BLOCKNAME}){
		LogMess("R2P_VV Initialisation: no BLOCKNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{STARTTIME}){
		LogMess("R2P_VV Initialisation: no STARTTIME specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{ENDTIME}){
		LogMess("R2P_VV Initialisation: no ENDTIME specified in rule!",1);
		$num_errors++;
	}
	if (! $self->{PERIOD}){
		LogMess("R2P_VV Initialisation: no PERIOD specified in rule!",1);
		$num_errors++;
	}

	#DataLine Format
	if (! $self->{LINE_FORMAT}){
		LogMess("R2P_VV Initialisation: no LINE_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
  if (! $self->{MIB_FILENAME}){
		LogMess("R2P_VV Initialisation: no MIB_FILENAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{COUNTER_NAME}){
		LogMess("R2P_VV Initialisation: no COUNTER_NAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{EQUIP_NO}){
		LogMess("R2P_VV Initialisation: no EQUIP_NO specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{COUNTER_TYPE}){
		LogMess("R2P_VV Initialisation: no COUNTER_TYPE specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{COUNTER_VALUE}){
		LogMess("R2P_VV Initialisation: no COUNTER_VALUE specified in rule!",1);
		$num_errors++;
	}
	
	if(exists $self->{OIDNAME_FILE} and $self->{OIDNAME_FILE}) {
		if (!exists $self->{REPLACE_RULE} || !$self->{REPLACE_RULE}) {
			LogMess('ERROR: REPLACE_RULE must be supplied when OIDNAME_FILE is specified', 1);
			$num_errors++;
		}
	}
	if(exists $self->{REPLACE_RULE} and $self->{REPLACE_RULE}) {
		if (!exists $self->{OIDNAME_FILE} || !$self->{OIDNAME_FILE}) {
			LogMess('ERROR: OIDNAME_FILE must be supplied when REPLACE_RULE is specified', 1);
			$num_errors++;
		}
	}
	#如果存在oid2name则读入到文件
	if(exists $self->{OIDNAME_FILE} and $self->{OIDNAME_FILE}) {
		open oFILE, $self->{OIDNAME_FILE} || LogMess("Can not open $self->{OID2NAME_FILE}",1);
		%oidname=();
		while (defined($pLine = <oFILE>)) {
			chomp($pLine);
			#跳过空行
			next if (trimSpace($pLine)=~m/^$/);
			@aTemp=split('\|',$pLine);
			$sKey=trimSpace($aTemp[0]);
			$sVal=trimSpace($aTemp[1]);
			$oidname{$sKey}=$sVal;
		}
		$self->{OIDNAME}=\%oidname;
	}
	
	#print Dumper $self;
  return $num_errors;
}

################################################################################
# Subroutine name:  process_file()
#
# Description:      Controls the processing of all the files that match the
#                   INPUT_FILE_DESCRIPTION field in the config information
#
# Arguments:        self (scalar) - a reference to a hash that contains all 
#                                   the configuration options for this process.
#                                   
#                   filenm (scalar) - the location and filename of the file to be 
#                                     processed. 
#
#					header (scalar) - filename and directory name components
#
# Returns:          (scalar) - successfull or not 
#----------------------------------------------------------------------------------------------------
# 如果需要取历史数据，则按照文件名为 customid-#-equipid-#-blockname-#-period
# 此文件第一行为此数据的结束时间yyyymmddhhmm，第二行为列名，以后各行为数据
# 按照equipno和列名定位,行数据以!分割。处理完成后把当前数据按照此格式和文件名覆盖到指定目录下
#----------------------------------------------------------------------------------------------------
sub process_file {
    my ($self, $filenm, $header) =@_;

    my ($NoPathFilenm,%fileInfo);
    my ($pLine,$MibFile,$CounterName,$EquipNo,$CounterType,$CounterValue);
    my (%hLineData,$LineLink,%hColName,$countExistFirst,%hRawData,%hRawLine);
    my ($hisData,$iInterval,$hisFileExist,$cValue,$hisD);
    my ($iTemp,%hCountColName,$sLeft,$sRight,$sTemp);
    my (%hRawZeroData,$sZeroKey,$sRawZeroKey,$iZeroEquip,$iRawZeroEquip);
    my ($sKey,$sAccu,@colName,$subKey,$subTemp,$iCount);
    my ($tjCol,$jsCol,$exprCol,@aJsCol,$sVar,$iVar,$sExpr,$sOk,$sDo);
    my ($lastCountName,$lastHash,$lastEquipNo,$iLine);

    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) {
#    	$fileInfo{CUSTOMID}=eval('$'.$self->{CUSTOMID}); 2013-12-11
    	$fileInfo{EQUIPID}=eval('$'.$self->{EQUIPID});
    	$fileInfo{BLOCKNAME}=eval('$'.$self->{BLOCKNAME});
    	$fileInfo{STARTTIME}=eval('$'.$self->{STARTTIME});
    	$fileInfo{ENDTIME}=eval('$'.$self->{ENDTIME});
    	$fileInfo{PERIOD}=eval('$'.$self->{PERIOD});
    } else {
    	LogMess("R2P_VV : Can not get Filename Information:${NoPathFilenm}.",1);
    	return -1;
    }
    #analyse data line
    #---- read RAW file, create output file ---------------
    AudMess("  R2P_VV: About to process $filenm");
    #如果是空文件则返回
    return 0 if (-z $filenm);
    #初始化标志数据
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
    $pLine="";
    %hLineData=();
    %hRawData=();
    %hRawZeroData=();
    %hColName=();
    $countExistFirst="YES";
    $iInterval=1;
    $hisFileExist="NO";
    #added by 2014-04-21 
    $lastCountName="";
    $lastHash="ZERO";
    $lastEquipNo=0;
 
    while (defined($pLine = <FILE>)) {
			chomp($pLine);
			#跳过空行
			next if (trimSpace($pLine)=~m/^$/);
			#部分值为分行的字符串，导致解析错误。解决方案为补充到上一行的值中。
			#SNMPv2-MIB::sysDescr.0 = STRING: H3C Comware Platform Software
			#COMWARE (R) Software Version 5.20, Release 3808
			#H3C Firewall SecPath F5000-C
			# sysDescr="H3C Comware Platform Software COMWARE (R) Software Version 5.20, Release 3808 H3C Firewall SecPath F5000-C"
			#print "$pLine\n";
			#判断并把OID替换为name
			if(exists $self->{OIDNAME} and $self->{OIDNAME}) {
				#REPLACE_RULE在EngineConfig中配置，左边为等号左侧的部分
				if ($pLine=~/$self->{REPLACE_RULE}/) {
					$sLeft=trimSpace($1);
					$pLine=~s/$sLeft/$self->{OIDNAME}->{$sLeft}/ig if (exists $self->{OIDNAME}->{$sLeft});
				}
			}
			#数据分割
			if ($pLine=~/$self->{LINE_FORMAT}/) {
				$MibFile=trimSpace(eval('$'.$self->{MIB_FILENAME}));
				$CounterName=trimSpace(uc(eval('$'.$self->{COUNTER_NAME})));
				$EquipNo=trimSpace(eval('$'.$self->{EQUIP_NO}));
				#如果变量号是空，则令序号为0 2013-08-01 by zhung
				$EquipNo=0 if (!defined($EquipNo) || (trimSpace($EquipNo) eq ""));
				$CounterType=trimSpace(uc(eval('$'.$self->{COUNTER_TYPE})));
				$CounterValue=trimSpace(eval('$'.$self->{COUNTER_VALUE}));
				#形如HOST-RESOURCES-TYPES::hrStorageFixedDisk的值进一步拆分出hrStorageFixedDisk
				$CounterValue=trimSpace($2) if ($CounterValue=~/^(.+)\:\:(\w+)$/);
#				AudMess("R2P_VV : DataLine information are MibFile:${MibFile} CName:${CounterName} EquipNo:${EquipNo} CType:${CounterType} CValue:${CounterValue}",5);
				$cValue=$CounterValue;
				#如果为字符串，避免值中间有空格，把空格用连字符‘-’代替，以免导致入库错误
				if ($CounterType=~/STRING/) {
					$cValue=$CounterValue;
					$cValue=~s/ /\_/g;
					#去掉字符串中的"
					$cValue=~s/\"//g;
				}
				#如果是累加方式，则需要减前面的数值，判断类型中包含COUNT
				if ($CounterType=~/COUNT/) {
					#历史数据，只有需要减的计数器才做历史存储
					$sTemp=join('-',$CounterName,$EquipNo);
					$hCountColName{$sTemp}=$cValue;
					#第一次处理时读入历史数据
					if ($countExistFirst eq "YES") {
						$countExistFirst="NO";
						#读取数据文件内容，并做计算，如果文件不存在，则此文件不做产出，只做基础数据使用
						$hisData=ReadHisData(\%fileInfo,$self);
						if ($hisData > 0) {
							$iInterval=HisInterval(\%fileInfo,$self);
							$hisFileExist="YES";
							#避免处理时出现基础数据晚于处理数据的情况
							if ($iInterval > 0) {
								$iTemp=0;
								$iTemp=$hisData->{$sTemp} if (exists $hisData->{$sTemp});
								$cValue=($CounterValue - $iTemp)/$iInterval;
								$cValue=0 if ($cValue < 0);
							}
						}
					} else {
						$iTemp=0;
						$iTemp=$hisData->{$sTemp} if (($hisFileExist eq "YES") && exists $hisData->{$sTemp});
						$cValue=($CounterValue - $iTemp)/$iInterval;
						$cValue=0 if ($cValue < 0);
					}
				}
				#存储数据,分单行和多行
				if ($EquipNo eq "0") {
						$hRawZeroData{$CounterName}=$cValue;
						$lastHash="ZERO";
				} else {
					$lastHash="MULT";
					#	$hRawData{$CounterName}->{$EquipNo}=$cValue;
					if (exists $hRawData{$CounterName}) {
						$hRawData{$CounterName}->{$EquipNo}=$cValue;
					} else {
						$hRawData{$CounterName}=();
						$hRawData{$CounterName}->{$EquipNo}=$cValue;
					}
				}
				$lastCountName=$CounterName;
				$lastEquipNo=$EquipNo;
			} else {
				#如果当前行没有‘=’出现，则认为是上一行的字符串折行了
				#如果计数器名字为空，则是第一行或还没有进行拆分，则直接跳过
				next if ($lastCountName eq ""); 
				#处理空格
				$pLine=~s/ /\_/g;
				#去掉字符串中的"
				$pLine=~s/\"//g;
				if ($lastHash eq "ZERO") {
					$hRawZeroData{$lastCountName}=$hRawZeroData{$lastCountName}."_".$pLine if (exists $hRawZeroData{$lastCountName});
				} else {
					$hRawData{$lastCountName}->{$lastEquipNo}=$hRawData{$lastCountName}->{$lastEquipNo}."_".$pLine if (exists $hRawData{$lastCountName});
				}
				LogMess("R2P_VV : format error--or--continue value last line.${pLine}.",2);
				next;
			}
    }
    close FILE;
 		#处理需要累加的数据，并放到单行的哈希数组中，作为对象的整体描述输出
 		if (exists $self->{ACCU_COLUMN}) {
 			$sAccu=$self->{ACCU_COLUMN};
 			foreach $sKey (keys %{$sAccu}) {
                                $iLine=0;
 				$CounterName=$sKey;
 				$pLine=$sAccu->{$sKey};
 				#需要累加的数据都在多行里面，单行的数据如果需要处理直接在loadmap中写四则运算就可以
 				@colName=split('\|',uc($pLine));
 				$tjCol="";
 				$jsCol="";
 				$exprCol="";
 				@aJsCol=();
 				$tjCol=trimSpace($colName[0]);#第一列是条件字段
 				$jsCol=trimSpace($colName[1]);#第二列是变量字段
 				$exprCol=trimSpace($colName[2]);#第二列是计算字段
 				@aJsCol=split(',',$jsCol);
 				next if (!exists $hRawData{$tjCol} and ($tjCol ne "ALL"));#如果条件不是ALL并且不存在则进入下一个循环
 				next if ($jsCol eq "");#如果变量为空则进入下一行
 				next if ($exprCol eq "");#如果表达式为空则进入下一行
 				if ($tjCol eq "ALL") {
 					#如果不设置条件，则把全部数据都累加
 					$iTemp=0;
 					$sVar=$aJsCol[0];
 					foreach $EquipNo (keys %{$hRawData{$sVar}}) {
 						$sExpr=$exprCol;
 						$sOk="YES";
 						$sDo="NO";
 						for ($iVar=0;$iVar<=$#aJsCol;$iVar++) {
  							if (exists $hRawData{$aJsCol[$iVar]}->{$EquipNo}) {
  								$sExpr=~s/$aJsCol[$iVar]/$hRawData{$aJsCol[$iVar]}->{$EquipNo}/ig;
  								$sDo="YES";
  							} else {
  								$sOk="NO";
  								last;
  							}
 						}
 						if (($sOk eq "YES") and ($sDo eq "YES")) {
                                                   $iTemp=$iTemp + eval($sExpr);
                                                   $iLine=$iLine+1;
						}
 					}
					$sTemp=join('_',$CounterName,'_Line');
					$hRawZeroData{$sTemp}=$iLine;
					$sTemp="";
					$iLine=0;
 					$hRawZeroData{$CounterName}=$iTemp;
 				} else {
 					$iTemp=0;
 					%hRawLine=();
 					#初始化变量
          foreach  $EquipNo (keys %{$hRawData{$tjCol}}) {
          	$hRawLine{$EquipNo}="NO";
          }
          foreach  $EquipNo (keys %{$hRawData{$tjCol}}) {
 						next if (exists $hRawLine{$EquipNo} and ($hRawLine{$EquipNo} eq 'OK'));#用过一次
 						$sTemp=$hRawData{$tjCol}->{$EquipNo};#分类值用来取后面的计算值
 						$hRawLine{$EquipNo}="OK";
 						$sOk="YES";
 						$sDo="NO";
 						$sExpr=$exprCol;
 						for ($iVar=0;$iVar<=$#aJsCol;$iVar++) {
 							if ($hRawData{$aJsCol[$iVar]}->{$EquipNo}) {
 								$sExpr=~s/$aJsCol[$iVar]/$hRawData{$aJsCol[$iVar]}->{$EquipNo}/ig;
 								$sDo="YES";
 							} else {
 								$sOk="NO";
 								last;
 							}
 						}
 						if (($sOk eq "YES") and ($sDo eq "YES")) {
							$iTemp=$iTemp + eval($sExpr);
							$iLine=$iLine+1;
						}
 						#从其他里面找与条件相同的项，如果相同则累加
 						foreach $subKey (keys %{$hRawData{$tjCol}}){
 							next if ($hRawLine{$subKey} eq 'OK');#只能计算一次
 							$subTemp=$hRawData{$tjCol}->{$subKey};
 							if ($sTemp eq $subTemp) {
 								$hRawLine{$subKey}="OK";#做用过的标记
 								$sOk="YES";
 								$sDo="NO";
		 						$sExpr=$exprCol;
		 						for ($iVar=0;$iVar<=$#aJsCol;$iVar++) {
		 							if ($hRawData{$aJsCol[$iVar]}->{$subKey}) {
		 								$sExpr=~s/$aJsCol[$iVar]/$hRawData{$aJsCol[$iVar]}->{$subKey}/ig;
		 								$sDo="YES";
		 							} else {
		 								$sOk="NO";
		 								last;
		 							}
		 						}
		 						if (($sOk eq "YES") and ($sDo eq "YES")) {
									$iTemp=$iTemp + eval($sExpr);
									$iLine=$iLine+1;
								}
 							}
 						}
 						$sTemp=join('_',$CounterName,$sTemp);
 						$hRawZeroData{$sTemp}=$iTemp;
 						$iTemp=0;
						$sTemp=join('_',$CounterName,'_Line');
						$hRawZeroData{$sTemp}=$iLine;
						$sTemp="";
						$iLine=0;
 					}
 				}
 			}
 		}
 
    #输出数据，基础数据文件和中间文件；如果原来无基础数据文件，则不输出中间文件，只产生基础数据文件
    OutHisData(\%fileInfo,\%hCountColName,$self);
    #如果不存在COUNTER累加型数据，或者存在累加型但有基础数据存在，则输出中间文件
    if (($countExistFirst eq "YES") || ($hisFileExist eq "YES")) {
    	 OutPifData(\%fileInfo,\%hRawZeroData,$fileInfo{BLOCKNAME},$self->{OUTPUT_DIR},1);
    	 #多行数据分别写成多个文件，blockname来自配置文件
    	 if (exists $self->{LINE_COUNTER}){
    	 	foreach $sKey (keys %{$self->{LINE_COUNTER}}) {
    	 		@colName=split('\|',uc($self->{LINE_COUNTER}->{$sKey}));
    	 		next if (@colName <1);#配置文件错误，没有可输出的列
    	 		%hRawLine=();#初始化
    	 		#形成输出数据
    	 		$hRawLine{COL_NAME}='EQUIP_NO'.'|'.uc($self->{LINE_COUNTER}->{$sKey});#列名
    	 		$CounterName=$colName[0];#取第一个列对应的索引值，作为输出的行数
    	 		foreach $subKey (keys %{$hRawData{$CounterName}}) {
    	 			$sTemp="$subKey";
	    	 		for ($iCount=0;$iCount<=$#colName;$iCount++) {
    	 				if (exists $hRawData{$colName[$iCount]}->{$subKey}) {
	    	 				$CounterValue=$hRawData{$colName[$iCount]}->{$subKey};
	    	 			} else {
	    	 				$CounterValue=0;
	    	 			}
    	 				$sTemp=$sTemp.'|'.$CounterValue;
	    	 		}
	    	 		$hRawLine{$subKey}=$sTemp;
    	 		}
    	 		OutPifData(\%fileInfo,\%hRawLine,$sKey,$self->{OUTPUT_DIR},2);
    	 	}
    	}
    }
  return 0;    
}
###########################################################################
# 名称：ReadHisData
# 描述：把历史数据读入hash数组
# 参数：组成customid-#-equipid-#-blockname-#-period为基础数据文件名称
# 返回：数据地址
###########################################################################
sub ReadHisData {
	my ($fileInfo,$self)=@_;
	
	my ($hisFile,$line,@aLine,$LineNum);
	my (%hisD,@colName,$recKey);
	
	#匹配成历史数据文件名称
#	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	if (-e $hisFile) {
		$LineNum=0;
		if (open(inFile,"${hisFile}")) {
			while (defined($line=<inFile>)) {
				chomp($line);
				$LineNum=$LineNum+1;
				#第一行是数据结束时间，跳过
				next if ($LineNum == 1);

				@aLine=split('\|',$line);
				$hisD{$aLine[0]}=$aLine[1];
			}
		} else {
			return -1;
		}
	} else {
		return -1;
	}
	
	return \%hisD;
}
###########################################################################
# 名称：HisInterval
# 描述：判断与上次数据的时间间隔为几个周期
# 参数：组成customid-#-equipid-#-blockname-#-period为基础数据文件名称
# 返回：间隔周期
###########################################################################
sub HisInterval {
	my ($fileInfo,$self)=@_;
	
	my ($iInterval,$hisFile,$line,$LineNum);
	
	$iInterval=1;
	$LineNum=0;
	#匹配成历史数据文件名称
#	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	if (-e $hisFile) {
		if (open(inFile,"${hisFile}")) {
			while (defined($line=<inFile>)) {
				chomp($line);
				$LineNum=$LineNum+1;
				$iInterval=DiffMinute($fileInfo->{ENDTIME},$line)/$fileInfo->{PERIOD} if ($LineNum == 1 );
				last;
			}
		}
	}
	$iInterval=1 if ($iInterval == 0);
	return $iInterval;				
}
###########################################################################
# 名称：OutHisData
# 描述：判断
# 参数：组成customid-#-equipid-#-blockname-#-period为基础数据文件名称
# 返回：无
###########################################################################
sub OutHisData {
	my ($fileInfo,$hData,$self)=@_;
	
	my ($hisFile,@aColName,$sKey,$iRet);
	#匹配成历史数据文件名称
#	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};	
	#每次写清空一下上次的文件
	$iRet=open(OUTFILE,">$hisFile");
	if ($iRet) {
		close outFile;
	} else {
		LogMess("R2P_VV:init_file --Can not open ${hisFile} to write",1);
	}
	#写结束时间
	write_scalar_data($hisFile,$fileInfo->{ENDTIME});
	#写数据
	foreach $sKey (keys %{$hData}) {
		write_scalar_data($hisFile,$sKey.'|'.$hData->{$sKey});
	}
}

###########################################################################
# 名称：OutPifData
# 描述：判断
# 参数：组成customid-#-equipid-#-blockname-#-starttime-#-endtime-#-period-#-I.pif为基础数据文件名称
# 返回：无
###########################################################################
sub OutPifData {
	my ($fileInfo,$rawData,$sBlockName,$outDir,$iMode)=@_;
	
	my ($pifFile,@aColName,$sKey);
	my ($sEquipId,$sStartDate,$sStartTime,$sEndDate,$sEndTime,$sPeriod);
	
#	$sCustomId=$fileInfo->{CUSTOMID};
	$sEquipId=$fileInfo->{EQUIPID};
	$sPeriod=$fileInfo->{PERIOD};
	#匹配成历史数据文件名称
#	$pifFile=$outDir.'/'.$sCustomId.'-#-'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';
	$pifFile=$outDir.'/'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';	
	$sStartDate=convert_date_snmp($fileInfo->{STARTTIME});
	$sStartTime=convert_time_snmp($fileInfo->{STARTTIME});
	$sEndDate=convert_date_snmp($fileInfo->{ENDTIME});
	$sEndTime=convert_time_snmp($fileInfo->{ENDTIME});
	
	#初始化
	init_file($pifFile);
	#写数据
#	write_scalar_data($pifFile,'CUSTOMID|EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
	write_scalar_data($pifFile,'EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
#	write_scalar_data($pifFile,"${sCustomId}|${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,"${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,'##END|HEADER');
	write_scalar_data($pifFile,"##START|${sBlockName}");
	if ($iMode == 1) {
		#写列名
		@aColName=keys %{$rawData};
		write_array_data($pifFile,@aColName);
		#写数据
		write_array_data($pifFile,@$rawData{@aColName});
	} else {
		write_scalar_data($pifFile,$rawData->{COL_NAME});
		for $sKey (keys %{$rawData}) {
			next if ($sKey eq "COL_NAME");
			write_scalar_data($pifFile,$rawData->{$sKey});
		}
	}
	write_scalar_data($pifFile,"##END|${sBlockName}");
}

1;
