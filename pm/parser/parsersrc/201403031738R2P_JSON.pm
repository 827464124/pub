package R2P_JSON;

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
	
	if (! $self->{FILE_FORM}){
		LogMess("R2P_JSON Initialisation: no FILE_FORM specified in rule!",1);
		$num_errors++;
	}
  return $num_errors;
}

################################################################################
sub pout
{
	my ($item,@content) = @_;
	my ($fileline,$data,$i);
	
	
	if ( ref($item) eq "HASH" ) 
	{
 	 LogMess("item is a reference to a hash",1);
	}
	
	foreach my $elements (keys %$item)
	{
		LogMess("$elements=$$item{$elements}",1);
		
		if($elements eq "data")
		{
			LogMess("我找到了",1);
		
		foreach my $idata(@{$item->{"data"}})
		{
			LogMess("xxxxx\t$idata=$idata->{password}",1);
		}
		}
	}
	
	return $fileline;
}



sub outputline
{
	my ($headcols,$bodycols,$item) = @_;
	my ($elements,$headcontent,$bodycontent,$i,$j,$firstdata,$seconddata);
	my %filecontent =();
	
foreach $elements (keys %$item) #$elements值为response
	{
		#head部分
			for ($i = 0; $i < @$headcols; $i++) 
			{
	 			if($i<(@$headcols-1))
	 			{
					$headcontent .=$item->{$elements}->{$$headcols[$i]}."\|";
	 			}
	 			else 
	 			{
	 				$headcontent .=$item->{$elements}->{$$headcols[$i]};
	 			}
	 		}
	 		 	
		foreach  $firstdata(keys %{$item->{$elements}})
		{
			# $item->{$elements}->{$lidata} 值为 $obj->{response}->{xxxx}
			LogMess("yyyy\t$firstdata=$item->{$elements}->{$firstdata}",1);
			#解析body部分
			if (ref ($item->{$elements}->{$firstdata}) eq "ARRAY") 
			{
				LogMess("AAA: sogaa",1);
				foreach  $seconddata (@{$item->{$elements}->{$firstdata}})
				{
					#hash
					LogMess("aa=>$seconddata->{password}",1);

				for ($j = 0; $j < @$bodycols; $j++) 
				{
					
	 				if($j<(@$bodycols-1))
	 				{
						$bodycontent .=$seconddata->{$$bodycols[$j]}."\|";
	 				}
	 				else 
	 				{
	 					$bodycontent .=$seconddata->{$$bodycols[$j]};
	 				}
	 			}
	 			 	$bodycontent .= "\n";				
				}			
			}
		}
				
	}
	LogMess("\t \t 222:$headcontent",1);
	LogMess("\t \t 333:$bodycontent",1);
	$filecontent{head}=$headcontent;	
	$filecontent{body}=$bodycontent;
	
	
	return %filecontent;
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
		my (@head,@body,$headitem,$bodyitem,$headvalue,$colsvalue);
		
		
		#实例化json对象
		$json = new JSON;
			    
    #FileName analyse
    $NoPathFilenm=basename($filenm);
    %fileInfo=();
    if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) 
    {
#    	$fileInfo{SERVICEID}=eval('$'.$self->{SERVICEID});
#    	$fileInfo{PROVID}=eval('$'.$self->{PROVID});
#    	$fileInfo{BLOCKNAME}=$self->{BLOCKNAME};
#    	$fileInfo{HEADCOLS}=$self->{HEADCOLS};
#    	$fileInfo{BODYCOLS}=$self->{BODYCOLS};
			$fileInfo{head}=$self->{FILE_FORM}->{host_head};
			$fileInfo{body}=$self->{FILE_FORM}->{host_body};
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
		#create head colname; 配置文件中的PROVID+SERVICEID+HEAECOLS
#		$headcols= $fileInfo{HEADCOLS};
#		LogMess("headcols=$headcols",1);
		
		@head=split(/\|/,$fileInfo{head});
		#文件列
		@body =split(/\|/,$fileInfo{body});
		
		

		
		
		#打开json输入文件
    open FILE, $filenm || LogMess("Can not open ${filenm}",1);
		
		#打开pif输出文件
    open(FCONTENT,">$pifFile") || die "This file open $!";  
    #写入文件头部分
    print FCONTENT "##UNIRES HOST Parser Intermediate file\n";
    print FCONTENT "##START|HEADER\n";
    print FCONTENT "$fileInfo{head}\n";
    
		while (<FILE>)
    {
    	$js .= "$_";
  	}
  	
		$obj = $json->decode($js);
#		printf Dumper($obj)."\n";
#		write_scalar_data($pifFile,'##END|HEADER');
#		write_scalar_data($pifFile,"##START|HOST");
		
		#####测试中
#		my $objref = \$obj;
#		my $lineresult= outputline("head",$obj,@head);
#		my $lineresult= outputline($obj,@head,@body);
		my %filecon= outputline(\@head,\@body,$obj);
#		foreach my $fresult (keys %lresult)
#		{
#			LogMess("xxxxxxxxx   \tlresult=$lresult{body}",1);
#		}
		#		my $lineresult= &outputline($objref,@head);
#		
#		LogMess("lineresult=$lineresult",1);
		
		
#		for(my $j=0; $j<@head;$j++)
#	 	{ 			
#	 			if($j<(@head-1))
#	 			{
#	 				$headvalue=$obj->{'response'}->{$head[$j]}."\|";
#	 			}
#	 			else
#	 			{
#	 				$headvalue=$obj->{'response'}->{$head[$j]};
#	 			}
#					print FCONTENT "$headvalue";
#	 	}
#	 	
		chomp($filecon{head});
	 	print FCONTENT "$filecon{head}";
#	 	print FCONTENT "$obj->{'response'}->{'data'}\n";
    print FCONTENT "\n##END|HEADER\n";
    print FCONTENT "##START|HOST\n";
		print FCONTENT "$fileInfo{body}\n";
		
#		my $bodyresult= &pout($obj->{'response'},@body);
#		my $bodyresult= &outputline($obj,@body,"body");
		
#		LogMess("bodyresult=$bodyresult",1);
		chomp($filecon{body});
		print FCONTENT "$filecon{body}";
		

		print FCONTENT "\n##END|HOST\n";
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
