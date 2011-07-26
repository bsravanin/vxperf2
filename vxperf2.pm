#! /usr/bin/perl -w
#  Author: Sravan Bhamidipati
#  Date: 26th July, 2011
#  Purpose: Perl module with subroutines to parse text databases, summarize and visualize them based on a rules file.


use strict;
use File::Basename;
use File::Path;


######################################CHECKING ARRAY EQUALITY######################################
# Name: equals
# Purpose: To check whether two integer arrays are equal. Smart match operator introduced only in 5.10.
# Parameters: Two integer arrays.
# Returns: 1 if equal, 0 if not equal.
sub equals {
	if ($#{$_[0]} != $#{$_[1]}) {return 0}

	foreach my $val (0 .. $#{$_[0]}) {
		unless ($_[0][$val] eq $_[1][$val]) {return 0}
	}

	return 1;
}
######################################CHECKED ARRAY EQUALITY#######################################


#########################################PARSING LOG FILE##########################################
# Name: parseLogFile
# Purpose: To parse log file and create a database out of it.
# Parameters: Path to log file.
# Returns: @database, an array of hashes.
sub parseLogFile {
	my ($logPath, $isTable, $isNewTable, $tableNum, $row, $column) = ($_[0], 0, 1, 0, 0, 0), my ($tablename, @line, @tables, @database);

	# EXTRACT UNIQUE TABLES INTO AN ARRAY OF ARRAYS
	# EXTRACT ROWS INTO AN ARRAY OF HASHES
	open LOG, $logPath or die "Cannot open $logPath for read: $!\n";
	while (<LOG>) {
		if ($_ eq "\n" || /^\s*$/) {$isTable = 1}
		elsif ($isTable == 1) {
			$isTable = 0;
			chomp();
			@line = split(/\s+/, $_);

			if ($line[0] =~ /:/) {$line[0] = "Time"}

			if ($#tables >= 0) {
				$isNewTable = 1;
				$tableNum = 0;

				foreach $tablename (@tables) {
					if ($isNewTable == 1) {equals(\@$tablename, \@line) ? ($isNewTable = 0) : $tableNum++}
					# if ($isNewTable == 1) {(@$tablename ~~ @line) ? ($isNewTable = 0) : $tableNum++}
				}
			}

			if ($isNewTable == 1) {push @tables, [@line]}
		}
		else {
			chomp();
			@line = split(/\s+/, $_);

			for $column (0 .. $#{$tables[$tableNum]}) {$database[$row]{$tables[$tableNum][$column]} = $line[$column]}
			$row++;
		}
	}
	close LOG;

	# DEBUG LOGGING
	# foreach $row (@tables) {foreach $column (0 .. $#{$row}) {print "@$row[$column]\t"} print "\n"}
	# foreach $row (@database) {foreach $column (keys %{$row}) {print "$column: @$row{$column}\t"} print "\n"}

	return @database;
}
#########################################PARSED LOG FILE###########################################


###########################################APPLYING RULES##########################################
# Name: applyRules
# Purpose: First parse rules file. Second apply the rules on database. Third write results.
# Parameters: Path to rules file, Path to results directory, @database (obtained by parsing log file).
# Returns: -
sub applyRules {
	my ($rulesFile, $resultsDir, @databases) = @_;

	foreach (@databases) {
		if (ref($_) ne 'ARRAY') {die "One of the arguments of subroutine applyRules is not an array reference.\n"}
	}

	#######################################PARSING RULES FILE######################################
	my ($plot, $offset, $dataPoints, $field, $zaxis, $temp, @line, @yaxes, @plots, @only) = ("", 0, 0);

	open RULES, $rulesFile or die "Cannot open $rulesFile for read: $!\n";
	while (<RULES>) {
		chomp();
		s#^\s+##;
		if (/^\s*y-axis/i) {
			($temp, @line) = split(/\s+/, $_);
			foreach $field (@line) {push @yaxes, $field}
		}
		elsif (/^\s*z-axis/i) {
			@line = split(/\s+/, $_);
			$zaxis = $line[1];
		}
		elsif (/^\s*plot/i) {
			s#/#!#g;	# FOR FIELDS CONTAINING '/' IN THEM.
			($temp, @line) = split(/\s+/, $_);
			foreach $field (@line) {$plot = ($plot eq "") ? $field : $plot . "-" . $field}
			push @plots, $plot;
			$plot = "";
		}
		elsif (/^\s*only/i) {
			($temp, @line) = split(/\s+/, $_);
			foreach $field (@line) {push @only, $field}
		}
		elsif (/^\s*offset/i) {
			@line = split(/\s+/, $_);
			$offset = $line[1];
		}
		elsif (/^\s*points/i) {
			@line = split(/\s+/, $_);
			$dataPoints = $line[1];
		}
	}
	close RULES;
	#######################################PARSED RULES FILE#######################################


	if (! -d $resultsDir) {mkpath ($resultsDir) || die "Directory $resultsDir can't be created: $!\n"}


	########################################POST-PROCESSING########################################
	my ($summary, @ydatasets) = (1);

	foreach (@databases) {
		my @database = @{$_}, my ($row, %fieldOffset, %fieldPoints, %ydata, %functions);

		foreach $row (@database) {
			foreach $field (@yaxes) {
				if (defined(@$row{$field})) {
					if ($offset > 0) {
						if (!defined($fieldOffset{$field}) || $fieldOffset{$field} < $offset) {
							$fieldOffset{$field}++;
							next;
						}
					}
					if ($dataPoints > 0) {
						if (!defined($fieldPoints{$field}) || $fieldPoints{$field} < $dataPoints) {$fieldPoints{$field}++}
						else {last}
					}

					# ADJUST FOR UNITS
					@$row{$field} =~ s/(%$|k$)// || @$row{$field} =~ s/(.*)m$/$1*1024/e || @$row{$field} =~ s/(.*)g$/$1*1048576/e;

					# EVALUATE FUNCTIONS
					push @{$ydata{$field}}, @$row{$field};

					$functions{$field}{'rows'}++;
					$functions{$field}{'sum'} += @$row{$field};
					if (!defined($functions{$field}{'max'}) || $functions{$field}{'max'} == 0 || @$row{$field} > $functions{$field}{'max'}) {$functions{$field}{'max'} = @$row{$field}}
					if (!defined($functions{$field}{'min'}) || $functions{$field}{'min'} == 0 || @$row{$field} < $functions{$field}{'min'}) {$functions{$field}{'min'} = @$row{$field}}

					if (defined($zaxis) && defined(@$row{$zaxis})) {
						push @{$ydata{"$field=@$row{$zaxis}"}}, @$row{$field};

						$functions{"$field=@$row{$zaxis}"}{'rows'}++;
						$functions{"$field=@$row{$zaxis}"}{'sum'} += @$row{$field};
						if (!defined($functions{"$field=@$row{$zaxis}"}{'max'}) || $functions{"$field=@$row{$zaxis}"}{'max'} == 0 || @$row{$field} > $functions{"$field=@$row{$zaxis}"}{'max'}) {$functions{"$field=@$row{$zaxis}"}{'max'} = @$row{$field}}
						if (!defined($functions{"$field=@$row{$zaxis}"}{'min'}) || $functions{"$field=@$row{$zaxis}"}{'min'} == 0 || @$row{$field} < $functions{"$field=@$row{$zaxis}"}{'min'}) {$functions{"$field=@$row{$zaxis}"}{'min'} = @$row{$field}}
					}
				}
			}
		}

		push @ydatasets, \%ydata;

		my $column;
		open SUMMARY, ">> $resultsDir/summary.txt" or die "Cannot open $resultsDir/summary.txt for write: $!\n";
		if ($#databases > 0) {print SUMMARY "Summary $summary:\nField\tMin\tMax\tSum\tRows\tAvg\n"}
		else {print SUMMARY "Summary:\nField\tMin\tMax\tSum\tRows\tAvg\n"}
		foreach $row (sort keys %functions) {
			print SUMMARY "$row\t";
			foreach $column (keys %{$functions{$row}}) {print SUMMARY "$functions{$row}{$column}\t"}
			print SUMMARY $functions{$row}{'sum'}/$functions{$row}{'rows'}, "\n";
		}
		print SUMMARY "\n";
		close SUMMARY;
		$summary++;
	}
	#########################################POST-PROCESSED########################################


	########################################GETTING RESULTS########################################
	use Graphics::GnuplotIF;

	my ($gnuplot, $ydataset, $key, $only, @gnuplots, @titles, %ydata) = (Graphics::GnuplotIF->new, "");

	$gnuplot->gnuplot_cmd("cd \"$resultsDir\"; set terminal png size 1200, 900");
	$gnuplot->gnuplot_set_xlabel("Time ----->");

	foreach $plot (@plots) {
		$gnuplot->gnuplot_cmd("set output \"$plot.png\"");
		$plot =~ s#!#/#g;	# FOR FIELDS CONTAINING '/' IN THEM.

		foreach $field (@yaxes) {
			if ($plot =~ /^$field$|^$field-|-$field-|-$field$/) {
				if($#ydatasets > 0) {$ydataset = 1}

				foreach (@ydatasets) {
					%ydata = %{$_};

					foreach $key (sort keys %ydata) {
						if (defined($zaxis) && $key =~ /$field=/) {
							if (scalar(@only) == 0) {
								push @gnuplots, \@{$ydata{$key}};
								push @titles, "$key$ydataset";
							}
							else {
								foreach $only (@only) {
									if ($key =~ /$only$/) {
										push @gnuplots, \@{$ydata{$key}};
										push @titles, "$key$ydataset";
									}
								}
							}
						}
						elsif (!defined($zaxis) && $key eq $field) {
							push @gnuplots, \@{$ydata{$key}};
							push @titles, "$key$ydataset";
						}
					}

					if($#ydatasets > 0) {$ydataset++}
				}
			}
		}

		$gnuplot->gnuplot_set_plot_titles( @titles );
		$gnuplot->gnuplot_plot_y(@gnuplots);
		@gnuplots = @titles = ();
	}
	##########################################GOT RESULTS##########################################
}
###########################################APPLIED RULES###########################################


1;


#__END__
###########################################DOCUMENTATION###########################################
=head1

=head1 NAME

B<vxperf2>

=head1 SYNOPSIS

  use vxperf2;

  @database = &parseLogFile($logPath);
  &applyRules($rulesFile, $resultsDir, \@database);
  &applyRules($rulesFile2, $resultsDir2, \@database);

  @database1 = &parseLogFile($logPath1);
  @database2 = &parseLogFile($logPath2);
  @database3 = &parseLogFile($logPath3);
  .
  .
  .
  &applyRules($rulesFile, $resultsDir, \@database1, \@database2, \@database3, ...);

=head1 DESCRIPTION

B<vxperf2> is a generic parser to analyze logs that are in a text database format. (e.g. Output generated by various OS monitoring utilities.) Using a rules file with six different keywords, the parser can perform several useful operations on one or more logs. It can summarize (basic functions count, max, min, sum, avg), visualize (plot), navigate (skip data points), zoom in (consider a subset of data points) and compare (within and across logs) any specified subset of fields of interest.

=head1 RULES FILE

Below is an example rules file using all valid keywords. The first word and only the first word of any rule is treated as a keyword.

  # This is a comment and the beginning of the rules file.
  y-axis: columnA columnB columnC
  y-axis: columnD columnE columnF columnG
  z-axis: columnZ
  plot: columnA columnB
  plot: columnC columnE columnG
  only: value1 value2
  only: value3 value4
  offset: n
  points: m
  # End of rules file.

=head1 KEYWORDS

B<vxperf2> accepts six keywords: B<y-axis>, B<z-axis>, B<plot>, B<only>, B<offset>, B<points>. All lines which don't start with a keyword are ignored (comments).

There is no keyword "x-axis" because it is always fixed to the number of rows.

=over 2

=item *

B<y-axis>: A user might be interested in the summaries (count, sum, max, min, avg) related to specific fields, not all of them. Rules starting with B<y-axis> list the fields to be considered for summarizing logs. Using the above example rules file B<vxperf2> will summarize fields columnA, columnB, columnC, columnD, columnE, columnF and columnG.

=item *

B<z-axis>: At times a user is more interested in filtered logs than the whole. e.g. While collecting the output of Unix top (http://www.unixtop.org/), a user might actually be interested only in a few specific processes (specific PIDs or specific process names). The rule starting with B<z-axis> contains the field whose values are treated as another dimension of the fields. Note that there can be only one B<z-axis>. Only the first field in the first rule containing this keyword will be used. If valuez1, valuez2, valuez3 are distinct values of field columnZ then along with columnA, B<vxperf2> will also summarize columnA-valuez1, columnA-valuez2, and columnA-valuez3. And so on for other fields.

=item *

B<plot>: A graph can at times convey more information than a few functions. Rules starting with B<plot> list the fields which are to be plotted on the Y-axis (against the number of rows on the X-axis). All fields listed in one B<plot> rule will be plotted in a single PNG image. A different PNG image will be created for each line starting with B<plot>. B<vxperf2> will plot columnA and columnB in one PNG image titled "columnA-columnB.png", and plot columnC, columnE and columnG in another PNG image titled "columnC-columnE-columnG.png".

=item *

B<only>: Plots often become cluttered with too many different curves, which is even more likely when a B<z-axis> is specified. Rules starting with B<only> list the values of B<z-axis> which are to be plotted, and the remaining values will be discarded. B<vxperf2> will plot columnA-value1, columnA-value2, columnB-value1, columnB-value2 in one PNG image titled "columnA-columnB.png". And so on for other plots.

=item *

B<offset>: The rule starting with B<offset> contains the number of rows of each field from the beginning of a log to be ignored. Note that there can be only one B<offset>. Only the first string in the first rule containing this keyword will be used. If one considers the plots, B<offset> is a way to navigate along them.

=item *

B<points>: The rule starting with B<points> contains the number of data points of each field of a log to be considered. Note that there can be only one B<points>. Only the first string in the first rule containing this keyword will be used. If one considers the plots, B<points> is a way to zoom into them.

=back

=head1 SUBROUTINES

The B<vxperf2> module contains three subroutines: B<equals>, B<parseLogFile> and B<applyRules>.

=over 2

=item *

B<equals> takes the references to two arrays and returns 1 if the arrays are equal (length and values at each index) and 0 if they are not. This subroutine was needed internally for the module and thus implemented and thus exposed. Usage:

  $boolean = &equals(\@array1, \@array2);

=item *

B<parseLogFile> takes the path to a text file, parses it, creates and returns a database (an array of hashes) out of it. Each hash of the array corresponds to a line of the text file. Usage:

  $database = &parseLogFile($logPath);

=item *

B<applyRules> takes the path to a rules file, the path to a results directory, and references to one or more databases (arrays of hashes) created using the afore-mentioned B<parseLogFile> subroutine. It parses the rules file, applies the extracted rules on the databases, writes the summaries into "$resultsDir/summary.txt" and the plots appropriately as PNG images in $resultsDir. Usage:

  &applyRules($rulesFile, $resultsDir, \@database1, \@database2, \@database3, ...);

=back

=head1 DATA STRUCTURES

Apart from the basic Perl data types like integers, strings, arrays and hashes, B<vxperf2> turned out to be a useful exercise in getting acquainted with some basic two-dimensional Perl data structures.

=over 2

=item *

B<@tables> is an array of arrays. Each element is a table name (sequence of fields) which corresponds to a unique header of a text file. Each table name is stored in the form of an array (list of fields).

=item *

B<@database> is an array of hashes. Each element is a row (hash) in one of the tables (fields as hash keys) which corresponds to a line in the text file (hash values).

=item *

B<%ydata> is a hash of arrays. Each element is a list of values corresponding to a field, and is used for plotting the graphs (against the number of rows).

=item *

B<%functions> is a hash of hashes. Each element is a hash (with functions as keys) which corresponds to a field.

=back

=head1 DEPENDENCIES

B<vxperf2> uses the CPAN module B<Graphics::GnuplotIF> (http://search.cpan.org/perldoc?Graphics::GnuplotIF) to plot various graphs, which provides a Perl API to B<gnuplot> (http://sourceforge.net/projects/gnuplot).

B<vxperf2.pl> is a Perl wrapper around B<vxperf2> which can be run from the command-line or called from non-Perl scripts.

B<log2db> which is also shipped with the tarball is not a dependency but a module to modify various standard monitoring logs into text databases, which can then be passed to B<vxperf2>. B<log2db.pl> is a Perl wrapper around B<log2db> which can be run from the command-line or called from non-Perl scripts.

=head1 LIMITATIONS

Data integrity is assumed and never verified.

B<vxperf2> can reliably parse only files in a text database format. The format has a simple syntax: any line following one or more blank lines is considered a header (sequence of fields) of a table. All subsequent lines are considered rows of that table. Each field or value in any line is a "word" separated from other field(s) with whitespace.

Plotting is made assuming uniform intervals between any two rows of a certain field.

=head1 WISHLIST

=over 2

=item *

Multiple rules with the keyword B<only>.

=item *

More functions to summarize data.

=item *

Arithmetic expressions on y-axes, on z-values.

=item *

More options for plotting.

=item *

Detect correlation patterns between fields (y-axes).

=item *

Plotting against custom x-axes.

=back

=head1 AUTHOR

B<Sravan Bhamidipati> (Sravan_Bhamidipati@symantec.com, bsravanin@gmail.com)

=head1 CREDITS

Dhrubojyoti Biswas contributed to the design discussions. Shrinivas Chandukar contributed various ideas through the original vxperf (written mostly using Awk).

=head1 LICENSE AND COPYRIGHT

GNU GPL: http://www.gnu.org/copyleft/gpl.html

=head1 LAST UPDATED

1st June, 2011

=cut
