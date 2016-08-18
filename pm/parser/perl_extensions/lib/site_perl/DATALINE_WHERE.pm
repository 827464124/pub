#
#-------------------------------------------------------------------------------
# @(#) common-modules/DATALINE_WHERE/DATALINE_WHERE.pm common-modules_r2.1.3.2:cset.000729:7:6 04/26/00 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
# This deletes all lines except the specified ones, or removes
# lines which are equal to specified regualr expression.
#
# A list of regular expressions can be used.
#
package DATALINE_WHERE;

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


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use strict;
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
	$self->{PRODUCE_PIF} = "True";
	$self->{PRODUCE_LIF} = "True";
	$self->{keep_files} = "True";
	$self->{debug} = "True";

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
	my ($num_succ_processed, @files);
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

	# Check to see if COUNTER_NAME contains a value 
	if (! $self->{COUNTER_NAME}){ 
		LogMess("Dataline_Where: no COUNTER_NAME specified in rule!", 2); 
		return 0;
	} 

	if (! $self->{KEEP_WHERE} && ! $self->{REMOVE_WHERE}){ 
		LogMess("Dataline_Where: no regular expression specified in rule!", 2); 
		return 0;
	} 

	# Loop over the list of files to process
	foreach ( keys %files_h ) {
		if( $self->process_a_file($in_dir."/".$_, $out_dir) != 0 ) {
			AudMess("ERROR: processing '$_'");
		}
		$num_succ_processed++;
	}

	return $num_succ_processed;
}


sub process_a_file() {
	my ($self, $in_file, $out_dir ) = @_;

	my ($pif_obj, $lif_obj, $blk_name, $out_file, $new_pif, $dir, $h_ref);
	my (@names, @values, %h_i, %d_h);

	AudMess("Processing '${in_file}'");

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

	$pif_obj = PIF_Handler->New();
	$pif_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $pif_obj->Read_Names(\@names);
	$pif_obj->Read_Values(\@values);

	@h_i{@names} = @values;

	my $ext;
	if ($self->{FILENAME_ADDITION}){
		$ext="-#-".$self->{FILENAME_ADDITION};
	}

	# Creating the output filename
	$out_file = basename($in_file);
	$out_file =~ s/\.pif$/${ext}-#-DW.pt/;

	$new_pif = dirname($in_file)."/".$out_file;

	# If the option PRODUCE_PIF is true, then produce PIF file!
	if( $self->{PRODUCE_PIF} ) {
		$pif_obj->Open_PIF_Write($new_pif);
		$pif_obj->PIF_Write("HEADER", \%h_i);
	}

	AudMess("Output file: '${out_file}'");

	# If the option PRODUCE_LIF is true, then produce LIF file!
	if( $self->{PRODUCE_LIF} ) {
		$lif_obj = LIF_Writer->New();
		$lif_obj->Open($out_dir."/".$out_file);

		$lif_obj->Open_Block();
		$lif_obj->Block_Info(\%h_i);
		$lif_obj->WriteToFile();
	}

	my $n;
	my $counter_name = $self->{COUNTER_NAME};
	my $keep = 0;

	# Looping over all the Data blocks in the file
	while( $blk_name = $pif_obj->Read_Names(\@names) ) {
		
		# Setting the output block name to be the blk_name from
		# the PIF file if an output block name is not specified
		# in the UserConfig.pm
		if( exists($self->{OUTPUT_BLOCK_NAME}) && $self->{OUTPUT_BLOCK_NAME}) {
			$blk_name = $self->{OUTPUT_BLOCK_NAME};
		}

		# Looping over all the lines in this PIF block and processing them
		VALUES: while ( $pif_obj->Read_Values(\@values) ) {
			%d_h = ();
			@d_h{@names} = @values;
			$keep = 0;

			if ($self->{KEEP_WHERE}){
				# If lines don't match reg. expression, skip
				foreach $n(@{$self->{KEEP_WHERE}}){
					LogMess ( "Dataline_Where: Reg is $n, value is $d_h{$counter_name}", 4);
					next if not $d_h{$counter_name} =~ /$n/;

					# If keeping, then write line to hash
					$keep=1;
				}
				if ($keep == 0){next VALUES;}
			}

			if ($self->{REMOVE_WHERE}){
				foreach $n(@{$self->{REMOVE_WHERE}}){
					if ($d_h{$counter_name} =~ /$n/){
						LogMess( "Dataline_Where: '$n' and associated counters removed", 4);
						next VALUES;
					}
				}
			}
			
			# Delete the counters from the hash, which are not required
			foreach ( @{$self->{REDUNDANT_COUNTERS}} ){
			 	delete $d_h{$_};
			} 

			# Add new counter name and value (if defined!)
			$d_h{$self->{ADD_NEW_COUNTER}}=$self->{NEW_COUNTER_VALUE} if $self->{ADD_NEW_COUNTER};

			# Writing the Block into the LIF file
			$lif_obj->Create_Block($blk_name, \%d_h) if $self->{PRODUCE_LIF};

			# Writing the block into the new PIF file
			$pif_obj->PIF_Write($blk_name, \%d_h) if $self->{PRODUCE_PIF};
		}
	}

	# Closing the Output file and renaming the completed output file to
	# end in the appropriate extension
	if( $self->{PRODUCE_LIF} ) {
		$lif_obj->Close();
		# add read privilege to metrica on sdwg1
		# add by fanjun on 2003-11-07
		chmod(0644,$out_dir."/".$out_file);
		#AudMess("Modify Privilege of $out_dir/$out_file to 0644");
		store_processed_file($self->{keep_files}, 0, $self->{debug}, rename_completed_file(".pt", ".lif", $out_dir."/".$out_file));
	}	

	if( $self->{PRODUCE_PIF} ) {
		$pif_obj->Close_PIF_Write();
		rename_completed_file(".pt", ".pif", $new_pif);
	}

	return 0;
}

1; # So the use or require succeeds
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

DATALINE_WHERE - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DATALINE_WHERE;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for DATALINE_WHERE was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
