#
#--------------------------------------------------------------------
# @(#) common-modules/GenUtils/GenUtils.pm common-modules_r2.1.3.2:cset.000589:6:6 06/30/99 @(#)
#--------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package GenUtils;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(files_in_dir store_processed_file rename_completed_file convert_date_format);
$VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use AudLog;
use File::Basename;

my %MONTH_NAMES = ( '1' => "Jan", '2'  => "Feb", '3'  => "Mar",
		'4'  => "Apr", '5' => "May", '6'  => "Jun",
		'7'  => "Jul", '8'  => "Aug", '9' => "Sep",
		'10' => "Oct", '11' => "Nov", '12' => "Dec" );
my $FMT_DATE = '';
my $UNFMT_DATE = '';


# This function converts the date format into a format suitable
# for the Loader. As its arguement it takes a reference to a scalar
# that contains the date string
sub convert_date_format($) {
	my $ref = shift;

	if( $UNFMT_DATE eq $$ref ){
		$$ref = $FMT_DATE;
		return;
	}

	$$ref =~ /\s*(\d*)\s*-\s*(\d*)\s*-\s*(\d*)\s*/o;

	$UNFMT_DATE = $$ref;

	# Creating the new date string
	$$ref = $3.$MONTH_NAMES{int($2)}.$1;

	$FMT_DATE = $$ref;
	return;
}

# Reads the names of all the files in the directory
sub files_in_dir($) {
	# The argument to this function is a scalar that contains the name
	# of the directory that the listing is wanted for.
	opendir DIR, shift;
	my @files = readdir DIR;
	close DIR;

	return @files;
}

# This function renames and stores completed files.  The old file end
# with extension $old_ext and will be renamed with $new_ext.
sub rename_completed_file($$$) {
	my ($old_ext, $new_ext, $file) = @_;

	my $new_name = $file;
	$new_name =~ s/${old_ext}$/${new_ext}/i;
	LogMess("Renaming '$file' to '$new_name'", 5);
	rename $file, $new_name;
	return $new_name;
}

sub store_processed_file {
	my ($storage_dir, $delete_orig, $debug, $fullfilename) = @_;

	my $dirname = dirname($fullfilename);
	my $basename = basename($fullfilename);

	return 0 if( $debug );

	if( $storage_dir ) {
		my $new_name = $storage_dir."/".$basename;
	
		LogMess("Storing '$basename'", 5);
	
		my $ret = rename $fullfilename, $new_name;
		if( not $ret ) {
			LogMess("Error storing '$basename' ".$!, 1);
			return -1;
		}

		if( not $delete_orig ) {
			LogMess("Relinking to original name '$basename'", 5);
			link $new_name, $fullfilename;
		}
	}
	elsif( not $storage_dir and $delete_orig ) {
		LogMess("Deleting '$basename'", 5);
		unlink($fullfilename);
	}
	return 0;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GenUtils - Perl extension that contains some general utilities used
           in all the parsers

=head1 SYNOPSIS

  use GenUtils;

  convert_date_format($date_scalar);

  @files = files_in_dir( $dir_name );

  $new_name = rename_completed_file( $old_ext, $new_ext, $filename );

  store_processed_file( $keep, $delete, $debug, $filename );

=head1 DESCRIPTION


=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
