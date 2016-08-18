#-------------------------------------------------------------------------------
# @(#) common-modules/JOIN/JOIN.pm common-modules_r2.1.3.2:cset.000777:11:11 11/16/00 @(#) 
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package JOIN;

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

#############################################################
# Subroutine name:  New()
#
# Description:      Object initialisation routine
#
# Arguments:        None
#
# Returns:          Object reference
# 
# Note:            	Sets some default values
#
sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{keep_files} = "True";
	$self->{debug} = "True";

	$self->{PRODUCE_PIF} = 0;
	$self->{PRODUCE_LIF} = 'TRUE';

	$self->{COUNTERS_TO_JOIN_ON} = ();
	$self->{OUTPUT_BLOCK_NAME} = undef;
	$self->{REDUNDANT_COUNTERS} = ();

	bless ($self, $class);
}

#############################################################
# Subroutine name:  load_config()
#
# Description:      Object configuration loading routine
#
# Arguments:        keep_files(scalar) - indicating where to store output
#       									files (if defined).
#                   debug (scalar) - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          nothing
#
sub load_config {
	my $self = shift;
	($self->{keep_files}, $self->{debug}, $self->{'__config__'}) = @_;

	# Inserting all the configuration information into the objects records
	my $key;
	foreach $key ( keys %{$self->{'__config__'}} ) {
		$self->{$key} = $self->{'__config__'}->{$key};
	}

	# Checking if an old option name has been used.  If it has
	# copy it to the new option name.
	if( exists($self->{NON_APPLICABLE_HEADER_COUNTERS}) &&
		! exists($self->{REDUNDANT_HEADER_COUNTERS}) &&
		! $self->{REDUNDANT_HEADER_COUNTERS} ) {
		$self->{REDUNDANT_HEADER_COUNTERS} =
			$self->{NON_APPLICABLE_HEADER_COUNTERS};
	}

}

##############################################################
# Subroutine name:  process()
#
# Description:      Controls the processing of all the files that match the
#                   INPUT_FILE_DESCRIPTION field in the config information
#
# Arguments:    self (scalar) - a reference to a hash that contains all
#                  	the configuration options for this process.
#               in_dir (scalar) - location of input directory for this rule
#                  	(i.e. intermediate directory of the parser)
#            	in_files (scalar) - a reference to an array of suitable
#					files in in_dir 
#            	out_dir (scalar) - location of output directory for this rule
#            	local_hash_ref (scalar) - a reference to a hash local to
#                   &post_parser, (holds 1 empty hash element with key
#                  	FILES_STILL_WANTED)
#
# Returns : $num_succ_processed (scalar)  
#             (configured to only be 0, but calling function expects
#             $num_succ_processed < 0 if error occurs)

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
		
		# Check if it has found all the partners
		if( @partner_files < @{$self->{INPUT_FILE_DESCRIPTION}} ) {

			# Check to see if any of the partner files are younger than the keep time
			foreach ( @partner_files  ) {
				if( $self->{HOURS_TO_WAIT_FOR_PARTNER_FILES} > (-M $in_dir."/".$_)*24 ) {
					LogMess("$_ younger than keep time, @partner_files not processed", 3);
					push @files_still_required, @partner_files;
					next PATTERN;
				}
			}
		}
		
		# Join the files together and produce a LIF file
		AudMess("For pattern '$pattern', join files @partner_files");
		$self->join_files($in_dir, $out_dir, @partner_files);
	}

	# Returning the list of files that are still required by this
	# rule
	@{$local_hash_ref->{FILES_STILL_WANTED}} = @files_still_required;
	return $num_succ_processed;
}

sub join_files {
	my ($self, $in_dir, $out_dir, @files) = @_;

	my ($i_obj, $out_file, $o_obj, $file, $sortkey, $element, $var1, $dir, $href);
	my (@names, @values);
	my (%common_header, %common_data_hash, %tmp_hash, %names_hash);


	# If the OUTPUT_DIR is specified set the output directory
	# to be OUTPUT_DIR, rather than the one specified on the 
	# command line.  first check that it exists and is writable etc.
	# Otherwise, log and error message and exit this rule.
	if( exists($self->{OUTPUT_DIR}) && $self->{OUTPUT_DIR} ) {
		$dir = $self->{OUTPUT_DIR};
		if( -d $dir && -w $dir && -r $dir && -x $dir ) {
			LogMess("For this rule, output directory set to '".$dir."'", 3);
			$out_dir = $self->{OUTPUT_DIR};
		} else {
			LogMess("ERROR: Output directory '".$dir."' has incorrect permissions", 1);
			return -1;
		}
	}

	$i_obj = PIF_Handler->New();

	# Looping over all the files to be joined together
	foreach $file ( @files ) {

		# Open the file
		$i_obj->Open($in_dir."/".$file);

		# Read in the header information
		$i_obj->Read_Names(\@names);
		$i_obj->Read_Values(\@values);

		# Put the header information in the common header hash
		@common_header{@names} = @values;

		# Read in the names of the counters in the data block
		$i_obj->Read_Names(\@names);

		# Loop over all the lines of data
		while( $i_obj->Read_Values(\@values) ) {
			
			@tmp_hash{@names} = @values;

			# Construct the sortkey for the data line
			$sortkey = join '', @tmp_hash{ @{$self->{COUNTERS_TO_JOIN_ON}} };

			# Insert the data line in the correct hash
			@{$common_data_hash{$sortkey}}{@names} = @values;
		}

		# Add all the keys used to this hash
		@names_hash{@names}=();
	}

	# Put unique time/data in header to signify time output join file produced
	if (exists($self->{TIME_JOINFILE_PRODUCED}) and $self->{TIME_JOINFILE_PRODUCED} ) {
		my $time = localtime;
		$time =~ s/(\w+)\s(\w+)\s(\d+)\s(\d+:\d+:\d+)\s(\d+)/$1$3$2$5_$4/;
		$common_header{TIME_JOINFILE_PRODUCED} = $time;
	}

	# Construct the output filename
	$out_file = $self->{OUTPUT_FILENAME_START};
	foreach ( @{$self->{HEADER_COUNTERS_TO_USE_IN_OUTPUT_FILENAME}} ) {
		$out_file .= "-#-".$common_header{$_};
	}
	# Check that output file name is unique
	my ($count, $done, $proposed_pif, $proposed_lif, $suffix );
	until ($done) {
		$suffix = '-#-'. $count if ($count);
		$suffix .= '-#-J';
		$proposed_pif =  $in_dir."/".$out_file.$suffix.".pif";
	 	$proposed_lif =  $out_dir."/".$out_file.$suffix.".lif";
		if ($self->{PRODUCE_PIF} and (-e $proposed_pif) )  {
			$count++;
			next;
		}
		if ($self->{PRODUCE_LIF} and (-e $proposed_lif) )  {
			 $count++;
			 next;
		}
		# Looks like we have a unique output file name
		$done =1;
	}

	$out_file .= $suffix.".pt";

	# Changes /'s in the file name to be _'s.  Because /'s are
	# not allowed in Unix files names.
	$out_file =~ s/\//_/g;

	AudMess("Output file '$out_file'");

	# Deleting things from the header record that don't apply to the
	# combined data.  First checking that the user has specified
	# a list of header counters to delete.
	if( exists $self->{REDUNDANT_HEADER_COUNTERS} ) {
		foreach ( @{$self->{REDUNDANT_HEADER_COUNTERS}} ) {
			delete $common_header{$_};
		}
	}

	my ($dmf, $var);
	# Starting the PIF file if its wanted
	if( $self->{PRODUCE_PIF} ) {
		$i_obj->Open_PIF_Write($in_dir."/".$out_file);
		$i_obj->PIF_Write('HEADER', \%common_header);


		# Make sure that all the keys get output to the PIF file on the very
		# first entry. This will avoid keys not being able to be added after
		# the first line, and thus no data will be lost.
		foreach $var1 (keys(%common_data_hash)){
			# Assign the first element from the COMMON_DATA_HASH to
			# the NAMES_HASH
			$href=$common_data_hash{$var1};
			@names_hash{keys %$href}= values %$href; 

		    # delete first element from COMMON_DATA_HASH to avoid the data being
		    # output twice.
		    delete $common_data_hash{$var1};

			# Now the first element has been added to the NAMES_HASH end this
			# loop as it is no longer required.
			last;
		}

		# Delete unrequired counters from the hash 
		foreach $dmf ( @{$self->{REDUNDANT_COUNTERS}}) {
			delete $names_hash{$dmf};
		}

		# Output the element from NAMES_HASH to PIF file, as all the
		# keys/counter names are in the NAMES_HASH, then no keys will be 
		# excluded.
		$i_obj->PIF_Write($self->{OUTPUT_BLOCK_NAME}, \%names_hash)
			if $self->{PRODUCE_PIF};
	}

	# Starting the LIF file if its wanted
	if( $self->{PRODUCE_LIF} ) {
		# Produce the output file.
		$o_obj = LIF_Writer->New();
		$o_obj->Open($out_dir."/".$out_file);

		$o_obj->Open_Block();

		# Printing the header information to the file
		$o_obj->Block_Info(\%common_header);
		$o_obj->WriteToFile();

		# This data line has to be outputted here, as it has been removed from
		# the common_data_hash, so wouldn't be written to the file, if a PIF is
		# to also be produced.
		# REDUNDANT_COUNTERS are removed from the hash in the above PIF block.
		$o_obj->Create_Block($self->{OUTPUT_BLOCK_NAME},  \%names_hash) if $self->{PRODUCE_PIF};
	}



	# Loop over the Common data hash
	foreach $var (keys %common_data_hash) {

		# Delete the specified counters from the hash 
		foreach $dmf ( @{$self->{REDUNDANT_COUNTERS}}) {
			delete $common_data_hash{$var}->{$dmf};
		}
			
		# Write out the hash contents for this sortkey
		$o_obj->Create_Block($self->{OUTPUT_BLOCK_NAME}, $common_data_hash{$var})
			if $self->{PRODUCE_LIF};
		$i_obj->PIF_Write($self->{OUTPUT_BLOCK_NAME}, $common_data_hash{$var})
			if $self->{PRODUCE_PIF};
	}
	
	# Closing and storing the new Parser Intermediate File.
	if( $self->{PRODUCE_PIF} ) {
		$i_obj->Close_PIF_Write();
		rename_completed_file(".pt", ".pif", $in_dir."/".$out_file);
	}

	# Closing and storing the completed Loader Input File
	if( $self->{PRODUCE_LIF} ) {
		$o_obj->Close();

		# Rename the completed output file to the appropriate extension
		# and store it if wanted
		store_processed_file($self->{keep_files}, 0, $self->{debug}, rename_completed_file(".pt", ".lif", $out_dir."/".$out_file));
	}

	return 0;
}

1; # So the use or require works
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

JOIN - A Perl extension that joins uniquely identified records
            from multiple Parser Intermediate files into one record.

=head1 SYNOPSIS

  use JOIN;

  $obj_id = Joinfiles->New();

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
