#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Test::Harness;
runtests( qw( 
              pf.t 
              person.t 
              pfcmd.t 
              SNMP.t 
              SwitchFactory.t
              binaries.t
              config.t
              critic.t
              hardware-snmp-objects.t
              pod.t
              podCoverage.t
              php.t
              services.t
              vlan.t
              data.t
              graph.t
              nodecategory.t
              floatingdevice.t
              network-devices/cisco.t
              pfsetvlan.t
              radius.t
              report.t
              node.t
              flow.t
            )
);
