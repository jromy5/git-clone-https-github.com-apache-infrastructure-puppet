#!/usr/bin/perl -pl

# http://www.kluge.net/~felicity/random/split-procmail-from.txt
# (with some mods by Roy)

# Splits a single from (log) file into seperate YYYYMM files.
# It turns out that this will split mbox formatted files as well.

# WARNING: To run this on an existing YYYYMM file, move the
#          source file to a new name FIRST

BEGIN { %months = map { $_ => sprintf "%02d",++$i } qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/ };

if ( /^From / ) {
	my($month,$y) = /(\w+)\s+\d+\s+\S+\s+(\d+)$/;
	next if ( $lm eq $month );
	$lm = $month;
	my($m) = $months{$month};
	close(OUT);
	open(OUT, ">>$y$m") || die "Can't open new file!  $y$m\n";
	select(OUT);
	print STDERR "Writing $y$m";
}
