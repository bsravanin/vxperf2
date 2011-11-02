#! /usr/bin/perl -w
#  Author: Sravan Bhamidipati
#  Date: 2nd November, 2011
#  Purpose: Modify logs into text databases that vxperf2 can parse.
#  DONE: esxtop iostat mpstat netstat pidstat prstat sar slabinfo typeperf vmstat vxfsstatBCache vxfsstatICache vxstat
#  TODO: sarasc top


use strict;
use File::Basename;
use File::Path;


# Name: modifyIostat
# Purpose: To modify iostat log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyIostat {
	my ($logPath, $tablePath, $time, $firstWord, $os, @temp) = ($_[0], $_[1], "", 0, "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if ($firstWord == 0) {
			$firstWord++;
			if (/Linux/) {$os = "linux"}
		}
		
		if ($os eq "linux") {
			if (/Time:/) {
				&use24HourFormat();
				chomp();
				@temp = split(/\s+/, $_);
				$time = $temp[1];
				print MODIFIED "\n";
			}
			else {
				if (/(\d\d)\/(\d\d)\/(\d\d)/ || $_ eq "\n") {}
				else {
					s#^(.*)(avg-cpu:)?#$time\t$1#;
					(/Device:/) ? print MODIFIED "\n$_" : print MODIFIED $_;
				}
			}
		}
		else {
			if (/\d\d:\d\d:\d\d/) {
				&use24HourFormat();
				chomp();
				@temp = split(/\s+/, $_);
				$time = $temp[3];
				print MODIFIED "\n";
			}
			elsif (/tty\s+cpu/ || /extended\s+device\s+statistics/) {}
			elsif (/device/) {print MODIFIED "\n$time\t$_"}
			else {print MODIFIED "$time\t$_"}
		}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyNetstat
# Purpose: To modify netstat log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyNetstat {
	my ($logPath, $tablePath, $time, $interface, @temp) = ($_[0], $_[1], "", "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/input/) {
			@temp = split(/\s+/, $_);
			$interface = $temp[2];
		}
		elsif (/packets/) {print MODIFIED "\n$interface-input-packets\t$interface-input-errs\t$interface-output-packets\t$interface-output-errs\t$interface-output-colls\t$interface-input-total-packets\t$interface-input-total-errs\t$interface-output-total-packets\t$interface-output-total-errs\t$interface-output-total-colls\n"}
		else {print MODIFIED $_}
		
	}
	close MODIFIED;
	close LOG;
}


# Name: modifySlabinfo
# Purpose: To modify slabinfo log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifySlabinfo {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/SLAB_INFO > INFO/) {
			&use24HourFormat();
			s#-#\t#g;
			chomp();
			@temp = split(/\s+/, $_);
			$time = $temp[1];
			print MODIFIED "\n";
		}
		else {
			if (/slabinfo\s+-\s+version:/) {}
			else {
				s/#|<|>|:|tunables|slabdata//g && s#^#$time\t#;
				print MODIFIED $_;
			}
		}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifySolstat
# Purpose: To modify mpstat or prstat log of Solaris to tables.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifySolstat {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/Sun |Mon |Tue |Wed |Thu |Fri |Sat /) {
			&use24HourFormat();
			chomp();
			@temp = split(/\s+/, $_);
			$time = $temp[3];
			print MODIFIED "\n";
		}
		elsif (/Total:/) {
			chomp();
			@temp = split(/,\s+|\s+/, $_);
			print MODIFIED "\nprocesses\tlwps\tld1\tld5\tld15\n$temp[1]\t$temp[3]\t$temp[7]\t$temp[8]\t$temp[9]\n\n";
		}
		else {
			s#^(PID|CPU)#\n$1#;
			# s#^(Total:|CPU)#\n$time\t$1# || s#^#$time\t#;
			print MODIFIED $_;
		}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifySysstat
# Purpose: To modify pidstat or sar log of Sysstat to tables.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifySysstat {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/(\d\d)\/(\d\d)\/(\d\d)/ || /Average/) {}
		else {&use24HourFormat(); print MODIFIED $_}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyTypeperf
# Purpose: To modify esxtop (ESX) or typeperf (Windows) log to tables.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyTypeperf {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		s/" "/"0"/g;
		s/"\(|\)|\\\\//g;
		s/ |\(|\\|\//-/g;
		s/",/\t/g;
		s/"//g;
		s/-+/-/g;
		print MODIFIED $_;
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyVmstat
# Purpose: To modify vmstat log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyVmstat {
	my ($logPath, $tablePath, $time) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/memory/ || /--/) {print MODIFIED "\n"}
		elsif (/us\s+sy\s+/) {
			s/us\s+sy\s+/us sys /;
			print MODIFIED $_;
		}
		else {print MODIFIED $_}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyVxfsstatBCache
# Purpose: To modify vxfsstat_bcache log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyVxfsstatBCache {
	my ($logPath, $tablePath, $time, $current, $maximum, $lookups, $hitRate, $recycleAge, @temp) = ($_[0], $_[1], "", "", "", "", "", "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\ncurrent\tmaximum\tlookups\thitRate\trecycleAge\n";
	print MODIFIED "\n";
	while (<LOG>) {
		s#^\s+##;
		if ($_ eq "\n" || /buffer cache statistics/) {}
		elsif (/sample/) {
			chomp();
			($time, @temp) = split(/\s+/, $_);
		}
		elsif (/Kbyte/) {
			chomp();
			@temp = split(/\s+/, $_);
			$current = $temp[0];
			$maximum = $temp[3];
		}
		elsif (/lookups/) {
			chomp();
			@temp = split(/\s+/, $_);
			$lookups = $temp[0];
			$hitRate = $temp[2];
		}
		elsif (/recycle/) {
			chomp();
			($recycleAge, @temp) = split(/\s+/, $_);
			print MODIFIED "$time\t$current\t$maximum\t$lookups\t$hitRate\t$recycleAge\n";
		}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyVxfsstatICache
# Purpose: To modify vxfsstat_icache log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyVxfsstatICache {
	my ($logPath, $tablePath, $time, $maximumDNLCEntries, $totalLookups, $fastDNLCLookups, $totalDNLCLookups, $DNLCHitRate, $totalEnter, $hitPerEnter, $totalDirCacheSetup, $callsPerSetup, $directoryScan, $fastDirectoryScan, $inodesCurrent, $inodesPeak, $inodesMaximum, $inodeLookups, $inodeHitRate, $inodesAllocated, $inodesFreed, $recycleAge, $freeAge, @temp) = ($_[0], $_[1], "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	print MODIFIED "time\tmaximumDNLCEntries\ttotalLookups\tfastDNLCLookups\ttotalDNLCLookups\tDNLCHitRate\ttotalEnter\thitPerEnter\ttotalDirCacheSetup\tcallsPerSetup\tdirectoryScan\tfastDirectoryScan\tinodesCurrent\tinodesPeak\tinodesMaximum\tinodeLookups\tinodeHitRate\tinodesAllocated\tinodesFreed\trecycleAge\tfreeAge\n";
	while (<LOG>) {
		s#^\s+##;
		if ($_ eq "\n" && /Statistics/i) {}
		elsif (/sample/) {
			chomp();
			($time, @temp) = split(/\s+/, $_);
		}
		elsif (/maximum entries in dnlc/) {
			chomp();
			($maximumDNLCEntries, @temp) = split(/\s+/, $_);
		}
		elsif (/fast lookup/) {
			chomp();
			@temp = split(/\s+/, $_);
			$totalLookups = $temp[0];
			$fastDNLCLookups = $temp[3];
		}
		elsif (/dnlc lookup/) {
			chomp();
			@temp = split(/\s+/, $_);
			$totalDNLCLookups = $temp[0];
			$DNLCHitRate = $temp[4];
		}
		elsif (/hit per enter/) {
			chomp();
			@temp = split(/\s+/, $_);
			$totalEnter = $temp[0];
			$hitPerEnter = $temp[3];
		}
		elsif (/dircache/) {
			chomp();
			@temp = split(/\s+/, $_);
			$totalDirCacheSetup = $temp[0];
			$callsPerSetup = $temp[4];
		}
		elsif (/scan/) {
			chomp();
			@temp = split(/\s+/, $_);
			$directoryScan = $temp[0];
			$fastDirectoryScan = $temp[4];
		}
		elsif (/inodes current/) {
			chomp();
			@temp = split(/\s+/, $_);
			$inodesCurrent = $temp[0];
			$inodesPeak = $temp[3];
			$inodesMaximum = $temp[5];
		}
		elsif (/% hit rate/) {
			chomp();
			@temp = split(/\s+/, $_);
			$inodeLookups = $temp[0];
			$inodeHitRate = $temp[2];
		}
		elsif (/freed/) {
			chomp();
			@temp = split(/\s+/, $_);
			$inodesAllocated = $temp[0];
			$inodesFreed = $temp[3];
		}
		elsif (/recycle/) {
			chomp();
			($recycleAge, @temp) = split(/\s+/, $_);
		}
		elsif (/free age/) {
			chomp();
			($freeAge, @temp) = split(/\s+/, $_);
			print MODIFIED "$time\t$maximumDNLCEntries\t$totalLookups\t$fastDNLCLookups\t$totalDNLCLookups\t$DNLCHitRate\t$totalEnter\t$hitPerEnter\t$totalDirCacheSetup\t$callsPerSetup\t$directoryScan\t$fastDirectoryScan\t$inodesCurrent\t$inodesPeak\t$inodesMaximum\t$inodeLookups\t$inodeHitRate\t$inodesAllocated\t$inodesFreed\t$recycleAge\t$freeAge\n";
		}
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyVxfsstatFile
# Purpose: To modify vxfsstat_file log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyVxfsstatFile {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	print MODIFIED "Time\tvxi\tCount\n";
	while (<LOG>) {
		if ($_ eq "\n") {}
		elsif (/sample/) {
			chomp();
			($time, @temp) = split(/\s+/, $_);
		}
		else {print MODIFIED "$time\t$_"}
		
	}
	close MODIFIED;
	close LOG;
}


# Name: modifyVxstat
# Purpose: To modify vxstat log to table.
# Parameters: Path to log file, path to table file.
# Returns: -
sub modifyVxstat {
	my ($logPath, $tablePath, $time, @temp) = ($_[0], $_[1], "");

	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	open MODIFIED, ">$tablePath" or die "Cannot open $tablePath for write: $!\n";
	print MODIFIED "\n";
	while (<LOG>) {
		if (/OPERATIONS\s+BLOCKS\s+AVG\s+TIME/ || $_ eq "\n") {}
		elsif (/TYP\s+NAME\s+READ\s+WRITE\s+READ\s+WRITE\s+READ\s+WRITE/) {print MODIFIED "Time\tType\tName\tOpsRd\tOpsWr\tBlksRd\tBlksWr\tAvgRd\tAvgWr\n"}
		elsif (/Sun |Mon |Tue |Wed |Thu |Fri |Sat /)  {
			&use24HourFormat();
			chomp();
			@temp = split(/\s+/, $_);
			if ($temp[3] =~ /\d{4}/) {$time = $temp[4]}
			elsif ($temp[4] =~ /\d{4}/) {$time = $temp[3]}
		}
		else {s#^#$time\t#; print MODIFIED $_}
	}
	close MODIFIED;
	close LOG;
}


# Name: use24HourFormat
# Purpose: To modify a timestamp to 24-hour format.
# Parameters: String containing timestamp.
# Returns: -
sub use24HourFormat {
	my $colon = ":";	# Timestamp delimiter
	s#(\d\d):(\d\d):(\d\d)\s+AM#$1:$2:$3#g || s#(\d\d):(\d\d):(\d\d)\s+PM#($1+12).$colon.$2.$colon.$3#eg;
}


1;


#__END__
###########################################DOCUMENTATION###########################################
=head1

=head1 NAME

B<log2db>

=head1 SYNOPSIS

  use log2db;

  &modifyIostat($logPath, $tablePath);		# iostat
  &modifyNetstat($logPath, $tablePath);		# netstat
  &modifySlabinfo($logPath, $tablePath);	# slabinfo
  &modifySolstat($logPath, $tablePath);		# mpstat, prstat
  &modifySysstat($logPath, $tablePath);		# pidstat, sar
  &modifyTypeperf($logPath, $tablePath);	# esxtop, typeperf
  &modifyVmstat($logPath, $tablePath);		# vmstat
  &modifyVxfsstatBCache($logPath, $tablePath);	# vxfsstat_bcache
  &modifyVxfsstatICache($logPath, $tablePath);	# vxfsstat_icache
  &modifyVxfsstatFile($logPath, $tablePath);	# vxfsstat_file
  &modifyVxstat($logPath, $tablePath);		# vxstat

=head1 DESCRIPTION

B<log2db> is a utility to modify log files generated using esxtop, iostat, mpstat, netstat, pidstat, prstat, sar, slabinfo, typeperf, vmstat, vxfsstat, vxstat into text database that can be parsed by B<vxperf2>. B<log2db.pl> is the Perl wrapper around B<log2db> which can be run from the command-line or called from non-Perl scripts.

=head1 SUBROUTINES

The B<log2db> module contains eleven subroutines: B<modifyIostat>, B<modifyNetstat>, B<modifySlabinfo>, B<modifySolstat>, B<modifySysstat>, B<modifyTypeperf>, B<modifyVmstat>, B<modifyVxfsstatBCache>, B<modifyVxfsstatICache>, B<modifyVxfsstatFile> and B<modifyVxstat>.

All of them take two parameters -- path to the log file to be modified and path to the table file to be saved as. They're all very trivial, basic, and "hardcoded". One golden rule for creating subroutines is that B<the table file should always start with a newline>.

=head1 AUTHOR

B<Sravan Bhamidipati> (Sravan_Bhamidipati@symantec.com, bsravanin@gmail.com)

=head1 CREDITS

Rajalaxmi Angadi contributed to the B<modifyVxfsstatBCache>, B<modifyVxfsstatICache>, B<modifyVxfsstatFile> and B<modifyVxstat> subroutines.

=head1 LICENSE AND COPYRIGHT

GNU GPL: http://www.gnu.org/copyleft/gpl.html

=head1 LAST UPDATED

2nd November, 2011

=cut