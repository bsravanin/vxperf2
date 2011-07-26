#! /usr/bin/perl -w
#  Author: Sravan Bhamidipati
#  Date: 26th July, 2011
#  Purpose: Modify a known log type into a text database.
#  DONE: esxtop iostat mpstat netstat pidstat prstat sar slabinfo typeperf vmstat vxfsstatBCache vxfsstatICache vxfsstatFile vxstat
#  TODO: sarasc top


use strict;
use log2db;
use File::Basename;
use Switch;

if (scalar(@ARGV) != 3) {die "Usage: $0 <esxtop|iostat|mpstat|netstat|pidstat|prstat|sar|slabinfo|typeperf|vmstat|vxfsstatBCache|vxfsstatFile|vxfsstatICache|vxstat> <logPath> <dbPath>\n"}

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

	case 'typeperf' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyTypeperf($logPath, $tablePath);
	}

	case 'vmstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVmstat($logPath, $tablePath);
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

	case 'vxstat' {
		if (! -d $saveDir) {mkpath ($saveDir) || warn "Directory $saveDir already exists or can't be created: $!\n"}
		&modifyVxstat($logPath, $tablePath);
	}

	else {die "Please verify the spelling of $logType.\nUsage: $0 <esxtop|iostat|mpstat|netstat|pidstat|prstat|sar|slabinfo|typeperf|vmstat|vxfsstatBCache|vxfsstatFile|vxfsstatICache|vxstat> <logPath> <dbPath>\n"}
}
