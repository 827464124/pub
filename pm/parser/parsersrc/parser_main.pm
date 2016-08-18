#----------------------------------------------------------------
# @(#) parser_main.pm 
#----------------------------------------------------------------

package MYPROGRAM;

# Make sure there is atleast a v5.003+ version of perl
# available.
require 5.003;

use lib '../perl_extensions/lib/perl5/site_perl', '../perl_extensions/lib/site_perl';

use strict;
use Getopt::Long;
use File::Basename;
use File::Find;

# Metrica specific utilities
use AudLog;
use DirLock;
use GenUtils;
use UserConfig;

# Engine
use Engine;

# Post-parser
use PostParser;

my ($c_file, $l_file, $l_level, $a_file);
my ($i_dir, $o_dir, $p_dir, $int_dir);
my $parser_name="Parser";
my $debug=0;
my $input_storage_dir=0;
my $intermediate_storage_dir=0;
my $output_storage_dir=0;
my $parse_count=0;
my $loader_size=0;
my $sum;



$Getopt::Long::ignorecase=1;
$Getopt::Long::autoabbrev=1;


my $result = GetOptions(
    "audit_file=s" => \$a_file,
    "debug!" => \$debug,
    "help" => \&help_routine,
    "input_directory=s" => \$i_dir,
    "intermediate_directory=s" => \$int_dir,
    "input_storage_dir=s" => \$input_storage_dir,
    "intermediate_storage_dir=s" => \$intermediate_storage_dir,
    "output_storage_dir=s" => \$output_storage_dir,
    "log_file=s" => \$l_file,
    "log_level=i" => \$l_level,
    "name=s" => \$parser_name,
    "output_directory=s" => \$o_dir,
    "parser_directory=s" => \$p_dir,
    "parse_count=s" => \$parse_count,
    "loader_size=i" => \$loader_size,
    "<>" => \&process_unknown_arguments);

# Initialising the log and Audit files.
if( defined($l_file) ) {
    LogInit($l_file, $l_level);
}

if( defined($a_file) ) {
    AudInit($a_file);
}

if( defined($input_storage_dir) && $input_storage_dir !=0 ) {
    if( not check_dir($input_storage_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$input_storage_dir'", 1);
        exit;
    }
}

if( defined($intermediate_storage_dir) && $intermediate_storage_dir !=0 ) {
    if( not check_dir($intermediate_storage_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$intermediate_storage_dir'", 1);
        exit;
    }
}

if( defined($output_storage_dir) && $output_storage_dir!=0 ) {
    if( not check_dir($output_storage_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$output_storage_dir'", 1);
        exit;
    }
}

my $fatal_error = 0;
# Checking that all the required arguments have been supplied
# and are valid
if( defined($i_dir) ) {
    if( not check_dir($i_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$i_dir'", 1);
        $fatal_error++;
    }
}
else {
    LogMess("Argument 'input_directory' must".
        " be supplied\n");
    $fatal_error++;
}

if( defined($int_dir) ) {
    if( not check_dir($int_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$int_dir'", 1);
        $fatal_error++;
    }
}
else {
    LogMess("Argument 'intermediate_directory' must".
        " be supplied\n");
    $fatal_error++;
}

if( defined($o_dir) ) {
    if( not check_dir($o_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$o_dir'", 1);
        $fatal_error++;
    }
}
else {
    LogMess("Argument 'output_directory' must".
        " be supplied\n");
    $fatal_error++;
}

if( defined($p_dir) ) {
    if( not check_dir($p_dir) ) {
        LogMess("Incorrect access permission on ".
            "directory '$p_dir'", 1);
        $fatal_error++;
    }
}
else {
    LogMess("Argument 'parser_directory' must".
        " be supplied\n");
    $fatal_error++;
}



if( $fatal_error ) {
    AudMess($parser_name." died from errors");
    exit $fatal_error;
}

# Do the Lock file stuff in the in_directory.  If the return
# from the lock file stuff is true, exit cleanly


if( lock_process($i_dir) ) {
    exit 3;
}

# Do the stuff with the Parser Engine
my $ret=1;
while ($ret) {
	# Check the size of the loader directory.  If it is bigger than the 
	# configurable value set in nprparser_start, quit and wait for the
	# next parser run.
	$sum = 0;
	if ( $loader_size != 0) {
		# Go through all the files in the directory finding their size
	  	find (\&dir_size, $o_dir);
	  	LogMess ("Loader dir size limit is $loader_size bytes, size of loader dir is $sum bytes",3);
		if ($sum > $loader_size) {
			AudMess("Parser output/Loader directory is $sum bytes. This exceeds limit of $loader_size bytes - wait for next run.");
			last ;
		}
	}else {
    	 	LogMess("Loader dir size utility not configured",3);
	}
	
	# Call parser engine
	$ret = engine( $i_dir, $int_dir, $input_storage_dir, $debug, $parse_count);
	
	# Starting the post parser.  It processes all the file in the
	# intermediate directory and generates output in the output
	# directory.  The module 'UserConfig.pm' is used to configure
	# the operation of the post parser.
	post_parser( $int_dir, $o_dir, $intermediate_storage_dir, $output_storage_dir, $debug);
}

# Removing the proces lock file from the in_directory
unlock_process();

# This is where the main program finishes
exit 0;

#------------------------------------------------------------

# Checking directories
sub check_dir($) {
    my $dir = shift;
    if( ! -d $dir || ! -w $dir || ! -r $dir || ! -x $dir ) {
        return 0;
    }
    return "True";
}

sub check_file($) {
    my $dir = shift;
    if( ! -e $dir || ! -r $dir ) {
        return 0;
    }
    return "True";
}

sub process_unknown_arguments {
    my $unknown = shift;

    LogMess("Unknown argument '$unknown'\n");

    if( -t STDERR ) { help_routine(); }
    
}

############################################################################################################
#  Sub routine: dir_size()
# 
#  Description:  Finds to sum of the size of files in a directory
#     In this code this sub is used by the File::Find subroutine,
#     which you call by passing a code reference, i.e. in this case &dir_size,
#     and a list of directories. For each of the directories find recursively call the function
#     Within subroutine dir_size $_ is set to the basename of the file being visited
#  Arguments:  
#
#  Returns: $sum - scalar, Sum of the files in the directory
#
sub dir_size {
     # We don't want to add the size of the directory to $sum
     unless (-d ) {
	$sum += -s;
     }
     return $sum;
}


sub help_routine {
    print join "",
    "Usage: $0 [mandatory-options] [optional-options]\n",
    "    Where 'mandatory-options' are:\n",
    "    --configuration_file       Parser engine configuration file\n",
    "    --input_directory          Directory of input files\n",
    "    --intermediate_directory   Directory to deposit input files in\n",
    "    --output_directory         Directory to place output files in\n",
    "    --parser_directory         The home directory of the parser\n",
    "\n",
    "    and 'optional-options' are:\n",
    "    --audit_file               A file where audit messages are written\n",
    "    --debug                    Debugging option.  Default is 'nodebug'\n",
    "    --input_storage_dir           Keeps all input files\n",
    "    --intermediate_storage_dir    Keeps all intermediate files\n",
    "    --output_storage_dir          Keeps all output files\n",
    "    --log_file                 A file where log messages are written\n",
    "    --log_level                A numeric log level.  defualt is 1\n",
    "    --name                     The parser name\n",
    "    --help                     This help message\n",
    "\n";

    exit 0;
}


