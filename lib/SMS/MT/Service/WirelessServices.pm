package SMS::MT::Service::WirelessServices;
#### Package information ####
# Description and copyright:
#   See POD (i.e. perldoc SMS::MT::Service::WirelessServices).
####

#### Class structure ####
# Protected fields:
#	-UID
#	-PWD
#	-LAST_ERROR_CODE
#	-LAST_ERROR_MESSAGE
# Constructors:
#	new()
# Protected methods:
#	_send_request()
#	_set_error()
# Public class methods:
#	get_max_text_length()
#	get_service_name()
# Public methods:
#	get_last_error_code()
#	get_last_error_message()
#	send_groupicon()
#	send_logo()
#	send_picture()
#	send_ringtone()
#	send_text()
####

use strict;
use Carp;
use SMS::Image;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

my %ERRORS = (	'96' => 'Blocked account',
		'97' => 'Parameter syntax error',
		'98' => 'Insufficient balance',
		'99' => 'Login failed');

our $VERSION = '0.01';

1;

####
# Constructor new()
# Parameters:
#	Hash containing
#		-UID: user id
#		-PWD: password
#
####
sub new {
 my $package = shift;
 my %params = @_;
 my $self  = {};
 bless $self;

 # Check parameters
 my $param_uid = $params{'UID'};
 unless(defined($param_uid)) {
  croak("UID parameter missing!\n");
 }
 my $param_pwd = $params{'PWD'};
 unless(defined($param_pwd)) {
  croak("PWD parameter missing!\n");
 }

 # Set private fields
 $self->{'-UID'} = $param_uid;
 $self->{'-PWD'} = $param_pwd;
 $self->{'-LAST_ERROR_CODE'} = '';
 $self->{'-LAST_ERROR_MESSAGE'} = '';

 # Return self reference
 return $self;
}

####
# Method:	_send_request
# Description:	Performs a post request via HTTP
# Parameters:	1. Reference to hash of POST parameters.
# Returns:	Boolean result
####
sub _send_request {
 my $self = shift;
 my $postparams = shift;
 my $script = shift;
 $postparams->{'UID'} = $self->{'-UID'};
 $postparams->{'PWD'} = $self->{'-PWD'};
 $self->{'-LAST_ERROR_CODE'} = '';
 $self->{'-LAST_ERROR_MESSAGE'} = '';
 my $ua = new LWP::UserAgent();
 $ua->agent(__PACKAGE__ . "/$VERSION " . $ua->agent());
 my $request = POST("http://www.wireless-services.nl$script",
 		    Content => $postparams);
 my $response = $ua->request($request);
 unless($response->is_success()) {
  return $self->_set_error('','HTTP error: ' . $response->status_line());
 }
 unless($response->content() =~ /^(\d{1,3})\s*$/) {
  return $self->_set_error('','Invalid response: ' . $response->content());
 }
 return $self->_set_error($1);
}

####
# Method:	_set_error
# Description:	Sets an error code and message.
# Parameters:	1. Error code
#		2. Optional custom error message.
# Returns:	Boolean result. TRUE if no error code means success, else FALSE.
####
sub _set_error {
 my $self = shift;
 my $code = shift;
 my $msg = shift;
 if (defined($msg)) {
  $self->{'-LAST_ERROR_MESSAGE'} = $msg;
 }
 my $codenum = $code + 0;
 if (exists($ERRORS{$codenum})) {
  $self->{'-LAST_ERROR_CODE'} = $code;
  unless(defined($msg)) {
   $self->{'-LAST_ERROR_MESSAGE'} = $ERRORS{$codenum};
  }
  return 0;
 }
 if ($codenum == 1) {
  $self->{'-LAST_ERROR_CODE'} = $code;
  $self->{'-LAST_ERROR_MESSAGE'} = 'OK';
  return 1;
 }
 if ($codenum >= 100) {
  $self->{'-LAST_ERROR_CODE'} = $code;
  unless(defined($msg)) {
   $self->{'-LAST_ERROR_MESSAGE'} = 'Success, object sent in ' . ($codenum - 100) . ' message(s)';
  }
  return 1;
 }
 $self->{'-LAST_ERROR_CODE'} = $code;
 unless(defined($msg)) {
  $self->{'-LAST_ERROR_MESSAGE'} = 'Unknown response code';
 }
 return 0;
}

####
# Method:	get_last_error_code
# Description:	Get's the last error code.
# Parameters:	none
# Returns:	An error code
####
sub get_last_error_code {
 my $self = shift;
 return $self->{'-LAST_ERROR_CODE'};
}

####
# Method:	get_last_error_message
# Description:	Get's the last error message.
# Parameters:	none
# Returns:	An error message
####
sub get_last_error_message {
 my $self = shift;
 return $self->{'-LAST_ERROR_MESSAGE'};
}

####
# Class method:	get_max_text_length
# Description:	Get's the maximum text SMS length.
# Parameters:	none
# Returns:	Max length
####
sub get_max_text_length {
 return 160;
}

####
# Class method:	get_service_name
# Description:	Get's the current plugin module's service name.
# Parameters:	none
# Returns:	Name
####
sub get_service_name {
 return 'Wireless Services';
}

####
# Method:	send_groupicon
# Description:	Sends an SMS CLI icon.
# Parameters:	1. Reference to binary data buffer containing an OTA bitmap.
#		2. (Reference to) comma seperated string or reference to array of recipients.
#		3. Reference to hash of optional parameters containing any of the keys: FROM, VALIDITY, FLASH.
# Returns:	Boolean result
####
sub send_groupicon {
 my $self = shift;
 my $data = shift;
 my $rcp = shift;
 my $options = shift;
 my $postparams = {'IMG' => unpack('H*',$$data),
 		   'IMGTYPE' => 'GROUP',
 		   'IMGFORMAT' => 'OTA'};
 if (ref($rcp) eq 'ARRAY') {
  $postparams->{'N'} = join(',',@{$rcp});
 }
 elsif (ref($rcp) eq 'SCALAR') {
  $postparams->{'N'} = $$rcp;
 }
 else {
  $postparams->{'N'} = $rcp;
 }
 if (exists($options->{'FROM'})) {
  $postparams->{'O'} = $options->{'FROM'};
 }
 if (exists($options->{'VALIDITY'})) {
  $postparams->{'VAL'} = $options->{'VALIDITY'};
 }
 if (exists($options->{'FLASH'})) {
  $postparams->{'FLASH'} = $options->{'FLASH'};
 }
 return $self->_send_request($postparams,'/sendpic.php');
}


####
# Method:	send_logo
# Description:	Sends an SMS logo.
# Parameters:	1. Reference to binary data buffer.
#		2. (Reference to) comma seperated string or reference to array of recipients.
#		3. Mobile operator code
#		4. Reference to hash of optional parameters containing any of the keys: FROM, VALIDITY, FLASH, CALLBACK.
# Returns:	Boolean result
####
sub send_logo {
 my $self = shift;
 my $data = shift;
 my $rcp = shift;
 my $oper = shift;
 my $options = shift;
 my $postparams = {'IMG' => unpack('H*',$$data),
 		   'IMGTYPE' => 'LOGO',
 		   'IMGFORMAT' => 'OTA',
 		   'MC' => $oper};
 if (ref($rcp) eq 'ARRAY') {
  $postparams->{'N'} = join(',',@{$rcp});
 }
 elsif (ref($rcp) eq 'SCALAR') {
  $postparams->{'N'} = $$rcp;
 }
 else {
  $postparams->{'N'} = $rcp;
 }
 if (exists($options->{'FROM'})) {
  $postparams->{'O'} = $options->{'FROM'};
 }
 if (exists($options->{'VALIDITY'})) {
  $postparams->{'VAL'} = $options->{'VALIDITY'};
 }
 if (exists($options->{'FLASH'})) {
  $postparams->{'FLASH'} = $options->{'FLASH'};
 }
 return $self->_send_request($postparams,'/sendpic.php');
}

####
# Method:	send_picture
# Description:	Sends an SMS picture.
# Parameters:	1. Reference to binary data buffer.
#		2. (Reference to) comma seperated string or reference to array of recipients.
#		3. Reference to hash of optional parameters containing any of the keys: FROM, VALIDITY, FLASH, CALLBACK, MSG.
# Returns:	Boolean result
####
sub send_picture {
 my $self = shift;
 my $data = shift;
 my $rcp = shift;
 my $options = shift;
 my $postparams = {'IMG' => unpack('H*',$$data),
 		   'IMGTYPE' => 'PICTURE',
 		   'IMGFORMAT' => 'OTA'};
 if (ref($rcp) eq 'ARRAY') {
  $postparams->{'N'} = join(',',@{$rcp});
 }
 elsif (ref($rcp) eq 'SCALAR') {
  $postparams->{'N'} = $$rcp;
 }
 else {
  $postparams->{'N'} = $rcp;
 }
 if (exists($options->{'FROM'})) {
  $postparams->{'O'} = $options->{'FROM'};
 }
 if (exists($options->{'VALIDITY'})) {
  $postparams->{'VAL'} = $options->{'VALIDITY'};
 }
 if (exists($options->{'FLASH'})) {
  $postparams->{'FLASH'} = $options->{'FLASH'};
 }
 if (exists($options->{'MSG'})) {
  $postparams->{'M'} = $options->{'MSG'};
 }
 return $self->_send_request($postparams,'/sendpic.php');
}

####
# Method:	send_ringtone
# Description:	Sends a ringing tone.
# Parameters:	1. (Reference to) RTTTL string.
#		2. (Reference to) comma seperated string or reference to array of recipients.
#		3. Reference to hash of optional parameters containing any of the keys: FROM, VALIDITY, CALLBACK, NAME.
# Returns:	Boolean result
####
sub send_ringtone {
 my $self = shift;
 my $data = shift;
 my $rcp = shift;
 my $options = shift;
 my $postparams = {};
 if (ref($data)) {
  $postparams->{'RT'} = $$data;
 }
 else {
  $postparams->{'RT'} = $data;
 }
 if (ref($rcp) eq 'ARRAY') {
  $postparams->{'N'} = join(',',@{$rcp});
 }
 elsif (ref($rcp) eq 'SCALAR') {
  $postparams->{'N'} = $$rcp;
 }
 else {
  $postparams->{'N'} = $rcp;
 }
 if (exists($options->{'FROM'})) {
  $postparams->{'O'} = $options->{'FROM'};
 }
 if (exists($options->{'VALIDITY'})) {
  $postparams->{'VAL'} = $options->{'VALIDITY'};
 }
 if (exists($options->{'NAME'})) {
  $postparams->{'NAME'} = $options->{'NAME'};
 }
 return $self->_send_request($postparams,'/sendringtone.php');
}

####
# Method:	send_text
# Description:	Sends an SMS text message.
# Parameters:	1. Text message
#		2. (Reference to) comma seperated string or reference to array of recipients.
#		3. Reference to hash of optional parameters containing any of the keys: FROM, VALIDITY, FLASH, CALLBACK.
# Returns:	Boolean result
####
sub send_text {
 my $self = shift;
 my $msg = shift;
 my $rcp = shift;
 my $options = shift;
 my $postparams = {'M' => $msg};
 if (ref($rcp) eq 'ARRAY') {
  $postparams->{'N'} = join(',',@{$rcp});
 }
 elsif (ref($rcp) eq 'SCALAR') {
  $postparams->{'N'} = $$rcp;
 }
 else {
  $postparams->{'N'} = $rcp;
 }
 if (exists($options->{'FROM'})) {
  $postparams->{'O'} = $options->{'FROM'};
 }
 if (exists($options->{'VALIDITY'})) {
  $postparams->{'VAL'} = $options->{'VALIDITY'};
 }
 if (exists($options->{'FLASH'})) {
  $postparams->{'FLASH'} = $options->{'FLASH'};
 }
 return $self->_send_request($postparams,'/sendsms.php');
}

__END__


=head1 NAME

SMS::MT::Service::WirelessServices - SMS::MT plugin module.

=head1 SYNOPSIS

    use SMS::MT;

    my $sm = new SMS::MT('UID' => 'joeblow',
                         'PWD' => 'secret',
                         'PLUGIN' => 'WirelessServices');


=head1 DESCRIPTION

This package contains a class for creating a standalone object or an object
that acts as a plugin for a SMS::MT receptor object. See the SMS::MT
documentation for details. This class sends mobile terminated SMS's via
the interfaces of http://www.wireless-services.nl .


=head1 CLASS METHODS

=over 4

=item new ('UID' => $userid, 'PWD' => $password);

Returns a new SMS::MT::Service::WirelessServices object.

=item get_max_text_length()

Returns the maximum text length supported by this service.

=item get_service_name()

Returns the descriptive SMS service name.

=back


=head1 OBJECT METHODS

=over 4

=item get_last_error_code()

Returns the last service specific error code. Below is a list of codes and
messages specific to this service:

 96	Blocked account
 97	Parameter syntax error
 98	Insufficient balance
 99	Login failed

=item get_last_error_message()

Returns the last service specific error message. See C<get_last_error_code>.

=item send_groupicon()

See SMS::MT documentation.

=item send_logo()

See SMS::MT documentation.

=item send_picture()

See SMS::MT documentation.

=item send_ringtone()

See SMS::MT documentation.

=item send_text()

See SMS::MT documentation.

=back


=head1 SUPPORTED OPTIONAL PARAMETERS TO send*() METHODS

All send*() methods support optional parameters that are passed as a
reference to a hash.

Below is a list of all supported optional parameter keys and what kind of
values are to be associated with them.

=over 4

=item FROM

The value must contain the sender of the message.

=item VALIDITY

The value must contain the validity of the message in minutes.

=item FLASH

The value must contain a boolean indicating if this is a flash SMS.

=item NAME

The value must contain the name of the ringtone. This name should override any
name already specified in the RTTTL string.

=item MSG

The value must contain the textual message of a picture message.

=back


=head1 HISTORY

=over 4

=item Version 0.01  2001-11-06

Initial version

=back


=head1 AUTHOR

Craig Manley	c.manley@skybound.nl


=head1 COPYRIGHT

Copyright (C) 2001 Craig Manley <c.manley@skybound.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under under the same terms as Perl itself. There is NO warranty;
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut