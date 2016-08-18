#
#--------------------------------------------------------------------
# @(#) common-modules/LIF_Writer/LIF_Writer.pm common-modules_r2.1.3.2:cset.000075:3:3 06/14/98 @(#)
#--------------------------------------------------------------------
#
#
# This package contains the fucntions that are used to write the
# information out in Loader Input Format (LIF).
package LIF_Writer;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );
$VERSION = '0.01';

use FileHandle;
use AudLog;

# Object/Class Constructor function.
sub New {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{filename} = undef;
	$self->{filehandle} = undef;
	$self->{indent_level} = 0;
	$self->{space} = "  ";
	$self->{indent_space} = "";
	$self->{store} = "";

	bless ($self, $class);
	return $self;
}

# Object methods.
sub Open($) {
	my $self = shift;
	$self->{filename} = shift;

	if( -e $self->{filename} ) {
		LogMess("$self->{filename} already exists, overwritting", 3);
	}
	
	$self->{filehandle} = new FileHandle;
	$self->{filehandle}->open("> $self->{filename}")
		or LogMess("Can't open $self->{filename} for output", 1);

	# Write header lines to the file.
	$self->{store} .= "#%npr\n#\n";

	$self->Open_Block();
}

sub WriteToFile() {
	my $self = shift;

	$self->{filehandle}->print( $self->{store} );
	$self->{store} = "";
	return;
}

sub Open_Block() {
	my( $self, $name ) = @_;

	# Indenting the correct number of levels.
	$self->{store} .= $self->{indent_space};

	# Printing the block name if there is one.
	$name and $self->{store} .= $name." ";

	# Adding an open bracket and newline at the end of the line.
	$self->{store} .= "{\n";

	# Sorting out the indentation level and its spacing.
	$self->{indent_level}++;
	$self->{indent_space} = $self->{space} x $self->{indent_level};
	return;
}

sub Close_Block() {
	my $self = shift;

	# Sorting out the indentation level and its spacing.
	$self->{indent_level}--;
	$self->{indent_space} = $self->{space} x $self->{indent_level};
	$self->{store} .= $self->{indent_space}."}\n";
	return;
}

sub Write_Comment() {
	(shift)->{store} .= "# ".(shift)."\n";
	return;
}

# This function prints all the elements of a hash to the output string.
# The reference is supplied as an argument.  It checks is the value of
# the has element has any length.  If there is no length then nothing is
# printed.
sub Block_Info() {
	my( $self, $ref ) = @_;

	foreach( keys %$ref ) {
		next if !$_;
		next if !length( $ref->{$_} );
		$self->{store} .= $self->{indent_space}.$_." ".$ref->{$_}."\n";
	}

	return;
}


# This function opens, writes the information and closes the block.
# It takes a blockname and a Hash reference as arguments.
sub Create_Block() {
	my( $self, $name, $ref ) = @_;

	my $block = $self->{indent_space}.$name." {\n";

	foreach( keys %$ref ) {
		next if !$_;
		next if !length( $ref->{$_} );
		$block .= $self->{indent_space}.$self->{space}.$_." ".$ref->{$_}."\n";
	}

	$block .= $self->{indent_space}."}\n";
	$self->{filehandle}->print( $block );

	return;
}


sub Close() {
	my $self = shift;

	# Adding brackets to close off all the blocks.
	while( 0 < $self->{indent_level} ) {
		$self->Close_Block();
	}

	$self->WriteToFile();

	$self->{filehandle}->close;

	$self = {};
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

LIF_Writer - a Perl 5 object that produces a Metrica Loader Input
             File.

=head1 SYNOPSIS

  use LIF_Writer;

  $objid = LIF_Writer->New();

  $objid->Open($filename);

  $objid->Open_Block( $blockname );
  
  $objid->Close_Block();
  
  $objid->WriteToFile();
  
  $objid->Write_Comment( "Comment string" );
  
  $objid->Block_Info( \%counter_hash );

  $objid->Create_Block( $blockname, \%counter_hash );

  $objid->Close();

=head1 DESCRIPTION

This perl object includes a set of subroutines that enable the easy production
of a Metrica Loader Input Format (LIF) file.

The rest of this man page will get done eventually but it is not that
important are the moment.  Look at the functions if you want to find
out what they do.

=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
