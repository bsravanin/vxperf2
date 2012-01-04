#! /usr/bin/perl -w
#
#  Author: Sravan Bhamidipati @bsravanin
#  License: MIT License http://www.opensource.org/licenses/mit-license.php
#  Courtesy: Symantec Corporation http://www.symantec.com
#  Date: 29th November, 2011
#  Purpose: Modify a known log type into a text database.
#  DONE: esxtop iostat mpstat netstat pidstat prstat sar slabinfo top typeperf vmstat vrstat vxfsstatBCache vxfsstatICache vxfsstatFile vxmemstat vxrlink vxrlinkE vxrlinkStatus vxrvg vxstat
#  TODO: sarasc


use strict;
use log2db;
use File::Basename;
use Switch;

if (scalar(@ARGV) != 3) {die "Usage: $0 <esxtop|iostat|mpstat|netstat|pidstat|prstat|sar|slabinfo|top|typeperf|vmstat|vrstat|vxfsstatBCache|vxfsstatFile|vxfsstatICache|vxmemstat|vxrlink|vxrlinkE|vxrlinkStatus|vxrvg|vxstat> <logPath> <dbPath>\n"}

my ($logType, $logPath, $tablePath) = ($ARGV[0], $ARGV[1], $ARGV[2]);
my $saveDir = dirname($tablePath);

switch ($logType) {
	case 'esxtop' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyTypeperf($logPath, $tablePath);
	}

	case 'iostat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyIostat($logPath, $tablePath);
	}

	case 'mpstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifySolstat($logPath, $tablePath);
	}

	case 'netstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyNetstat($logPath, $tablePath);
	}

	case 'pidstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifySysstat($logPath, $tablePath);
	}

	case 'prstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifySolstat($logPath, $tablePath);
	}

	case 'sar' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifySysstat($logPath, $tablePath);
	}

	case 'slabinfo' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifySlabinfo($logPath, $tablePath);
	}

	case 'top' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyTop($logPath, $tablePath);
	}

	case 'typeperf' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyTypeperf($logPath, $tablePath);
	}

	case 'vmstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVmstat($logPath, $tablePath);
	}

	case 'vrstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVrstat($logPath, $tablePath);
	}

	case 'vxfsstatBCache' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxfsstatBCache($logPath, $tablePath);
	}

	case 'vxfsstatFile' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxfsstatAll($logPath, $tablePath);
	}

	case 'vxfsstatICache' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxfsstatICache($logPath, $tablePath);
	}

	case 'vxmemstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVvrstat($logPath, $tablePath);
	}

	case 'vxrlink' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVvrstat($logPath, $tablePath);
	}

	case 'vxrlinkE' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxrlinkE($logPath, $tablePath);
	}

	case 'vxrlinkStatus' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxrlinkStatus($logPath, $tablePath);
	}

	case 'vxrvg' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVvrstat($logPath, $tablePath);
	}

	case 'vxstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxstat($logPath, $tablePath);
	}

	else {die "Please verify the spelling of $logType.\nUsage: $0 <esxtop|iostat|mpstat|netstat|pidstat|prstat|sar|slabinfo|top|typeperf|vmstat|vrstat|vxfsstatBCache|vxfsstatFile|vxfsstatICache|vxmemstat|vxrlink|vxrlinkE|vxrlinkStatus|vxrvg|vxstat> <logPath> <dbPath>\n"}
}
