#!/usr/bin/perl

package class;
@ISA=(Exporter);

sub new()
{
		my $class=shift;
		my $self={};
		print "$class\n";
		$self->{'word'}=shift;
		bless $self,$class;
		return $self;
}

sub s_print()
{
		$self=shift;
		print "$self->{'word'}\n";
}
