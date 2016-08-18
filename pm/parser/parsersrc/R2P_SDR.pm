#----------------------------------------------------------------
# @(#) SNMP R2P_SDR.pm
#----------------------------------------------------------------
# This takes RAW SNMP CELL Files, and converts them to PIF file types.
#
# This program relies EngineConfig.pm Files.
# Follow:
# UDP-MIB::udpInDatagrams.0 = Counter32: 46385
#---------------------------------------------------------------
# written by Zhung on 2007-01-10
#----------------------------------------------------------------
# 增加对一个文件中有单行和多行数据的处理
#   written by zhung 2013-08-02
#-----------------------------------------------------------------

package R2P_SDR;

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
		LogMess("R2P_SDR Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
        if (! $self->{CUSTOMID}){
		LogMess("R2P_SDR Initialisation: no CUSTOMID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{EQUIPID}){
		LogMess("R2P_SDR Initialisation: no EQUIPID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{BLOCKNAME}){
		LogMess("R2P_SDR Initialisation: no BLOCKNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{STARTTIME}){
		LogMess("R2P_SDR Initialisation: no STARTTIME specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{ENDTIME}){
		LogMess("R2P_SDR Initialisation: no ENDTIME specified in rule!",1);
		$num_errors++;
	}
	if (! $self->{PERIOD}){
		LogMess("R2P_SDR Initialisation: no PERIOD specified in rule!",1);
		$num_errors++;
	}

	#DataLine Format
	if (! $self->{LINE_FORMAT}){
		LogMess("R2P_SDR Initialisation: no LINE_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
  if (! $self->{SDRNAME}){
		LogMess("R2P_SDR Initialisation: no SDRNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{SDRVALUE}){
		LogMess("R2P_SDR Initialisation: no SDRVALUE specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{SDRTYPE}){
		LogMess("R2P_SDR Initialisation: no SDRTYPE specified in rule!",1);
		$num_errors++;
	}

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
    
    my ($NoPathFilenm,%fileInfo,$pLine);
    my ($sdrName,$sdrValue,$sdrType,%rpmData,%degData,%volData,%lineData,$iCount,$sTemp);
    #数据状态
    my %dataStatus = (
    	"0X00" => "Power Supply Information", 
			"0X01" => "DC Output", 
			"0X02" => "DC Load",
			"0X03" => "Management Access Record",
			"0X04" => "Base Compatibility Record",
			"0X05" => "Extended Compatibility Record",
			"0X06" => "reserved for ASF Fixed SMBus Device record", 
			"0X07" => "reserved for ASF Legacy-Device Alerts",
			"0X08" => "reserved for ASF Remote Control", 
			"0X09" => "Extended DC Output",
		  "0X0A" => "Extended DC Load",);
			
    #FileName analyse
    %rpmData=();
    %degData=();
    %volData=();
    %lineData=();
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) {
    	$fileInfo{CUSTOMID}=eval('$'.$self->{CUSTOMID});
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
    $iCount=0;
    $rpmData{"COLNAME"}="SDRNAME|SDRVALUE|SDRSTATUS";
    $degData{"COLNAME"}="SDRNAME|SDRVALUE|SDRSTATUS";
    $volData{"COLNAME"}="SDRNAME|SDRVALUE|SDRSTATUS";
    $lineData{"COLNAME"}="SDRNAME|SDRVALUE|SDRSTATUS";
    while (defined($pLine = <FILE>)) {
			chomp($pLine);
			#跳过空行
			next if (trimSpace($pLine)=~m/^$/);
			if ($pLine=~/$self->{LINE_FORMAT}/) {
				$sdrName=trimSpace(eval('$'.$self->{SDRNAME}));
				$sdrValue=trimSpace(uc(eval('$'.$self->{SDRVALUE})));
				$sdrType=trimSpace(eval('$'.$self->{SDRTYPE}));
		  	#替换value中的状态为说明
		  	$sTemp=$sdrValue;
		  	$sdrValue=~s/$sTemp/$dataStatus{$sTemp}/g  if (exists $dataStatus{$sTemp});
		  	#处理分拆出的数据
			  $sdrName=~s/ /\_/g;
			  $sdrValue=~s/ /\_/g;
			  #保存数据
			  if ($sdrValue=~/.*RPM.*/g) {
			  	$rpmData{$iCount}="${sdrName}|${sdrValue}|${sdrType}";
			  } 
			  if ($sdrValue=~/.*DEGREES.*/g ) {
			  	$degData{$iCount}="${sdrName}|${sdrValue}|${sdrType}";
			  } 
			  if ( $sdrValue=~/.*VOLTS.*/g || $sdrValue=~/.*AMPS.*/g) {
			  	$volData{$iCount}="${sdrName}|${sdrValue}|${sdrType}";
			  }
			  $lineData{$iCount}="${sdrName}|${sdrValue}|${sdrType}";
			  $iCount=$iCount+1;
			}
		}
		OutPifData(\%fileInfo,\%lineData,$fileInfo{BLOCKNAME},$self->{OUTPUT_DIR});	
		OutPifData(\%fileInfo,\%rpmData,$fileInfo{BLOCKNAME}.'RPM',$self->{OUTPUT_DIR});
		OutPifData(\%fileInfo,\%degData,$fileInfo{BLOCKNAME}.'DEG',$self->{OUTPUT_DIR});
		OutPifData(\%fileInfo,\%volData,$fileInfo{BLOCKNAME}.'VOL',$self->{OUTPUT_DIR});				
		return 0;
}
###########################################################################
# 名称：OutPifData
# 描述：判断
# 参数：组成customid-#-equipid-#-blockname-#-starttime-#-endtime-#-period-#-I.pif为基础数据文件名称
# 返回：无
###########################################################################
sub OutPifData {
	my ($fileInfo,$rawData,$sBlockName,$outDir)=@_;
	
	my ($pifFile,@aColName,$sKey);
	my ($sCustomId,$sEquipId,$sStartDate,$sStartTime,$sEndDate,$sEndTime,$sPeriod);
	
	$sCustomId=$fileInfo->{CUSTOMID};
	$sEquipId=$fileInfo->{EQUIPID};
	$sPeriod=$fileInfo->{PERIOD};
	#匹配成历史数据文件名称
	$pifFile=$outDir.'/'.$sCustomId.'-#-'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';
	$sStartDate=convert_date_snmp($fileInfo->{STARTTIME});
	$sStartTime=convert_time_snmp($fileInfo->{STARTTIME});
	$sEndDate=convert_date_snmp($fileInfo->{ENDTIME});
	$sEndTime=convert_time_snmp($fileInfo->{ENDTIME});
	
	#初始化
	init_file($pifFile);
	#写数据
	write_scalar_data($pifFile,'CUSTOMID|EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
	write_scalar_data($pifFile,"${sCustomId}|${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,'##END|HEADER');
	write_scalar_data($pifFile,"##START|${sBlockName}");
	write_scalar_data($pifFile,$rawData->{"COLNAME"});
	for $sKey (keys %{$rawData}) {
		next if ($sKey eq "COLNAME");
		write_scalar_data($pifFile,$rawData->{$sKey});
	}
	write_scalar_data($pifFile,"##END|${sBlockName}");
}

1;    
