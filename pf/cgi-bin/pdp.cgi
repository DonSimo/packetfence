#!/usr/bin/perl -w

package PFAPI;

#use Data::Dumper;
use strict;
use warnings;

use CGI;
use Log::Log4perl;

use constant INSTALL_DIR => '/usr/local/pf';
use lib INSTALL_DIR . "/lib";
use pf::config;
use pf::db;
use pf::util;
use pf::iplog;
use pf::radius::custom;
use pf::violation;

use SOAP::Transport::HTTP;

Log::Log4perl->init("$conf_dir/log.conf");
my $logger = Log::Log4perl->get_logger('pdp.cgi');
Log::Log4perl::MDC->put('proc', 'pdp.cgi');
Log::Log4perl::MDC->put('tid', 0);


SOAP::Transport::HTTP::CGI
    -> dispatch_to('PFAPI')
    -> handle;


sub event_add {
  my ($class, $date, $srcip, $type, $id) = @_;
  $logger->info("violation: $id - IP $srcip");

  # fetch IP associated to MAC
  my $srcmac = ip2mac($srcip);
  if ($srcmac) {

    # trigger a violation
    violation_trigger($srcmac, $id, $type, ( ip => $srcip ));

  } else {
    $logger->info("violation on IP $srcip with trigger ${type}::${id}: violation not added, can't resolve IP to mac !");
    return(0);
  }
  return (1);
}

sub radius_authorize {
  my ($class, $nas_port_type, $switch_ip, $eap_type, $mac, $port, $user_name, $ssid) = @_;
  my $radius = new pf::radius::custom();

  #TODO change to trace level once done
  $logger->info("received a radius authorization request with parameters: ".
           "nas port type => $nas_port_type, switch_ip => $switch_ip, EAP-Type => $eap_type, ".
           "mac => $mac, port => $port, username => $user_name, ssid => $ssid");

  my $return;
  eval {
      $return = $radius->authorize($nas_port_type, $switch_ip, $eap_type, $mac, $port, $user_name, $ssid);
  };
  if ($@) {
      $logger->logdie("radius authorize failed with error: $@");
  }
  return $return;
}
