#
#-------------------------------------------------------------------------------
# @(#) common-modules/Engine/Engine.pm common-modules_r2.1.3.2:cset.000796:40:40 11/20/00 @(#)  
#-------------------------------------------------------------------------------
#
#
#   Author: Robert Hannaford
# 
# 
#   This module controls the invocations of the 
#   vendor interfaces.
#
#
#   Copyright (C) ADC Metrica 1998
#
package Engine;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(engine);
$VERSION = '0.01';

use File::Basename;
use EngineConfig;
use AudLog;
use GenUtils;

################################################################################
# Subroutine name:  engine()
#
# Description:    The engine verifys the and invokes the rule-type
#                 to be applied to the selected files.
#
# Arguments:        in_dir (scalar) - the name of the directory that the
#                                     input files are to be read from
#                   out_dir (scalar) - the name of the directory that the
#                                     files are to be written to 
#                   input_storage_dir (scalar) - directory where files
#                                     will be stored.
#                   debug - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#
#
# Returns:         default 
#
sub engine {
	my ($in_dir, $out_dir, $input_storage_dir, $debug, $p_count) = @_;
	# Declaring variables local to this subroutine
	my ($obj_id, $rule, $config, $retval, @filenames);
	AudMess("Start Parser Engine");

	# Getting the configuration information from the EngineConfig module
	$config = engine_config();

	my ($allowed_depth, $current_depth, $ret);
	my $processedAllFiles = 0;

	# Looping over the list of Vendor Interfaces that will
	# be used to process the files in the input directory tree
	RULE: foreach $rule ( @$config ) {

		# Checking that RULE_TYPE has been specified for this rule
		if( not exists($rule->{RULE_TYPE}) ) {
			LogMess("Option 'RULE_TYPE'must be supplied for each rule", 1);
			next RULE;
		}

		# Addition of New Vendor Interface
		# Requiring new Vendor Interface to process files	
		# Checking that the rule is valid
		eval { require $rule->{RULE_TYPE}.".pm"};
		if ($@) {
			LogMess("'".$rule->{RULE_TYPE}."' is not a valid rule in EngineConfig. \nPerl error: " .$@ ,1);
			next RULE;
		}
		
		# Using the Rule Name in the Log message if it is specified
		# for this rule.  Else just use the rule type in the log
		# message.
		if( exists $rule->{RULE_DESC} and $rule->{RULE_DESC} ) {
			AudMess("Processing rule '".$rule->{RULE_DESC}."', type '".
				$rule->{RULE_TYPE}."'");
		}
		else {
			AudMess("Processing rule type '".$rule->{RULE_TYPE}."'");
		}

		# Checking that the option INPUT_FILE_DESCRIPTION has
		# been supplied.
		if( !exists($rule->{INPUT_FILE_DESCRIPTION})
			||  !($rule->{INPUT_FILE_DESCRIPTION}) ) {
			LogMess("The option 'INPUT_FILE_DESCRIPTION' must be supplied for this rule", 1);
			next RULE;
		}

		# Checking that the INPUT_FILE_DESCRIPTION is a scalar
		# or a reference to a list.
		if( ref($rule->{INPUT_FILE_DESCRIPTION}) ne 'ARRAY'
			&& ref($rule->{INPUT_FILE_DESCRIPTION}) ne '' ) {
			LogMess("Invalid value for 'INPUT_FILE_DESCRIPTION'", 1);
			next RULE;
		}

		# Finding out how many sub directories deep the input
		# directories are nested.
		$allowed_depth = 0;
		if( exists($rule->{INPUT_DIR_DEPTH})
			&& 0 < $rule->{INPUT_DIR_DEPTH} ) {
			$allowed_depth = $rule->{INPUT_DIR_DEPTH};
		}

		# Creating the object identifier for this rule.
		$obj_id = $rule->{RULE_TYPE}->New();

		# Inserting the name of the output directory into the
		# hash containing the configuration information for this
		# Vendor Interface.
		$rule->{INPUT_DIR} =$in_dir;
		$rule->{OUTPUT_DIR} = $out_dir;

		# Load the configuration stuff into the object
		$ret = $obj_id->load_config($input_storage_dir, $debug, $rule);
		if( $ret ) {
			LogMess("Error, Incorrect configuration options for rule '$rule->{RULE_TYPE}'", 1);
			next RULE;
		}

		# Use the object to process the rule
		$current_depth = 0;
		$ret = process_dir($in_dir, $input_storage_dir, $debug,
			$allowed_depth, $current_depth, $rule, $obj_id, \@filenames);



		# Drip Feed Mechanism
		# This determines whether the Engine and Post-parser run again
		$processedAllFiles = -2 if $ret == -2 ;
	
	}

		AudMess("Finish Parser Engine");


	#count the number of files successfully parsed
	if($p_count) {
		if ($retval=parser_utility($p_count, $debug, @filenames)and $debug){
			LogMess(" Debug : nonzero return value $retval from sub parser_utility ", 4);
		}
	}else{
		LogMess("Parse Count Utility: Is not required",4);
	}

	# Drip Feed Mechanism
	# checking whether the Engine and Post-parser runs again
	return $processedAllFiles ? -2 : 0;
}




###########################################################################################################################
# Subroutine name: parser_utility
#
# Description: 	initialiser of NPR 3.1 parser utility.  Matches files 
#		to the description and counts the number
#              	of sucessfully parsed files matching that description, 
#		writing to the appropriate file.
#
# Arguments: 	p_count (scalar) - The name of the npr root directory
#
# 		debug - a boolean indicating whether or not
#		the parser is being run in debug mode
#
#		filenames (array) - contains the names of the files
# 		sucessfully parsed
#
# Return: scalar value  -0	All is well
#			-1	Failed on p_count test (no counting)
#			-2	Failed to open cofiguration file (no counting
#
#


# Count the number of files parsed in this engine.

sub parser_utility {
	my($p_count, $debug, @filenames) = @_;
	my($rtnval);
AudMess("Starting parser utility for $p_count");

LogMess("parsed files are\n". join("\n", @filenames) ." for this engine", 5);
# check that $p_count is a valid directory

	# count the number of files parsed in by this engine call
	my ($match, $label,);
		if ( ! -d $p_count || ! -r $p_count || ! -w $p_count || ! -x $p_count) {
                	LogMess ("Parse Count Utility: $p_count is not a directory or has the wrong access permission", 3);
                	$p_count = 0;
                	return 1;
                }
	if ($p_count) {
		my (@new, $i, $number_unknown, $c_match) ;
        	foreach (@filenames) {
			push (@new, $_);
   			}

 	       unless (open (CONF, '<'.$p_count."/configuration/parse.conf") ) {
        	        LogMess("Warning, Parse Count Utility: Cannot open $p_count/configuration/parse.conf", 3);
                	return 2;
			}

		# Count the number of matched files parsed
       		 my @data = <CONF>;
       		 close CONF;
       		 while (@data) {
		 	my $line = shift @data;
                	if ($line =~ /^Match|^-------|^unknown/) {
                       	next;
                	}else {
                      		($match, $label) = split (/\s+/, $line, 2);

                    		# strip spaces out of label name
                       		$label =~ s/\s+//g;
                       		$c_match = 0;
                      		for ($i=0; $i<@filenames; $i++){
                                	if ($filenames[$i]  =~ /$match/ ) {
                                     		# Found a match
                                     		$c_match += 1;
                                     		undef ($new[$i]);
					}
				}
                	}

  	              if($c_match){
				if ($rtnval=count_parse($p_count, $label, $match, $c_match) and $debug)  {
				LogMess (" Debug : nonzero return value $rtnval from sub count_parse \n",4);
				} 
                	}
         	}  #end of while loop
	

	# Count the number of unmatched files parsed
        	 $number_unknown = 0;
	 	foreach (@new) {
			if ($_){ 
			$number_unknown++; 
	      		}
         	}
 
		if($number_unknown){
			$label= "UNKNOWN";
			$match= "unknown";
        		if ($rtnval=count_parse($p_count, $label, $match, $number_unknown) and $debug) {
				LogMess(" Debug : nonzero return value $rtnval from sub count_parse \n", 4);
			}
		}
	}
AudMess("Finished Parser Utility");

return 0;
}
#####################################################################################################################################
# Subroutine name:  count_parse()
# Description: checks files are valid and accessible, reads and writes to the counter files 
#   
# Arguments:	label (scalar)	 name of file to open file as
#		match (scalar)	 string of characters to match file names against
#		c_match (scalar) number of files successfully parsed by the engine
# Return : scalar value  0 - alls well
#			 1 - not able to open new file (disk full?)
#			 2 - counter files cannot be accessed or written to
#			 3 - cannot open the counter file
#			 4 - cannot open to write to counter file
#			 5 - counter file has the wrong format


sub count_parse {
	my($p_count, $label, $match, $c_match) = @_;
	my @count;
	if ( ! -e $p_count."/result/parse_unit/".$label) {
		if (new_file($p_count."/result/parse_unit/".$label)) {
			return 1;
	        }	
	}
		# Check the files for read and write access
	if ( not file_check($p_count."/result/parse_unit/".$label)) {
		LogMess("warning: Parser Count Utility:  File $p_count/result/parse_unit/$label has incorrect access permissions", 2);
		return 2;
	}else{
	
		unless (open (UNIT, '<'.$p_count."/result/parse_unit/". $label) ) {
                        LogMess("Warning, Parser Count Utility: Cannot open file $p_count/result/parse_unit/$label ", 2) ;
                	return 3;
		}else{

                        LogMess("Parse Count Utility: match = $match; label= $label;", 4);
                        
			@count = <UNIT>;
                        close UNIT;
                        chomp ($count[0]);
                        LogMess ("Parse Count Utility: Found matches count = $c_match and number already parsed = $count[0] for $match files",4);
                        if ($count[0] =~ /^\d+$/ ) {
                                $count[0] += $c_match;
                                LogMess("Parse Count Utility: The value of count is now $count[0]",4);
                                unless (open  (UNIT, '>'.$p_count."/result/parse_unit/".$label)) {
                                        LogMess ( "WARNING: Parser Count Utiltiy: Failed to write to $p_count/result/parse_unit/$label", 3);
                                        return 4;
                                }
                                print UNIT $count[0] . "\n";
                                close UNIT;
                        }else{
                                LogMess("WARNING: Parse Count Utility: ".$p_count."/result/parse_unit/".$label." has the wrong format", 3);
                                return 5;
                        }

              }
        }
return 0;
}



####################################################################################################################################
#
# Subroutine name: file_check()
#
# Description: checks files for read and write access
#
# Arguments:   none
#
# returns: scalar value 0 - There are not read or write permissions
#
#          scalar value 1 - There are read and write permissions
#
 
# Checking files for read and write access
sub file_check($){

my $file = shift;
	if( ! -r $file || ! -w $file){
		return 0;
		}
	return 1;
} 

#################################################################################################################################
#
# Subroutine name: new_file()
#
# Description: Creates counter file with the name label with
#	       read and write access	
#
# Arguments:   none
#
# returns: scalar value 1 - Cannot open the file ( disk full? or bad directory )
#		        2 - File created o.k.
#

#creating file if the relevent file does not exist

sub new_file($){
    my $file = shift;
	open (UNIT, '+>'.$file) or return 1;
	print UNIT "0";
	close UNIT;
LogMess("Creating $file for counter input", 4);
return 0;

}

################################################################################
# Subroutine name:  process_dir()
#
# Description: 
#  process_dir is a recursive function that processes all the
#  files in a directory and will go into any sub directories
#  that it finds if it has been configured to.
#
# Arguments:        in_dir (scalar) - the name of the directory that the
#                                     input files are to be read from
#                   out_dir (scalar) - the name of the directory that the
#                                     files are to be written to
#                   input_storage_dir (scalar) - directory where files
#                                     will be stored.
#                   debug - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   allowed_depth (scalar) - The maximum depth of
#                                     sub-directories to search for files.
#                   current_depth (scalra) - current depth from main
#                                     directory.
#
# Returns:          Number of files processed 
#
sub process_dir {
	my ($in_dir, $input_storage_dir, $debug,
		$allowed_depth, $current_depth, $rule, $obj_ref, $filenames_ref) = @_;
	################################################################################
	# Subroutine name:  file_sort()
	#
	# Description:      In-line sort routine which does an ordinary numeric sort
	#
	# Arguments:        none
	#
	# Returns:          sorted file list
	#
	sub file_sort {
		return (-M shift @_) <=> (-M shift @_);
	}

	AudMess("Processing files in '".$in_dir."'");

    # Crash Recovery Mechanism Part 1
    # Load crashed file name from input directory,
    # and rename crashed file to .bad
    my($crashedFile);
    if (-e $in_dir."/.recovery") { 
        open RECOVERY, $in_dir."/.recovery";
        $crashedFile = <RECOVERY>;
        close RECOVERY;
		if ((rename $in_dir."/".$crashedFile, $in_dir."/".$crashedFile.".bad") == 1) {
        	AudMess("Renaming crashed file, $crashedFile to a .bad file");
		} else {
			AudMess("Unable to rename crashed file $crashedFile to .bad");
		}
    }

	# Getting the list of files to process, ignoring UNIX hidden files,
	# ones with the '.bad' and '.pt' extensions.
	my @in_files = grep !/^\./, grep !/.bad$/,
		grep !/.pt$/, files_in_dir( $in_dir );

	# Drip Feed Mechanism
	# Sorts the files in the input directory according to
	# the ORDER_OF_FILES field
	if ( exists $rule->{ORDER_OF_FILES} and $rule->{ORDER_OF_FILES} ) {
		if($rule->{ORDER_OF_FILES} eq "YOUNGEST_FIRST") {
			@in_files = sort {file_sort($in_dir.'/'.$a, $in_dir.'/'.$b)} (@in_files);
			LogMess("Files list sorted with $rule->{ORDER_OF_FILES}",4);
		} elsif($rule->{ORDER_OF_FILES} eq "OLDEST_FIRST") {
			@in_files = reverse sort {file_sort($in_dir.'/'.$a, $in_dir.'/'.$b)} (@in_files);
			LogMess("Files list sorted with $rule->{ORDER_OF_FILES}",4);
		} elsif($rule->{ORDER_OF_FILES} eq "" || $rule->{ORDER_OF_FILES} eq "DIRECTORY_ORDER") {
			LogMess("File list will be processed in DIRECTORY_ORDER",4);
		} else {
			LogMess("Invalid data in ORDER_OF_FILES field",1);
		}
	} else {
			LogMess("File list will be processed in DIRECTORY_ORDER",4);
	}

	# Drip Feed Mechanism
	# Extracting the number of files to process according
	# to the NUMBER_OF_FILES_TO_PROCESS field
	my($totalFiles, $filesLeftToProcess);
	if( exists $rule->{NUMBER_OF_FILES_TO_PROCESS} 
			and $rule->{NUMBER_OF_FILES_TO_PROCESS}) {
		if( $rule->{NUMBER_OF_FILES_TO_PROCESS} =~ /\D/) {
			LogMess("Error, < $rule->{NUMBER_OF_FILES_TO_PROCESS} > is not a number value",1);
			return 0; 
		}
		if( $rule->{NUMBER_OF_FILES_TO_PROCESS} <= 0 ) {
			LogMess("Invalid value in NUMBER_OF_FILES_TO_PROCESS",1);
			return 0;
		} else {
			$totalFiles = $rule->{NUMBER_OF_FILES_TO_PROCESS};
			LogMess("Processing ".$totalFiles." file(s) only",4);
		}
	} else {
		$totalFiles = scalar(@in_files);
	}

	# Get the list of files that are to be processed by this rule.
	# But first checking if they have provided a list of regular
	# expressions or just one.
	my ($check_file_desc, $pattern);
	if( ref($rule->{INPUT_FILE_DESCRIPTION}) eq "ARRAY" ) {
		$check_file_desc = \&Engine::check_array;
	}
	else {
		$check_file_desc = \&Engine::check_scalar;
	}

	# Looping over all the files in the current directory
	my ($name, $ret, $num_files, $t_file, $index, $orig_filename, $new_in_file);
	my($tempName, %headerFields, %filenameFields, %directoryFields);
	$num_files = 0;
	FILE: while( @in_files ) {
		# Exit loop when finished processing $totalFiles
		last FILE if ($totalFiles <= 0);
	
		$t_file = shift @in_files;
		$name = $in_dir.'/'.$t_file;
	
		# Check if the current file is a directory
		if( -d $name && -r $name && -w $name && -x $name ) {

			# Checking if we are already down too many levels
			# of directories.
			if( $allowed_depth > $current_depth ) {
				$ret = process_dir( $name, $input_storage_dir, $debug,
					$allowed_depth, $current_depth + 1, $rule, $obj_ref, $filenames_ref);
				# Return correct value if there are more files to process 
				return $ret if $ret==-2;
			}
			else {
				LogMess("Skipping directory '".$in_dir."', too deep", 3);
			}

			# Get the next file to process.
			next FILE;
		}

		# Checking if the current file matches the file descriptions
		# to be processed by this Vendor Interface.
		next FILE if !&$check_file_desc($t_file, $rule);

		# Crash Recovery Mechanism Part 2
		# Store current file that's being processed in case parser crashs
		LogMess("Storing current file, $t_file in '.recovery' file",4);
		open RECOVERY, ">$in_dir/.recovery";
		print RECOVERY $t_file;
		close RECOVERY;

		# Error Checking on File Access
		# Checking if the file is a normal file.
		if( -f $name && -r $name && -w $name ) {

			$orig_filename = undef;
			# Checking if the file is compressed
			if( $name =~ /\.Z$/ ) {
				LogMess("Create uncompressed copy of '".
					basename($name)."'", 3);

				# Uncompress the file using the system zcat command
				$new_in_file = uncompress($name);
				if( ! $new_in_file ) {
					AudMess("ERROR processing '${name}'; Renaming '$name' to '.bad'");

					rename ${name}, ${name}.'.bad';
					return 0;
				}

				$orig_filename = $name;
				$name = $new_in_file;
			}

			# Filename Component Extraction 
			# Extract filename components for inclusion
			# in a PIF header
			if(exists $rule->{FILENAME_HEADER_FIELDS} and $rule->{FILENAME_HEADER_FIELDS}) {
				@filenameFields{keys %{$rule->{FILENAME_HEADER_FIELDS}}} = values %{$rule->{FILENAME_HEADER_FIELDS}};
				LogMess("Extracting FILENAME_HEADER_FIELDS",4);
				foreach (keys %filenameFields) {
					$tempName = basename($name);
					$tempName =~ s/$filenameFields{$_}/$1/;
					$filenameFields{$_} = $1;
				}
			}

			# Directory Name Extraction
			# Extract directory name component for inclusion
			# in a PIF header
			if(exists $rule->{DIRECTORY_HEADER_FIELDS} and $rule->{DIRECTORY_HEADER_FIELDS}) {
				@directoryFields{keys %{$rule->{DIRECTORY_HEADER_FIELDS}}} = values %{$rule->{DIRECTORY_HEADER_FIELDS}};
				LogMess("Extracting DIRECTORY_HEADER_FIELDS",4);
				foreach (keys %directoryFields) {
					$tempName = dirname($name);
					$tempName =~ s/$directoryFields{$_}/$1/;
					$directoryFields{$_} = $1;
				}
			}

			# Component Extraction
			# Merging Hashes
			%headerFields = (%filenameFields, %directoryFields);

			# Use the Vendor Interface to process the data file
        	AudMess("Processing '".basename($name)."'");
			$ret = $obj_ref->process_file($name, \%headerFields);
        	AudMess("Finished '".basename($name)."'");
			
			# Drip Feed Mechanism
			# Check return value from Vendor Interface
			$totalFiles-- if $ret==0 ;

			# If it is an uncompressed copy of a file that is being
			# processed, delete the uncompressed copy of the input
			# file and set the $in_file back to the original name
			if( $orig_filename ) {
				# Deleting the uncompressed copy of the input file
				LogMess("Delete Uncompressed copy of '".
					basename($orig_filename)."'", 3);
				unlink $name;

				$name = $orig_filename;
			}

			# Checking the return value from the Vendor Interface.
			# If a '0' is returned the file was processed Ok.
			if( !$ret ) {
				push(@$filenames_ref, basename($name));
				if( $debug || (exists($rule->{DO_NOT_DELETE}) && $rule->{DO_NOT_DELETE}) ) {
				}
				else {
					if (create_store_dir ($rule, \$input_storage_dir, $name) ) {
					   store_processed_file($input_storage_dir, 'Delete_Original',
						$debug, $name);
					}else {
					   LogMess ("Couldn't store file '$name' correctly",2);
					}
				}
			}
			# If a '-1' was returned, an error occurred so
			# rename the file to '.bad'
			elsif( -1 == $ret ) {
				if( !$debug ) {
					AudMess("ERROR processing '${name}'; Renaming '$name' to '.bad'");

					rename $name, $name.'.bad';
				}
			}
			# If a '-2' was returned, basically the configuration
			# information for this interface was not compatible
			# with this file.  Don't rename or delete this file.
			elsif( -2 == $ret ) {
			}
			# If it gets this far, the Vendor Interface has returned
			# something that is not recognised.
			else {
				LogMess("Unrecognised return value from '".
					$rule->{RULE_TYPE}."'", 1);
			}

		} else {
			LogMess("File $t_file has no read/write permissions or is not owned by user",1);
		}

		$num_files++;

		# Crash Recovery Mechanism Part 3
		# Remove recovery file since parser did not crash
		unlink $in_dir."/.recovery";
		LogMess("Removing .recovery file from input directory",4);
	}
	
	AudMess("Processed '".$num_files."' files in '".$in_dir."'");

	# Drip Feed Mechanism
	# If there is any files in the directory that have not been looked at by
	# the current interface the return -2 to tell the Engine that it needs run
	# again.
	if (@in_files) {
		LogMess("Files in this directory still need to be processed",4);
		return -2;
	} else {
		LogMess("All Files Processed",4);
		return 0;
	}
}

################################################################################
# Subroutine name:  uncompress()
#
# Description:      
#
# This function creates an uncompressed copy of a compressed
# file.  It takes one filename as its only arguement.  It
# returns the name of the uncompressed copy of the file it
# has created.  On error it returns 0;
#
# Arguments:        file (scalar) - Name of the file to be processed
#
# Returns:          name of uncompressed file 
#
sub uncompress {
	my $file = shift;

	my $new_file = $file;
	$new_file =~ s/\.Z$//;

	# Uncompressing the file using the system 'zcat' command
	my $rc = system( "zcat '${file}' > '${new_file}'" );

	# Checking the return code from the system function
	if( 0 != $rc ) {
		LogMess("ERROR uncompressing '".$file."'", 1);
		unlink $new_file;
		return 0;
	}

	return $new_file;
}

################################################################################
# Subroutine name:  check_array()
#
# Description:      Checks for valid contents of an array.  
#
# Arguments:        fname (scalar) - filename
#
# Returns:          default
#
sub check_array {
	my ($fname, $rule) = @_;

	my $pattern;
	foreach $pattern ( @{$rule->{INPUT_FILE_DESCRIPTION}} ) {
		if( $fname =~ /$pattern/ ) {
			return 1;
		}
	}
	return 0;
}

################################################################################
# Subroutine name:  check_scalar()
#
# Description:      Checks for valid array.  
#
# Arguments:        fname (scalar) - filename
#
# Returns:          default
#
sub check_scalar {
	my ($fname, $rule) = @_;

	return ($fname =~ /$rule->{INPUT_FILE_DESCRIPTION}/ ) ? 1 : 0;
}

################################################################################
# Subroutine name:  create_store_dir()
#
# Description:     Checks whether the input_storage_dir needs sub dirs to accomodate
#		the hierarchy of input files
#
# Arguments:  $rule - The rule's config
#		$input_storage_ref  - reference to full path of input_storage_dir
#		$name - full path name of file that is to be stored
#
# Returns:  1 - There's an appropriate storage directory to store file
#	    0 - Can not create sub directory to store file
#
sub create_store_dir {
  my ($rule, $input_storage_ref, $name) = @_;
  my $real_in_dir = $rule->{INPUT_DIR};
  my $current_in_dir = dirname($name);

  if ( $real_in_dir ne $current_in_dir ) {
      	# Not in highest level of input directory	
    	$current_in_dir =~ s/^$real_in_dir\///;
    	my @levels = split ( /\//, $current_in_dir);
	my $store_dir =  $$input_storage_ref ;
  	LogMess ("The input storage dir needs a hierarchy of ". join ('/', @levels), 5);	
	foreach (@levels) {
	     # Build path for sub dir
	     $store_dir = $store_dir. "/".$_;
	     unless ( -d $store_dir &&  -w $store_dir &&  -r $store_dir &&  -x $store_dir ) {
	         # Something is wrong with dir - i.e. it might not exists yet
		 # So try to create
		 unless (mkdir ($store_dir, 0755) ) {
			# Could not create directory
			return 0;
		 } 
		 LogMess ("Created an input storage sub dir '$_' (i.e. $store_dir)", 3);
	     }
	}
    	# Successful directory exists and has correct permissions
    	$$input_storage_ref = $store_dir;
    	return 1;
  }else {
     # File was in highest level of input directory,
     # so will be stored in the highest level dir of storage dir
     # Nothing to do
     return 1;
  }
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Engine - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Engine;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Engine was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
