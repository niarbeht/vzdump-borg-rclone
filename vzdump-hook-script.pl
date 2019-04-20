#!/usr/bin/perl -w

# hook script for vzdump (--script option)
# Originally written by Proxmox, licensed under Affero GPL v3
# Modified 2019 by Nathan Todd

use strict;
use switch;

print "HOOK: " . join (' ', @ARGV) . "\n";3

my $phase = shift;

#TODO make functions to pull out standard args and return as list
#TODO call bespoke functions for each stage.  Functions might just be stubs that log.
#TODO job-start: Ensure repo exists, if not, init if able to
#TODO backup-end: Put tarfile into repo in repo list
#TODO backup-end or pre-stop: Sync repo to remote targets from list (rclone supports local storage as a remote!)
switch($phase) {
    case 'job-start' {}     #DUMPDIR, STOREID
    case 'job-end' {}       #DUMPDIR, STOREID
    case 'job-abort' {}     #DUMPDIR, STOREID
    case 'backup-start' {}  #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case 'backup-end' {}    #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME, TARFILE
    case 'backup-abort' {}  #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case 'log-end' {}       #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME, LOGFILE
    case 'pre-stop' {}      #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case 'pre-restart' {}   #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    else {} #Log unknown phase
}

if ($phase eq 'job-start' || 
    $phase eq 'job-end'  || 
    $phase eq 'job-abort') { 

    my $dumpdir = $ENV{DUMPDIR};

    my $storeid = $ENV{STOREID};

    print "HOOK-ENV: dumpdir=$dumpdir;storeid=$storeid\n";

    # do what you want 

} elsif ($phase eq 'backup-start' || 
	 $phase eq 'backup-end' ||
	 $phase eq 'backup-abort' || 
	 $phase eq 'log-end' || 
	 $phase eq 'pre-stop' ||
	 $phase eq 'pre-restart') {

    my $mode = shift; # stop/suspend/snapshot

    my $vmid = shift;

    my $vmtype = $ENV{VMTYPE}; # openvz/qemu

    my $dumpdir = $ENV{DUMPDIR};

    my $storeid = $ENV{STOREID};

    my $hostname = $ENV{HOSTNAME};

    # tarfile is only available in phase 'backup-end'
    my $tarfile = $ENV{TARFILE};

    # logfile is only available in phase 'log-end'
    my $logfile = $ENV{LOGFILE}; 

    print "HOOK-ENV: vmtype=$vmtype;dumpdir=$dumpdir;storeid=$storeid;hostname=$hostname;tarfile=$tarfile;logfile=$logfile\n";

    # example: copy resulting backup file to another host using scp
    if ($phase eq 'backup-end') {
    	#system ("scp $tarfile backup-host:/backup-dir") == 0 ||
    	#    die "copy tar file to backup-host failed";
    }

    # example: copy resulting log file to another host using scp
    if ($phase eq 'log-end') {
    	#system ("scp $logfile backup-host:/backup-dir") == 0 ||
    	#    die "copy log file to backup-host failed";
    }
    
} else {

    die "got unknown phase '$phase'";

}

exit (0);

