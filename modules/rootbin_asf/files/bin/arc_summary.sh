#!/bin/sh

#based on arc_summary.pl v0.3
#http://cuddletech.com/arc_summary/

## benr@cuddletech.com
## arc_summary.pl v0.3
#
# Simplified BSD License (http://www.opensource.org/licenses/bsd-license.php)
# Copyright (c) 2008, Ben Rockwood (benr@cuddletech.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright notice, this 
#	list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, 
#	this list of conditions and the following disclaimer in the documentation 
#	and/or other materials provided with the distribution.
#    * Neither the name of the Ben Rockwood nor the names of its contributors may be 
#	used to endorse or promote products derived from this software without specific 
#	prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

get() {
    var="$1"
    name="$2"
    value=$(sysctl -n "$name")
    eval $var=\"$value\"
}

for X in $(sysctl -e kstat.zfs.misc.arcstats | sed 's/\./_/g'); do
    eval $X
done

getstat() {
    #get "$1" "kstat.zfs.misc.arcstats.$2"
    eval $1=\$kstat_zfs_misc_arcstats_$2
}

### System Memory ###
get free_pages vm.stats.vm.v_free_count
get pagesize hw.pagesize

get phys_memory hw.physmem
free_memory=$((free_pages * pagesize))
#get lotsfree_memory xxx

printf "System Memory:\n"
printf "\t Physical RAM: \t%d MB\n" $((phys_memory / 1024 / 1024))
printf "\t Free Memory : \t%d MB\n" $((free_memory / 1024 / 1024))
#printf "\t LotsFree: \t%d MB\n" $((lotsfree_memory / 1024 / 1024))
printf "\n"
##########################


#### Tunables #####################
#my @tunables = `grep zfs /etc/system`;
#print "ZFS Tunables (/etc/system):\n";
#foreach(@tunables){
#        chomp($_);
#        print "\t $_\n";
#}
#print "\n";

#### ARC Sizing ###############
getstat mru_size p
getstat target_size c
getstat arc_min_size c_min
getstat arc_max_size c_max

getstat arc_size size
mfu_size=$((target_size - mru_size));
mru_perc=$((100*mru_size / target_size))
mfu_perc=$((100*mfu_size / target_size))


printf "ARC Size:\n";
printf "\t Current Size:             %d MB (arcsize)\n" $((arc_size / 1024 / 1024))
printf "\t Target Size (Adaptive):   %d MB (c)\n" $((target_size / 1024 / 1024))
printf "\t Min Size (Hard Limit):    %d MB (zfs_arc_min)\n" $((arc_min_size / 1024 / 1024))
printf "\t Max Size (Hard Limit):    %d MB (zfs_arc_max)\n" $((arc_max_size / 1024 / 1024))

printf "\nARC Size Breakdown:\n"

printf "\t Most Recently Used Cache Size: \t %2d%% \t%d MB (p)\n" $mru_perc $((mru_size / 1024 / 1024))
printf "\t Most Frequently Used Cache Size: \t %2d%% \t%d MB (c-p)\n" $mfu_perc $((mfu_size / 1024 / 1024))
printf "\n"
##################################

#my $arc_size = ${Kstat}->{zfs}->{0}->{arcstats}->{size};

        

####### ARC Efficency #########################
getstat arc_hits hits
getstat arc_misses misses
arc_accesses_total=$((arc_hits + arc_misses))

arc_hit_perc=$((100*arc_hits / arc_accesses_total))
arc_miss_perc=$((100*arc_misses / arc_accesses_total))


getstat mfu_hits mfu_hits
getstat mru_hits mru_hits
getstat mfu_ghost_hits mfu_ghost_hits
getstat mru_ghost_hits mru_ghost_hits
anon_hits=$((arc_hits - (mfu_hits + mru_hits + mfu_ghost_hits + mru_ghost_hits)))

real_hits=$((mfu_hits + mru_hits))
real_hits_perc=$((100 * real_hits / arc_accesses_total))

### These should be based on TOTAL HITS ($arc_hits)
anon_hits_perc=$((100*anon_hits / $arc_hits))
mfu_hits_perc=$((100*mfu_hits / $arc_hits))
mru_hits_perc=$((100*mru_hits / $arc_hits))
mfu_ghost_hits_perc=$((100*mfu_ghost_hits / $arc_hits))
mru_ghost_hits_perc=$((100*mru_ghost_hits / $arc_hits))


getstat demand_data_hits demand_data_hits
getstat demand_metadata_hits demand_metadata_hits
getstat prefetch_data_hits prefetch_data_hits
getstat prefetch_metadata_hits prefetch_metadata_hits

demand_data_hits_perc=$((100*demand_data_hits / arc_hits))
demand_metadata_hits_perc=$((100*demand_metadata_hits / arc_hits))
prefetch_data_hits_perc=$((100*prefetch_data_hits / arc_hits))
prefetch_metadata_hits_perc=$((100*prefetch_metadata_hits / arc_hits))


getstat demand_data_misses demand_data_misses
getstat demand_metadata_misses demand_metadata_misses
getstat prefetch_data_misses prefetch_data_misses
getstat prefetch_metadata_misses prefetch_metadata_misses

demand_data_misses_perc=$((100*demand_data_misses / arc_misses))
demand_metadata_misses_perc=$((100*demand_metadata_misses / arc_misses))
prefetch_data_misses_perc=$((100*prefetch_data_misses / arc_misses))
prefetch_metadata_misses_perc=$((100*prefetch_metadata_misses / arc_misses))

prefetch_data_total=$((prefetch_data_hits + prefetch_data_misses))
prefetch_data_perc="00";
if [ $prefetch_data_total -gt 0 ]; then
        prefetch_data_perc=$((100*prefetch_data_hits / prefetch_data_total))
fi

demand_data_total=$((demand_data_hits + demand_data_misses))
demand_data_perc=$((100*demand_data_hits / demand_data_total))


printf "ARC Efficiency:\n"
printf "\t Cache Access Total:        \t %d\n" $arc_accesses_total
printf "\t Cache Hit Ratio:      %2d%%\t %d   \t[Defined State for buffer]\n" $arc_hit_perc $arc_hits
printf "\t Cache Miss Ratio:     %2d%%\t %d   \t[Undefined State for Buffer]\n" $arc_miss_perc $arc_misses
printf "\t REAL Hit Ratio:       %2d%%\t %d   \t[MRU/MFU Hits Only]\n" $real_hits_perc $real_hits
printf "\n"
printf "\t Data Demand   Efficiency:    %2d%%\n" $demand_data_perc
if [ $prefetch_data_total -eq 0 ]; then
        printf "\t Data Prefetch Efficiency:    DISABLED (zfs_prefetch_disable)\n"
else
        printf "\t Data Prefetch Efficiency:    %2d%%\n" $prefetch_data_perc
fi
printf "\n"


printf "\tCACHE HITS BY CACHE LIST:\n"
if [ $anon_hits -lt 1 ]; then
        printf "\t  Anon:                       --%% \t Counter Rolled.\n"
else
        printf "\t  Anon:                       %2d%% \t %d            \t[ New Customer, First Cache Hit ]\n" $anon_hits_perc $anon_hits
fi
printf "\t  Most Recently Used:         %2d%% \t %d (mru)      \t[ Return Customer ]\n" $mru_hits_perc $mru_hits
printf "\t  Most Frequently Used:       %2d%% \t %d (mfu)      \t[ Frequent Customer ]\n" $mfu_hits_perc $mfu_hits
printf "\t  Most Recently Used Ghost:   %2d%% \t %d (mru_ghost)\t[ Return Customer Evicted, Now Back ]\n" $mru_ghost_hits_perc $mru_ghost_hits
printf "\t  Most Frequently Used Ghost: %2d%% \t %d (mfu_ghost)\t[ Frequent Customer Evicted, Now Back ]\n" $mfu_ghost_hits_perc $mfu_ghost_hits

printf "\tCACHE HITS BY DATA TYPE:\n"
printf "\t  Demand Data:                %2d%% \t %d \n" $demand_data_hits_perc $demand_data_hits
printf "\t  Prefetch Data:              %2d%% \t %d \n" $prefetch_data_hits_perc $prefetch_data_hits
printf "\t  Demand Metadata:            %2d%% \t %d \n" $demand_metadata_hits_perc $demand_metadata_hits
printf "\t  Prefetch Metadata:          %2d%% \t %d \n" $prefetch_metadata_hits_perc $prefetch_metadata_hits

printf "\tCACHE MISSES BY DATA TYPE:\n"
printf "\t  Demand Data:                %2d%% \t %d \n" $demand_data_misses_perc $demand_data_misses
printf "\t  Prefetch Data:              %2d%% \t %d \n" $prefetch_data_misses_perc $prefetch_data_misses
printf "\t  Demand Metadata:            %2d%% \t %d \n" $demand_metadata_misses_perc $demand_metadata_misses
printf "\t  Prefetch Metadata:          %2d%% \t %d \n" $prefetch_metadata_misses_perc $prefetch_metadata_misses

printf -- "---------------------------------------------\n"
###############################################
