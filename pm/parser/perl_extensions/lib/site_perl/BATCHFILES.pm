#
#-------------------------------------------------------------------------------
# @(#) common-modules/BATCHFILES/BATCHFILES.pm common-modules_r2.1.3.2:cset.000733:10:10 04/26/00 %Z
#-------------------------------------------------------------------------------
#
#   Entry Points:   New, load_config, process
#
#   Author: Robert Hannaford
# 
# For improving the loader efficiency, a defined
# number/type of PIF files can be placed into one
# LIF file.
#
# Copyright (C) ADC Metrica 1998
#
package BATCHFILES;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

#use diagnostics;
use GenUtils;
use File::Basename;
use PIF_Handler;
use LIF_Writer;
use AudLog;

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

	$self->{keep_files} = "True";
	$self->{debug} = "True";

	$self->{PRODUCE_PIF} = 0;
	$self->{PRODUCE_LIF} = 'TRUE';

	$self->{OUTPUT_BLOCK_NAME} = undef;
	$self->{REDUNDANT_COUNTERS} = ();

	bless ($self, $class);
}

################################################################################
# Subroutine name:  load_config()
#
# Description:      Object configuration loading routine
#
# Arguments:        keep_files (scalar) - a boolean indicating whether or not
#                                         to store copies input and output files
#                                         once they have been finished with
#                   debug (scalar) - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          default
#
sub load_config {
	my $self = shift;
	($self->{keep_files}, $self->{debug}, $self->{'__config__'}) = @_;

	# Inserting all the configuration information into the objects records
	my $key;
	foreach $key ( keys %{$self->{'__config__'}} ) {
		$self->{$key} = $self->{'__config__'}->{$key};
	}
}

################################################################################
# Subroutine name:  process()
#
# Description:      Controls the processing of all the files that match the
#                   INPUT_FILE_DESCRIPTION field in the config information
#
# Arguments:        in_dir (scalar) - the name of the directory that the
#                                     input files are to be read from
#                   in_files (scalar) - a reference to a list that contains
#                                       all the files present in the input
#                                       directory that should be considered
#                                       for processing
#                   out_dir (scalar) - the name of the directory where all
#                                      output files should be written
#
# Returns:          (scalar) - the number of files processed
#
sub process {
	my ($self, $in_dir, $in_files, $out_dir, $local_hash_ref, @the_rest) = @_;

	# Declaring variables local to this subroutine
	my ($file, $num_succ_processed, $pattern, $ref);
	my (%hash_of_patterns, @partner_files, @files_still_required);

	# Looping over the list of input file descriptions and extracting
	# the pattern that matches the one regular expression in the
	# file name INPUT_FILE_DESCRIPTION
	foreach $pattern ( @{$self->{INPUT_FILE_DESCRIPTION}} ) {
		foreach $file ( @$in_files ) {
			# inserting the pattern file in a hash of patterns
			$hash_of_patterns{$1}->{$file} = () if( $file =~ /$pattern/ );
		}
	}

	# Loop over each pattern in the list
	PATTERN: foreach $pattern ( keys %hash_of_patterns ) {
		$ref = $hash_of_patterns{$pattern};
		@partner_files = keys %$ref;
		
		# Check to see if any of the partner files are younger than the keep time
		foreach ( @partner_files  ) {
			if( $self->{HOURS_TO_WAIT_FOR_PARTNER_FILES} > (-M $in_dir.'/'.$_)*24 ) {
				LogMess("$_ younger than keep time, @partner_files not processed", 3);
				push @files_still_required, @partner_files;
				next PATTERN;
			}
		}

		# Join the files together and produce a LIF file
		AudMess("For pattern '$pattern', batching files \n". join( "\n", @partner_files));
		$self->batch_files($in_dir, $out_dir, $pattern, @partner_files);
	}

	# Returning the list of files that are still required by this
	# rule
	@{$local_hash_ref->{FILES_STILL_WANTED}} = @files_still_required;
	return $num_succ_processed;
}

################################################################################
# Subroutine name:  batch_files()
#
# Description:      Controls the processing of all the files that match the
#                   INPUT_FILE_DESCRIPTION field in the config information
#
# Arguments:        in_files (scalar) - a reference to a list that contains
#                                       all the files present in the input
#                                       directory that should be considered
#                                       for processing
#                   out_dir (scalar) - the name of the directory where all
#                                      output files should be written
#                   pattern (scalar) - pattern used to construct output
#                                      filename
#                   files (list)     - List of files to be processed
#
# Returns:          (scalar) - success (0) or fail (-1)
#
sub batch_files {
	my ($self, $in_dir, $out_dir, $pattern, @files) = @_;

	my ($i_obj, $out_file, $o_obj, $file, $sortkey);
	my (@names, @values, $blk_name, $random, $name_start);
	my (%common_header, %counter_hash, %tmp_hash);

	$i_obj = PIF_Handler->New();

	# Generating a random number to go in the file name
	# to ensure it is unique.
	$random = int(rand(10000));

	# Construct the output filename
	if( exists($self->{OUTPUT_FILENAME_START}) &&
		$self->{OUTPUT_FILENAME_START}) {
		$name_start = $self->{OUTPUT_FILENAME_START};
	}

	# Constructing the final output filename from its different
	# components. If a file of the same name already exists,
	# increment the random number part of the filename until a
	# name is found that is not currently being used.
	$out_file = join '-#-', $name_start, $pattern, $random, 'BF.lif';
	while( -e $out_dir.'/'.$out_file ) {
		$random++;
		$out_file = join '-#-', $name_start, $pattern, $random, 'BF.lif';
	}
	
	# Now constructing the temporary file name that will be used
	# whiel this file is being processed
	$out_file = join '-#-', $name_start, $pattern, $random, 'BF.pt';

	AudMess("Output file '$out_file'");

	# Starting the LIF file if its wanted
	# Produce the output file.
	$o_obj = LIF_Writer->New();
	$o_obj->Open($out_dir.'/'.$out_file);

	$o_obj->Open_Block();

	# Printing the header information to the file
	$o_obj->Block_Info(\%common_header);
	$o_obj->WriteToFile();

	# Looping over all the files to be joined together
	foreach $file ( @files ) {
		# Each file's contents are concatennated to LIF
		# Previous file's contents are no longer required
		undef (%common_header);
		undef (%counter_hash);
		
		# Open the file
		$i_obj->Open($in_dir.'/'.$file);

		# Read in the header information
		$i_obj->Read_Names(\@names);
		$i_obj->Read_Values(\@values);

		# Put the header information in the common header hash
		@common_header{@names} = @values;

		# Deleting things from the header record that don't apply to the
		# combined data.  First checking that the user has specified
		# a list of header counters to delete.
		if( exists $self->{REDUNDANT_HEADER_COUNTERS} ) {
			foreach ( @{$self->{REDUNDANT_HEADER_COUNTERS}} ) {
				delete $common_header{$_};
			}
		}

		$o_obj->Open_Block();
		# Printing the header information to the file
		$o_obj->Block_Info(\%common_header);
		$o_obj->WriteToFile();

		# Looping over all the data blocks in the file
		while( $blk_name = $i_obj->Read_Names(\@names) ) {

			# Creating a name for output block name if not provided
			if( exists($self->{OUTPUT_BLOCK_NAME}) &&
				$self->{OUTPUT_BLOCK_NAME}) {
				$blk_name = $self->{OUTPUT_BLOCK_NAME};
			}

			# Loop over all the lines of data
			while( $i_obj->Read_Values(\@values) ) {
			
				@counter_hash{@names}=@values;

				# Delete the redundant counters from the hash
				foreach ( @{$self->{REDUNDANT_COUNTERS}} ) {
					delete $counter_hash{$_};
				}

				# Writing the Block into the LIF file
				$o_obj->Create_Block($blk_name, \%counter_hash);
			}
		}

		$o_obj->Close_Block();
	}

	# Closing and storing the completed Loader Input File
	$o_obj->Close();

	# Rename the completed output file to the appropriate extension
	# and store it if wanted
	store_processed_file($self->{keep_files}, 0, $self->{debug},
		rename_completed_file('.pt', '.lif', $out_dir.'/'.$out_file));

	return 0;
}

1; # So the use or require works
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BATCHFILES - A Perl extension that produces one Metrica/NPR Loader file
             from multiple parser intermediate files.

=head1 SYNOPSIS

  use ACCUMULATE;

  $obj_id = BATCHFILES->New();

  $obj_id->load_config( $keep_files, $debug, \%config )

  $obj_id->process( $in_dir, \@in_files, $out_dir )

=head1 DESCRIPTION

  There are three entry points to this object.  The first 'New' creates the
  ibject and stores the identifier in the scalar varaible '$objid'.  The second
  'load_config' allows the user to configure the object to run as they desire.
  The third 'process' goes through and processes the files in the input directory
  '$in_dir' as defined by the configuration information.  The output
  of the process is output into the directory '$out_dir'.

=head1 AUTHOR

B. Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
