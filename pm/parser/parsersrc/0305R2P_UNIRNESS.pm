package R2P_UNIRNESS;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use JSON;

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
		LogMess("R2P_JSON Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
	
  if (! $self->{SYSNAME})
  {
		LogMess("R2P_JSON Initialisation: no SYSNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{NENAME})
	{
		LogMess("R2P_JSON Initialisation: no NENAME specified in rule!",1);
		$num_errors++;
	}
	
  return $num_errors;
}

################################################################################
# Subroutine name:  outputline
#
# Description:      �ļ������������
#
# Arguments:        $headcols: �ļ�ͷ�����������ֶβ���
#										$bodycols���ļ����������������ݲ���
#                   $item: jsonģ��������json����
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          %filecontent:��ʽת������ļ�����
#                   $filecontent{head}:�ļ�ͷ����
#										$filecontent{body}:�ļ�������

sub outputline
{
	my ($headcols,$bodycols,$item) = @_;
	my ($elements,$i,$j,$firstdata,$seconddata);
	my $headcontent="";
	my $bodycontent="";
	my %filecontent =();
	
	foreach $elements (keys %$item) #$elementsֵΪresponse
	{
		#head����
		for ($i = 0; $i < @$headcols; $i++) 
		{
	 		if($i<(@$headcols-1))
	 		{
	 			#�����������Ϊ obj->{response}->{xxxxx}
				$headcontent .= $item->{$elements}->{$$headcols[$i]}."\|";
	 		}
	 		else 
	 		{
	 			$headcontent .= $item->{$elements}->{$$headcols[$i]};
	 		}
	 	}
	 		 	
	 	#����body����
		foreach  $firstdata(keys %{$item->{$elements}})
		{
			# $item->{$elements}->{$lidata} ֵΪ $obj->{response}->{xxxx}
			if (ref ($item->{$elements}->{$firstdata}) eq "ARRAY") 
			{
				foreach  $seconddata (@{$item->{$elements}->{$firstdata}})
				{
					#hash
					for ($j = 0; $j < @$bodycols; $j++) 
					{
		 				if($j<(@$bodycols-1))
		 				{
		 					#�����������Ϊ obj->{response}->{data}->{xxxx}
							$bodycontent .= $seconddata->{$$bodycols[$j]}."\|";
	 					}
	 					else 
	 					{
	 						$bodycontent .= $seconddata->{$$bodycols[$j]};
	 					}
	 				}
	 			 	$bodycontent .= "\n";				
				}	
			}
		}
				
	}
	
	#�������
	$filecontent{head}=$headcontent;	
	$filecontent{body}=$bodycontent;
	
	return \%filecontent;
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
		my ($json,$js,$obj,$item);   
		my (@head,@body,$blockname,$ne_head,$ne_body);
		
		
		#ʵ����json����
		$json = new JSON;
			    
    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) 
    {
    	$fileInfo{SYSNAME}=eval('$'.$self->{SYSNAME});
    	$fileInfo{NENAME}=eval('$'.$self->{NENAME});
			#������blockname���ļ����е�SYSNAME+NENAME
    	$fileInfo{BLOCKNAME}=eval('$'.$self->{SYSNAME}).eval('$'.$self->{NENAME});
    	$blockname= uc($fileInfo{BLOCKNAME});
#    	$fileInfo{HEADCOLS}=$self->{HEADCOLS};
#    	$fileInfo{BODYCOLS}=$self->{BODYCOLS};
			#ƴ��ͷ�ļ����ļ����  ������
			$ne_head=eval('$'.$self->{NENAME})."_head";
			$ne_body=eval('$'.$self->{NENAME})."_body";
			
			$fileInfo{head}=$self->{FILE_FORM}->{$ne_head};
			$fileInfo{body}=$self->{FILE_FORM}->{$ne_body};
    }
     else 
		{
    	LogMess("R2P_JSON : Can not get Filename Information:${NoPathFilenm}.",1);
    	return -1;
		}
    #analyse data line
    #---- read RAW file, create output file ---------------
    AudMess("R2P_JSON: About to process $filenm");
    #����ǿ��ļ��򷵻�
    return 0 if (-z $filenm);
    
    
		#rename xx.req to xx.pif
		$newfile = $NoPathFilenm;
		$newfile=~s/.json/.pif/;
		rename ($NoPathFilenm,$newfile);

		#�����ļ�����Ҫ�޸�Ϊ��̬·��
	  $self->{OUTPUT_DIR} ='/home/nuoen/log'; #����Ϊ��ʱ���ڣ�������
		$pifFile=$self->{OUTPUT_DIR}.'/'.$newfile;
		
		
		#��ʼ��
#		init_file($pifFile);		

		@head=split(/\|/,$fileInfo{head});
		#�ļ���
		@body =split(/\|/,$fileInfo{body});
		
		#��json�����ļ�
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
		
		#��pif����ļ�
    open(FCONTENT,">$pifFile") || die "This file open $!";  
    #д���ļ�ͷ����
    print FCONTENT "##UNIRES $fileInfo{NENAME} Parser Intermediate file\n";
    print FCONTENT "##START|HEADER\n";
    print FCONTENT "$fileInfo{head}\n";
    
		while (<FILE>)
    {
    	$js .= "$_";
  	}
  	
		$obj = $json->decode($js);
#		printf Dumper($obj)."\n";
#		write_scalar_data($pifFile,'##END|HEADER');
		
		#�����ļ������������
		my $filecon= outputline(\@head,\@body,$obj);
		chomp($$filecon{head});
	 	print FCONTENT "$$filecon{head}";

    print FCONTENT "\n##END|HEADER\n";
    print FCONTENT "##START|$blockname\n";
		print FCONTENT "$fileInfo{body}\n";
		
		chomp($$filecon{body});
		print FCONTENT "$$filecon{body}";
		

		print FCONTENT "\n##END|$blockname\n";
#    while (defined($pLine = <FILE>))
#    {
#			#ɾ���ļ��еĻ��з�\n�Ϳո�
#			chomp($pLine);
#			$pLine =~s/\s//g;     
#			#��������
#			next if (trimSpace($pLine)=~m/^$/);
#			
#			#get first line $. and writer new file
#			if($.==1)	
#			{
#					$pLine = $pLine."$fileInfo{PROVID}|$fileInfo{SERVICEID}";
#					write_scalar_data($pifFile,$fileInfo{HEADCOLS});
#					write_scalar_data($pifFile,$pLine);
#					write_scalar_data($pifFile,'##END|HEADER');
#					write_scalar_data($pifFile,"##START|$fileInfo{BLOCKNAME}");
#					write_scalar_data($pifFile,"$fileInfo{BODYCOLS}");
#			}
#			else
#			{
#				write_scalar_data($pifFile,$pLine);
#			}
#			
#    }
#    write_scalar_data($pifFile,"##END|HOST");
    close FILE;    
		close(FCONTENT);
  return 0;
}


1;
