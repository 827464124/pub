#
#-------------------------------------------------------------------------------
# @(#) common-modules/PIF_2_LIF/PIF_2_LIF.pm common-modules_r2.1.3.2:cset.000563:4:4 06/07/99 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package PIF_2_LIF;
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
use LIF_Writer;
use PIF_Handler;
use AudLog;

sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	# These two variables should be set to true of false
	# depending on whether or not the desired type of output file
	# is wanted
	$self->{PRODUCE_PIF} = 0;
	$self->{PRODUCE_LIF} = "True";
	$self->{keep_files} = "True";
	$self->{debug} = "True";

	$self->{REDUNDANT_COUNTERS} = ();

	$self->{NEW_HEADER_NAMES} = ();
	$self->{NEW_HEADER_VALUES} = ();

	bless ($self, $class);
}

sub load_config {
	my $self = shift;
	($self->{keep_files}, $self->{debug}, $self->{'__config__'}) = @_;

	# Inserting all the configuration information into the objects records
	my $key;
	foreach $key ( keys %{$self->{'__config__'}} ) {
		$self->{$key} = $self->{'__config__'}->{$key};
	}
}

# Object Methods
sub process {
	my ($self, $in_dir, $in_files, $out_dir) = @_;

	# Declaring variables local to this subroutine
	my ($num_succ_processed, $dir, @files );
	my ($pattern, %files_h);

	$num_succ_processed = 0;

	# Get the list of files that are to be processed by this rule.  But first
	# checking if they have provided a list of regular expressions or just
	# one.
	if( ref($self->{INPUT_FILE_DESCRIPTION}) eq "ARRAY" ) {
		foreach $pattern ( @{$self->{INPUT_FILE_DESCRIPTION}} ) {
			push @files, grep /$pattern/, @$in_files;
		}
	}
	else {
		@files = grep /$self->{INPUT_FILE_DESCRIPTION}/, @$in_files;
	}

	# Removing duplicates from the list of files
	@files_h{@files} = ();

	# If the OUTPUT_DIR is specified set the output directory
	# to be OUTPUT_DIR, rather than the one specified on the 
	# command line.  first check that it exists and is writable etc.
	# Otherwise, log and error message and exit this rule.
	if( exists($self->{OUTPUT_DIR}) && $self->{OUTPUT_DIR} ) {
	    $dir = $self->{OUTPUT_DIR};
		if( -d $dir && -w $dir && -r $dir && -x $dir ) {
			LogMess("For this rule, output directory set to '".$dir."'", 3);
			$out_dir = $self->{OUTPUT_DIR};
		}
		else {
			LogMess("ERROR: Output directory '".$dir."' has incorrect permissions", 1);
			return -1;
		}
	}

	# Loop over the list of files to process for this rule
	foreach ( keys %files_h ) {
		if( $self->process_a_file($in_dir."/".$_, $out_dir) != 0 ) {
			AudMess("ERROR: processing '$_'");
		}
		$num_succ_processed++;
	}

	return $num_succ_processed;
}


sub process_a_file() {
	my ($self, $in_file, $out_dir) = @_;

	my ($i_obj, $o_obj, $blk_name, $out_file, $new_pif, $num_names, $num_vals);
	my (@names, @values);
	my (%h_i, %counter_hash);

	AudMess("Processing '${in_file}'");

	$i_obj = PIF_Handler->New();
	$i_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $i_obj->Read_Names(\@names);
	$i_obj->Read_Values(\@values);

	@h_i{@names} = @values;
	if (( $self->{NEW_HEADER_NAMES})||($self->{NEW_HEADER_VALUES})){
		# count number of names & values (assign to $number
		# if uneven match, print error and abort addition

		$num_names=@{$self->{NEW_HEADER_NAMES}};
		$num_vals=@{$self->{NEW_HEADER_VALUES}};

		if ($num_names == $num_vals){
			LogMess("  Added $num_names new name(s) and value(s) to HEADER record", 5);
			@h_i{@{$self->{NEW_HEADER_NAMES}}}=@{$self->{NEW_HEADER_VALUES}};
		}
		else{
			LogMess("  Mismatched No. of NAME($num_names) and VALUE($num_vals) to add to header", 2); 
			return -1;
		}
	}

	# Looping over all the data blocks in the file
	while( $blk_name = $i_obj->Read_Names(\@names) ) {

		# Creating a name for output block name if not provided
		if( exists($self->{OUTPUT_BLOCK_NAME}) &&
			$self->{OUTPUT_BLOCK_NAME}) {
			$blk_name = $self->{OUTPUT_BLOCK_NAME};
		}

		if (not $o_obj){

			# Creating the output filename
			$out_file = basename($in_file);
			$out_file =~ s/\.pif$/-#-P.pt/;

			# Appending an optional user specified string to the
			# start of the output file name.
			$out_file = $self->{OUTPUT_FILENAME_START}.'-#-'.$out_file
				if( exists($self->{OUTPUT_FILENAME_START})
				&& $self->{OUTPUT_FILENAME_START});

			$new_pif = dirname($in_file)."/".$out_file;

			if( $self->{PRODUCE_PIF} ) {
				$i_obj->Open_PIF_Write($new_pif);
				$i_obj->PIF_Write("HEADER", \%h_i);
			}

			AudMess("Output file: '${out_file}'");

			if( $self->{PRODUCE_LIF} ) {
				$o_obj = LIF_Writer->New();
				$o_obj->Open($out_dir."/".$out_file);

				$o_obj->Open_Block();
				$o_obj->Block_Info(\%h_i);
				$o_obj->WriteToFile();
			}
		}
	          
		# Initialising the hash before inserting a different
		# set of names from this block.
		%counter_hash = ();

		# Looping over all the Data lines in this block
		while ( $i_obj->Read_Values(\@values) ) {

			@counter_hash{@names}=@values;

			# Delete the counters from the hash that now make no sense
			foreach ( @{$self->{REDUNDANT_COUNTERS}} ) {
				delete $counter_hash{$_};
			}

			# Writing the Block into the LIF file
			$o_obj->Create_Block($blk_name, \%counter_hash) if $self->{PRODUCE_LIF};

			# Writing the block into the new PIF file
			$i_obj->PIF_Write($blk_name, \%counter_hash) if $self->{PRODUCE_PIF};
		}
	}

	# Closing the Output file and renaming the completed output file to
	# end in the appropriate extension
	
	if($self->{PRODUCE_PIF}&& $i_obj )   {
		$i_obj->Close_PIF_Write();
		rename_completed_file(".pt", ".pif", $new_pif);
	}
	if($self->{PRODUCE_LIF}&& $o_obj ) {
		$o_obj->Close();
		store_processed_file($self->{keep_files}, 0, $self->{debug}, rename_completed_file(".pt", ".lif", $out_dir."/".$out_file));
	}

	return 0;
}

1; # So the use or require succeeds
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

PIF_2_LIF - A Perl extension that converts files it PIF/LIF  without doing anything special 
              to records in a Parser Intermediate file.

=head1 SYNOPSIS

  use PIF_2_LIF;

  $obj_id = PIF_2_LIF->New();

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

D. Fisher, david.fisher@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
