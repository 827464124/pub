package R2P_ENG;

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
sub load_config 
{
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
	if (! $self->{FILENAME_FORMAT})
	{
		LogMess("R2P_ENG Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
  if (! $self->{SERVICEID})
  {
		LogMess("R2P_ENG Initialisation: no SERVICEID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{PROVID})
	{
		LogMess("R2P_ENG Initialisation: no PROVID specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{BLOCKNAME}){
		LogMess("R2P_ENG Initialisation: no BLOCKNAME specified in rule!",1);
		$num_errors++;
	}
#
#	if (! $self->{STARTTIME}){
#		LogMess("R2P_ENG Initialisation: no STARTTIME specified in rule!",1);
#		$num_errors++;
#	}
#	
#	if (! $self->{ENDTIME}){
#		LogMess("R2P_ENG Initialisation: no ENDTIME specified in rule!",1);
#		$num_errors++;
#	}
#	if (! $self->{PERIOD}){
#		LogMess("R2P_ENG Initialisation: no PERIOD specified in rule!",1);
#		$num_errors++;
#	}
#
#	#DataLine Format
#	if (! $self->{LINE_FORMAT}){
#		LogMess("R2P_ENG Initialisation: no LINE_FORMAT specified in rule!",1);
#		$num_errors++;
#	}
#	
#  if (! $self->{SDRNAME}){
#		LogMess("R2P_ENG Initialisation: no SDRNAME specified in rule!",1);
#		$num_errors++;
#	}
#
#	if (! $self->{SDRVALUE}){
#		LogMess("R2P_ENG Initialisation: no SDRVALUE specified in rule!",1);
#		$num_errors++;
#	}
#
#	if (! $self->{SDRTYPE}){
#		LogMess("R2P_ENG Initialisation: no SDRTYPE specified in rule!",1);
#		$num_errors++;
#	}
  return $num_errors;
}

################################################################################
# Subroutine name:  process_file()
#
# Description:      Formating engine files routine
#
# Arguments:        $filenm :Format engine filename
#                   debug (scalar) - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          0 for success,
#                   the number of errors found for failure
#

sub process_file
{
    my ($self, $filenm, $header) =@_;
    my ($NoPathFilenm,%fileInfo,$pLine,$newfile,$pifFile,$headcols);
   
    
    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) 
    {
    	$fileInfo{SERVICEID}=eval('$'.$self->{SERVICEID});
    	$fileInfo{PROVID}=eval('$'.$self->{PROVID});
    	$fileInfo{BLOCKNAME}=$self->{BLOCKNAME};
    	$fileInfo{HEADCOLS}=$self->{HEADCOLS};
    	$fileInfo{BODYCOLS}=$self->{BODYCOLS};
    }
     else 
	{
    	LogMess("R2P_ENG : Can not get Filename Information:${NoPathFilenm}.",1);
    	return -1;
	}
    #analyse data line
    #---- read RAW file, create output file ---------------
    AudMess("  R2P_ENG: About to process $filenm");
    #如果是空文件则返回
    return 0 if (-z $filenm);
    
    #打开文件
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
    $pLine="";

		#rename xx.req to xx.pif
		$newfile = $NoPathFilenm;
		$newfile=~s/.req/.pif/;
		rename ($NoPathFilenm,$newfile);

		#生成文件名需要修改为动态路径
	    #$self->{OUTPUT_DIR} ='/home/nuoen/log'; #此行为临时存在，测试用
		$pifFile=$self->{OUTPUT_DIR}.'/'.$newfile;
		
		
		#初始化
		init_file($pifFile);		
		#create head colname; 配置文件中的PROVID+SERVICEID+HEAECOLS
		$headcols= $fileInfo{HEADCOLS};
		LogMess("headcols=$headcols",1);
		
    while (defined($pLine = <FILE>))
    {
			#删除文件中的换行符\n和空格
			chomp($pLine);
			$pLine =~s/\s//g;     
			#跳过空行
			next if (trimSpace($pLine)=~m/^$/);
			
			#get first line $. and writer new file
			if($.==1)
			{
					$pLine = $pLine."$fileInfo{PROVID}|$fileInfo{SERVICEID}";
					write_scalar_data($pifFile,$fileInfo{HEADCOLS});
					write_scalar_data($pifFile,$pLine);
					write_scalar_data($pifFile,'##END|HEADER');
					write_scalar_data($pifFile,"##START|$fileInfo{BLOCKNAME}");
					write_scalar_data($pifFile,"$fileInfo{BODYCOLS}");
			}
			else
			{
				write_scalar_data($pifFile,$pLine);
			}
			
    }
    write_scalar_data($pifFile,"##END|$fileInfo{BLOCKNAME}");
    close FILE;
    
  return 0;
}

1;
