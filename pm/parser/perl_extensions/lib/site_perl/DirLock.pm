#
#-------------------------------------------------------------------------------
# @(#) common-modules/DirLock/DirLock.pm common-modules_r2.1.3.2:cset.000076:3:3 06/14/98 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package DirLock;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(lock_process unlock_process);
$VERSION = '0.01';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use strict;
use AudLog;
use File::Basename;

my $lock_file_name;

sub make_lock_file {
	my $filename = shift;

	# Checking if the lock file already exists
	if( -e $filename ) {
		LogMess("Old Lock file found", 5 );
		open LOCK, "<$filename" or return "Can't open existing Lock File", 1;

		# Try and read the PID number from the file
		my $pid = <LOCK>;
		close LOCK;

		# Checking if something was read from the file
		if( not defined($pid) ) {
			return "Existing Lock File is empty - exiting", 1;
		}
		$pid =~ tr/\n//d;
		LogMess("Old Lock file contains pid [${pid}]", 5 );

		# Checking if a process with this PID exist
		if( kill 0 => $pid ) {
			return "Process already running", 1;
		}

		# All seems OK.  Deleteing the lockfile
		unlink($filename);
		LogMess("Removing Old Lock file", 5 );
	}

	# Opening the new lock file to be written to
	open LOCK, ">${filename}" or return "Can't create Lock File", 1;

	# Printing the process id to the lock file
	# Probably should put some error checking on the writing
	# of the PID to the file
	print LOCK $$, "\n";

	close LOCK;

	# Storing the lock file name as a package variable
	$lock_file_name = $filename;

	return;
}

sub lock_process {
	my $lock_dir = shift;
#modified by zhung my @retstat = make_lock_file($name);  --> my $retstat = make_lock_file($name);
	LogMess("lock_process(${lock_dir},$0)", 5 );

	my $name = ${lock_dir}."/.lock_".basename($0).".pid";
	my $retstat = make_lock_file($name);

	if( defined($retstat) ) {
		LogMess($retstat);
		return "STARTUP_EXIT";
	}
	else {
		return;
	}
}

sub unlock_process {

	LogMess("unlock_process(${lock_file_name})", 5 );

	unlink($lock_file_name);
}

1; # So the use or require works

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

DirLock - An extension that provides a simple directory locking mechanism.

=head1 SYNOPSIS

  use DirLock;
  lock_process("input/directory");
  unlock_process();

=head1 DESCRIPTION

This module provides a simple directory locking mechanism.  It places
a file ".lock_progname.pid" in the required directory.  If another
instance of the same program attempts to start processing the directory
it will descover the 'lock' file is there.

On completion of processing the 'lock' file is removed.

=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut
