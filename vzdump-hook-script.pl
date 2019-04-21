#!/usr/bin/perl -w

# hook script for vzdump (--script option)
# Originally written by Proxmox, licensed under Affero GPL v3
# Modified 2019 by Nathan Todd

use strict;
use warnings;
use Switch;

print "HOOK: " . join (' ', @ARGV) . "\n";

#Done with main, all subroutines from here on out

#Arg extractors
#extractArgs takes the existing %args and returns an expanded %args as appropriate for our stage.
sub extractArgs {
    my $args = @_;

    switch ($args->{-phase}) {
        case "log-end" {next;}
        case "backup-end" {
            if ($args->{-phase} eq "log-end") {
                $args->{-logfile} = $ENV{"LOGFILE"};
            } elsif ($args->{-phase} eq "backup-end") {
                $args->{-tarfile} = $ENV{"TARFILE"};
            }
            next;
        }
        case "backup-start" {next;}
        case "backup-abort" {next;}
        case "pre-stop" {next;}
        case "log-end" {next;}
        case "backup-end" {next;}
        case "pre-restart" { #VMTYPE, DUMPDIR, STOREID, HOSTNAME
            $args->{-vmtype} = $ENV{"VMTYPE"};
            $args->{-hostname} = $ENV{"HOSTNAME"};
            next;
        }
        case "job-start" {next;}
        case "job-end" {next;}
        case "job-abort" { #DUMPDIR, STOREID
            $args->{-dumpdir} = $ENV{"DUMPDIR"};
            $args->{-storeid} = $ENV{"STOREID"};
        }
        else {} #TODO Log unknown phase
    }

    return $args;
}

#readConfig reads the config file (consider having separate secrets file?)
# sub readConfig {
#     my %config;
#     my $cfg_path = "/etc/pxmx-borg-rclone.conf";
#     open my $fh, $cfg_path or die "Failed to open $cfg_path: $!";

#     # Loop across all lines in file
#     while (<$fh>) {
#     # one line of data is now in $_
#         if (m/BORG_REPO_PATH=(\S+)/) {
#             $config{-repo_path} = $1;
#             last;
#         } elsif (m/BORG_REPO_NAME=(\S+)/) {
#             $config{-repo_name} = $1;
#             last;
#         } elsif (m/BORG_COMPRESSION=(\S+)/) {
#             $config{-borg_compression} = $1;
#             last;
#         } elsif (m/RCLONE_REMOTE=(\S+)/) {
#             $config{-rclone_remote} = $1;
#             last;
#         } elsif (m/RCLONE_BUCKET_NAME=(\S+)/) {
#             $config{-rclone_bucket_name} = $1;
#             last;
#         } elsif (m/RCLONE_BWLIMIT=(\S+)/) {
#             $config{-rclone_bwlimit} = $1;
#             last;
#         } elsif (m/RCLONE_TRANSFERS=(\S+)/) {
#             $config{-rclone_transfers} = $1;
#             last;
#         } elsif (m/BORG_KEEP_YEARLY=(\S+)/) {
#             $config{-borg_keep_yearly} = $1;
#             last;
#         } elsif (m/BORG_KEEP_MONTHLY=(\S+)/) {
#             $config{-borg_keep_monthly} = $1;
#             last;
#         } elsif (m/BORG_KEEP_WEEKLY=(\S+)/) {
#             $config{-borg_keep_weekly} = $1;
#             last;
#         } elsif (m/BORG_KEEP_DAILY=(\S+)/) {
#             $config{-borg_keep_daily} = $1;
#             last;
#         } elsif (m/BORG_KEEP_HOURLY=(\S+)/) {
#             $config{-borg_keep_hourly} = $1;
#             last;
#         }
#     }

#     return %config;
# }

sub readConfig {
    my $file = "/etc/pxmx-borg-rclone.conf";
    my %answer;

    open CONFIG, "$file" or die "Couldn't read config file $file: $!\n";
    while (<CONFIG>) {
        next if (/^#|^\s*$/);  # skip blanks and comments
        my ($variable, $value) = split /=/;
        #$answer{$variable} = $value;
        print "$variable $value \n";
        switch ($variable) {
            case "BORG_REPO_PATH" {$answer{-borg_repo_path} = $value;}
            case "BORG_REPO_NAME" {$answer{-borg_repo_name} = $value;}
            case "BORG_COMPRESSION" {$answer{-borg_compression} = $value;}
            case "BORG_KEEP_YEARLY" {$answer{-borg_keep_yearly} = $value;}
            case "BORG_KEEP_MONTHLY" {$answer{-borg_keep_monthly} = $value;}
            case "BORG_KEEP_WEEKLY" {$answer{-borg_keep_weekly} = $value;}
            case "BORG_KEEP_DAILY" {$answer{-borg_keep_daily} = $value;}
            case "BORG_KEEP_HOURLY" {$answer{-borg_keep_hourly} = $value;}
            case "RCLONE_REMOTE" {$answer{-rclone_remote} = $value;}
            case "RCLONE_BUCKET_NAME" {$answer{-rclone_bucket_name} = $value;}
            case "RCLONE_BWLIMIT" {$answer{-rclone_bwlimit} = $value;}
            case "RCLONE_TRANSFERS" {$answer{-rclone_transfers} = $value;}
            else {$answer{$variable} = $value;}
        }
    }
    close CONFIG;

    return \%answer;
}

#Stage subroutines
sub jobStart {
    #TODO check if repo is init'd
    #TODO if repo is not init'd, init it
    #TODO do I care about determining if rclone remotes already exist?  Do I set them up here, or trust the user to already have them?
    #TODO remember to shift out args and config
    print "In jobStart";
}

sub jobEnd {
    print "In jobEnd";
}

sub jobAbort {
    print "In jobAbort";
}

sub backupStart {
    print "In backupStart";
}

sub backupEnd {
    #TODO put tarfile into repo
    #TODO 
    #system ("scp $tarfile backup-host:/backup-dir") == 0 || die "copy tar file to backup-host failed";
    print "In backupEnd";
}

sub backupAbort {
    print "In backupAbort";
}

sub logEnd {
    print "In logEnd";
}

sub preStop {
    print "In preStop";
}

sub preRestart {
    print "In preRestart";
}

my $args = {};

$args->{-phase} = shift;

#Check if we should shift mode and vmid
switch ($args->{-phase}) {
    case "backup-start" {next;}
    case "backup-end" {next;}
    case "backup-abort" {next;}
    case "log-end" {next;}
    case "pre-stop" {next;}
    case "pre-restart" {
        $args->{-mode} = shift; 
        $args->{-vmid} = shift;
    }
}

$args = extractArgs($args);

my $config = readConfig();

my $key;
my $value;

print "HOOK ARG:";
while (($key, $value) = each (%{$args})) {
    $value = $args->{$key};
    print " $key = $value;";
}
print "\n";

print "HOOK CONF:";
while (($key, $value) = each (%{$config})) {
    $value = $args->{$key};
    print " $key = $value;";
}
print "\n";

#TODO make test script to dump args output to file to see what the args look like

#TODO make functions to pull out standard args and return as list
#TODO call bespoke functions for each stage.  Functions might just be stubs that log.
#TODO job-start: Ensure repo exists, if not, init if able to
#TODO backup-end: Put tarfile into repo in repo list
#TODO backup-end or pre-stop: Sync repo to remote targets from list (rclone supports local storage as a remote!)
switch($args->{-phase}) {
    case "job-start" {jobStart($args, $config);}        #DUMPDIR, STOREID
    case "job-end" {jobEnd($args, $config);}            #DUMPDIR, STOREID
    case "job-abort" {jobAbort($args, $config);}        #DUMPDIR, STOREID
    case "backup-start" {backupStart($args, $config);}  #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case "backup-end" {backupEnd($args, $config);}      #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME, TARFILE
    case "backup-abort" {backupAbort($args, $config);}  #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case "log-end" {logEnd($args, $config);}            #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME, LOGFILE
    case "pre-stop" {preStop($args, $config);}          #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    case "pre-restart" {preRestart($args, $config);}    #mode, vmid, VMTYPE, DUMPDIR, STOREID, HOSTNAME
    else {die "got unknown phase '$args->{-phase}'";} #TODO Log unknown phase
}

exit (0);

