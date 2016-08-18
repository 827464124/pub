#!/usr/bin/perl -w

use strict;

use File::Basename;

my (@aCols,@aValues,$iCol,$sSql,$sub_sql_cols,$sub_sql_value);

$sub_sql_cols="abc,uyyd,ikj";
$sub_sql_value="123,567,985";

		@aCols=split(',',$sub_sql_cols);
			@aValues=split(',',$sub_sql_value);
			for ($iCol=0;$iCol<=$#aCols;$iCol++) {
				if ($iCol == 0) {
					$sSql=$aCols[$iCol]."='".$aValues[$iCol]."'";
				} else {
					$sSql=$sSql.",".$aCols[$iCol]."='".$aValues[$iCol]."'";
				}
			}
print "$sSql\n";