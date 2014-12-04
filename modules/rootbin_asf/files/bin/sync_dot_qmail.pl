#!/usr/bin/perl
#
use strict;
use warnings FATAL => "all";

opendir my $apmail_home, "/home/apmail"
    or die "Can't opendir /home/apmail: $!";
open my $dot_qmail, ">", "/home/smtpd/dot-qmail"
    or die "Can't open /home/smtpd/dot-qmail: $!";

select($dot_qmail);
$\="\n";

while (defined($_ = readdir $apmail_home)) {
    s/^\.qmail-// and print lc;
}

closedir $apmail_home or die "Can't closedir /home/apmail: $!";
close $dot_qmail or die "Can't close /home/smtpd/dot-qmail: $!";

for my $host (qw/nike athena/) {
    system("/usr/local/bin/rsync  -e 'ssh -o \"BatchMode yes\"'  --rsync-path=/usr/local/bin/rsync -t /home/smtpd/dot-qmail smtpd\@$host.apache.org:/home/smtpd/dot-qmail 2>/dev/null >/dev/null") == 0
	or warn "rsync to $host had an error: $?";
}

exit 0;
