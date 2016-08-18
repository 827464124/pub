#
#--------------------------------------------------------------------
# @(#) common-modules/PostParser/PostParser.pm common-modules_r2.1.3.2:cset.000565:15:15 06/08/99 @(#)
#--------------------------------------------------------------------
#
#
#   Author: Robert Hannaford
# 
# 
#   This module controls the invocations of the 
#   post-parser rules interfaces.
#
#   Copyright (C) ADC Metrica 1998
#
package PostParser;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( post_parser );
$VERSION = '0.01';

use strict;
use File::Basename;

# Including all the ADC Metrica specific extensions
use AudLog;
use GenUtils;
use DirLock;
use UserConfig;

################################################################################
# Subroutine name:  post_parser()
#
# Description:    The post-parser processes the input directory 
#                 and invokes the rules to be applied to the selected files.
#
# Arguments:        in_dir (scalar) - the name of the directory that the
#                                     input files are to be read from
#                   out_dir (scalar) - the name of the directory that the
#                                     files are to be written to 
#                   intermediate_storage_dir (scalar) - directory where int. 
#                                     files will be stored.
#                   output_storage_dir (scalar) - directory where output 
#                                     files will be stored.
#                   debug - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#
#
# Returns:         default 
#
sub post_parser {
	my ($in_dir, $out_dir, $intermediate_storage_dir, $output_storage_dir,
		$debug) = @_;

	# Declaring variables local to this subroutine
	my ($file, $in_file, $out_file, $obj_id);
	my (@in_files, $rule, $config, %obj_hash);
	my (%local_hash, %files_still_wanted);

	AudMess("Start Post Parser");

	# Getting the configuration information from the UserConfig module
	$config = postparser_config();

	# Getting the list of files to process, ignoring UNIX hidden files,
	# ones with the '.bad' and '.pt' extensions.
	@in_files = grep !/^\./, grep !/.bad$/, grep !/.pt$/, files_in_dir( $in_dir );

	RULE: foreach $rule ( @$config ) {

		# Checking that the rule is a valid type
       	if( not exists($rule->{RULE_TYPE}) ) {
        	LogMess("Option 'RULE_TYPE'must be supplied for each rule", 1);
        	next RULE;
      	}

		# Addition of New Post-parser tool
		# Requiring new Post-parser tool to process files       
		# Checking that the rule is valid
		eval { require $rule->{RULE_TYPE}.".pm"};
		if ($@) {
			LogMess("'".$rule->{RULE_TYPE}."' is not a valid rule in UserConfig",1);
			next RULE;
		}

		# Using the Rule description in the Log message if it is
		# specified for this rule. Or use the rule name, which
		# is the old name of this option, is it is specified.
		# Else just use the rule type in the log message.
		if( exists $rule->{RULE_DESC} and $rule->{RULE_DESC} ) {
			AudMess("Processing rule '".$rule->{RULE_DESC}."', type '".
				$rule->{RULE_TYPE}."'");
		}
		elsif( exists $rule->{RULE_NAME} and $rule->{RULE_NAME} ) {
			AudMess("Processing rule '".$rule->{RULE_NAME}."', type '".
				$rule->{RULE_TYPE}."'");
		}
		else {
			AudMess("Processing rule type '".$rule->{RULE_TYPE}."'");
		}

		# Checking that the option INPUT_FILE_DESCRIPTION has
		# been supplied and that it has a valid value.  That is
		# a scalar value or a reference to a list.
		if( !exists($rule->{INPUT_FILE_DESCRIPTION})
			||  !($rule->{INPUT_FILE_DESCRIPTION}) ) {
			LogMess("Error, the option 'INPUT_FILE_DESCRIPTION' must be supplied", 1);
			next RULE;
		}
		elsif( ref($rule->{INPUT_FILE_DESCRIPTION}) ne 'ARRAY' &&
			ref($rule->{INPUT_FILE_DESCRIPTION}) ne '' ) {
			LogMess("Invalid value for 'INPUT_FILE_DESCRIPTION'", 1);
			next RULE;
		}

		# Creating the object identifier for this rule.
		$obj_id = $rule->{RULE_TYPE}->New();

		# Load the configuration stuff into the object
		$obj_id->load_config($output_storage_dir, $debug, $rule);

		# Initialising the list is files that should not be deleted or
		# stored when the intermediate directory is cleaned up
		@{$local_hash{FILES_STILL_WANTED}} = ();
		

		# Use the object to process the rule
		if( 0 > $obj_id->process($in_dir, \@in_files, $out_dir, \%local_hash) ) {
			AudMess("ERROR processing this Rule");
		}

		# Inserting the list of FILES_STILL_WANTED returned from
		# the process subroutine into the hash of files that are
		# not to be deleted when this routine cleans up its input
		# directory
		if( length(@{$local_hash{FILES_STILL_WANTED}}) ) {
			@files_still_wanted{@{$local_hash{FILES_STILL_WANTED}}} = ();
		}

		# If this rule has added files to the intermediate directory
		# then we should reread the directory so that the next rule
		# can process the new files if it wants.
		if( exists($rule->{PRODUCE_PIF}) and $rule->{PRODUCE_PIF} ) {
			@in_files = grep !/^\./, grep !/.bad$/, grep !/.pt$/, files_in_dir( $in_dir );
		}
	}

	AudMess("Finish Post Parser");

	return if $debug;

	# Deleting/storing the files in the intermediate directory
	# that are no longer needed.
	AudMess("Remove unnecessary files");
	my $num_files = 0;
	my $t_file;
	foreach $t_file ( @in_files ) {

		# Checking if the current file should be deleted/stored
		# or not.
		next if exists($files_still_wanted{$t_file});

		store_processed_file($intermediate_storage_dir, "Delete_Original",
			$debug, $in_dir."/".$t_file);
		$num_files++;
	}
	AudMess("Removing '$num_files' files");

	return;
}

1;
