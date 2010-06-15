package pf::pfcmd;

=head1 NAME

pf::pfcmd - module for the PacketFence command line interface.

=cut

=head1 DESCRIPTION

pf::pfcmd contains the functions necessary for the command line interface
F</usr/local/pf/bin/pfcmd> to parse the options.

=cut

use strict;
use warnings;
use diagnostics;

use Log::Log4perl;
use Regexp::Common qw(net);

sub parseCommandLine {
    my ($commandLine) = @_;
    my $logger = Log::Log4perl::get_logger("pf::pfcmd");
    $logger->debug("starting to parse '$commandLine'");

    $commandLine =~ s/\s+$//;
    my ($main, $params) = split( / +/, $commandLine, 2 );
    #make sure params contains at least an empty string
    $params = '' if (! defined($params));

    my %regexp = (
        'class'           => qr{ ^ (view) \s+ ( all | \d+ ) $ }xms,
        'config'          => qr{ ^ ( get | set | help )
                                   \s+
                                   ( [ a-zA-Z0-9_@\.\:=/\-,?]+)
                                 $ }xms,
        'configfiles'     => qr{ ^ ( push | pull ) $ }xms,
        'fingerprint'     => qr{ ^ (view) 
                                   \s+ 
                                   ( all | \d+ (?: ,\d+)* ) 
                                 $ }xms,
        'floatingnetworkdeviceconfig'
                          => qr/ ^ ( get | delete )
                                   \s+
                                   ( all | $RE{net}{MAC} | stub )
                                 $  /xms,
        'graph'           => qr/ ^ (?:
                                     ( nodes | registered
                                       | unregistered
                                       | violations ) 
                                     (?:
                                       \s+
                                       ( day | month | year )
                                     )?
                                     |
                                     ( ifoctetshistorymac )
                                     \s+
                                     ( $RE{net}{MAC} )
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )
                                     \s* [,] \s*
                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                     |
                                     ( ifoctetshistoryswitch )
                                     \s+
                                     ( $RE{net}{IPv4} )
                                     \s+
                                     ( \d+)
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )
                                     \s* [,] \s*
                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                     |
                                     ( ifoctetshistoryuser )
                                     \s+
                                     ( [a-zA-Z0-9\-\_\.\@]+ )
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )
                                     \s* [,] \s*
                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                   )
                                 $ /xms,
        'help'            => qr{ ^ ( [a-z]* ) $ }xms,
        'history'         => qr/ ^
                                   ( $RE{net}{IPv4} | $RE{net}{MAC} )
                                   (?:
                                     \s+
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'ifoctetshistorymac' => qr/ ^
                                   ( $RE{net}{MAC} )
                                   (?:
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )

                                     \s* [,] \s*

                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'ifoctetshistoryswitch' => qr/ ^
                                   ( $RE{net}{IPv4} )
                                   \s+
                                   ( \d+)
                                   (?:
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )

                                     \s* [,] \s*

                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'ifoctetshistoryuser' => qr{ ^
                                   ( [a-zA-Z0-9\-\_\.\@]+ )
                                   (?:
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )

                                     \s* [,] \s*

                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                   )?
                                 $ }xms,
        'interfaceconfig' => qr{ ^ ( get | delete )
                                   \s+
                                   ( all | [a-z0-9\.\:]+ )
                                 $  }xms,
        'ipmachistory'    => qr/ ^
                                   ( $RE{net}{IPv4} | $RE{net}{MAC} )
                                   (?:
                                     \s+
                                     start_time \s* [=] \s*
                                     ( [^,=]+ )

                                     \s* [,] \s*

                                     end_time \s* [=] \s*
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'locationhistorymac' => qr/ ^
                                   ( $RE{net}{MAC} )
                                   (?:
                                     \s+
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'locationhistoryswitch' => qr/ ^
                                   ( $RE{net}{IPv4} )
                                   \s+
                                   ( \d+ )
                                   (?:
                                     \s+
                                     ( [^,=]+ )
                                   )?
                                 $ /xms,
        'lookup'          => qr{ ^ ( person | node ) 
                                   \s+
                                   ( [0-9a-zA-Z_\-\.\:@]+ )
                                 $  }xms,
        'manage'          => qr/ ^ 
                                   (?:
                                     ( freemac | deregister )
                                     \s+
                                     ( $RE{net}{MAC} )
                                     |
                                     ( vclose | vopen )
                                     \s+
                                     ( $RE{net}{MAC} )
                                     \s+
                                     ( \d+ )
                                   )
                                 $ /xms,
        'networkconfig'   => qr/ ^ ( get | delete )
                                   \s+
                                   ( all | $RE{net}{IPv4} )
                                 $  /xms,
        'node'            => qr/ ^ (?:
                                     ( view )
                                     \s+
                                     (?: 
                                         (all) 
                                       | ($RE{net}{MAC}) 
                                       | ( category | pid )
                                         \s* [=] \s*
                                         ( [0-9a-zA-Z_\-\.\:]+ )
                                     )
                                     (?:
                                       \s+ ( order ) \s+ ( by )
                                       \s+ ( [a-z_]+ )
                                       (?: \s+ ( asc | desc ))?
                                     )?
                                     (?:
                                       \s+ ( limit )
                                       \s+ ( \d+ )
                                       \s* [,] \s*
                                       ( \d+ )
                                     )?
                                     |
                                     ( count )
                                     \s+
                                     (?:   ( all )
                                         | ( $RE{net}{MAC} )
                                         | ( category | pid )
                                           \s* [=] \s*
                                           ( [0-9a-zA-Z_\-\.\:]+ )
                                     )
                                     |
                                     ( delete )
                                     \s+ ( $RE{net}{MAC} )
                                   )
                                 $ /xms,
        'nodecategory'    => qr{ ^ (?:
                                     (view) \s+ (all|\d+)
                                   )
                                   |
                                   (?:
                                     (delete) \s+ (\s+)
                                   )
                                 $  }xms,
        'person'          => qr{ ^ (view)
                                   \s+
                                   ( [a-zA-Z0-9\-\_\.\@]+ )
                                 $ }xms,
        'reload'          => qr{ ^ ( fingerprints | violations ) $  }xms,
        'report'          => qr{ ^ (?: #for grouping only
                                     ( active | inactive | openviolations 
                                       | os | osclass | registered | statics 
                                       | unknownprints | unregistered )
                                     |
                                     (?: #for grouping only
                                       ( openviolations | os | osclass 
                                         | registered | statics
                                         | unknownprints | unregistered 
                                       )
                                       \s+
                                       ( all | active )
                                     )
                                   )
                                 $  }xms,
        'schedule'        => qr{ ^ (?:
                                     ( view )
                                     \s+
                                     ( all | \d+ )
                                     |
                                     ( delete )
                                     \s+
                                     ( \d+ )
                                   )
                                 $ }xms,
        'service'         => qr{ ^ ( dhcpd | httpd | named | pfdetect 
                                     | pf | pfdhcplistener | pfmon 
                                     | pfredirect | pfsetvlan | snmptrapd 
                                     | snort )
                                   \s+
                                   ( restart | start | status | stop
                                     | watch )
                                 $  }xms,
        'switchconfig'    => qr/ ^ ( get | delete ) 
                                   \s+
                                   ( all | default | $RE{net}{IPv4} )
                                 $  /xms,
        'switchlocation'  => qr/ ^ ( view )
                                   \s+
                                   ($RE{net}{IPv4})
                                   \s+
                                   (\d+)
                                 $  /xms,
        'traplog'         => qr{ ^ (?:
                                     ( update )
                                     |
                                     (?:
                                       most \s+
                                       ( \d+ ) \s+
                                       ( day | week | total )
                                     )
                                   )
                                 $ }xms,
        'trigger'         => qr{ ^ ( view ) 
                                   \s+
                                   ( all | \d+ )
                                   (?:
                                     \s+
                                     ( scan | detect )
                                   )?
                                 $ }xms,
        'ui'              => qr{ ^ 
                                   (?:
                                     (?:
                                       ( dashboard )
                                       \s+
                                       ( current_grace | current_activity 
                                         | current_node_status )
                                     )
                                     |
                                     (?:
                                       ( dashboard )
                                       \s+
                                       ( recent_violations_opened
                                         | recent_violations_closed
                                         | recent_violations
                                         | recent_registrations )
                                       (?:
                                         \s+ ( \d+ )
                                       )?
                                     )
                                     |
                                     (?:
                                       ( menus )
                                       (?:
                                         \s+ file \s* [=] \s* 
                                         ( [a-zA-Z\-_.]+ )
                                       )?
                                     )
                                   )
                                 $  }xms,
        'update'          => qr{ ^ ( fingerprints | oui ) $  }xms,
        'version'         => qr{ ^ $ }xms,
        'violation'       => qr{ ^ ( view )
                                   \s+
                                   ( all | \d+ )
                                 $ }xms,
        'violationconfig' => qr{ ^ ( get | delete )
                                   \s+
                                   ( all | defaults | \d+ )
                                 $  }xms,
    );
    $logger->debug("main cmd argument is " . ($main || 'undefined'));
    if ( defined($main) && exists($regexp{$main}) ) {
        my %cmd;
        if ($params =~ $regexp{$main}) {
            $cmd{'command'}[0] = $main;
            push @{$cmd{'command'}}, $1 if (defined($1));
            push @{$cmd{'command'}}, $2 if (defined($2));
            push @{$cmd{'command'}}, $3 if (defined($3));
            push @{$cmd{'command'}}, $4 if (defined($4));
            push @{$cmd{'command'}}, $5 if (defined($5));
            push @{$cmd{'command'}}, $6 if (defined($6));
            push @{$cmd{'command'}}, $7 if (defined($7));
            push @{$cmd{'command'}}, $8 if (defined($8));
            push @{$cmd{'command'}}, $9 if (defined($9));
            push @{$cmd{'command'}}, $10 if (defined($10));
            push @{$cmd{'command'}}, $11 if (defined($11));
            push @{$cmd{'command'}}, $12 if (defined($12));
            push @{$cmd{'command'}}, $13 if (defined($13));
            push @{$cmd{'command'}}, $14 if (defined($14));
            push @{$cmd{'command'}}, $15 if (defined($15));
            push @{$cmd{'command'}}, $16 if (defined($16));
            push @{$cmd{'command'}}, $17 if (defined($17));
            push @{$cmd{'command'}}, $18 if (defined($18));
            push @{$cmd{'command'}}, $19 if (defined($19));
            push @{$cmd{'command'}}, $20 if (defined($20));
            if ($main eq 'manage') {
                push @{$cmd{'manage_options'}}, $cmd{'command'}[1];
                push @{$cmd{'manage_options'}}, $cmd{'command'}[2];
                push @{$cmd{'manage_options'}}, $cmd{'command'}[3] if ($cmd{'command'}[3]);
            }
            if ($main eq 'node') {
                push @{$cmd{'node_options'}}, $cmd{'command'}[1];
                push @{$cmd{'node_options'}}, $cmd{'command'}[2];
                if ($cmd{'command'}[1] eq 'view') {
                    if (defined($4)) {
                        push @{$cmd{'node_filter'}}, [$4, $5];
                    }
                    if (defined($6)) {
                        push @{$cmd{'orderby_options'}}, ($6, $7, $8, $9);
                    }
                    if (defined($10)) {
                        push @{$cmd{'limit_options'}}, ($10, $11, ',', $12);
                    }
                }
                if ($cmd{'command'}[1] eq 'count') {
                    if (defined($16)) {
                        push @{$cmd{'node_filter'}}, [$16, $17];
                    }
                }
            }
            if ($main eq 'nodecategory') {
                push @{$cmd{'nodecategory_options'}}, $cmd{'command'}[1];
                push @{$cmd{'nodecategory_options'}}, $cmd{'command'}[2];
            }
            if ($main eq 'person') {
                push @{$cmd{'person_options'}}, $cmd{'command'}[1];
                push @{$cmd{'person_options'}}, $cmd{'command'}[2];
            }
            if ($main eq 'schedule') {
                push @{$cmd{'schedule_options'}}, $cmd{'command'}[1];
                push @{$cmd{'schedule_options'}}, $cmd{'command'}[2];
            }
            if ($main eq 'violation') {
                push @{$cmd{'violation_options'}}, $cmd{'command'}[1];
                push @{$cmd{'violation_options'}}, $cmd{'command'}[2];
            }
        } else {
            if ($main =~ m{ ^ (?:
                            node | person | interfaceconfig | networkconfig
                            | switchconfig | violationconfig | violation
                            | manage | schedule | nodecategory
                            | floatingnetworkdeviceconfig
                              ) $ }xms ) {
                return parseWithGrammar($commandLine);
            }
            @{$cmd{'command'}} = ('help', $main);
        }
        return %cmd;
    }
    
    return parseWithGrammar($commandLine);
}


sub parseWithGrammar {
    my ($commandLine) = @_;
    require pf::pfcmd::pfcmd_pregrammar;
    import pf::pfcmd::pfcmd_pregrammar;
    my $parser = pfcmd_pregrammar->new();

    my $result = $parser->start($commandLine);
    my %cmd;
    $cmd{'grammar'} = ( defined($result) ? 1 : 0 );
    return %cmd;
}

=head1 AUTHOR

Dominik Gehl <dgehl@inverse.ca>

Olivier Bilodeau <obilodeau@inverse.ca>

Regis Balzard <rbalzard@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2009, 2010 Inverse inc.

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
