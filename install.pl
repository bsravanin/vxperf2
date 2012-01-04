#! /usr/bin/perl -w
#
#  Author: Sravan Bhamidipati @bsravanin
#  License: MIT License http://www.opensource.org/licenses/mit-license.php
#  Courtesy: Symantec Corporation http://www.symantec.com
#  Date: 16th November, 2011
#  Purpose: Copy modules related to vxperf2 into @INC, and respective wrappers into BIN.

use strict;
use File::Path;
use File::Copy;
use File::Basename;

if (! -d "$INC[0]/Graphics") {mkpath ("$INC[0]/Graphics") || die "Directory $INC[0]/Graphics can't be created: $!\n"}

foreach ("Graphics/GnuplotIF.pm", "log2db.pm", "vxperf2.pm") {copy ($_, "$INC[0]/" . $_) || die "File $_ can't be copied: $!\n"}

foreach ("log2db.pl", "vxperf2.pl") {
	copy ($_, dirname($^X) . "/" . $_) || die "File $_ can't be copied: $!\n";
	chmod 0755, dirname($^X) . "/" . $_;
}
