#!/usr/bin/env perl

# Copyright 1999-2005 The Apache Software Foundation or its licensors, as
# applicable.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;

######################################################################
## Configurations Options...
######################################################################

# testAddr - where to email test emails in debug mode
my $testAddr = "Jim Jagielski <jim\@apache.org>";

# admin - person to email in case of trouble running the script.
my $admin = "ASF Operations <operations\@apache.org>";

# fromAddr - the name that should be used as a "From" line when sending emails.
my $fromAddr = "Marvin <no-reply\@apache.org>";

# boardAddr - ASF board email address (mailing list board@)
#             NB it should be in a form that can be supplied as a To: line
#             NB remember to add backslash before '@'!
my $boardAddr     = "ASF Board <board\@apache.org>";
my $chairAddr     = "ASF Chairman <chairman\@apache.org>";
my $incAddr       = "ASF Incubator PMC <private\@incubator.apache.org>";
my $membersAddr   = "ASF Members <members\@apache.org>";

##./svnlook cat /x1/svn/repos-private committers/board/committee-info.txt
## my $svnRepoURL = 'https://svn.apache.org/repos/private';
my $svnRepoURL  = 'file:////x1/svn/repos/private';
my $svnRepoPath = '/x1/svn/repos/private';

my @svnFiles = ( 'committers/board/committee-info.txt',
                 'committers/board/calendar.txt' );

# Worldclock URLs, reg and shorten
my $timeDateURL = "http://www.timeanddate.com/worldclock/fixedtime.html?iso=%4d%02d%02dT%s&msg=ASF+Board+Meeting";
my $timeDateShorten = "http://www.timeanddate.com/createshort.html?url=/worldclock/fixedtime.html?iso=%4d%02d%02dT%s&msg=ASF+Board+Meeting&confirm=1";

# initialDate - prior to this day of the month we will send the 'initial' reports,
#               after it we'll send the 'final' reminders.
my $finalDate = 5;

# templates - the files to use as templates.
my %templates = (
    'initial' => 'reminder1.txt',
    'final'   => 'reminder2.txt'
);

my %inctemplates = (
    'ipmc'    => 'ipmc_reminder.txt',
    'ppmc'    => 'ppmc_reminder.txt',
    'members' => 'members_reminder.txt'
);
my $incReportURL = 'http://incubator.apache.org/report_due_ROTATION.txt';

# DEBUG - script will print out information on what's going
#         on to stdout and will also not send out emails to people
#         apart from the admins.
my $DEBUG = 0;

######################################################################
## Don't edit below this line!
######################################################################

# Packages we need that are builtin Perl packages
use File::Basename;
use File::Copy;
use File::Spec::Functions;
use Cwd qw(realpath);
use FindBin;

use lib 'CPAN';

# Extra packages that we provide
use File::Slurp;
use Date::Manip;
use LWP::Simple;

# Globals

my @appList = (
    [ 'svn',      '/usr/bin/svn' ],
    [ 'sendmail', '/usr/sbin/sendmail' ],
    [ 'sudo',     '/usr/bin/sudo' ],
    [ 'svnlook',  '/usr/bin/svnlook' ],
    [ 'curl',     '/usr/bin/curl' ],
    [ 'wget',     '/usr/bin/wget' ],
);

my (%apps, %pmcs, %reports);
my ($infoFn, $runDay, $wday, $monnum, $monabbr, $monname, $year, $mtgDate, $mtgDay, $dueDate, $incDueDate, $runDate, $tdURL);
my $basedir = realpath(dirname($0));
my $getFunc = \&getRemoteFiles;
my $sendEmail = 1;
my $makeCal = 0;
my $noFetch = 0;
my $keepFiles = 0;
my $isCron = 0;
my $doReports = 1;
my $cronDay = 1;   # default is Mon
my @daysOWeek = qw( Sun Mon Tues Weds Thurs Fri Sat );
my $justMembers = 0;
my (@meetingDates, %pmcReports);
my $calDir = $basedir;
my @prezReports = (
    'Infrastructure',
    'Fundraising',
    'Marketing and Publicity',
    'Brand Management',
    'Executive Assistant'
);

# Arguments?
for my $i (0 .. $#ARGV) {
    my $a = $ARGV[$i];
    next if ($a !~ /^-/);
    if ($a =~ /^--([\d]+)$/) {
        $cronDay = $1 % 7;
        $isCron = 1;
    }
    $DEBUG = 1 if $a =~ /debug/;
    $getFunc = \&getLocalFiles if $a =~ /local/;
    $getFunc = \&getRemoteFiles if $a =~ /remote/;
#    $makeCal = 1 if $a =~ /calend/;
    $sendEmail = 0 if $a =~ /no-email/;
    $noFetch = 1 if $a =~ /no-fetch/;
    $calDir = $ARGV[$i + 1] if $a =~ /cal-dir/;
    $keepFiles = 1 if $a =~ /save-file/;
    usage() if $a =~ /help/;
    $justMembers = 1 if $a =~ /just-mems/;
    $isCron = 1 if $a =~ /cron/;
}

# Script start
getNowDateInformation();
sendMail($testAddr, $fromAddr, "Marvin run on $runDate");

# If we are in cron-mode and we're not the 1st or last cronday,
# skip sending the PMC and Inc reports
if ($isCron &&
    !($wday == $cronDay && ($runDay <= 7 || $runDay >= (lastDay()-6)))) {
        $doReports = 0;
}

fixupConfig();
&$getFunc();
findMeetingDate();

if ($DEBUG + $sendEmail + $makeCal == 0) {
    print "Nothing to do! Exiting\n";
    sendMail($testAddr, $fromAddr, "Marvin has NULL");
    exit;
}

if (meetingDatePassed()) {
    getNextMonthInformation();
    findMeetingDate();
}
readPMCList($infoFn);
readReports($infoFn);
showActions();
if ($sendEmail || $DEBUG) {
    # If in cron-mode, send out members reminder the week before the meeting only
    sendMembersReminder() unless ($isCron && (($runDay > $mtgDay) || ($mtgDay - $runDay > 7)));
    sendMail($testAddr, $fromAddr, "Marvin reminded members");
    if (!$justMembers && $doReports) {
        sendReports($templates{'initial'}) if $runDay < $finalDate;
        sendReports($templates{'final'}) if $runDay >= $finalDate;
        sendIncReports();
        sendMail($chairAddr, $fromAddr,
                 "[REMINDER] Create Board Agenda",
                 "If you haven't already, create the board agenda!");
        sendMail($testAddr, $fromAddr, "Marvin sent reminders");

    }
}

if ($makeCal) {
    makeCalendar(catfile($calDir, 'board_cal.ics'),
                 catfile($calDir, 'board_cal.rdf'));
}

##createAgenda() if $runDay < $finalDate;
cleanFiles() unless $keepFiles;
sendMail($testAddr, $fromAddr, "Marvin run completed");
## End!


# Functions used by the script...
sub usage
{
    print <<EOT;
$0: usage
    --debug      enable debug output
    --local      use 'svnlook' & sudo to get files from local SVN repository
                 Path: $svnRepoPath
    --remote     use 'svn' to get files from remote source [DEFAULT]
                 URL: $svnRepoURL
    --calendar   create calendar output file
    --no-email   don't send emails
    --no-fetch   don't fetch SVN files
    --save-files preserve files retrieved from SVN
    --cron       only run if the 1st or last day Monday of the month
    --#          Enable cron-mode for day # (0 = Sunday, etc...)
    --just-mems  just send members reminder email
    --help       print this message

EOT
    exit(1);
}

sub showActions
{
    print "Starting processing now. Options in use:\n\n";
    printf("\t%-30s: %s\n", 'Run date', $runDate);
    printf("\t%-30s: %d %s %d\n", 'Detected date', $runDay, $monabbr, $year);
    printf("\t%-30s: %s\n", 'Processing type',
           ($runDay < $finalDate ? 'initial' : 'final'));
    if ($noFetch) {
        printf("\t%-30s: %s\n", 'Data files', 'use existing files');
    }
    printf("\t%-30s: %s\n", 'Data file location',
           ($getFunc == \&getLocalFiles ? 'locally' : 'remotely'));
    printf("\t%-30s: %s\n", 'Cron mode',
           ($isCron == 1 ? 'yes' : 'no'));
    printf("\t%-30s: %s\n", 'Cron day',
           $daysOWeek[$cronDay]) if $isCron == 1;
    printf("\t%-30s: %s\n", 'Send reminder emails',
           ($sendEmail == 1 ? 'yes' : 'no'));
    printf("\t%-30s: %s\n", 'Just members reminder',
           ($justMembers == 1 ? 'yes' : 'no'));
    printf("\t%-30s: %s\n", 'Create vCal file',
           ($makeCal == 1 ? 'yes' : 'no'));
    printf("\t%-30s: enabled\n", 'Debugging') if $DEBUG;
    printf("\t%-30s: %s\n", 'Due Date', $dueDate);
    printf("\t%-30s: %s\n", 'Meeting Date', $mtgDate);
    printf("\t%-30s: %s\n", 'TimeDate URL', $tdURL);

    print "\n";
}

sub fixupConfig
{
    # Start by finding any applications we'll need. If we fail at this point
    # we can't report it, so just print an error to stdout and exit.
    # Once this is complete we can use reportError().
    my $seen_error = 0;
    foreach my $arrp (@appList) {
        my $app = findApp($arrp->[0]);
        if ($app eq '') {
            if ($arrp->[1]) {
                print "Using default location for '$arrp->[0]'\n";
                $app = $arrp->[1];
            } else {
                print "Failed to find '$arrp->[0]' which is required!\n";
                $seen_error = 1;
            }
        }
        $apps{$arrp->[0]} = $app;
    }

    # Can we find the template files we'll need?
    foreach my $t (keys(%templates)) {
        my $tfn = catfile($basedir, $templates{$t});
        if (! -f $tfn) {
            reportError("Template '$templates{$t}' used for $t ".
                        "reports doesn't exist!");
            $seen_error = 1;
        }
        $templates{$t} = $tfn;
    }
    # Can we find the template files we'll need?
    foreach my $t (keys(%inctemplates)) {
        my $tfn = catfile($basedir, $inctemplates{$t});
        if (! -f $tfn) {
            reportError("Template '$inctemplates{$t}' used for $t ".
                        "reports doesn't exist!");
            $seen_error = 1;
        }
        $inctemplates{$t} = $tfn;
    }
    exit(1) if $seen_error;
}

sub findApp
{
    my $app = shift;
    my $loc = `which $app`;
    chomp($loc);
    if ($loc eq '') {
        my $ckpath = catfile($basedir, $app);
        $loc = $ckpath if -f $ckpath;
    }

    return $loc;
}

sub sendMail
{
    my ($to, $from, $subj, $msg) = @_;
    if ($DEBUG) {
        print "To:      $to\n";
        print "From:    $from\n";
        print "Subject: $subj\n";
        print "\n";
        print $msg;
        print "\n---------------------------------\n";
    }
    return unless $sendEmail;
    return if $DEBUG && !$testAddr;
    open(MAIL, "| $apps{sendmail} -t") || return;
    print MAIL "To: $to\n" unless $DEBUG;
    print MAIL "To: $testAddr\n" if $DEBUG;
    print MAIL "From: $from\n";
    print MAIL "Subject: " unless $subj =~ /^Subject:/;
    print MAIL "$subj\n\n";
    print MAIL $msg;
    close(MAIL);
    print "sendMail done\n" if $DEBUG;
}

sub reportError
{
    my $msg = shift;
    print 'ERROR: '.$msg;
    print "\n" unless $msg =~ /\n$/;
    return unless -x $apps{sendmail};
    if ($admin && ! $DEBUG) {
        sendMail($admin, $fromAddr, "Error while executing reminders.pl",
                 $msg);
        sendMail($testAddr, $fromAddr, "Error while executing reminders.pl",
                 $msg);
    }
}

sub getRemoteFiles
{
    print "Getting files from remote repository [$svnRepoURL]:\n";
    for my $i (0 .. $#svnFiles) {
        my $outputFN = catfile($basedir, basename($svnFiles[$i]));
        if ($noFetch && -f $outputFN) {
            print "\tUsing existing ".basename($svnFiles[$i])."\n";
            next;
        }
        my $cmd = "$apps{svn} cat $svnRepoURL/$svnFiles[$i]";
        `$cmd > $outputFN`;
        if ($? && !$DEBUG) {
            sendMail($testAddr, $fromAddr, "Failed to get $svnFiles[$i] from SVN");
            die "Failed to get $svnFiles[$i] from SVN\n$!";
        }
    }
    print "\tOK\n";
}

sub getLocalFiles
{
    print "Getting files from local store:\n";
    for my $i (0 .. $#svnFiles) {
        my $outputFN = catfile($basedir, basename($svnFiles[$i]));
        if ($noFetch && -f $outputFN) {
            print "\tUsing existing ".basename($svnFiles[$i])."\n";
            next;
        }
        my $cmd = "$apps{sudo} -u nobody $apps{svnlook} ".
                  "cat $svnRepoPath $svnFiles[$i]";
        `$cmd > $outputFN`;
        if ($? && !$DEBUG) {
            sendMail($testAddr, $fromAddr, "Failed to get $svnFiles[$i] from SVN");
            die "Failed to get $svnFiles[$i] from SVN\n$!";
        }
    }
    print "\tOK\n";
}

sub cleanFiles
{
    if ($noFetch) {
        print "Saving existing data files\n";
        return;
    }
    for my $i (0 .. $#svnFiles) {
        my $outputFN = catfile($basedir, basename($svnFiles[$i]));
        unlink($outputFN) if -f $outputFN;
    }
}

sub lastDay {
    my @monthDays= qw( 31 28 31 30 31 30 31 31 30 31 30 31 );
    return 29 if $monnum == 1 and $year % 4 == 0 && $year % 100 == 0 || $year % 400 == 0;
    return $monthDays[$monnum];
}

sub getNowDateInformation
{
    my @info = gmtime();
    my @full = qw( January February March April May June July August September October November December );
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    $runDay = $info[3];
    $wday = $info[6];
    $monnum = $info[4];
    $monabbr = $abbr[$monnum];
    $monname = $full[$monnum];
    $year = $info[5] + 1900;
    $runDate = "$runDay $monabbr $year";
}

sub getNextMonthInformation
{
    my @full = qw( January February March April May June July August September October November December );
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    # You would think the below would work; it doesn't
    # my $nextmo = DateCalc("1 $monabbr, $year", "next month");
    #
    $monnum += 1;
    if ($monnum > 11) {
        $monnum = 0;
        $year += 1;
    }
    $runDay = 1;
    $monabbr = $abbr[$monnum];
    $monname = $full[$monnum];
}

sub readPMCList
{
    my $fn = catfile($basedir, basename($svnFiles[0]));
    die "Unable to open '$fn' for reading...\n" unless -f $fn;
    my @lines = read_file($fn);
    my $tabp = 0;
    my $start = 0;
    foreach my $l (@lines) {
        last if $l =~ /^2\. /;
        $start = 1 if $l =~ /^1\. /;
        next if $start == 0;
        next unless $l =~ /^    /;
        chomp($l);

        if ($l =~ /^    ---/) {
            $tabp = length($l);
            while (substr($l, $tabp, 1) ne ' ') {
                $tabp--;
            }
            next;
        }

        next if $l =~ /^    NAME/;
        my $pmc = substr($l, 0, $tabp);
        my $name = substr($l, $tabp);
        $pmc =~ s/^\s*//;
        $pmc =~ s/\s*$//;
        $name =~ s/^\s*//;
        print "PMC: $pmc => $name\n" if $DEBUG;
        push(@{$pmcs{lc $pmc}{emails}}, $name );
    }
}

sub findMeetingDate
{
    #
    # Date format looks like:
    #    Wed, 16 November 2011, 10 am Pacific
    #
    #
    my $fn = catfile($basedir, basename($svnFiles[1]));
    my @lines = read_file($fn);
    my $tdTime = "1730";
    $mtgDate = "";
    # Look for date in calendar file
    foreach my $l (@lines) {
        next unless $l =~ /\*\)/;
        $l =~ s/\s+\*\) |\n//g;
        $l = $1 if $l =~ /(.*)\s+\(.*/;

        if ($l =~ /\s+$monabbr/ && $l =~ /\s+$year/) {
            $mtgDate = $l;
            last;
        }
    }
    # if not found, generate as 3rd Wednesday of the month
    if (!$mtgDate) {
        my @dates = ParseRecur("0:1*3:3:0:0:0","","Jan 1 ".$year, "Dec 31 ".$year);
        $mtgDate = UnixDate(ParseDate($dates[$monnum]), "%a, %e %B %Y") . ", 10:30 am Pacific";
    }
    # Assume we are PST
    $mtgDate =~ s/Pacific/PST/;
    # Now check if that date is PST or PDT. Get secs from epoch and check localtime
    my $secs = UnixDate(ParseDate($mtgDate), "%s");
    my @ll = localtime($secs);
    $mtgDay = $ll[3];
    if ($ll[8] == 1) {
       $mtgDate =~ s/PST/PDT/;
       $tdTime = "1830";
    }
    my $foo = DateCalc($mtgDate, "1 week ago");
    $dueDate = UnixDate(ParseDate($foo), "%a, %b %E");
    $foo = DateCalc($mtgDate, "2 weeks ago");
    $incDueDate = UnixDate(ParseDate($foo), "%a, %b %E");
    print "Meeting date this month: $mtgDate\n";
    push(@meetingDates, $secs) if $makeCal;
    $tdURL = sprintf($timeDateURL, $ll[5]+1900, $ll[4]+1, $ll[3], $tdTime);
    my $shorten = get(sprintf($timeDateShorten, $ll[5]+1900, $ll[4]+1, $ll[3], $tdTime));
    if ($shorten) {
        $shorten =~ m/id=selectable>([^<]*)</;
        $tdURL = $1 if $1;
    }
}

sub meetingDatePassed
{
    my $now = ParseDate("now");
    my $then = ParseDate($mtgDate);
    return 1 if Date_Cmp($now, $mtgDate) == 1;
    return 0;
}

sub readReports
{
    my $fn = catfile($basedir, basename($svnFiles[0]));
    die "Couldn't read '$fn'...\n" unless -f $fn;
    my @lines = read_file($fn);
    my @months;
    my $active = 0;
    my $start = 0;

    foreach my $l (@lines) {
        # We only parse section 2.xxx
        $start = 1 if $l =~ /^2\. /;
        last if $l =~ /^3\. /;

        # skip lines until we get to the correct section and we have
        # a line that is of interest
        next if ($start == 0 || $l =~ /^---|^\n|^====/);

        chomp($l);
        if ($l =~ /^[a-zA-Z]*, [a-zA-Z]*, [a-zA-Z]*, [a-zA-Z]*/) {
            @months = $l =~ /^(.*), (.*), (.*), (.*)/;
            next;
        }

        if ($l =~ /^Next month/) {
            @months = ($monabbr);
            next;
        }

        next unless $l =~ /^    (.*)/;

        my $project = $1;
        $project =~ s/ *#.*$//;

        foreach my $m (@months) {
            my $month = substr($m, 0, 3);
            print "MONTH: $month => $project\n" if $DEBUG;
            $pmcReports{$month}{$project}++;
        }
    }
}

sub sendReports
{
    my $templFn = shift;
    my ($subject, $body);
    my $actions = "I have just sent the following report reminders:\n\n";

    reportError("Template '$templFn' does not exist - no reports sent!")
          unless -f $templFn;

    my @lines = read_file($templFn);
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^Subject:/) {
            $subject = $lines[$i];
            next;
        }
        next if $lines[$i] =~ /^\#/;
        $body .= $lines[$i];
    }

    $subject =~ s/\[month\]/$monabbr/g;
    $subject =~ s/\[year\]/$year/g;
    $subject =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[dueDate\]/$dueDate/g;

    if (! $pmcReports{$monabbr}) {
        print "Didn't find any PMC's who need to submit a report for ".
              "month '$monabbr'\n";
        return;
    }

    my %reports = %{$pmcReports{$monabbr}};
    foreach my $k (sort(keys(%reports))) {
        my $pmclist .= "\t - $k\n";
        if ($pmcs{lc $k}) {
            my @emails = @{$pmcs{lc $k}{emails}};
            foreach my $e (@emails) {
                my ($whoTo, $mybody);
                if (grep { /\b$k/i }  @prezReports) {
                    $whoTo = 'operations@apache.org';
                } else {
                    $whoTo = 'board@apache.org';
                }
                $mybody = $body;
                $mybody =~ s/\[whoTo\]/$whoTo/g;

                print "Reminder sent to $e for project $k : $whoTo\n";
                $actions .= sprintf("\t - %-30s to %s\n", $k, $e);
                sendMail($e, $boardAddr, $subject, $mybody.$pmclist);
            }
        } else {
            sendMail($boardAddr, $fromAddr, "Missing Chairperson",
                     "Unable to find a chair person for committee '$k'");
            $actions .= "\t - $k *** NO EMAIL ADDRESS FOUND ***\n";
        }
    }
    sendMail($boardAddr, $fromAddr, "Report Reminders sent for $monabbr $year",
             $actions);
}

sub sendIncReports
{
    my $templFn = $inctemplates{'ppmc'};
    my ($subject, $body);

    reportError("Template '$templFn' does not exist - no reports sent!")
          unless -f $templFn;

    my @lines = read_file($templFn);
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^Subject:/) {
            $subject = $lines[$i];
            next;
        }
        next if $lines[$i] =~ /^\#/;
        $body .= $lines[$i];
    }

    $subject =~ s/\[month\]/$monabbr/g;
    $subject =~ s/\[year\]/$year/g;
    $body =~ s/\[month\]/$monname/g;
    $body =~ s/\[year\]/$year/g;
    $body =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[dueDate\]/$dueDate/g;
    $body =~ s/\[incDueDate\]/$incDueDate/g;

    my $rotation = ($monnum) %3+1;
    $incReportURL =~ s/ROTATION/$rotation/;
    my @ppmcs = `$apps{curl} -s $incReportURL`;
    my $ppmclist = "";
    foreach my $p (@ppmcs) {
        my $nsub = $subject;
        if ($p =~ /"(.*)".*<(.*incubator.apache.org)>/) {
            my $a = $1;
            my $b = $2;
            $nsub =~ s/\[ppmc\]/$a/g;
            sendMail($b, $fromAddr, $subject, $body);
            $ppmclist .= "\t$a\t<$b>\n";
        }
    }

    $templFn = $inctemplates{'ipmc'};
    $subject = "";
    $body = "";
    reportError("Template '$templFn' does not exist - no reports sent!")
          unless -f $templFn;

    @lines = read_file($templFn);
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^Subject:/) {
            $subject = $lines[$i];
            next;
        }
        next if $lines[$i] =~ /^\#/;
        $body .= $lines[$i];
    }
    $subject =~ s/\[month\]/$monabbr/g;
    $subject =~ s/\[year\]/$year/g;
    $body =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[dueDate\]/$dueDate/g;
    $body =~ s/\[incDueDate\]/$incDueDate/g;
    sendMail($incAddr, $fromAddr, $subject, $body.$ppmclist);
}

sub sendMembersReminder
{
    my $templFn = $inctemplates{'members'};
    my ($subject, $body);

    reportError("Template '$templFn' does not exist - no reports sent!")
          unless -f $templFn;

    my @lines = read_file($templFn);
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^Subject:/) {
            $subject = $lines[$i];
            next;
        }
        next if $lines[$i] =~ /^\#/;
        $body .= $lines[$i];
    }
    $subject =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[meetingDate\]/$mtgDate/g;
    $body =~ s/\[tdUrl\]/$tdURL/g;
    sendMail($membersAddr, $fromAddr, $subject, $body);
}

##########
# UNTESTED
##########
sub makeCalendar
{
    my ($icsFn, $rdfFn) = @_;
    print "Trying to create ICS calendar '$icsFn'\n";
    print "Trying to create RDF calendar '$rdfFn'\n";

    open(my $icsFh, ">$icsFn");
    open(my $rdfFh, ">$rdfFn");

    my $today = ParseDate('today');
    print $icsFh <<EOT;
BEGIN:VCALENDAR
PRODID:-//Apache Software Foundation//NONSGML Board Meetings Reminder Script//EN
VERSION:2.0
EOT
    print $rdfFh <<EOT;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF xml:lang="en"
         xmlns="http://www.w3.org/2002/12/cal/ical#"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <version>2.0</version>
  <Vtimezone>
    <tzid>PST</tzid>
    <standard rdf:parseType="Resource">
      <dtstart rdf:parseType="Resource">
        <dateTime>1970-01-01T00:00:00</dateTime>
      </dtstart>
      <tzoffsetfrom>+0800</tzoffsetfrom>
      <tzoffsetto>+0800</tzoffsetto>
    </standard>
  </Vtimezone>
EOT
    foreach my $d (@meetingDates) {
        my $m = UnixDate($d, "%B");
        my $utc = UnixDate(Date_ConvTZ($d, '', 'UTC'), "%G%m%dT%H%M%SZ");
        my $pst = UnixDate(Date_ConvTZ($d, '', 'PST'), "%G%m%dT%H%M%S");
        my $stat = ($m =~ /$monabbr/ ? "CONFIRMED" : "TENTATIVE");
        my $desc = "Reports due from the following projects:\\n";
        my %reports = %{$pmcReports{substr(UnixDate($d, "%B"), 0, 3)}};
        foreach my $k (sort(keys(%reports))) {
            $desc .= "  $k\\n";
        }

        print $icsFh <<EOT;
BEGIN:VEVENT
DTSTART:$utc
DTSTART;TZID=US-Pacific:$pst
SUMMARY:$m Board Meeting
STATUS:$stat
DESCRIPTION:$desc
END:VEVENT
EOT
        $utc = UnixDate(Date_ConvTZ($d, '', 'UTC'), "%G-%m-%dT%H:%M:%SZ");
        $pst = UnixDate(Date_ConvTZ($d, '', 'PST'), "%G-%m-%dT%H:%M:%S");

        print $rdfFh <<EOT;
  <Vevent>
    <summary>$m Board Meeting</summary>
    <dtstart>$utc</dtstart>
    <duration>PT2H</duration>
    <status>$stat</status>
    <description>$desc</description>
  </Vevent>
EOT
    }

    print $icsFh "END:VCALENDAR\n";
    close($icsFh);
    print $rdfFh "</rdf:RDF>\n";
    close($rdfFh);
}

