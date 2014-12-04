#!/usr/bin/perl -w
#
# $Id: arc_summary.pl 172 2010-02-16 04:12:50Z jhell $
#
# Copyright (c) 2008, Ben Rockwood (benr@cuddletech.com)
# Modifications Copyright (c) 2010, jhell <jhell@dataix.net>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

use strict;

my $Kstat;

my @k = `sysctl 'kstat.zfs.misc.arcstats'`;

foreach my $k (@k) {
  chomp $k;
  my ($name,$value) = split /:/, $k;
  my @z = split /\./, $name;
  my $n = pop @z;
  ${Kstat}->{zfs}->{0}->{arcstats}->{$n} = $value;
}

### System Memory ###
my $phys_pages = ${Kstat}->{unix}->{0}->{system_pages}->{physmem};
my $free_pages = ${Kstat}->{unix}->{0}->{system_pages}->{freemem};
my $pagesize = `sysctl -n 'hw.pagesize'`;
my $phys_memory = `sysctl -n 'hw.physmem'`;
print "---------------------------------------------------------------------";
print "\nSystem Summary\n";
my $unamev = `uname -v |sed 's/@.*//' |xargs`;
my $unamem = `uname -m`;
my $unamep = `uname -p`;
my $osreldate = `sysctl -n kern.osreldate`;
my $zpl = `sysctl -n vfs.zfs.version.zpl`;
my $spa = `sysctl -n vfs.zfs.version.spa`;
my $ktext = `kldstat | awk \'BEGIN {print "16i 0";} NR>1 {print toupper(\$4) "+"} END {print "p"}\' | dc`;
my $text = ( $ktext / 1 );
my $kdata = `vmstat -m | sed -Ee '1s/.*/0/;s/.* ([0-9]+)K.*/\\1+/;\$s/\$/1024*p/' | dc`;
my $data = ( $kdata / 1 );
my $kmem = ( $text + $data );
my $throttle = ${Kstat}->{zfs}->{0}->{arcstats}->{memory_throttle_count};
print "OS Release Date:\t\t\t\t$osreldate";
print "Hardware Platform:\t\t\t\t$unamem";
print "Processor Architecture:\t\t\t\t$unamep";
print "Storage pool Version:\t\t\t\t$spa";
print "Filesystem Version:\t\t\t\t$zpl";
print "\nKernel Memory Usage\n";
printf("TEXT:\t\t\t\t$text KiB,\t%d MiB\n", $text / 1048576 );
printf("DATA:\t\t\t\t$data KiB,\t%d MiB\n", $data / 1048576 );
printf("TOTAL:\t\t\t\t$kmem KiB,\t%d MiB\n", $kmem / 1048576 );
print "\n$unamev";
print "---------------------------------------------------------------------\n";
print "\nZFS ARC Summary Report\n\n";
print "System Memory:\n";
printf("\tPhysical RAM:\t\t\t\t%d MiB\n", $phys_memory / 1048576 );
printf("\tThrottle Count:\t\t\t\t%d\n", $throttle );
print "\n";

#### ARC Sizing ###############
my $mru_size = ${Kstat}->{zfs}->{0}->{arcstats}->{p};
my $target_size = ${Kstat}->{zfs}->{0}->{arcstats}->{c};
my $arc_min_size = ${Kstat}->{zfs}->{0}->{arcstats}->{c_min};
my $arc_max_size = ${Kstat}->{zfs}->{0}->{arcstats}->{c_max};

my $arc_size = ${Kstat}->{zfs}->{0}->{arcstats}->{size};
my $mfu_size = ${target_size} - $mru_size;
my $mru_perc = 100*($mru_size / $target_size);
my $mfu_perc = 100*($mfu_size / $target_size);

print "ARC Size:\n";
printf("\tCurrent Size:\t\t\t\t%d MiB (arcsize)\n", $arc_size / 1048576 );
printf("\tTarget Size (Adaptive):\t\t\t%d MiB (c)\n", $target_size / 1048576 );
printf("\tMin Size (Hard Limit):\t\t\t%d MiB (arc_min)\n", $arc_min_size / 1048576 );
printf("\tMax Size (Hard Limit):\t\t\t%d MiB (arc_max)\n", $arc_max_size / 1048576 );

print "\nARC Size Breakdown:\n";

printf("\tRecently Used Cache Size:\t%2d%%\t%d MiB (p)\n", $mru_perc, $mru_size / 1048576 );
printf("\tFrequently Used Cache Size:\t%2d%%\t%d MiB (c-p)\n", $mfu_perc, $mfu_size / 1048576 );
print "\n";
        
####### ARC Efficency #########################
my $arc_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{hits};
my $arc_misses = ${Kstat}->{zfs}->{0}->{arcstats}->{misses};
my $arc_accesses_total = ($arc_hits + $arc_misses);

my $arc_hit_perc = 100*($arc_hits / $arc_accesses_total);
my $arc_miss_perc = 100*($arc_misses / $arc_accesses_total);

my $mfu_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{mfu_hits};
my $mru_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{mru_hits};
my $mfu_ghost_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{mfu_ghost_hits};
my $mru_ghost_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{mru_ghost_hits};
my $anon_hits = $arc_hits - ($mfu_hits + $mru_hits + $mfu_ghost_hits + $mru_ghost_hits);

my $real_hits = ($mfu_hits + $mru_hits);
my $real_hits_perc = 100*($real_hits / $arc_accesses_total);

### These should be based on TOTAL HITS ($arc_hits)
my $anon_hits_perc = 100*($anon_hits / $arc_hits);
my $mfu_hits_perc = 100*($mfu_hits / $arc_hits);
my $mru_hits_perc = 100*($mru_hits / $arc_hits);
my $mfu_ghost_hits_perc = 100*($mfu_ghost_hits / $arc_hits);
my $mru_ghost_hits_perc = 100*($mru_ghost_hits / $arc_hits);

my $demand_data_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{demand_data_hits};
my $demand_metadata_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{demand_metadata_hits};
my $prefetch_data_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{prefetch_data_hits};
my $prefetch_metadata_hits = ${Kstat}->{zfs}->{0}->{arcstats}->{prefetch_metadata_hits};

my $demand_data_hits_perc = 100*($demand_data_hits / $arc_hits);
my $demand_metadata_hits_perc = 100*($demand_metadata_hits / $arc_hits);
my $prefetch_data_hits_perc = 100*($prefetch_data_hits / $arc_hits);
my $prefetch_metadata_hits_perc = 100*($prefetch_metadata_hits / $arc_hits);


my $demand_data_misses = ${Kstat}->{zfs}->{0}->{arcstats}->{demand_data_misses};
my $demand_metadata_misses = ${Kstat}->{zfs}->{0}->{arcstats}->{demand_metadata_misses};
my $prefetch_data_misses = ${Kstat}->{zfs}->{0}->{arcstats}->{prefetch_data_misses};
my $prefetch_metadata_misses = ${Kstat}->{zfs}->{0}->{arcstats}->{prefetch_metadata_misses};

my $demand_data_misses_perc = 100*($demand_data_misses / $arc_misses);
my $demand_metadata_misses_perc = 100*($demand_metadata_misses / $arc_misses);
my $prefetch_data_misses_perc = 100*($prefetch_data_misses / $arc_misses);
my $prefetch_metadata_misses_perc = 100*($prefetch_metadata_misses / $arc_misses);

my $prefetch_data_total = ($prefetch_data_hits + $prefetch_data_misses);
my $prefetch_data_perc = "00";
if ($prefetch_data_total > 0 ) {
        $prefetch_data_perc = 100*($prefetch_data_hits / $prefetch_data_total);
}

my $demand_data_total = ($demand_data_hits + $demand_data_misses);
my $demand_data_perc = 100*($demand_data_hits / $demand_data_total);

print "ARC Efficiency:\n";
printf("\tCache Access Total:\t\t\t%d\n", $arc_accesses_total);
printf("\tCache Hit Ratio:\t\t%2d%%\t%d\n", $arc_hit_perc, $arc_hits);
printf("\tCache Miss Ratio:\t\t%2d%%\t%d\n", $arc_miss_perc, $arc_misses);
printf("\tActual Hit Ratio:\t\t%2d%%\t%d\n", $real_hits_perc, $real_hits);
print "\n";
printf("\tData Demand Efficiency:\t\t%2d%%\n", $demand_data_perc);
if ($prefetch_data_total == 0){ 
        printf("\tData Prefetch Efficiency:\tDISABLED (zfs_prefetch_disable)\n");
} else {
        printf("\tData Prefetch Efficiency:\t%2d%%\n", $prefetch_data_perc);
}
print "\n";

print "\tCACHE HITS BY CACHE LIST:\n";
if ( $anon_hits < 1 ){
        printf("\t  Anonymous:\t\t\t--%%\tCounter Rolled.\n");
} else {
        printf("\t  Anonymous:\t\t\t%2d%%\t%d\n", $anon_hits_perc, $anon_hits);
}

printf("\t  Most Recently Used:\t\t%2d%%\t%d (mru)\n", $mru_hits_perc, $mru_hits);
printf("\t  Most Frequently Used:\t\t%2d%%\t%d (mfu)\n", $mfu_hits_perc, $mfu_hits);
printf("\t  Most Recently Used Ghost:\t%2d%%\t%d (mru_ghost)\n", $mru_ghost_hits_perc, $mru_ghost_hits);
printf("\t  Most Frequently Used Ghost:\t%2d%%\t%d (mfu_ghost)\n", $mfu_ghost_hits_perc, $mfu_ghost_hits);

print "\n\tCACHE HITS BY DATA TYPE:\n";
printf("\t  Demand Data:\t\t\t%2d%%\t%d\n", $demand_data_hits_perc, $demand_data_hits);
printf("\t  Prefetch Data:\t\t%2d%%\t%d\n", $prefetch_data_hits_perc, $prefetch_data_hits);
printf("\t  Demand Metadata:\t\t%2d%%\t%d\n", $demand_metadata_hits_perc, $demand_metadata_hits);
printf("\t  Prefetch Metadata:\t\t%2d%%\t%d\n", $prefetch_metadata_hits_perc, $prefetch_metadata_hits);

print "\n\tCACHE MISSES BY DATA TYPE:\n";
printf("\t  Demand Data:\t\t\t%2d%%\t%d\n", $demand_data_misses_perc, $demand_data_misses);
printf("\t  Prefetch Data:\t\t%2d%%\t%d\n", $prefetch_data_misses_perc, $prefetch_data_misses);
printf("\t  Demand Metadata:\t\t%2d%%\t%d\n", $demand_metadata_misses_perc, $demand_metadata_misses);
printf("\t  Prefetch Metadata:\t\t%2d%%\t%d\n\n", $prefetch_metadata_misses_perc, $prefetch_metadata_misses);

#### Tunables #####################
my @tunables = `sysctl kern.maxusers vfs.zfs vm.kmem_size vm.kmem_size_scale vm.kmem_size_min vm.kmem_size_max`;
print "ZFS Tunable (sysctl):\n";
foreach(@tunables){
        chomp($_);
        print "\t$_\n";
}
print "---------------------------------------------------------------------\n";
