#----------------------------------------------------------------
# @(#) SNMP R2P_STATUS.pm
#----------------------------------------------------------------
# This takes RAW SNMP CELL Files, and converts them to PIF file types.
#
# This program relies EngineConfig.pm Files.
# Follow�����������������ݣ�:
# Interfaces: 4, Recv/Trans packets: 524823/406722 | IP: 536594/425757
# 2 interfaces are down!
#---------------------------------------------------------------
# written by Zhung on 2007-01-10
#          LC-LG NMS
#----------------------------------------------------------------

package R2P_STATUS;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use AudLog;
use File::Basename;
use SNMP_PUB;

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
    my ($key, $num_errors);
    foreach $key ( keys %{$self->{'__config__'}} ) {
        $self->{$key} = $self->{'__config__'}->{$key};
    }

    $num_errors=0;

    # Now check for the mandatory configuration options specific to
	# this interface.
	#FileName Format
	if (! $self->{FILENAME_FORMAT}){
		LogMess("R2P_STATUS Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
        if (! $self->{CUSTOMID}){
		LogMess("R2P_STATUS Initialisation: no CUSTOMID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{EQUIPID}){
		LogMess("R2P_STATUS Initialisation: no EQUIPID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{BLOCKNAME}){
		LogMess("R2P_STATUS Initialisation: no BLOCKNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{STARTTIME}){
		LogMess("R2P_STATUS Initialisation: no STARTTIME specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{ENDTIME}){
		LogMess("R2P_STATUS Initialisation: no ENDTIME specified in rule!",1);
		$num_errors++;
	}
	if (! $self->{PERIOD}){
		LogMess("R2P_STATUS Initialisation: no PERIOD specified in rule!",1);
		$num_errors++;
	}

	#DataLine Format
	if (! $self->{DATA_FORMAT}){
		LogMess("R2P_STATUS Initialisation: no DATA_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
        if (! $self->{IF_NUM}){
		LogMess("R2P_STATUS Initialisation: no IF_NUM specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{RECV_PKS}){
		LogMess("R2P_STATUS Initialisation: no RECV_PKS specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{TRANS_PKS}){
		LogMess("R2P_STATUS Initialisation: no TRANS_PKS specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{RECV_IP}){
		LogMess("R2P_STATUS Initialisation: no RECV_IP specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{TRANS_IP}){
		LogMess("R2P_STATUS Initialisation: no TRANS_IP specified in rule!",1);
		$num_errors++;
	}
	#down interfaces Format
	if (! $self->{DOWN_FORMAT}){
		LogMess("R2P_STATUS Initialisation: no DOWN_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
        if (! $self->{IF_DOWN_NUM}){
		LogMess("R2P_STATUS Initialisation: no IF_DOWN_NUM specified in rule!",1);
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
# �����Ҫȡ��ʷ���ݣ������ļ���Ϊ customid-#-equipid-#-blockname-#-period
# ���ļ���һ��Ϊ�����ݵĽ���ʱ��yyyymmddhhmm���ڶ���Ϊ�������Ժ����Ϊ����
# ����equipno��������λ,��������!�ָ������ɺ�ѵ�ǰ���ݰ��մ˸�ʽ���ļ������ǵ�ָ��Ŀ¼��
#----------------------------------------------------------------------------------------------------
sub process_file {
    my ($self, $filenm, $header) =@_;

    my ($NoPathFilenm,%fileInfo);
    my ($pLine);
    my (%hLineData,$LineLink,%hColName,%hRawData);
    my ($hisData,$iInterval,$hisFileExist,$LineNum,$hRawLine);
    my ($iTemp);
    
    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) {
    	$fileInfo{CUSTOMID}=eval('$'.$self->{CUSTOMID});
    	$fileInfo{EQUIPID}=eval('$'.$self->{EQUIPID});
    	$fileInfo{BLOCKNAME}=eval('$'.$self->{BLOCKNAME});
    	$fileInfo{STARTTIME}=eval('$'.$self->{STARTTIME});
    	$fileInfo{ENDTIME}=eval('$'.$self->{ENDTIME});
    	$fileInfo{PERIOD}=eval('$'.$self->{PERIOD});
    	#AudMess("R2P_STATUS : Filename information are CustomId:$fileInfo{CUSTOMID} EQUIPID:$fileInfo{EQUIPID} BlockName:$fileInfo{BLOCKNAME} StartTime:$fileInfo{STARTTIME} EndTime:$fileInfo{ENDTIME} Period:$fileInfo{PERIOD}",4);
    } else {
    	LogMess("R2P_STATUS : Can not get Filename Information:${NoPathFilenm}.",1);
    	return -1;
    }
    #analyse data line
    #---- read RAW file, create output file ---------------
    AudMess("  R2P_STATUS: About to process $filenm");
    #��ʼ����־����
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
    $pLine="";
    %hLineData=();
    %hRawData=();
    %hColName=();
    $iInterval=1;
    $hisFileExist="NO";
    $LineNum=0;
    $LineLink={};
    $hRawLine={};
    $LineLink->{EQUIPNO}=0;
    $hRawLine->{EQUIPNO}=0;
    $hLineData{0}=$LineLink;
    $hRawData{0}=$hRawLine;
    while (defined($pLine = <FILE>)) {
	chomp($pLine);
	$LineNum=$LineNum+1;
	next if ($LineNum == 1);
	#��������
	next if (trimSpace($pLine)=~m/^$/);
	#���ݷָ�
	if ($LineNum == 2) {
		if ($pLine=~/$self->{DATA_FORMAT}/) {
			$LineLink->{IF_NUM}=trimSpace(eval('$'.$self->{IF_NUM}));
			$LineLink->{RECV_PKS}=trimSpace(eval('$'.$self->{RECV_PKS}));
			$LineLink->{TRANS_PKS}=trimSpace(eval('$'.$self->{TRANS_PKS}));
			$LineLink->{RECV_IP}=trimSpace(eval('$'.$self->{RECV_IP}));
			$LineLink->{TRANS_IP}=trimSpace(eval('$'.$self->{TRANS_IP}));	
		} else {
			LogMess("R2P_STATUS : Can not analyse ${LineNum} line:${pLine}. ",2);
			next;
		}
	}
	if ($LineNum == 3) {
		if ($pLine=~/$self->{DOWN_FORMAT}/) {
			$LineLink->{IF_DOWN_NUM}=trimSpace(eval('$'.$self->{IF_DOWN_NUM}));
		} else {
			LogMess("R2P_STATUS : Can not analyse ${LineNum} line:${pLine}.",2);
			next;
		}
	}							
    }
    close FILE;
    #����
    $hColName{EQUIPNO}='OK';
    $hColName{IF_NUM}='OK';
    $hColName{RECV_PKS}='OK';
    $hColName{TRANS_PKS}='OK';
    $hColName{RECV_IP}='OK';
    $hColName{TRANS_IP}='OK';
    $hColName{IF_DOWN_NUM}='OK';
    #�����ݵı���
    @$hRawLine{keys %$LineLink}=@$LineLink{keys %$LineLink};
    #���������ݲ�������
    $hisData=ReadHisData(\%fileInfo,$self);
    if ($hisData > 0) {
    	$iInterval=HisInterval(\%fileInfo,$self);
    	$hisFileExist="YES";
    	#���⴦��ʱ���ֻ����������ڴ������ݵ����
    	$hisFileExist="NO" if ($iInterval < 0);
    	$iTemp=0;
    	$iTemp=$hisData->{0}->{RECV_PKS} if (($hisFileExist eq "YES") && exists $hisData->{0}->{RECV_PKS});
    	$hLineData{0}->{RECV_PKS}=($hRawData{0}->{RECV_PKS} - $iTemp)/$iInterval;
    	$hLineData{0}->{RECV_PKS}=0 if ($hLineData{0}->{RECV_PKS} < 0);
    	
    	$iTemp=0;
    	$iTemp=$hisData->{0}->{TRANS_PKS} if (($hisFileExist eq "YES") && exists $hisData->{0}->{TRANS_PKS});
    	$hLineData{0}->{TRANS_PKS}=($hRawData{0}->{TRANS_PKS} - $iTemp)/$iInterval;
    	$hLineData{0}->{TRANS_PKS}=0 if ($hLineData{0}->{TRANS_PKS} < 0);

    	$iTemp=0;
    	$iTemp=$hisData->{0}->{RECV_IP} if (($hisFileExist eq "YES") && exists $hisData->{0}->{RECV_IP});
    	$hLineData{0}->{RECV_IP}=($hRawData{0}->{RECV_IP} - $iTemp)/$iInterval;
    	$hLineData{0}->{RECV_IP}=0 if ($hLineData{0}->{RECV_IP} < 0);

    	$iTemp=0;
    	$iTemp=$hisData->{0}->{TRANS_IP} if (($hisFileExist eq "YES") && exists $hisData->{0}->{TRANS_IP});
    	$hLineData{0}->{TRANS_IP}=($hRawData{0}->{TRANS_IP} - $iTemp)/$iInterval;
    	$hLineData{0}->{TRANS_IP}=0 if ($hLineData{0}->{TRANS_IP} < 0);
    }
    
    #������ݣ����������ļ����м��ļ������ԭ���޻��������ļ���������м��ļ���ֻ�������������ļ�
    OutHisData(\%fileInfo,\%hColName,\%hRawData,$self);
    #����л������ݴ��ڣ�������м��ļ�
    OutPifData(\%fileInfo,\%hColName,\%hLineData,$self) if ($hisFileExist eq "YES");
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
	my (%hisData,@colName,$recKey);
	
	#ƥ�����ʷ�����ļ�����
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	if (-e $hisFile) {
		%hisData=();
		$LineNum=0;
		if (open(inFile,"${hisFile}")) {
			while (defined($line=<inFile>)) {
				chomp($line);
				$LineNum=$LineNum+1;
				#��һ�������ݽ���ʱ�䣬����
				next if ($LineNum == 1);
				#�ڶ�������
				if ($LineNum == 2) {
					@colName=split('\|',$line);
					next;
				}
				@aLine=split('\|',$line);
				$recKey={};
				@$recKey{@colName}=@aLine;
				$hisData{$recKey->{EQUIPNO}}=$recKey if (exists $recKey->{EQUIPNO});
			}
		} else {
			return -1;
		}
	} else {
		return -1;
	}
	
	return \%hisData;
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
	#ƥ�����ʷ�����ļ�����
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
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
	my ($fileInfo,$colName,$lineData,$self)=@_;
	
	my ($hisFile,@aColName,$aLineData,$sKey);
	#ƥ�����ʷ�����ļ�����
	$hisFile=$self->{HIS_DATA_DIR}.'/'.$fileInfo->{CUSTOMID}.'-#-'.$fileInfo->{EQUIPID}.'-#-'.$fileInfo->{BLOCKNAME}.'-#-'.$fileInfo->{PERIOD};
	
	#��ʼ���ļ�
	open(outFile,">$hisFile");
	close outFile;
	#д����ʱ��
	write_scalar_data($hisFile,$fileInfo->{ENDTIME});
	#д����
	@aColName=keys %$colName;
	write_array_data($hisFile,@aColName);
	#д����
	foreach $sKey (keys %$lineData) {
		$aLineData=$lineData->{$sKey};
		write_array_data($hisFile,@$aLineData{@aColName});
	}
}

###########################################################################
# ���ƣ�OutPifData
# �������ж�
# ���������customid-#-equipid-#-blockname-#-starttime-#-endtime-#-period-#-I.pifΪ���������ļ�����
# ���أ���
###########################################################################
sub OutPifData {
	my ($fileInfo,$colName,$lineData,$self)=@_;
	
	my ($pifFile,@aColName,$aLineData,$sKey);
	my ($sCustomId,$sEquipId,$sStartDate,$sStartTime,$sEndDate,$sEndTime,$sPeriod,$sBlockName);
	
	$sCustomId=$fileInfo->{CUSTOMID};
	$sEquipId=$fileInfo->{EQUIPID};
	$sPeriod=$fileInfo->{PERIOD};
	$sBlockName=$fileInfo->{BLOCKNAME};
	#ƥ�����ʷ�����ļ�����
	$pifFile=$self->{OUTPUT_DIR}.'/'.$sCustomId.'-#-'.$sEquipId.'-#-'.$sBlockName.'-#-'.$fileInfo->{STARTTIME}.'-#-'.$fileInfo->{ENDTIME}.'-#-'.$sPeriod.'-#-I.pif';
	$sStartDate=convert_date_snmp($fileInfo->{STARTTIME});
	$sStartTime=convert_time_snmp($fileInfo->{STARTTIME});
	$sEndDate=convert_date_snmp($fileInfo->{ENDTIME});
	$sEndTime=convert_time_snmp($fileInfo->{ENDTIME});
	
	#��ʼ��
	init_file($pifFile);
	#д����
	write_scalar_data($pifFile,'CUSTOMID|EQUIPID|STARTDATE|STARTTIME|ENDDATE|ENDTIME|PERIOD');
	write_scalar_data($pifFile,"${sCustomId}|${sEquipId}|${sStartDate}|${sStartTime}|${sEndDate}|${sEndTime}|${sPeriod}");
	write_scalar_data($pifFile,'##END|HEADER');
	write_scalar_data($pifFile,"##START|${sBlockName}");
	#д����
	@aColName=keys %$colName;
	write_array_data($pifFile,@aColName);
	#д����
	foreach $sKey (keys %$lineData) {
		$aLineData=$lineData->{$sKey};
		write_array_data($pifFile,@$aLineData{@aColName});
	}
	write_scalar_data($pifFile,"##END|${sBlockName}");
}

1;
