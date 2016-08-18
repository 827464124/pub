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
# update by lqzh on 2013-12-11  ���޸��ļ���ȥ��CUSTOMID	
#----------------------------------------------------------------
# ���Ӷ�һ���ļ����е��кͶ������ݵĴ���
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
    # is wanted,bless �� referent ���object

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
#2013-12-11 ���޸��ļ���ȥ��CUSTOMID	
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
	#�������oid2name����뵽�ļ�
	if(exists $self->{OIDNAME_FILE} and $self->{OIDNAME_FILE}) {
		open oFILE, $self->{OIDNAME_FILE} || LogMess("Can not open $self->{OID2NAME_FILE}",1);
		%oidname=();
		while (defined($pLine = <oFILE>)) {
			chomp($pLine);
			#��������
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
# �����Ҫȡ��ʷ���ݣ������ļ���Ϊ customid-#-equipid-#-blockname-#-period
# ���ļ���һ��Ϊ�����ݵĽ���ʱ��yyyymmddhhmm���ڶ���Ϊ�������Ժ����Ϊ����
# ����equipno��������λ,��������!�ָ������ɺ�ѵ�ǰ���ݰ��մ˸�ʽ���ļ������ǵ�ָ��Ŀ¼��
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
    #����ǿ��ļ��򷵻�
    return 0 if (-z $filenm);
    #��ʼ����־����
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
			#��������
			next if (trimSpace($pLine)=~m/^$/);
			#����ֵΪ���е��ַ��������½������󡣽������Ϊ���䵽��һ�е�ֵ�С�
			#SNMPv2-MIB::sysDescr.0 = STRING: H3C Comware Platform Software
			#COMWARE (R) Software Version 5.20, Release 3808
			#H3C Firewall SecPath F5000-C
			# sysDescr="H3C Comware Platform Software COMWARE (R) Software Version 5.20, Release 3808 H3C Firewall SecPath F5000-C"
			#print "$pLine\n";
			#�жϲ���OID�滻Ϊname
			if(exists $self->{OIDNAME} and $self->{OIDNAME}) {
				#REPLACE_RULE��EngineConfig�����ã����Ϊ�Ⱥ����Ĳ���
				if ($pLine=~/$self->{REPLACE_RULE}/) {
					$sLeft=trimSpace($1);
					$pLine=~s/$sLeft/$self->{OIDNAME}->{$sLeft}/ig if (exists $self->{OIDNAME}->{$sLeft});
				}
			}
			#���ݷָ�
			if ($pLine=~/$self->{LINE_FORMAT}/) {
				$MibFile=trimSpace(eval('$'.$self->{MIB_FILENAME}));
				$CounterName=trimSpace(uc(eval('$'.$self->{COUNTER_NAME})));
				$EquipNo=trimSpace(eval('$'.$self->{EQUIP_NO}));
				#����������ǿգ��������Ϊ0 2013-08-01 by zhung
				$EquipNo=0 if (!defined($EquipNo) || (trimSpace($EquipNo) eq ""));
				$CounterType=trimSpace(uc(eval('$'.$self->{COUNTER_TYPE})));
				$CounterValue=trimSpace(eval('$'.$self->{COUNTER_VALUE}));
				#����HOST-RESOURCES-TYPES::hrStorageFixedDisk��ֵ��һ����ֳ�hrStorageFixedDisk
				$CounterValue=trimSpace($2) if ($CounterValue=~/^(.+)\:\:(\w+)$/);
#				AudMess("R2P_VV : DataLine information are MibFile:${MibFile} CName:${CounterName} EquipNo:${EquipNo} CType:${CounterType} CValue:${CounterValue}",5);
				$cValue=$CounterValue;
				#���Ϊ�ַ���������ֵ�м��пո񣬰ѿո������ַ���-�����棬���⵼��������
				if ($CounterType=~/STRING/) {
					$cValue=$CounterValue;
					$cValue=~s/ /\_/g;
					#ȥ���ַ����е�"
					$cValue=~s/\"//g;
				}
				#������ۼӷ�ʽ������Ҫ��ǰ�����ֵ���ж������а���COUNT
				if ($CounterType=~/COUNT/) {
					#��ʷ���ݣ�ֻ����Ҫ���ļ�����������ʷ�洢
					$sTemp=join('-',$CounterName,$EquipNo);
					$hCountColName{$sTemp}=$cValue;
					#��һ�δ���ʱ������ʷ����
					if ($countExistFirst eq "YES") {
						$countExistFirst="NO";
						#��ȡ�����ļ����ݣ��������㣬����ļ������ڣ�����ļ�����������ֻ����������ʹ��
						$hisData=ReadHisData(\%fileInfo,$self);
						if ($hisData > 0) {
							$iInterval=HisInterval(\%fileInfo,$self);
							$hisFileExist="YES";
							#���⴦��ʱ���ֻ����������ڴ������ݵ����
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
				#�洢����,�ֵ��кͶ���
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
				#�����ǰ��û�С�=�����֣�����Ϊ����һ�е��ַ���������
				#�������������Ϊ�գ����ǵ�һ�л�û�н��в�֣���ֱ������
				next if ($lastCountName eq ""); 
				#����ո�
				$pLine=~s/ /\_/g;
				#ȥ���ַ����е�"
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
 		#������Ҫ�ۼӵ����ݣ����ŵ����еĹ�ϣ�����У���Ϊ����������������
 		if (exists $self->{ACCU_COLUMN}) {
 			$sAccu=$self->{ACCU_COLUMN};
 			foreach $sKey (keys %{$sAccu}) {
                                $iLine=0;
 				$CounterName=$sKey;
 				$pLine=$sAccu->{$sKey};
 				#��Ҫ�ۼӵ����ݶ��ڶ������棬���е����������Ҫ����ֱ����loadmap��д��������Ϳ���
 				@colName=split('\|',uc($pLine));
 				$tjCol="";
 				$jsCol="";
 				$exprCol="";
 				@aJsCol=();
 				$tjCol=trimSpace($colName[0]);#��һ���������ֶ�
 				$jsCol=trimSpace($colName[1]);#�ڶ����Ǳ����ֶ�
 				$exprCol=trimSpace($colName[2]);#�ڶ����Ǽ����ֶ�
 				@aJsCol=split(',',$jsCol);
 				next if (!exists $hRawData{$tjCol} and ($tjCol ne "ALL"));#�����������ALL���Ҳ������������һ��ѭ��
 				next if ($jsCol eq "");#�������Ϊ���������һ��
 				next if ($exprCol eq "");#������ʽΪ���������һ��
 				if ($tjCol eq "ALL") {
 					#������������������ȫ�����ݶ��ۼ�
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
 					#��ʼ������
          foreach  $EquipNo (keys %{$hRawData{$tjCol}}) {
          	$hRawLine{$EquipNo}="NO";
          }
          foreach  $EquipNo (keys %{$hRawData{$tjCol}}) {
 						next if (exists $hRawLine{$EquipNo} and ($hRawLine{$EquipNo} eq 'OK'));#�ù�һ��
 						$sTemp=$hRawData{$tjCol}->{$EquipNo};#����ֵ����ȡ����ļ���ֵ
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
 						#��������������������ͬ��������ͬ���ۼ�
 						foreach $subKey (keys %{$hRawData{$tjCol}}){
 							next if ($hRawLine{$subKey} eq 'OK');#ֻ�ܼ���һ��
 							$subTemp=$hRawData{$tjCol}->{$subKey};
 							if ($sTemp eq $subTemp) {
 								$hRawLine{$subKey}="OK";#���ù��ı��
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
 
    #������ݣ����������ļ����м��ļ������ԭ���޻��������ļ���������м��ļ���ֻ�������������ļ�
    OutHisData(\%fileInfo,\%hCountColName,$self);
    #���������COUNTER�ۼ������ݣ����ߴ����ۼ��͵��л������ݴ��ڣ�������м��ļ�
    if (($countExistFirst eq "YES") || ($hisFileExist eq "YES")) {
    	 OutPifData(\%fileInfo,\%hRawZeroData,$fileInfo{BLOCKNAME},$self->{OUTPUT_DIR},1);
    	 #�������ݷֱ�д�ɶ���ļ���blockname���������ļ�
    	 if (exists $self->{LINE_COUNTER}){
    	 	foreach $sKey (keys %{$self->{LINE_COUNTER}}) {
    	 		@colName=split('\|',uc($self->{LINE_COUNTER}->{$sKey}));
    	 		next if (@colName <1);#�����ļ�����û�п��������
    	 		%hRawLine=();#��ʼ��
    	 		#�γ��������
    	 		$hRawLine{COL_NAME}='EQUIP_NO'.'|'.uc($self->{LINE_COUNTER}->{$sKey});#����
    	 		$CounterName=$colName[0];#ȡ��һ���ж�Ӧ������ֵ����Ϊ���������
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
# ���ƣ�ReadHisData
# ����������ʷ���ݶ���hash����
# ���������customid-#-equipid-#-blockname-#-periodΪ���������ļ�����
# ���أ����ݵ�ַ
###########################################################################
sub ReadHisData {
	my ($fileInfo,$self)=@_;
	
	my ($hisFile,$line,@aLine,$LineNum);
	my (%hisD,@colName,$recKey);
	
	#ƥ�����ʷ�����ļ�����
#	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	if (-e $hisFile) {
		$LineNum=0;
		if (open(inFile,"${hisFile}")) {
			while (defined($line=<inFile>)) {
				chomp($line);
				$LineNum=$LineNum+1;
				#��һ�������ݽ���ʱ�䣬����
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
# ���ƣ�HisInterval
# �������ж����ϴ����ݵ�ʱ����Ϊ��������
# ���������customid-#-equipid-#-blockname-#-periodΪ���������ļ�����
# ���أ��������
###########################################################################
sub HisInterval {
	my ($fileInfo,$self)=@_;
	
	my ($iInterval,$hisFile,$line,$LineNum);
	
	$iInterval=1;
	$LineNum=0;
	#ƥ�����ʷ�����ļ�����
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
# ���ƣ�OutHisData
# �������ж�
# ���������customid-#-equipid-#-blockname-#-periodΪ���������ļ�����
# ���أ���
###########################################################################
sub OutHisData {
	my ($fileInfo,$hData,$self)=@_;
	
	my ($hisFile,@aColName,$sKey,$iRet);
	#ƥ�����ʷ�����ļ�����
#	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};	
	#ÿ��д���һ���ϴε��ļ�
	$iRet=open(OUTFILE,">$hisFile");
	if ($iRet) {
		close outFile;
	} else {
		LogMess("R2P_VV:init_file --Can not open ${hisFile} to write",1);
	}
	#д����ʱ��
	write_scalar_data($hisFile,$fileInfo->{ENDTIME});
	#д����
	foreach $sKey (keys %{$hData}) {
		write_scalar_data($hisFile,$sKey.'|'.$hData->{$sKey});
	}
}

###########################################################################
# ���ƣ�OutPifData
# �������ж�
# ���������customid-#-equipid-#-blockname-#-starttime-#-endtime-#-period-#-I.pifΪ���������ļ�����
# ���أ���
###########################################################################
sub OutPifData {
	my ($fileInfo,$rawData,$sBlockName,$outDir,$iMode)=@_;
	
	my ($pifFile,@aColName,$sKey);
	my ($sEquipId,$sStartDate,$sStartTime,$sEndDate,$sEndTime,$sPeriod);
	
#	$sCustomId=$fileInfo->{CUSTOMID};
	$sEquipId=$fileInfo->{EQUIPID};
	$sPeriod=$fileInfo->{PERIOD};
	#ƥ�����ʷ�����ļ�����
#	$pifFile=$outDir.'/'.$sCustomId.'-#-'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';
	$pifFile=$outDir.'/'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';	
	$sStartDate=convert_date_snmp($fileInfo->{STARTTIME});
	$sStartTime=convert_time_snmp($fileInfo->{STARTTIME});
	$sEndDate=convert_date_snmp($fileInfo->{ENDTIME});
	$sEndTime=convert_time_snmp($fileInfo->{ENDTIME});
	
	#��ʼ��
	init_file($pifFile);
	#д����
#	write_scalar_data($pifFile,'CUSTOMID|EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
	write_scalar_data($pifFile,'EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
#	write_scalar_data($pifFile,"${sCustomId}|${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,"${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,'##END|HEADER');
	write_scalar_data($pifFile,"##START|${sBlockName}");
	if ($iMode == 1) {
		#д����
		@aColName=keys %{$rawData};
		write_array_data($pifFile,@aColName);
		#д����
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
