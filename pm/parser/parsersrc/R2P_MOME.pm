package R2P_MOME;

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
#                   $filecontent{content}:�ļ�����(�ļ�ͷ+�ļ���)

sub outputline
{
	my ($headcols,$bodycols,$item) = @_;
	my ($elements,$i,$j,$firstdata,$seconddata);
	my $content="";
	my %filecontent =();
	
	foreach $elements (keys %$item) #$elementsֵΪresponse
	{
	 	#��ʼ����
		foreach  $firstdata(keys %{$item->{$elements}})
		{
			# $item->{$elements}->{$lidata} ֵΪ $obj->{response}->{xxxx}
			if (ref ($item->{$elements}->{$firstdata}) eq "ARRAY") 
			{
				#head����
				foreach  $seconddata (@{$item->{$elements}->{$firstdata}})
				{
					for ($i = 0; $i < @$headcols; $i++) 
					{
	 						#�����������Ϊ obj->{response}->{xxxxx}
							$content .= $item->{$elements}->{$$headcols[$i]}."\|";
	 				}
					#body����
					for ($j = 0; $j < @$bodycols; $j++) 
					{
		 				if($j<(@$bodycols-1))
		 				{
		 					#�����������Ϊ obj->{response}->{data}->{xxxx}
							$content .= $seconddata->{$$bodycols[$j]}."\|";
	 					}
	 					else 
	 					{
	 						$content .= $seconddata->{$$bodycols[$j]};
	 					}
	 				}
	 			 		$content .= "\n";				
				}	
			}
		}
				
	}
	
	#�������	
	$filecontent{content}=$content;
	return \%filecontent;
}

##########################################################
# Subroutine name:  OutJsonArray
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
#                   $filecontent{bodycontent}:�ļ�����(�ļ�ͷ+�ļ���)

sub OutJsonArray
{
	my ($headcols,$bodycols,$item) = @_;
	my ($elements,$i,$j,$firstdata,$idata);
	
#	my $headcontent="";
	my $bodycontent="";
	my %filecontent =();
	
	foreach $elements (keys %$item)
	{
#		LogMess("elements =======$elements",1);
		#��һ�㸸�ڵ�
		for $firstdata(@{$item->{$elements}})                                                                                                           
 		{
 			#ѭ��ȡ����ϣ�ṹ$firstdata�ļ�ֵ
 			while((my $firstkey, my $firstvalue) = each $firstdata)
 			{ 
#				print "$firstkey => $firstvalue\n"; 
				if( ref($firstvalue) eq "ARRAY")
				{
					#�ڶ��㸸�ڵ�
					for  $idata(@{$firstdata->{$firstkey}})
 					{
 						for ($i = 0; $i < @$headcols; $i++) 
						{
	 						$bodycontent .= $firstdata->{$$headcols[$i]}."\|";
	 					}
	 					for ($j = 0; $j < @$bodycols; $j++) 
						{
		 					if($j<(@$bodycols-1))
		 					{
		 						#�����������Ϊ obj->{response}->{data}->{xxxx}
								$bodycontent .= $idata->{$$bodycols[$j]}."\|";
	 						}
	 						else 
	 						{
		 						$bodycontent .= $idata->{$$bodycols[$j]};
	 						}
						}	

 						#��������json������
# 					print "ip:".$item->{'ip'}."\t";
#						print "type:".$item->{'type'}."\t";
#						print "id:".$firstdata->{'id'}."\t"; #��һ�㸸�ڵ�������                                                                                                                                                                                                                                                                       
#	 					print "unit:".$idata->{'unit'}."\n"; 
						$bodycontent .= "\n";	 
 					}
 				}
	 		}
		}	
	}
#	$filecontent{head}=$headcontent;	
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
		my (@head,@body,$blockname,$ne_head,$ne_body,$allcols);
		
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

			#ƴ��ͷ�ļ����ļ����  ������
			$ne_head=eval('$'.$self->{NENAME})."_head";
			$ne_body=eval('$'.$self->{NENAME})."_body";
			
			$fileInfo{head}=$self->{FILE_FORM}->{$ne_head};
			$fileInfo{body}=$self->{FILE_FORM}->{$ne_body};
			
			#�ж�ͷ�����Ƿ�Ϊ�գ��Ƿ����á����������Ĭ������Ϊ definecolname
			if(! $fileInfo{head})
			{
				AudMess("Can't get head colname,defined name is definecolname");
				$fileInfo{head}="definecolname";
			}
			#�ж��ļ�����������������û���Ϊ�գ������˳�������¼��־
			if(! $fileInfo{body})
			{
				AudMess("R2P_JSON: Abort to process");
				return -1;
			}    
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
#	  $self->{OUTPUT_DIR} ='/home/nuoen/log'; #����Ϊ��ʱ���ڣ�������
		$pifFile=$self->{OUTPUT_DIR}.'/'.$newfile;
		
		@head=split(/\|/,$fileInfo{head});
		#�ļ���
		@body =split(/\|/,$fileInfo{body});
		
		#��json�����ļ�
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
		
		#��pif����ļ�
    open(FCONTENT,">$pifFile") || die "This file open $!";  
    #д���ļ�ͷ����
    print FCONTENT "##METER $fileInfo{NENAME} Parser Intermediate file\n";
    print FCONTENT "##START|HEADER\n";
	  print FCONTENT "$fileInfo{head}\n";
    
    print FCONTENT "##END|HEADER\n";
    print FCONTENT "##START|$blockname\n";
		$allcols=$fileInfo{head}."|".$fileInfo{body};
		print FCONTENT "$allcols\n";
		
		while (my $line=<FILE>)
    {
#    	$js .= "$_";
			$js = $line; 
			$obj = $json->decode($js);
#			printf Dumper($obj)."\n";

			#�����ļ������������
			my $filecon= OutJsonArray(\@head,\@body,$obj);
			chomp($$filecon{body});
			print FCONTENT "$$filecon{body}";
		}
		print FCONTENT "\n##END|$blockname\n";
    
    close FILE;    
		close(FCONTENT);
  
  return 0;
}


1;
