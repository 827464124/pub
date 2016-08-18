#
#-------------------------------------------------------------------------------
# @(#) common-modules/RECORD_COUNT/RECORD_COUNT.pm common-modules_r2.1.3.2:cset.000563:7:7 2005/09/29 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) LANGCHAO LG 2005
#
package RECORD_COUNT;

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

sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	# These two variables should be set to true of false
	# depending on whether or not the desired type of output file
	# is wanted
	$self->{keep_files} = "True";
	$self->{debug} = "True";

	@{$self->{REDUNDANT_COUNTERS}} = ();
	@{$self->{NON_ADDITIVE_COUNTERS}} = ();

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
	my ($num_succ_processed, @files, $rule_num);
	my ($pattern, %files_h);

	$num_succ_processed = 0;
	$rule_num++;

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

	if( !exists($self->{OUTPUT_DIR}) || !$self->{OUTPUT_DIR} ) {
		LogMess('ERROR: OUTPUT_DIR must be specified!', 1);
		return -1;
	}
	
	# Removing duplicates from the list of files
	@files_h{@files} = ();

	# Loop over the list of files to process for this RECORD_COUNT rule
	foreach ( keys %files_h ) {
		if( $self->process_a_file($in_dir."/".$_, $out_dir) != 0 ) {
			AudMess("ERROR: processing record count for '$_'");
		}
		$num_succ_processed++;
	}

	return $num_succ_processed;
}

sub process_a_file() {
	my ($self, $in_file, $out_dir) = @_;

	# Declaring variable local to this subroutine
	my ($i_obj, $o_obj, $blk_name, $out_file, $new_pif, $dir);
	my ($sortkey, $n, $sum, $ref, $out_ref, $input_ref);
	my (@names, @values);
	my (%h_i, %ignore_counters, %hash_of_accums);
	my (@old_names, @new_names);

	AudMess("Processing RECORD_COUNT '${in_file}'");
	
	
	my $filename = basename($in_file, ".pif");
	my $record_count_file=$self->{OUTPUT_DIR} . '/' . $filename . '.record_count';
	if (open(COUNT,">$record_count_file")<=0) {
		LogMess("ERROR: open file $record_count_file failed!", 1);
		return -1;
	}
	
	$i_obj = PIF_Handler->New();
	$i_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $i_obj->Read_Names(\@names);
	$i_obj->Read_Values(\@values);

	@h_i{@names} = @values;

	# Looping over all the data blocks in the file
	while( $blk_name = $i_obj->Read_Names(\@names) ) {
		$sum=0;
		# Looping over all the Data lines in this block
		while ( $i_obj->Read_Values(\@values) ) {
			$sum++;
		}
		print COUNT "$h_i{'NODEID'}|$blk_name|$h_i{'START_DATE'}|$h_i{'START_TIME'}|$h_i{'INTERVAL'}|$sum\n"; 
	}

	close(COUNT);

	return 0;
}

1; # So the use or require succeeds
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RECORD_COUNT - A Perl extension that Accumulates counters across multiple
              records in a Parser Intermediate file.

=head1 SYNOPSIS

  use RECORD_COUNT;

  $obj_id = RECORD_COUNT->New();

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
