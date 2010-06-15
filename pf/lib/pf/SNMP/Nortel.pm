package pf::SNMP::Nortel;

=head1 NAME

pf::SNMP::Nortel - Object oriented module to access SNMP enabled Nortel switches

=head1 SYNOPSIS

The pf::SNMP::Nortel module implements an object oriented interface
to access SNMP enabled Nortel switches.

=cut

use strict;
use warnings;
use diagnostics;

use base ('pf::SNMP');
use Log::Log4perl;
use Net::SNMP;

sub getVersion {
    my ($this)        = @_;
    my $oid_s5ChasVer = '1.3.6.1.4.1.45.1.6.3.1.5';
    my $logger        = Log::Log4perl::get_logger( ref($this) );
    if ( !$this->connectRead() ) {
        return '';
    }
    $logger->trace("SNMP get_request for s5ChasVer: $oid_s5ChasVer");
    my $result = $this->{_sessionRead}
        ->get_request( -varbindlist => [$oid_s5ChasVer] );
    if ( exists( $result->{$oid_s5ChasVer} )
        && ( $result->{$oid_s5ChasVer} ne 'noSuchInstance' ) )
    {
        return $result->{$oid_s5ChasVer};
    }
    return '';
}

sub parseTrap {
    my ( $this, $trapString ) = @_;
    my $trapHashRef;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    if ( $trapString
        =~ /^BEGIN TYPE ([23]) END TYPE BEGIN SUBTYPE 0 END SUBTYPE BEGIN VARIABLEBINDINGS \.1\.3\.6\.1\.2\.1\.2\.2\.1\.1\.(\d+) = INTEGER: \d+\|\.1\.3\.6\.1\.2\.1\.2\.2\.1\.7\.\d+ = INTEGER: [^|]+\|\.1\.3\.6\.1\.2\.1\.2\.2\.1\.8\.\d+ = INTEGER: [^)]+\)/
        )
    {
        $trapHashRef->{'trapType'} = ( ( $1 == 2 ) ? "down" : "up" );
        $trapHashRef->{'trapIfIndex'} = $2;
    } elsif ( $trapString
        =~ /\|\.1\.3\.6\.1\.4\.1\.45\.1\.6\.5\.3\.12\.1\.3\.(\d+)\.(\d+) = Hex-STRING: ([0-9A-F]{2} [0-9A-F]{2} [0-9A-F]{2} [0-9A-F]{2} [0-9A-F]{2} [0-9A-F]{2})/
        )
    {
        $trapHashRef->{'trapType'}    = 'secureMacAddrViolation';
        $trapHashRef->{'trapIfIndex'} = ( $1 - 1 ) * 64 + $2;
        $trapHashRef->{'trapMac'}     = lc($3);
        $trapHashRef->{'trapMac'} =~ s/ /:/g;
        $trapHashRef->{'trapVlan'}
            = $this->getVlan( $trapHashRef->{'trapIfIndex'} );

#$trapHashRef->{'trapIfIndex'} = $this->getIfIndexForThisMac($trapHashRef->{'trapMac'});
#if ($trapHashRef->{'trapIfIndex'} == -1) {
#    $logger->error("cannot determine ifIndex for " . $trapHashRef->{'trapMac'} . " on switch " . $this->{_ip} . ". IGNORING Trap");
#    $trapHashRef->{'trapType'} = 'unknown';
#} else {
        $logger->debug( "ifIndex for "
                . $trapHashRef->{'trapMac'}
                . " on switch "
                . $this->{_ip} . " is "
                . $trapHashRef->{'trapIfIndex'} );

        #}
    } else {
        $logger->debug("trap currently not handled");
        $trapHashRef->{'trapType'} = 'unknown';
    }
    return $trapHashRef;
}

sub getTrunkPorts {
    my ($this) = @_;
    my $OID_rcVlanPortType = '1.3.6.1.4.1.2272.1.3.3.1.4';    #RC-VLAN-MIB
    my @trunkPorts;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    if ( !$this->connectRead() ) {
        return -1;
    }
    $logger->trace("SNMP get_table for rcVlanPortType: $OID_rcVlanPortType");
    my $result
        = $this->{_sessionRead}->get_table( -baseoid => $OID_rcVlanPortType );
    if ( defined($result) ) {
        foreach my $key ( keys %{$result} ) {
            if ( $result->{$key} == 2 ) {
                $key =~ /^$OID_rcVlanPortType\.(\d+)$/;
                push @trunkPorts, $1;
                $logger->info( "Switch " . $this->{_ip} . " trunk port: $1" );
            }
        }
    } else {
        $logger->warn( "Problem while reading rcVlanPortType for switch "
                . $this->{_ip} );
        return -1;
    }
    return @trunkPorts;
}

sub getUpLinks {
    my ($this) = @_;
    my @upLinks;

    if ( lc(@{ $this->{_uplink} }[0]) eq 'dynamic' ) {
        @upLinks = $this->getTrunkPorts();
    } else {
        @upLinks = @{ $this->{_uplink} };
    }
    return @upLinks;
}

sub getVoiceVlan {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    return ( $this->{_voiceVlan} || -1 );
}

sub getVlans {
    my $this           = shift;
    my $logger         = Log::Log4perl::get_logger( ref($this) );
    my $OID_rcVlanName = '1.3.6.1.4.1.2272.1.3.2.1.2';            #RC-VLAN-MIB
    my $vlans          = {};
    if ( !$this->connectRead() ) {
        return $vlans;
    }

    $logger->trace("SNMP get_table for rcVlanName: $OID_rcVlanName");
    my $result
        = $this->{_sessionRead}->get_table( -baseoid => $OID_rcVlanName );

    if ( defined($result) ) {
        foreach my $key ( keys %{$result} ) {
            $key =~ /^$OID_rcVlanName\.(\d+)$/;
            $vlans->{$1} = $result->{$key};
        }
    }
    return $vlans;

}

sub isDefinedVlan {
    my ( $this, $vlan ) = @_;
    my $logger         = Log::Log4perl::get_logger( ref($this) );
    my $OID_rcVlanName = '1.3.6.1.4.1.2272.1.3.2.1.2';            #RC-VLAN-MIB
    if ( !$this->connectRead() ) {
        return 0;
    }

    $logger->trace("SNMP get_request for rcVlanName: $OID_rcVlanName.$vlan");
    my $result = $this->{_sessionRead}
        ->get_request( -varbindlist => ["$OID_rcVlanName.$vlan"] );

    return (   defined($result)
            && exists( $result->{"$OID_rcVlanName.$vlan"} )
            && ( $result->{"$OID_rcVlanName.$vlan"} ne 'noSuchInstance' ) );
}

sub getAllVlans {
    my ( $this, @ifIndexes ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my $vlanHashRef;
    if ( !@ifIndexes ) {
        @ifIndexes = $this->getManagedIfIndexes();
    }

    my $OID_rcVlanPortDefaultVlanId
        = '1.3.6.1.4.1.2272.1.3.3.1.7';    # RC-VLAN-MIB
    if ( !$this->connectRead() ) {
        return $vlanHashRef;
    }
    $logger->trace(
        "SNMP get_table for rcVlanPortDefaultVlanId: $OID_rcVlanPortDefaultVlanId"
    );
    my $result = $this->{_sessionRead}
        ->get_table( -baseoid => $OID_rcVlanPortDefaultVlanId );
    foreach my $key ( keys %{$result} ) {
        my $vlan = $result->{$key};
        $key =~ /^$OID_rcVlanPortDefaultVlanId\.(\d+)$/;
        my $ifIndex = $1;
        if ( grep( { $_ == $ifIndex } @ifIndexes ) > 0 ) {
            $vlanHashRef->{$ifIndex} = $vlan;
        }
    }
    return $vlanHashRef;
}

sub getVlan {
    my ( $this, $ifIndex ) = @_;
    my $OID_rcVlanPortDefaultVlanId
        = '1.3.6.1.4.1.2272.1.3.3.1.7';    # RC-VLAN-MIB
    my $logger = Log::Log4perl::get_logger( ref($this) );
    if ( !$this->connectRead() ) {
        return 0;
    }
    $logger->trace(
        "SNMP get_request for rcVlanPortDefaultVlanId: $OID_rcVlanPortDefaultVlanId.$ifIndex"
    );
    my $result = $this->{_sessionRead}->get_request(
        -varbindlist => ["$OID_rcVlanPortDefaultVlanId.$ifIndex"] );
    return $result->{"$OID_rcVlanPortDefaultVlanId.$ifIndex"};
}

sub _setVlan {
    my ( $this, $ifIndex, $newVlan, $oldVlan, $switch_locker_ref ) = @_;
    my $OID_rcVlanPortMembers = '1.3.6.1.4.1.2272.1.3.2.1.11';    #RC-VLAN-MIB
    my $OID_rcVlanPortDefaultVlanId
        = '1.3.6.1.4.1.2272.1.3.3.1.7';                           #RC-VLAN-MIB
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my $result;

    if ( !$this->connectRead() ) {
        return 0;
    }
    if ( !$this->connectWrite() ) {
        return 0;
    }

    $logger->trace( "locking - trying to lock \$switch_locker{"
            . $this->{_ip}
            . "} in _setVlan" );
    {
        lock %{ $switch_locker_ref->{ $this->{_ip} } };
        $logger->trace( "locking - \$switch_locker{"
                . $this->{_ip}
                . "} locked in _setVlan" );
        $this->{_sessionRead}->translate(0);
        $logger->trace("SNMP get_request for rcVlanPortMembers");
        $result = $this->{_sessionRead}->get_request(
            -varbindlist => [
                "$OID_rcVlanPortMembers.$oldVlan",
                "$OID_rcVlanPortMembers.$newVlan"
            ]
        );
        my $oldPortMembers
            = $this->modifyBitmask(
            $result->{"$OID_rcVlanPortMembers.$oldVlan"},
            $ifIndex, 0 );
        my $newPortMembers
            = $this->modifyBitmask(
            $result->{"$OID_rcVlanPortMembers.$newVlan"},
            $ifIndex, 1 );
        $this->{_sessionRead}->translate(1);

        $logger->trace(
            "SNMP set_request for OID_rcVlanPortMembers: $OID_rcVlanPortMembers"
        );
        $result = $this->{_sessionWrite}->set_request(
            -varbindlist => [
                "$OID_rcVlanPortMembers.$newVlan",
                Net::SNMP::OCTET_STRING,
                $newPortMembers,
                "$OID_rcVlanPortMembers.$oldVlan",
                Net::SNMP::OCTET_STRING,
                $oldPortMembers,
                "$OID_rcVlanPortDefaultVlanId.$ifIndex",
                Net::SNMP::INTEGER,
                $newVlan
            ]
        );
    }
    $logger->trace( "locking - \$switch_locker{"
            . $this->{_ip}
            . "} unlocked in _setVlan" );
    return ( defined($result) );
}

sub getBoardPortFromIfIndex {
    my ( $this, $ifIndex ) = @_;

    # return (board,port)
    return ( ( 1 + int( $ifIndex / 64 ) ), ( $ifIndex % 64 ) );
}

sub getIfIndexFromBoardPort {
    my ( $this, $board, $port ) = @_;
    return ( ( $board - 1 ) * 64 + $port );
}

sub getAllSecureMacAddresses {
    my ($this) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my $OID_s5SbsAuthCfgAccessCtrlType
        = '1.3.6.1.4.1.45.1.6.5.3.10.1.4';    #S5-SWITCH-BAYSECURE-MIB

    my $secureMacAddrHashRef = {};
    if ( !$this->connectRead() ) {
        return $secureMacAddrHashRef;
    }
    my $result = $this->{_sessionRead}
        ->get_table( -baseoid => "$OID_s5SbsAuthCfgAccessCtrlType" );
    while ( my ( $oid_including_mac, $ctrlType ) = each( %{$result} ) ) {
        if ((   $oid_including_mac
                =~ /^$OID_s5SbsAuthCfgAccessCtrlType\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/
            )
            && ( $ctrlType == 1 )
            )
        {
            my $boardIndx = $1;
            my $portIndx  = $2;
            my $ifIndex
                = $this->getIfIndexFromBoardPort( $boardIndx, $portIndx );
            my $oldMac = sprintf( "%02x:%02x:%02x:%02x:%02x:%02x",
                $3, $4, $5, $6, $7, $8 );
            push @{ $secureMacAddrHashRef->{$oldMac}->{$ifIndex} },
                $this->getVlan($ifIndex);
        }
    }

    return $secureMacAddrHashRef;
}

sub getSecureMacAddresses {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my $OID_s5SbsAuthCfgAccessCtrlType
        = '1.3.6.1.4.1.45.1.6.5.3.10.1.4';    #S5-SWITCH-BAYSECURE-MIB

    my ( $boardIndx, $portIndx ) = $this->getBoardPortFromIfIndex($ifIndex);
    my $secureMacAddrHashRef = {};
    if ( !$this->connectRead() ) {
        return $secureMacAddrHashRef;
    }

    my $oldVlan = $this->getVlan($ifIndex);

    $logger->trace(
        "SNMP get_table for s5SbsAuthCfgAccessCtrlType: $OID_s5SbsAuthCfgAccessCtrlType.$boardIndx.$portIndx"
    );
    my $result = $this->{_sessionRead}->get_table(
        -baseoid => "$OID_s5SbsAuthCfgAccessCtrlType.$boardIndx.$portIndx" );
    while ( my ( $oid_including_mac, $ctrlType ) = each( %{$result} ) ) {
        if ((   $oid_including_mac
                =~ /^$OID_s5SbsAuthCfgAccessCtrlType\.$boardIndx\.$portIndx\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/
            )
            && ( $ctrlType == 1 )
            )
        {
            my $oldMac = sprintf( "%02x:%02x:%02x:%02x:%02x:%02x",
                $1, $2, $3, $4, $5, $6 );
            push @{ $secureMacAddrHashRef->{$oldMac} }, $oldVlan;
        }
    }

    return $secureMacAddrHashRef;
}

sub getMaxMacAddresses {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    #so that everything runs like on a Cisco
    return 2;
}

sub authorizeMAC {
    my ( $this, $ifIndex, $deauthMac, $authMac, $deauthVlan, $authVlan ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    if ( ($deauthMac) && ( !$this->isFakeMac($deauthMac) ) ) {
        $this->_authorizeMAC( $ifIndex, $deauthMac, 0 );
    }
    if ( ($authMac) && ( !$this->isFakeMac($authMac) ) ) {
        $this->_authorizeMAC( $ifIndex, $authMac, 1 );
    }
    return 1;
}

#called with $authorized set to true, creates a new line to authorize the MAC
#when $authorized is set to false, deletes an existing line
sub _authorizeMAC {
    my ( $this, $ifIndex, $MACHexString, $authorize ) = @_;

    #my $OID_s5SbsAuthCfgBrdIndx = '1.3.6.1.4.1.45.1.6.5.3.10.1.1';
    #my $OID_s5SbsAuthCfgPortIndx = '1.3.6.1.4.1.45.1.6.5.3.10.1.2';
    #my $OID_s5SbsAuthCfgMACIndx = '1.3.6.1.4.1.45.1.6.5.3.10.1.3';
    my $OID_s5SbsAuthCfgAccessCtrlType = '1.3.6.1.4.1.45.1.6.5.3.10.1.4';
    my $OID_s5SbsAuthCfgStatus         = '1.3.6.1.4.1.45.1.6.5.3.10.1.5';

    #my $OID_s5SbsAuthCfgSecureList = '1.3.6.1.4.1.45.1.6.5.3.10.1.6';
    my $logger = Log::Log4perl::get_logger( ref($this) );

    if ( !$this->isProductionMode() ) {
        $logger->info(
            "not in production mode ... we won't delete an entry from the SecureMacAddrTable"
        );
        return 1;
    }

    my ( $boardIndx, $portIndx ) = $this->getBoardPortFromIfIndex($ifIndex);

    my $cfgStatus = ($authorize) ? 2 : 3;

    #convert MAC into decimal
    #TODO extract this logic into a MAC2OID sub in util
    my @MACArray = split( /:/, $MACHexString );
    my $MACDecString = '';
    foreach my $hexPiece (@MACArray) {
        if ( $MACDecString ne '' ) {
            $MACDecString .= ".";
        }
        $MACDecString .= hex($hexPiece);
    }

    if ( !$this->connectWrite() ) {
        return 0;
    }
    my $result;

    if ($authorize) {
        $logger->trace(
            "SNMP set_request for s5SbsAuthCfgAccessCtrlType: $OID_s5SbsAuthCfgAccessCtrlType"
        );
        $result = $this->{_sessionWrite}->set_request(
            -varbindlist => [
                "$OID_s5SbsAuthCfgAccessCtrlType.$boardIndx.$portIndx.$MACDecString",
                Net::SNMP::INTEGER,
                1,
                "$OID_s5SbsAuthCfgStatus.$boardIndx.$portIndx.$MACDecString",
                Net::SNMP::INTEGER,
                $cfgStatus
            ]
        );
    } else {
        $logger->trace(
            "SNMP set_request for s5SbsAuthCfgStatus: $OID_s5SbsAuthCfgStatus"
        );
        $result = $this->{_sessionWrite}->set_request(
            -varbindlist => [
                "$OID_s5SbsAuthCfgStatus.$boardIndx.$portIndx.$MACDecString",
                Net::SNMP::INTEGER,
                $cfgStatus
            ]
        );
    }

    return ( defined($result) );
}

sub isDynamicPortSecurityEnabled {
    my ( $this, $ifIndex ) = @_;
    return 0;
}

sub isStaticPortSecurityEnabled {
    my ( $this, $ifIndex ) = @_;
    return 1;
}

sub setPortSecurityEnableByIfIndex {
    my ( $this, $ifIndex, $trueFalse ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    $logger->info("function not implemented yet");
    return 1;
}

sub isPortSecurityEnabled {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    my $oid_s5SbsSecurityStatus         = '1.3.6.1.4.1.45.1.6.5.3.3';
    my $oid_s5SbsSecurityAction         = '1.3.6.1.4.1.45.1.6.5.3.5';
    my $oid_s5SbsCurrentPortSecurStatus = '1.3.6.1.4.1.45.1.6.5.3.11.1.6';

    my ( $boardIndx, $portIndx ) = $this->getBoardPortFromIfIndex($ifIndex);

    my $s5SbsSecurityStatus         = undef;
    my $s5SbsSecurityAction         = undef;
    my $s5SbsCurrentPortSecurStatus = undef;

    if ( !$this->connectRead() ) {
        return 0;
    }

    $logger->trace(
        "SNMP get_next_request for s5SbsSecurityStatus: $oid_s5SbsSecurityStatus and s5SbsSecurityAction: $oid_s5SbsSecurityAction"
    );
    my $result = $this->{_sessionRead}->get_next_request( -varbindlist =>
            [ "$oid_s5SbsSecurityStatus", "$oid_s5SbsSecurityAction" ] );
    foreach my $oid ( keys %{$result} ) {
        if ( $oid =~ /^$oid_s5SbsSecurityStatus/ ) {
            $s5SbsSecurityStatus = $result->{$oid};
        } elsif ( $oid =~ /^$oid_s5SbsSecurityAction/ ) {
            $s5SbsSecurityAction = $result->{$oid};
            if ( $s5SbsSecurityAction == 2 ) {
                $logger->warn(
                    "s5SbsSecurityAction is 2 (trap) ... should be 6 (filter and trap)"
                );
            }
        }
    }

    $logger->trace(
        "SNMP get_request for s5SbsCurrentPortSecurStatus: $oid_s5SbsCurrentPortSecurStatus"
    );
    $result = $this->{_sessionRead}->get_request(
        -varbindlist => [
            "$oid_s5SbsCurrentPortSecurStatus.$boardIndx.$portIndx.0.0.0.0.0.0"
        ]
    );
    foreach my $oid ( keys %{$result} ) {
        if ( $oid
            =~ /^${oid_s5SbsCurrentPortSecurStatus}\.${boardIndx}\.${portIndx}\.0\.0\.0\.0\.0\.0/
            )
        {
            $s5SbsCurrentPortSecurStatus = $result->{$oid};
        }
    }

    return (
               defined($s5SbsSecurityStatus)
            && $s5SbsSecurityStatus == 1
            && defined($s5SbsSecurityAction)
            && ( $s5SbsSecurityAction == 6 || $s5SbsSecurityAction == 2 )
            && ( ( !defined($s5SbsCurrentPortSecurStatus) )
            || ( $s5SbsCurrentPortSecurStatus >= 2 ) )
    );
}

sub getPhonesDPAtIfIndex {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my @phones;
    if ( !$this->isVoIPEnabled() ) {
        $logger->debug( "VoIP not enabled on switch "
                . $this->{_ip}
                . ". getPhonesDPAtIfIndex will return empty list." );
        return @phones;
    }
    return $this->getPhonesLLDPAtIfIndex($ifIndex);
}

sub getPhonesLLDPAtIfIndex {
    my ( $this, $ifIndex ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my @phones;
    if ( !$this->isVoIPEnabled() ) {
        $logger->debug( "VoIP not enabled on switch "
                . $this->{_ip}
                . ". getPhonesLLDPAtIfIndex will return empty list." );
        return @phones;
    }
    my $oid_lldpRemPortId  = '1.0.8802.1.1.2.1.4.1.1.7';
    my $oid_lldpRemSysDesc = '1.0.8802.1.1.2.1.4.1.1.10';

    if ( !$this->connectRead() ) {
        return @phones;
    }
    $logger->trace(
        "SNMP get_next_request for lldpRemSysDesc: $oid_lldpRemSysDesc");
    my $result = $this->{_sessionRead}
        ->get_next_request( -varbindlist => ["$oid_lldpRemSysDesc"] );
    foreach my $oid ( keys %{$result} ) {
        if ( $oid =~ /^$oid_lldpRemSysDesc\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) {
            if ( $ifIndex eq $2 ) {
                my $cache_lldpRemTimeMark     = $1;
                my $cache_lldpRemLocalPortNum = $2;
                my $cache_lldpRemIndex        = $3;
                if ( $result->{$oid} =~ /^Nortel IP Telephone/ ) {
                    $logger->trace(
                        "SNMP get_request for lldpRemPortId: $oid_lldpRemPortId.$cache_lldpRemTimeMark.$cache_lldpRemLocalPortNum.$cache_lldpRemIndex"
                    );
                    my $MACresult = $this->{_sessionRead}->get_request(
                        -varbindlist => [
                            "$oid_lldpRemPortId.$cache_lldpRemTimeMark.$cache_lldpRemLocalPortNum.$cache_lldpRemIndex"
                        ]
                    );
                    if ($MACresult
                        && ($MACresult->{
                                "$oid_lldpRemPortId.$cache_lldpRemTimeMark.$cache_lldpRemLocalPortNum.$cache_lldpRemIndex"
                            }
                            =~ /^0x([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})$/i
                        )
                        )
                    {
                        push @phones, lc("$1:$2:$3:$4:$5:$6");
                    }
                }
            }
        }
    }
    return @phones;
}

sub isVoIPEnabled {
    my ($this) = @_;
    return ( $this->{_VoIPEnabled} == 1 );
}

=head1 AUTHOR

Regis Balzard <rbalzard@inverse.ca>

Dominik Gehl <dgehl@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2007-2008 Inverse inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
