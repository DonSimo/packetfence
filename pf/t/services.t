#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Test::More tests => 10;
use Log::Log4perl;
use File::Basename qw(basename);
use lib '/usr/local/pf/lib';

Log::Log4perl->init("/usr/local/pf/t/log.conf");
my $logger = Log::Log4perl->get_logger( basename($0) );
Log::Log4perl::MDC->put( 'proc', basename($0) );
Log::Log4perl::MDC->put( 'tid',  0 );

BEGIN { use_ok('pf::services') }

my $return_value;

# CONFIGURATION VALIDATION

# switches_conf_is_valid()

# modify global $conf_dir so that t/data/switches.conf will be loaded instead of conf/switches.conf
my $conf_dir = $main::pf::config::conf_dir;
$main::pf::config::conf_dir = "/usr/local/pf/t/data/";
ok(pf::services::switches_conf_is_valid(), "switches.conf validation with a good file");
# modify global $conf_dir so that t/data/bug766/switches.conf will be loaded instead of conf/switches.conf
$main::pf::config::conf_dir = "/usr/local/pf/t/data/bug766/";
ok(!pf::services::switches_conf_is_valid(), "switches.conf validation with a broken file (duplicate IP)");
$main::pf::config::conf_dir = $conf_dir;
# TODO add more tests around switches_conf_is_valid to test all cases


# SNORT

#is var/alert a named pipe?
ok (-p("/usr/local/pf/var/alert"), "snort var/alert is a named pipe");
# if this test fails, create the named pipe manually
# it is created by bin/pfcmd in sanity_check sub (a pfcmd service snort start 
# with trapping detection is enabled will do it)

print "sometimes prompt hang at this test, wait for 30 secs then hit Ctrl-C once and it should unstuck\n";

$return_value = pf::services::service_ctl ("snort", "start");
ok($return_value == 0, "service_ctl snort start returns expected value");

sleep 5;

ok(`pidof -x snort` =~ /\d+/, "snort starts successfully");

$return_value = pf::services::service_ctl ("pfdetect", "start");
ok($return_value == 0, "service_ctl pfdetect start returns expected value");

sleep 5;

# snort can crash once you bind to the alert pipe if its config is not good
ok(`pidof -x pfdetect` =~ /\d+/, "pfdetect stays running after binding to snort");

$return_value = pf::services::service_ctl ("snort", "stop");
ok($return_value == 1, "service_ctl snort stop returns expected value");

ok(`pidof -x snort` eq "\n", "snort stopped successfully");

# TODO do tests for all other services handled by pf::services
