#! /usr/bin/perl -w
#
#  Author: Sravan Bhamidipati @bsravanin
#  License: MIT License http://www.opensource.org/licenses/mit-license.php
#  Courtesy: Symantec Corporation http://www.symantec.com
#  Date: 25th November, 2011
#  Purpose: Summarize and visualize logs containing text databases.

use vxperf2;

if (scalar(@ARGV) < 3) {die "Usage: $0 <rulesPath> <resultsPath> <logPath1> <logPath2> <logPath3> ...\n"}

my $rulesFile = shift(@ARGV);
my $resultsDir = shift(@ARGV);
my @databases;

foreach (@ARGV) {push (@databases, [&parseLogFile($_)])}
&applyRules($rulesFile, $resultsDir, @databases);
