
package nine;
my  @map;


my @row_1 = 1..9;
my @row_2 = 1..9;
my @row_3 = 1..9;
my @row_4 = 1..9;
my @row_5 = 1..9;
my @row_6 = 1..9;
my @row_7 = 1..9;
my @row_8 = 1..9;
my @row_9 = 1..9;

my @col_1 = 1..9;
my @col_2 = 1..9;
my @col_3 = 1..9;
my @col_4 = 1..9;
my @col_5 = 1..9;
my @col_6 = 1..9;
my @col_7 = 1..9;
my @col_8 = 1..9;
my @col_9 = 1..9;



sub new()
{
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {
		"MAP" => @_
	};
	bless $self ,$class;
	return $self;
}


sub cal
{
	my $this = shift;
	my @tmp = $this->{"MAP"};
	foreach my $raw (@tmp){
		@raw_idx  = split ('_',$raw);
		return "raw data is wrong\n" if (@raw_idx !=3);
		my $row_cmd = '$row_'.$raw_idx[0]."[$raw_idx[2]] = 0" ;
		my $col_cmd = '$col_'.$raw_idx[1].'['.$raw_idx[2].'] = 0 ' ;
		print ";;;";
		eval ('print "$row_cmd-\n"');
		eval ('$row_1[2] = 0');
#		$row_1[2] = 0;
		eval ("$col_cmd;");
	}
}

sub prt 
{
	foreach my $data (@row_1){
		print $data."\n";
	}
}





1;















