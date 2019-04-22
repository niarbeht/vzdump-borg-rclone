#!/usr/bin/perl -w

# hook script for vzdump (--script option)
# Originally written by Proxmox, licensed under Affero GPL v3
# Modified 2019 by Nathan Todd

use strict;
use warnings;

print "HOOK: " . join (' ', @ARGV) . "\n";

#Done with main, all subroutines from here on out

#Arg extractors
#extractArgs takes the existing %args and returns an expanded %args as appropriate for our stage.
sub extractArgs {
    my $args = shift;

    my $cond = $args->{-phase};

    if($cond eq 'log-end') {
        $args->{-logfile} = $ENV{LOGFILE};
    } elsif ($cond eq'backup-end') {
        $args->{-tarfile} = $ENV{TARFILE};
    }

    if($cond eq 'log-end' or $cond eq 'backup-end' or
        $cond eq 'backup-start' or $cond eq 'backup-abort' or $cond eq 'pre-stop' or $cond eq 'pre-restart' or $cond eq 'post-restart') {
        $args->{-vmtype} = $ENV{"VMTYPE"};
        $args->{-hostname} = $ENV{"HOSTNAME"};
    }

    if($cond eq 'log-end' or $cond eq 'backup-end' or
        $cond eq 'backup-start' or $cond eq 'backup-abort' or $cond eq 'pre-stop' or $cond eq 'pre-restart' or $cond eq 'post-restart' or
        $cond eq 'job-start' or $cond eq 'job-end' or $cond eq 'job-abort') {
        $args->{-dumpdir} = $ENV{"DUMPDIR"};
        $args->{-storeid} = $ENV{"STOREID"};
    }

    return $args;
}

sub readConfig {
    my $answer = shift;
    my $file = '/etc/pxmx-borg-rclone.conf';

    open CONFIG, "$file" or die "Couldn't read config file $file: $!\n";
    while (<CONFIG>) {
        next if (/^#|^\s*$/);  # skip blanks and comments
        my ($variable, $value) = split /=/;
        $value =~ s/\n+$//; #cut newlines

        if($variable eq 'BORG_REPO_PATH') {
            $answer->{-borg_repo_path} = $value;
        } elsif ($variable eq 'BORG_REPO_NAME') {
            $answer->{-borg_repo_name} = $value;
        } elsif ($variable eq 'BORG_COMPRESSION') {
            $answer->{-borg_compression} = $value;
        } elsif ($variable eq 'BORG_KEEP_YEARLY') {
            $answer->{-borg_keep_yearly} = $value;
        } elsif ($variable eq 'BORG_KEEP_MONTHLY') {
            $answer->{-borg_keep_monthly} = $value;
        } elsif ($variable eq 'BORG_KEEP_WEEKLY') {
            $answer->{-borg_keep_weekly} = $value;
        } elsif ($variable eq 'BORG_KEEP_DAILY') {
            $answer->{-borg_keep_daily} = $value;
        } elsif ($variable eq 'BORG_KEEP_HOURLY') {
            $answer->{-borg_keep_hourly} = $value;
        } elsif ($variable eq 'RCLONE_REMOTE') {
            $answer->{-rclone_remote} = $value;
        } elsif ($variable eq 'RCLONE_BUCKET_NAME') {
            $answer->{-rclone_bucket_name} = $value;
        } elsif ($variable eq 'RCLONE_BWLIMIT') {
            $answer->{-rclone_bwlimit} = $value;
        } elsif ($variable eq 'RCLONE_TRANSFERS') {
            $answer->{-rclone_transfers} = $value;
        } else {
            $answer->{$variable} = $value;
        }
    }
    close CONFIG;

    return $answer;
}

sub readPassword {
    my $answer = 0;
    my $file = '/borg/pxmx-borg-password.conf';

    open CONFIG, "$file" or die "Couldn't read config file $file: $!\n";
    while (<CONFIG>) {
        next if (/^#|^\s*$/);  # skip blanks and comments
        my ($variable, $value) = split /=/;
        $value =~ s/\n+$//; #cut newlines
        if($variable eq 'BORG_PASSPHRASE') {
            $answer = $value;
        }
    }
    close CONFIG;

    return $answer;
}

#Stage subroutines
sub jobStart {
    #TODO check if repo is init'd
    #TODO if repo is not init'd, init it
    #TODO do I care about determining if rclone remotes already exist?  Do I set them up here, or trust the user to already have them?
    #TODO remember to shift out args and config
    print "In jobStart\n";
    my $args = shift;
    my $config = shift;
}

sub jobEnd {
    print "In jobEnd\n";
    my $args = shift;
    my $config = shift;
}

sub jobAbort {
    print "In jobAbort\n";
    my $args = shift;
    my $config = shift;
}

sub backupStart {
    print "In backupStart\n";
    my $args = shift;
    my $config = shift;
}

sub backupEnd {
    #TODO put tarfile into repo
    #TODO 
    #system ("scp $tarfile backup-host:/backup-dir") == 0 || die "copy tar file to backup-host failed";
    print "In backupEnd\n";
    my $args = shift;
    my $config = shift;
    my $borg_secret = shift;
    my @borg_create_command = ['borg', 'create',
        "--compression=$config->{-borg_compression}",
        "$config->{-borg_repo_path}".'/'."$config->{-borg_repo_name}".'::'."$args->{-vmtype}-$args->{-vmid}-\{now:\%Y-\%m-\%d_\%H-\%M-\%S\}",
        "$args->{-tarfile}"];
    my @borg_prune_command = [];

    for (my $i = 0; $i < @borg_create_command; $i++) {
        my $s = $borg_create_command[$i];
        print "$s ";
    }
    print "\n";

    #borg create --compression=$COMPRESSION $REPO_PATH/$REPO_NAME::vzdump-$1-{now:%Y-%m-%d_%H-%M-%S} $TARGETS/vzdump-*-$1-*
    #rm $TARGETS/vzdump-*-$1-*
    #borg prune --save-space --keep-yearly=$KEEP_YEARLY --keep-monthly=$KEEP_MONTHLY --keep-weekly=$KEEP_WEEKLY --keep-daily=$KEEP_DAILY --keep-hourly=$KEEP_HOURLY --prefix=vzdump-$1- $REPO_PATH/$REPO_NAME
    #rclone sync $REPO_PATH/$REPO_NAME $RCLONE_REMOTE:$BUCKET_NAME --bwlimit=$RCLONE_BWLIMIT --transfers=$RCLONE_TRANSFERS
    $ENV{BORG_PASSPHRASE} = $borg_secret;
    system(@borg_create_command);
    #system(@borg_prune_command);
    #prune here
    $ENV{BORG_PASSPHRASE} = ""; #clear secret from env just for kicks
}

sub backupAbort {
    print "In backupAbort\n";
    my $args = shift;
    my $config = shift;
}

sub logEnd {
    print "In logEnd\n";
    my $args = shift;
    my $config = shift;
}

sub preStop {
    print "In preStop\n";
    my $args = shift;
    my $config = shift;
}

sub preRestart {
    print "In preRestart\n";
    my $args = shift;
    my $config = shift;
}

sub postRestart {
    print "In postRestart\n";
    my $args = shift;
    my $config = shift;
}

#START MAIN

my $args = {};

$args->{-phase} = shift;

#Check if we should shift mode and vmid
if($args->{-phase} eq 'backup-start' or $args->{-phase} eq 'backup-end' or $args->{-phase} eq 'backup-abort' or $args->{-phase} eq 'log-end' or 
    $args->{-phase} eq 'pre-stop' or $args->{-phase} eq 'pre-restart' or $args->{-phase} eq 'post-restart') {
    $args->{-mode} = shift; 
    $args->{-vmid} = shift;

}

$args = extractArgs($args);

my $config = {};
$config = readConfig($config);

my $borg_secret = readPassword();

my $key;
my $value;

print 'HOOK ARG:';
while (($key, $value) = each (%{$args})) {
    $value = $args->{$key};
    print " $key = $value;";
}
print "\n";

print 'HOOK CONF:';
while (($key, $value) = each (%{$config})) {
    $value = $config->{$key};
    print " $key = $value;";
}
print "\n";

#TODO make test script to dump args output to file to see what the args look like

#TODO make functions to pull out standard args and return as list
#TODO call bespoke functions for each stage.  Functions might just be stubs that log.
#TODO job-start: Ensure repo exists, if not, init if able to
#TODO backup-end: Put tarfile into repo in repo list
#TODO backup-end or pre-stop: Sync repo to remote targets from list (rclone supports local storage as a remote!)

if($args->{-phase} eq 'job-start') {
    jobStart($args, $config);
} elsif ($args->{-phase} eq 'job-end') {
    jobEnd($args, $config);
} elsif ($args->{-phase} eq 'job-abort') {
    jobAbort($args, $config);
} elsif ($args->{-phase} eq 'backup-start') {
    backupStart($args, $config);
} elsif ($args->{-phase} eq 'backup-end') {
    backupEnd($args, $config, $borg_secret);
} elsif ($args->{-phase} eq 'backup-abort') {
    backupAbort($args, $config);
} elsif ($args->{-phase} eq 'log-end') {
    logEnd($args, $config);
} elsif ($args->{-phase} eq 'pre-stop') {
    preStop($args, $config);
} elsif ($args->{-phase} eq 'pre-restart') {
    preRestart($args, $config);
} elsif ($args->{-phase} eq 'post-restart') {
    postRestart($args, $config);
} else {
    die "got unknown phase '$args->{-phase}'";
}

exit (0);

