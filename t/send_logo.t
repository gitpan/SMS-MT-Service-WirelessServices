#!/usr/bin/perl -w

use strict;
use Term::ReadLine;
use Test;
use FindBin qw($Bin);
use SMS::MT;

BEGIN { plan tests => 1 }

my $uid;
my $pwd;
my $phn;

# Read user name, password, and phone number from console
my $term = new Term::ReadLine('Send CLI (group icon) test.');
while(1) {
 $uid = $term->readline('Enter user id: ');
 if (defined($uid) && length($uid)) {
  last;
 }
}
while(1) {
 $pwd = $term->readline('Enter password: ');
 if (defined($pwd) && length($pwd)) {
  last;
 }
}
while(1) {
 $phn = $term->readline('Enter phone number in int\'l format (leading +, country code, etc): ');
 if (defined($phn) && length($phn)) {
  last;
 }
}

# Read OTA data from file.
my $ota;
my $buf; # temporary buffer
my $file = $Bin . '/logo.ota';
open(F,"<$file") || die "Failed to open $file!\n";
binmode(F);
while(read F, $buf, 1024) {
 $ota .= $buf;
}
close(F);

# Create application object
my $sms = new SMS::MT('PLUGIN' => 'WirelessServices',
                      'UID' => $uid,
                      'PWD' => $pwd);

if ($sms->send_logo(\$ota,
		    [$phn],
		    '02F440',
		    {'FROM' => 'Joe Blow',
		     'FLASH' => 1,
		     'VALIDITY' => 3600
		    } )) {
 ok(1);
}
else {
 print "Failed to send SMS!\n";
 print 'Error code: ' . $sms->get_last_error_code() . "\n";
 print 'Error desc: ' . $sms->get_last_error_message() . "\n";
 ok(0);
}