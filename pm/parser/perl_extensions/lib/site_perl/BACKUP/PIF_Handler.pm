#
#--------------------------------------------------------------------
# @(#) common-modules/PIF_Handler/PIF_Handler.pm common-modules_r2.1.3.2:cset.000671:4:4 11/29/99 @(#) 
#--------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
# This package contains the functions that are used read in and write
# out files in the Parser Intermediate Format (PIF).
package PIF_Handler;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;
use FileHandle;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );
$VERSION = '0.01';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use AudLog;
#use diagnostics;


# Object/Class Constructor function.
sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{lines} = undef;
	$self->{filename} = undef;

	# Variables used for writing new PIF files
	$self->{out_filename} = undef;
	$self->{keys_list} = undef;
	$self->{out_buf} = undef;
	$self->{block_name} = undef;
	$self->{handle} = new FileHandle;

	bless ($self, $class);
	return $self;
}

sub DESTROY {
    my $self =shift;

    if (defined $self->{handle} ) { 
	close $self->{handle};
	LogMess ("PIF_Handler closing file $self->{filename}", 3);
    }
}


# Object methods.
#
# This function opens the filename and reads in all the lines
sub Open($) {
	my $self = shift;
	$self->{filename} = shift;
	my $handle = new FileHandle;

	unless (open $self->{handle}, "<$self->{filename}") {
		LogMess("Can't open $self->{filename} for input", 1);
		return 0;
	}
	LogMess ("PIF_Handler opening file $self->{filename}", 3);
	
	# FIX return 1 for success
	# (Previously: Returning the number of good lines read in)
	return 1;
}

# This function gets a line from PIF file
# Checks for EOF, if so returns 0
# If line is blank, then goes and gets another line
# Otherwise when successful, returns one line of file.
sub NextLine() {
	my $self = shift;
	my $handle = $self->{handle};
	while (<$handle>) {
		# Check not end of file
		if (eof $handle ) { return 0 }
		
		# Ignore blank lines
		next if ($_ =~ /^\s*$/);
	
		last;
	}
	return $_;
}	

# This function searches for the start of a block of data
# identified by '##START', and returns the first line of data
# as the counter names in the array referenced by $fields_ref.
# the function returns the names of the block found if
# it is successful.
sub Read_Names() {
	my ($self, $fields_ref) = @_;

	my ($line, $junk, $blk_name);

	# Looping over the lines searching for the start of
	# block indicator
	while( $self->NextLine() ) {
		
		# Searching from the the start of the block
		if( $_ =~ /^##START/ ) {
			($junk, $blk_name) = split /\|/, $_;
			$blk_name =~ s(\n)()g;
			last;
		}
	}

	# Reading in the first line of data
	while( $self->NextLine() ) {

		# Ignoring comment lines.
		if( $_ =~ /^#/ ) { 

			# If we have found the end of the block
			# indicator the end
			if( $_ =~ /^##END/ ) {
				@$fields_ref = ();
				return 0;
			}

			# Get the next line;
			next;
		}
		$line =$_;
		last;
	}

	# Splitting the data line into fields
	if( defined( $line ) )
	{
		@$fields_ref = split /\|/, $line;

		# Getting rid of the newline character at the
		# end of the last element in fields list.
		$$fields_ref[$#{$fields_ref}] =~ s(\n)()g;

		# Returning true, the block name 
		return $blk_name;
	}

	# Returning False
	return 0;
}

sub Read_Values {
	my ($self, $fields_ref) = @_;

	my $line;

	# Looping over the lines read from the file
	while( $self->NextLine() ) {

		# Ignoring comment lines.
		if( $_ =~ /^#/ ) { 

			# If we have found the end of the block
			# indicator the end
			if( $_ =~ /^##END/ ) {
				@$fields_ref = ();
				return 0;
			}

			# Get the next line;
			next;
		}
		$line = $_;
		last;
	}

	# Splitting the data line into fields
	if( defined( $line ) )
	{
		@$fields_ref = split /\|/, $line;

		# Getting rid of the newline character at the
		# end of the last element in fields list.
		$$fields_ref[$#{$fields_ref}] =~ s(\n)()g;

		# Returning true
		return scalar @$fields_ref;
	}

	# Returning False
	return 0;
}

# This function returns a reference to a list of rows that have been
# read from one block in a PIF file.
sub Read_Block_Values {
	my ($self, $list_ref) = @_;

	my ($blk_name, @values, @names, $t);
	$blk_name = $self->Read_Names(\@names);
	while( $self->Read_Values(\@values) ) {
		$t = undef;
		@$t{@names} = @values;
		push @$list_ref, $t;
	}
	return scalar @$list_ref;
}

# Set up variable so that a PIF file can be generated
sub Open_PIF_Write($) {
	my $self = shift;
	$self->{out_filename} = shift;

	$self->{keys_list} = undef;
	$self->{out_buf} = "## Metrica/NPR Parser Intermediate file\n";
	$self->{block_name} = undef;

	return 1;
}

# Write a comment to the PIF file.
sub PIF_WriteComment {
	my ($self, $comment) = @_;

	$self->{out_buf} .= "# $comment\n";
}

# Write a block of data to the PIF file
sub PIF_Write {
	my ($self, $block_name, $hash_ref) = @_;

	# if there has been no data blocks supplied before
	if( not $self->{block_name} ) {

		# Start the output block
		$self->{out_buf} .= "##START|".$block_name."\n";

		# Keep copies of the new block name and the list of counter names
		$self->{block_name} = $block_name;
		@{$self->{keys_list}} = keys %$hash_ref;

		# Add the list of counter names to the output buffer
		$self->{out_buf} .= join("|", @{$self->{keys_list}})."\n";
	}
	# If there has been a data block written before
	elsif( $block_name ne $self->{block_name} ) {

		# End the previos data block and start the next block
		$self->{out_buf} .= "##END|".$self->{block_name}."\n##START|".$block_name."\n";
		# Keep copies of the new block name and the list of counter names
		$self->{block_name} = $block_name;
		@{$self->{keys_list}} = keys %$hash_ref;

		# Add the list of counter names to the output buffer
		$self->{out_buf} .= join("|", @{$self->{keys_list}})."\n";
	}

	# Adding the current list of values to the output buffer
	$self->{out_buf} .= join("|", @$hash_ref{@{$self->{keys_list}}})."\n";
}

# Finish off the output and write the output buffer to the filename specified
sub Close_PIF_Write {
	my $self = shift;

	# Closing the last data block if there is one
	if( $self->{block_name} ) {
		$self->{out_buf} .= "##END|".$self->{block_name}."\n";
	}

	# Writing the output buffer to the file if there is anything
	# in the buffer
	if( $self->{out_buf} ) {
		open FILE, ">$self->{out_filename}" or 
			LogMess("Can't open $self->{out_filename} for output", 1);

		# Writing the output buffer to the file.
		print FILE $self->{out_buf};

		close FILE;
	}

	# Returning a true value.
	return "True";
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

PIF_Handler - Perl extension that reads and writes Parser Intermediate
              Format (PIF) files.

=head1 SYNOPSIS

  use PIF_Handler;

  $objid = PIF_Handler->New();

  The following subroutines are used to read in PIF files.
  $objid->Open( $filename );

  $ret = $objid->Read_Names( \@names );
     
  $ret = $objid->Read_Values( \@values );

  $ret = $objid->Read_Block_Values( \@list_of_hashes );

  The following subroutines are used to write out PIF files.
  $objid->Open_PIF_Write( $filename );

  $objid->PIF_WriteComment( $comment );

  $objid->PIF_Write( $blockname, \%data_block );

  $objid->Close_PIF_Write();

=head1 DESCRIPTION

  This Perl object is used to read and write Parser Intermediate
  Format (PIF) files.  

=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
