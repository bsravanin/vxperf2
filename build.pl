#! /usr/bin/perl -w
#
#  Author: Sravan Bhamidipati @bsravanin
#  License: MIT License http://www.opensource.org/licenses/mit-license.php
#  Courtesy: Symantec Corporation http://www.symantec.com
#  Date: 16th November, 2011
#  Purpose: Build vxperf2 tarball.

use strict;

use Pod::Html;
pod2html "--infile=log2db.pm", "--outfile=log2db.html";
pod2html "--infile=vxperf2.pm", "--outfile=vxperf2.html";

my ($date, $month, $year) = (localtime)[3, 4, 5];
$year += 1900;
$month += 1;
my $vxperf2 = "vxperf2-$year-$month-$date";

mkdir $vxperf2;

use File::Copy::Recursive "rcopy";
foreach ("build.pl", "examples", "Graphics", "install.pl", "log2db.html", "log2db.pl", "log2db.pm", "README", "vxperf2.html", "vxperf2.pl", "vxperf2.pm") {rcopy ($_, "$vxperf2/$_")}

`tar -czf $vxperf2.tar.gz $vxperf2`;
unlink "pod2htmi.tmp", "pod2htmd.tmp";

use File::Path;
rmtree $vxperf2;
