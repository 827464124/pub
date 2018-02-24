

package single;
our $single = 0;
my $g_self;
sub new {
#		return $g_self if (defined $g_self && ref ($g_self) eq __PACKAGE__);

		$this = shift;
		$class = ref ($this) || $this;
		my $self = {};
		bless $self ,$class;
#		$g_self = $self;
		$single ++;
		return $self;
}

sub add {
	my $this = shift ;
	$this->{"AAA"} ++;
}
sub get_instance_num
{
	return $single;
}

sub destroy 
{
	my $this = shift;
	our $single--;
#__PACKAGE__::DESTROY();
}

sub DESTROY {
	print "------\n";
	SUPER::DESTROY();
}


1;
