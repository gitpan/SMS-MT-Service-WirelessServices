#!/usr/bin/perl -w

use strict;
use Term::ReadLine;
use Test;
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

# Create application object
my $sms = new SMS::MT('PLUGIN' => 'WirelessServices',
                      'UID' => $uid,
                      'PWD' => $pwd);

if ($sms->send_ringtone('peanuts:d=4,o=5,b=160:f,8g,a,8a,8g,f,2g,f,p,f,8g,a,1a,2p,f,8g,a,8a,8g,f,2g,2f,2f,8g,1g',
			[$phn],
			{'FROM' => 'Joe Blow'})) {
 ok(1);
}
else {
 print "Failed to send SMS!\n";
 print 'Error code: ' . $sms->get_last_error_code() . "\n";
 print 'Error desc: ' . $sms->get_last_error_message() . "\n";
 ok(0);
}