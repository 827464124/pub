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
# Description:      文件解析输出函数
#
# Arguments:        $headcols: 文件头列名，管理字段部分
#										$bodycols：文件体列名，数据内容部分
#                   $item: json模块解析后的json数据
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          %filecontent:格式转换后的文件数据
#                   $filecontent{head}:文件头内容
#										$filecontent{body}:文件体内容

sub outputline
{
	my ($headcols,$bodycols,$item) = @_;
	my ($elements,$i,$j,$firstdata,$seconddata);
	my $headcontent="";
	my $bodycontent="";
	my %filecontent =();
	
	foreach $elements (keys %$item) #$elements值为response
	{
		#head部分
		for ($i = 0; $i < @$headcols; $i++) 
		{
	 		if($i<(@$headcols-1))
	 		{
	 			#解析后的内容为 obj->{response}->{xxxxx}
				$headcontent .= $item->{$elements}->{$$headcols[$i]}."\|";
	 		}
	 		else 
	 		{
	 			$headcontent .= $item->{$elements}->{$$headcols[$i]};
	 		}
	 	}
	 		 	
	 	#解析body部分
		foreach  $firstdata(keys %{$item->{$elements}})
		{
			# $item->{$elements}->{$lidata} 值为 $obj->{response}->{xxxx}
			if (ref ($item->{$elements}->{$firstdata}) eq "ARRAY") 
			{
				foreach  $seconddata (@{$item->{$elements}->{$firstdata}})
				{
					#hash
					for ($j = 0; $j < @$bodycols; $j++) 
					{
		 				if($j<(@$bodycols-1))
		 				{
		 					#解析后的内容为 obj->{response}->{data}->{xxxx}
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
	
	#添加数据
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
		
		
		#实例化json对象
		$json = new JSON;
			    
    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) 
    {
    	$fileInfo{SYSNAME}=eval('$'.$self->{SYSNAME});
    	$fileInfo{NENAME}=eval('$'.$self->{NENAME});
			#块名：blockname，文件名中的SYSNAME+NENAME
    	$fileInfo{BLOCKNAME}=eval('$'.$self->{SYSNAME}).eval('$'.$self->{NENAME});
    	$blockname= uc($fileInfo{BLOCKNAME});
#    	$fileInfo{HEADCOLS}=$self->{HEADCOLS};
#    	$fileInfo{BODYCOLS}=$self->{BODYCOLS};
			#拼出头文件和文件体的  列名称
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
    #如果是空文件则返回
    return 0 if (-z $filenm);
    
    
		#rename xx.req to xx.pif
		$newfile = $NoPathFilenm;
		$newfile=~s/.json/.pif/;
		rename ($NoPathFilenm,$newfile);

		#生成文件名需要修改为动态路径
	  $self->{OUTPUT_DIR} ='/home/nuoen/log'; #此行为临时存在，测试用
		$pifFile=$self->{OUTPUT_DIR}.'/'.$newfile;
		
		
		#初始化
#		init_file($pifFile);		

		@head=split(/\|/,$fileInfo{head});
		#文件列
		@body =split(/\|/,$fileInfo{body});
		
		#打开json输入文件
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
		
		#打开pif输出文件
    open(FCONTENT,">$pifFile") || die "This file open $!";  
    #写入文件头部分
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
		
		#调用文件解析输出函数
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
#			#删除文件中的换行符\n和空格
#			chomp($pLine);
#			$pLine =~s/\s//g;     
#			#跳过空行
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
