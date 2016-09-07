#!/usr/bin/perl

use Spreadsheet::ParseExcel;

my $parser = Spreadsheet::ParseExcel->new();
my $wsheet = $parser->parse('./cloadmap.xls');

if (!defined $wsheet ) { die "create sheet failed! ".$parser->error()."\n";}

for my $wh ($wsheet->worksheets())
{
		my ($min_row,$max_row) = $wh->row_range();
		my ($min_col,$max_col) = $wh->col_range();
		for my $row  ($min_row .. $max_row){
				for my $col ($min_col .. $max_col){
						my $cell = $wh->get_cell($row,$col);
						next unless $cell;
						print $cell->value()."\n";
				}
		}
}
