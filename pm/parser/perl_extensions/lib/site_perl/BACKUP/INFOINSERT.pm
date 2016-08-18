#
#-------------------------------------------------------------------------------
# @(#) common-modules/INFOINSERT/INFOINSERT.pm common-modules_r2.1.3.2:cset.000726:9:9 04/25/00 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package INFOINSERT;

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

	$self->{keep_files} = "True";
	$self->{debug} = "True";

	$self->{PRODUCE_PIF} = 0;
	$self->{PRODUCE_LIF} = 'TRUE';

	$self->{OUTPUT_BLOCK_NAME} = undef;
	$self->{REDUNDANT_COUNTERS} = ();

	# Setting the default, that if there is no secondary
	# data to insert into the data line, then the data line
	# is not printed out
	$self->{WRITE_DATA_LINE} = 0;

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
	my ($self, $in_dir, $in_files, $out_dir, $local_hash_ref) = @_;

	# Declaring variables local to this subroutine
	my ($num_succ_processed, @files );
	my ($pattern, %files_h);
	my (@info_files, %info_files_h, %data_to_insert);

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

	# Getting the list of files that contain the information that
	# is to be substituted into the data records.
	if( ref($self->{INFO_FILE_DESCRIPTION}) eq "ARRAY" ) {
		foreach $pattern ( @{$self->{INFO_FILE_DESCRIPTION}} ) {
			push @info_files, grep /$pattern/, @$in_files;
		}
	}
	else {
		@info_files = grep /$self->{INFO_FILE_DESCRIPTION}/, @$in_files;
	}

	# Removing duplicates from the list of files
	@info_files_h{@info_files} = ();
	@info_files = keys %info_files_h;

	# Adding the infomation files to the list of files that should not be
	# deleted from the intermediate directory.
	@{$local_hash_ref->{FILES_STILL_WANTED}} = keys %info_files_h;

	LogMess("INFO: '".scalar(keys %files_h)."' files found for INFOINSERT to process", 6);
	# If no data files are found to process then return
	return $num_succ_processed if not scalar(keys %files_h);

	# If there are no information files found, add the list of data
	# files that should be processed, to the list of files that should not
	# be deleted, then return.
	if( not scalar(keys %info_files_h) ) {
		push @{$local_hash_ref->{FILES_STILL_WANTED}}, keys %files_h;
		LogMess("WARNING: No secondary data files found for this rule", 1);
		return $num_succ_processed;
	}

	# Loop over the list of information files and read the data into
	# a hash
	$self->get_substitution_data( \%data_to_insert, $in_dir, \@info_files );

	# Loop over the list of files to process for this rule
	foreach ( keys %files_h ) {
		if( $self->process_a_file($in_dir."/".$_, $out_dir, \%data_to_insert) != 0 ) {
			AudMess("ERROR: processing '$_'");
		}
		$num_succ_processed++;
	}

	return $num_succ_processed;
}

# This function reads all the hierarchy data files in and stores
# the data in a hash.  The hash key is string of counters specified
# in the 'UserConfig.pm' module.
# 
# The hierarchy files should be in PIF format and only have
# one data block in them.  That is, one line of counter names
# and mulitple data lines after that.
#
sub get_substitution_data {
	my ($self, $info_hash_ref, $in_dir, $info_file_list) = @_;
	
	my ($input, @names, @values, $t, $key, $blk_name, $num_lines);
	$input = PIF_Handler->New();

	# Modifying the names of the counters that are going to be used
	# to construct the identifier for the lines of information that
	# are to be inserted into the data files.
	if( exists($self->{APPEND_STRING}) && $self->{APPEND_STRING} ) {
		grep {s/$/$self->{APPEND_STRING}/} @{$self->{NAMES_USED_TO_ID_INFORMATION}};
	}

	# Loop over the files in the list
	my $file;
	foreach $file ( @{$info_file_list} ) {

		AudMess("Processing infomation file '$file'");
		$input->Open($in_dir."/".$file);
		@names = ();

		# Reading in the names of the counters in until a block
		# is found that is not called 'HEADER'.  Basically this
		# makes the parser skip over the header block in a files if
		# it exists.
		$blk_name = 'HEADER';
		while( $blk_name eq 'HEADER' ) {
			@names = ();
			$blk_name = $input->Read_Names(\@names);
		}

		
		# Modifying the counter names that are read in from this file to
		# have the user specified append string on the end of the names.
		if( exists($self->{APPEND_STRING}) && $self->{APPEND_STRING} ) {
			grep {s/$/$self->{APPEND_STRING}/} @names;
			if (exists ($self->{'ONLY_INSERT'}) && $self->{'ONLY_INSERT'}) {
			grep {s/$/$self->{APPEND_STRING}/} @{$self->{'ONLY_INSERT'}};
			}
		}
		
		my %names_to_delete;
		my @names_to_delete2;
		if (exists ($self->{'ONLY_INSERT'}) && $self->{'ONLY_INSERT'}) {
			@names_to_delete{@names} = ();
			foreach (@{$self->{'ONLY_INSERT'}}) {
				delete $names_to_delete{$_};
			}
			foreach (@{$self->{'NAMES_USED_TO_ID_INFORMATION'}} ) {
				delete $names_to_delete{$_};
			}
			@names_to_delete2 = keys %names_to_delete;
		}


		# Keeping a record of how lines of information are in the hash
		# before starting work on this file.
		$num_lines = scalar keys %{$info_hash_ref};

		
		# Reading in the rest of the data lines in the file
		while( $input->Read_Values(\@values) ){
			$t = undef;
			@$t{@names} = @values;
			foreach ( @names_to_delete2 ) {
				delete $$t{$_};
			}
			# Construct the unique identifier for this line of 
			# hierarchy data.  Each element of the unique identifier is
			# prepended with the sequence '-#-' so that it ensures no
			# duplicate identifiers can be generated from certain
			# sequences of data, eg previously the key '-#-3-#-3' would
			# have been confused with the key '-#-33-#-'.
			$key = join '-#-', @$t{@{$self->{NAMES_USED_TO_ID_INFORMATION}}};

			# Inserting the data line into the information hash
			${$info_hash_ref}{$key} = $t;
		}

		$num_lines = scalar(keys %{$info_hash_ref}) - $num_lines;

		LogMess("'".$num_lines."' lines read in from '$file'", 6);
	}

	return scalar keys %{$info_hash_ref};
}

sub process_a_file() {
	my ($self, $in_file, $out_dir, $data_to_insert) = @_;

	my ($i_obj, $o_obj, $blk_name, $out_file, $new_pif);
	my (@names, @values, @new_names);
	my (%h_i, %counter_hash, %key_list);
	my ($h_ref, $header_key, $key, $var, $var2);

	AudMess("Processing '${in_file}'");

	$i_obj = PIF_Handler->New();
	$i_obj->Open($in_file);

	# Reading the Header information.
	$blk_name = $i_obj->Read_Names(\@names);
	$i_obj->Read_Values(\@values);

	@h_i{@names} = @values;

	# Constructing the part of the key, that identifies the data lines,
	# that comes from the header information.
	$header_key = join '-#-', @h_i{@{$self->{HEADER_NAMES_USED_TO_ID_DATA_RECORD}}};

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
			$out_file =~ s/\.pif$/-#-S.pt/;

			# Appending an optional user specified string to the
			# start of the output file name.
			$out_file = $self->{OUTPUT_FILENAME_START}.'-#-'.$out_file
				if( exists($self->{OUTPUT_FILENAME_START})
				&& $self->{OUTPUT_FILENAME_START});

			$new_pif = dirname($in_file).'/'.$out_file;

			if( $self->{PRODUCE_PIF} ) {
				$i_obj->Open_PIF_Write($new_pif);
				$i_obj->PIF_Write('HEADER', \%h_i);
			}

			AudMess("Output file: '${out_file}'");

			if( $self->{PRODUCE_LIF} ) {
				$o_obj = LIF_Writer->New();
				$o_obj->Open($out_dir.'/'.$out_file);

				$o_obj->Open_Block();
				$o_obj->Block_Info(\%h_i);
				$o_obj->WriteToFile();
			}
		}

		# Checking for any names that are in the secondary file
		# but not in the primary data file. Keeping a list of
		# these names for later use.
		@key_list{@names}=();
		foreach $var2 ( values %$data_to_insert ) {
			foreach $var(keys(%$var2)){
				push @new_names, $var if( not (exists ($key_list{$var})));
			}
			last;
		}

		# Initialising the hash before inserting a different
		# set of names from this block.
		%counter_hash = ();

		# Looping over all the Data lines in this block
		DATA_LINE: while ( $i_obj->Read_Values(\@values) ) {

			@counter_hash{@names}=@values;

			# Construct the Hierarchy key
			$key = join '-#-', $header_key,
				@counter_hash{@{$self->{NAMES_USED_TO_ID_DATA_RECORD}}};

			# Extract the reference to the list of information that is
			# to be inserted in this line of data.
			$h_ref = $data_to_insert->{$key};
			if( not $h_ref ) {
				LogMess("ERROR: No Information to insert for Data Key '".$key."'", 1);
				next DATA_LINE if( exists($self->{WRITE_DATA_LINE}) && not $self->{WRITE_DATA_LINE} );

				# Assign empty values to the missing counter names.
				@counter_hash{@new_names}=();
			}

			# Substitute the hierarchy data into the data record
			@counter_hash{keys %$h_ref} = values %$h_ref;
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


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

INFOINSERT - Perl extension for inserting information for a secondary
			 data file into each line of a primary data file.

=head1 SYNOPSIS

  use INFOINSERT;

  $obj_id = INFOINSERT->New();

  $obj_id->load_config( $keep_files, $debug, \%config );

  $obj_id->process( $in_dir, \@in_files, $out_dir, \%local_hash );

=head1 DESCRIPTION

There are three entry points to this object.  The first 'New' creates
the object and stores the identifier in the scalar variable '$obj_id'.
The second 'load_config' allows the user to configure the object to
run as they require.  The third 'process' goes through and processes
the files in the input directory '$in_dir' as defined by the configuration
information.  The output of the process is output into the directory
'$out_dir'.  The argument '%local_hash', is used to pass information
back from the INFOINSERT module to the calling function.

=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
