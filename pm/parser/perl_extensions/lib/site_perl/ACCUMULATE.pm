#
#-------------------------------------------------------------------------------
# @(#) common-modules/ACCUMULATE/ACCUMULATE.pm common-modules_r2.1.3.2:cset.000563:7:7 06/07/99 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package ACCUMULATE;

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
	$self->{PRODUCE_PIF} = "True";
	$self->{PRODUCE_LIF} = "True";
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

	# Checking that if the NEW_COUNTER_NAMES is supplied then
	# the OLD_COUNTER_NAMES is also supplied
	if( exists($self->{OLD_COUNTER_NAMES}) && $self->{OLD_COUNTER_NAMES} ) {
		if( !exists($self->{NEW_COUNTER_NAMES}) ||
			!$self->{NEW_COUNTER_NAMES} ) {
			LogMess('ERROR: NEW_COUNTER_NAMES must be supplied when OLD_COUNTER_NAMES is specified', 1);
			return -1;
		}
	}

	# Checking that if the OLD_COUNTER_NAMES is supplied then
	# the NEW_COUNTER_NAMES is also supplied
	if( exists($self->{NEW_COUNTER_NAMES}) && $self->{NEW_COUNTER_NAMES} ) {
		if( !exists($self->{OLD_COUNTER_NAMES}) ||
			!$self->{OLD_COUNTER_NAMES} ) {
			LogMess('ERROR: OLD_COUNTER_NAMES must be supplied when NEW_COUNTER_NAMES is specified', 1);
			return -1;
		}
	}
        
	# Checking that the list of counters to copy has the same
	# length as the list of counters to copy them to.
	if( exists($self->{OLD_COUNTER_NAMES}) && $self->{OLD_COUNTER_NAMES} ) {
		if( scalar( @{$self->{OLD_COUNTER_NAMES}} ) !=
			scalar( @{$self->{NEW_COUNTER_NAMES}} ) ) {
			LogMess('ERROR: Different lengths for Counter name lists', 1);
			return -1;
		}
	}
        # the COMPUTE_NAME & COMPUTE_EXPRESSION is also supplied
        if ( exists($self->{COMPUTE_EXPRESSION}) && $self->{COMPUTE_EXPRESSION} ) {
        	if ( !exists($self->{COMPUTE_NAME})  || !$self->{COMPUTE_NAME}) {
        		LogMess( 'ERROR: COMPUTE_NAME must be supplied when COMPUTE_EXPRESSION is specified',1);
        		return -1;
        	}
        }
      #  # Checking that if the COMPUTE_NAME is supplied then
        if ( exists($self->{COMPUTE_NAME}) && $self->{COMPUTE_NAME} ) {
        	if (!exists($self->{COMPUTE_EXPRESSION}) || !$self->{COMPUTE_EXPRESSION}) {
        		LogMess( 'ERROR: COMPUTE_EXPRESSION must be supplied when COMPUTE_NAME is specified',1);
        		return -1;
        	}
        }
        # Checking length of COUNTER of COMPUTE_NAME/DIVISOR_LIST/DIVIDEND_LIST
        if ( exists($self->{COMPUTE_NAME}) && $self->{COMPUTE_NAME} ) {
   		if ( scalar( @{$self->{COMPUTE_NAME}} ) != scalar( @{$self->{COMPUTE_EXPRESSION}} ) ) {
				LogMess('ERROR: Different lengths for Counter COMPUTE_NAME-COMPUTE_EXPRESSION', 1);
				return -1;
		}
	}
	# Removing duplicates from the list of files
	@files_h{@files} = ();

	# Loop over the list of files to process for this accumulate rule
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

	# Declaring variable local to this subroutine
	my ($i_obj, $o_obj, $blk_name, $out_file, $new_pif, $dir);
	my ($sortkey, $n, $sum, $ref, $out_ref, $input_ref);
	my (@names, @values);
	my (%h_i, %ignore_counters, %hash_of_accums);
	my (@old_names, @new_names);
        my (@compute_expression,@compute_name);
        my (%compute_list,$iCount,$sKey,@aTemp);
        my ($computeExp,$computeName);
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

	$i_obj = PIF_Handler->New();
	$i_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $i_obj->Read_Names(\@names);
	$i_obj->Read_Values(\@values);
 	@h_i{@names} = @values;
 	# Creating the output filename
	$out_file = basename($in_file);
	$out_file =~ s/\.pif$/-#-$self->{OUTPUT_BLOCK_NAME}-#-A.pt/;

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

	# Copying the counter names, that are to be duplicated in the
	# output data hash, to local lists.
	@old_names = @{$self->{OLD_COUNTER_NAMES}}
		if exists($self->{OLD_COUNTER_NAMES}) && $self->{OLD_COUNTER_NAMES};
	@new_names = @{$self->{NEW_COUNTER_NAMES}}
		if exists($self->{NEW_COUNTER_NAMES}) && $self->{NEW_COUNTER_NAMES};

	@ignore_counters{@{$self->{REDUNDANT_COUNTERS}}} = ();
	@ignore_counters{@{$self->{NON_ADDITIVE_COUNTERS}}} = ();
	@ignore_counters{@{$self->{COUNTERS_TO_SORT_ON}}} = ();
        # Get Divisor/Dividend from UserConfig.pm
        @compute_name=@{$self->{COMPUTE_NAME}}
        	if exists($self->{COMPUTE_NAME}) && $self->{COMPUTE_NAME};
	@compute_expression=@{$self->{COMPUTE_EXPRESSION}}
		if exists($self->{COMPUTE_EXPRESSION}) && $self->{COMPUTE_EXPRESSION};    
	
	if (exists($self->{COMPUTE_NAME}) && $self->{COMPUTE_NAME}) {
		@compute_list{@compute_name} = @compute_expression;
	}
	# Looping over all the data blocks in the file
	while( $blk_name = $i_obj->Read_Names(\@names) ) {
		# Setting the output block name to be the blk_name from
		# the PIF file if an output block name is not specified
		# in the UserConfig.pm
		if( exists($self->{OUTPUT_BLOCK_NAME}) &&
			$self->{OUTPUT_BLOCK_NAME}) {
			$blk_name = $self->{OUTPUT_BLOCK_NAME};
		}

		# Deciding if there is a string to append to the end of
		# each counter name that is not to be ignored
		if( exists($self->{APPEND_STR}) && $self->{APPEND_STR} ) {

			# Appending a string to the end of the name if the
			# counter is to be not to be ignored, ie the counter is
			# to be accumulated.
			grep { exists($ignore_counters{$_})?1:s/$/$self->{APPEND_STR}/ } @names;
		}

		# Looping over all the Data lines in this block
		while ( $i_obj->Read_Values(\@values) ) {

			$input_ref = undef;
			@$input_ref{@names}=@values;
                        #AudMess("'@{names}'");
                        #AudMess("'@{values}'");
                       	# Assigning a value to the number of data lines used in 
			# the accumulation so far.  As each line is added together
			# this will total up to the number of lines used in the
			# final accumulation.
			#--start Added by zhung on 2005-12-02-----
			# Compute Value from Counters With Divisor/Dividend=>compute_name
			if (exists($self->{COMPUTE_NAME}) && $self->{COMPUTE_NAME}) {
				foreach $computeName ( keys %compute_list) {
					$computeExp=$compute_list{$computeName};
					#替换表达式中的变量为值
					for ($iCount=0;$iCount<=$#names;$iCount++) {
						$sKey=$names[$iCount];
						$computeExp=~s/$sKey/$input_ref->{$sKey}/ig;
					}
					#判断除法的分母是否为0，支持一层除法
					if (index($computeExp,"/")>0) {
						@aTemp=split("/",$computeExp);
						if (eval($aTemp[1]) != 0) {
							$input_ref->{$computeName}=eval($computeExp);
						} else {
							$input_ref->{$computeName}=0;
						}
					} else {
						$input_ref->{$computeName}=eval($computeExp);
					}
				}
			}
			#----end--
			$input_ref->{$blk_name.'_NUM_IN_SUM'} = 1;

			#Construct the sort key from the line hash
			$sortkey = join '', @$input_ref{ @{$self->{COUNTERS_TO_SORT_ON}} };

			# Inserting this line as the first of its type
			if( !exists($hash_of_accums{$sortkey}) ) {
				$hash_of_accums{$sortkey} = $input_ref;
				next;
			}

			# Getting a reference to the existing hash.
			$ref = $hash_of_accums{$sortkey};
                        
			# Adding this line of data to the one that is already in there.
			foreach ( keys %{$ref} ) {

				# Testing if this counter is one to ignore
				next if exists $ignore_counters{$_};
				
				# Adding the value to the sum that has already been
				# accumulated for data lines that match this sortkey.
				$ref->{$_} += $input_ref->{$_};
			}
		}

		# Loop over the accumulated lines to modify the names
		# where needed and print the contents out.
		foreach $sum (keys %hash_of_accums) {
			
			# Getting a reference to the hash of data.
			$out_ref = $hash_of_accums{$sum};

			# Copying counters to new names that have been specified
			# in the UserConfig.pm
			@$out_ref{@new_names} = @$out_ref{@old_names};

			# Delete the counters from the hash that now make no sense
			foreach ( @{$self->{REDUNDANT_COUNTERS}} ) {
				delete $out_ref->{$_};
			}

			# Writing the Block into the LIF file
			$o_obj->Create_Block($blk_name, $out_ref) if $self->{PRODUCE_LIF};

			# Writing the block into the new PIF file
			$i_obj->PIF_Write($blk_name, $out_ref) if $self->{PRODUCE_PIF};
		}
	}

	# Closing the Output file and renaming the completed output file to
	# end in the appropriate extension
	if( $self->{PRODUCE_LIF} ) {
		$o_obj->Close();
		store_processed_file($self->{keep_files}, 0, $self->{debug}, rename_completed_file(".pt", ".lif", $out_dir."/".$out_file));
	}
	if( $self->{PRODUCE_PIF} ) {
		$i_obj->Close_PIF_Write();
		rename_completed_file(".pt", ".pif", $new_pif);
	}

	return 0;
}

1; # So the use or require succeeds
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

ACCUMULATE - A Perl extension that Accumulates counters across multiple
              records in a Parser Intermediate file.

=head1 SYNOPSIS

  use ACCUMULATE;

  $obj_id = ACCUMULATE->New();

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
