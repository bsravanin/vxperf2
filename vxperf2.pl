#! /usr/bin/perl -w
#  Author: Sravan Bhamidipati
#  Date: 24th May, 2011
#  Purpose: Summarize and visualize logs containing text databases.

use vxperf2;

if (scalar(@ARGV) != 3) {die "Usage: $0 <rulesPath> <resultsPath> <logPath>\n"}

my ($rulesFile, $resultsDir, $logPath) = ($ARGV[0], $ARGV[1], $ARGV[2]);

my @database = &parseLogFile($logPath);
&applyRules($rulesFile, $resultsDir, \@database);
