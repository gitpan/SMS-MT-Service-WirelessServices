use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'SMS::MT::Service::WirelessServices',
    'VERSION_FROM' => 'lib/SMS/MT/Service/WirelessServices.pm',
    'AUTHOR' => 'Craig Manley (c.manley@skybound.nl)',
    'ABSTRACT' => 'Plugin service module for SMS::MT.',
    'PREREQ_PM'	=> {	'SMS::MT' => '0.02',
			'LWP::UserAgent' => 0,
			'HTTP::Request'	=> 0,
			'HTTP::Response' => 0},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);