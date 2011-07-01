#! /usr/bin/perl -w
#  Author: Sravan Bhamidipati
#  Date: 1st June, 2011
#  Purpose: Build vxperf2 tarball.

use strict;

use Pod::Html;
pod2html "--infile=log2db.pm", "--outfile=log2db.html";
pod2html "--infile=vxperf2.pm", "--outfile=vxperf2.html";

my ($date, $month, $year) = (localtime)[3, 4, 5];
$year += 1900;
$month += 1;
my $vxper2 = "vxperf2-$year-$month-$date";

mkdir $vxper2;

use File::Copy::Recursive "rcopy";
foreach my $dir ("build.pl", "examples", "Graphics", "install.pl", "log2db.html", "log2db.pl", "log2db.pm", "README", "vxperf2.html", "vxperf2.pl", "vxperf2.pm") {rcopy ($dir, "$vxper2/$dir")}

`tar -czf $vxper2.tar.gz $vxper2`;
unlink "pod2htmi.tmp", "pod2htmd.tmp";

use File::Path;
rmtree $vxper2;
