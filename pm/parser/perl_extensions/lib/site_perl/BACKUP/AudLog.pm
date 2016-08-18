#
#-------------------------------------------------------------------------------
# @(#) common-modules/AudLog/AudLog.pm common-modules_r2.1.3.2:cset.000076:3:3 06/14/98 @(#)
#-------------------------------------------------------------------------------
#
#   Copyright (C) ADC Metrica 1998
#
package AudLog;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(AudInit LogInit LogMess AudMess);
$VERSION = '0.01';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Setting the default name for the Audit and Log files.
my $af_name = undef;
my $lf_name = undef;

# The default Log message level
my $loglevel = 1;

sub AudInit {
	$af_name = shift;

	if( -e $af_name ) {
	}
	else {
		open LOG, ">${af_name}";
		close LOG;
	}
}

sub LogInit {
	$lf_name = shift;
	my $level = shift;

	if( defined($level) ) { $loglevel = $level; }

	if( -e $lf_name ) {
	}
	else {
		open LOG, ">${lf_name}";
		close LOG;
	}
}

sub AudMess {
	my $audmess = shift;

	# Constructing the audit message
	my $mess = "[".$$."] ".scalar localtime()." ".$audmess."\n";

	if( defined($lf_name) ) {
		open AUDIT, ">>${af_name}";
		print AUDIT $mess;
		close AUDIT;
	}
	elsif( -t STDERR ) {
		print STDERR $mess;
	}

	# If the loglevel is higher than 1 then print the audit 
	# message out to the log file as well.
	if( 1 < $loglevel ) {
		my $mess = "[".$$."] ".scalar localtime()." ".$loglevel.":A ".$audmess."\n";
		if( defined($lf_name) ) {
			open LOG, ">>${lf_name}";
			print LOG $mess;
			close LOG;
		}
		elsif( -t STDERR ) {
			print STDERR $mess;
		}
	}
}

sub LogMess {
	my ($logmess, $messlevel) = @_;

	# Setting the default level of the message
	if( not defined($messlevel) ) { $messlevel = 1; }

	# Ignoring messages that aren't of the correct level
	if( $messlevel > $loglevel ) { return; }

	# Constructing the Log message
	my $mess = "[".$$."] ".scalar localtime()." ".$loglevel.":".$messlevel." ".$logmess."\n";

	if( defined($lf_name) ) {
		open LOGFILE, ">>${lf_name}";
		print LOGFILE $mess;
		close LOGFILE;
	}
	elsif( -t STDERR ) {
		print STDERR $mess;
	}
}

1;	# So the require or use succeeds.

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

AudLog - A simple N-level logging and auditing extension

=head1 SYNOPSIS

  use AudLog;
  AudInit("../filename.audit");
  $log_level = 5;
  LogInit("../filename.log", $log_level);

  AudMess("The message that you want printed");
  $message_level = 3;
  LogMess("The message that you want printed", $message_level);

=head1 DESCRIPTION

This extension implements a simple Audit and Logging utility.  The 
messages are written out to the file specified in the initialisation
routines.

Log messages with a level less than the log_level set with LogInit
will be printed to the log file.

Have fun.

=head1 AUTHOR

Bob Hannaford, bob.hannaford@adc.metrica.co.uk

=head1 SEE ALSO

perl(1).

=cut

