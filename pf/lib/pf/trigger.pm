package pf::trigger;

=head1 NAME

pf::trigger - module to manage the triggers related to the violations or
the Nessus scans (if enabled).

=cut

=head1 DESCRIPTION

pf::trigger contains the functions necessary to manage the different 
triggers related to the violations or the Nessus scans.

=head1 CONFIGURATION AND ENVIRONMENT

Read the F<pf.conf> configuration file.

=cut

use strict;
use warnings;
use Log::Log4perl;

use constant TRIGGER => 'trigger';

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );
    @ISA = qw(Exporter);
    @EXPORT = qw(
        trigger_db_prepare
        $trigger_db_prepared
        
        trigger_view
        trigger_view_enable
        trigger_view_all
        trigger_delete_all
        trigger_in_range
        trigger_add
        trigger_view_type
        trigger_view_tid
    );
}

use pf::config;
use pf::db;
use pf::util;
use pf::violation qw(violation_trigger violation_add);
use pf::iplog qw(ip2mac);

# The next two variables and the _prepare sub are required for database handling magic (see pf::db)
our $trigger_db_prepared = 0;
# in this hash reference we hold the database statements. We pass it to the query handler and he will repopulate
# the hash if required
our $trigger_statements = {};

=head1 SUBROUTINES

This list is incomplete.
        
=over   
        
=cut    

sub trigger_db_prepare {
    my $logger = Log::Log4perl::get_logger('pf::trigger');
    $logger->debug("Preparing pf::trigger database queries");

    $trigger_statements->{'trigger_desc_sql'} = get_db_handle()->prepare(qq [ desc `trigger` ]);

    $trigger_statements->{'trigger_view_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,type,description from `trigger`,class where class.vid=`trigger`.vid and tid_start<=? and tid_end>=? and type=?]);

    $trigger_statements->{'trigger_view_enable_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,type,whitelisted_categories from `trigger`,class where class.vid=`trigger`.vid and tid_start<=? and tid_end>=? and type=? and disable="N" ]
    );

    $trigger_statements->{'trigger_view_vid_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,description from `trigger`,class where class.vid=`trigger`.vid and class.vid=?]);

    $trigger_statements->{'trigger_view_tid_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,type,description from `trigger`,class where class.vid=`trigger`.vid and tid_start<=? and tid_end>=? ]);

    $trigger_statements->{'trigger_view_all_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,type,description from `trigger`,class where class.vid=`trigger`.vid ]);

    $trigger_statements->{'trigger_view_type_sql'} = get_db_handle()->prepare(
        qq[ select tid_start,tid_end,class.vid,type,description from `trigger`,class where class.vid=`trigger`.vid and type=?]);

    $trigger_statements->{'trigger_exist_sql'} = get_db_handle()->prepare(
        qq [ select vid,tid_start,tid_end,type,whitelisted_categories from `trigger` where vid=? and tid_start<=? and tid_end>=? and type=? and whitelisted_categories=? ]
   );

    $trigger_statements->{'trigger_add_sql'} = get_db_handle()->prepare(
        qq [ insert into `trigger`(vid,tid_start,tid_end,type,whitelisted_categories) values(?,?,?,?,?) ]
    );

    $trigger_statements->{'trigger_delete_vid_sql'} = get_db_handle()->prepare(qq [ delete from `trigger` where vid=? ]);

    $trigger_statements->{'trigger_delete_all_sql'} = get_db_handle()->prepare(qq [ delete from `trigger` ]);

    $trigger_db_prepared = 1;
    return 1;
}

sub trigger_desc {
    return db_data(TRIGGER, $trigger_statements, 'trigger_desc_sql');
}

sub trigger_view {
    my ( $tid, %type ) = @_;
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_sql', $tid, $tid, $type{type});
}

sub trigger_view_enable {
    my ( $tid, $type ) = @_;
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_enable_sql', $tid, $tid, $type);
}

sub trigger_view_vid {
    my ($vid) = @_;
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_vid_sql', $vid);
}

sub trigger_view_tid {
    my ($tid) = @_;
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_tid_sql', $tid, $tid);
}

sub trigger_view_all {
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_all_sql');
}

sub trigger_view_type {
    my ($type) = @_;
    return db_data(TRIGGER, $trigger_statements, 'trigger_view_type_sql', $type);
}

sub trigger_delete_vid {
    my ($vid) = @_;
    my $logger = Log::Log4perl::get_logger('pf::trigger');

    db_query_execute(TRIGGER, $trigger_statements, 'trigger_delete_vid_sql', $vid) || return (0);
    $logger->debug("triggers vid $vid deleted");
    return (1);
}

sub trigger_delete_all {
    my $logger = Log::Log4perl::get_logger('pf::trigger');
    db_query_execute(TRIGGER, $trigger_statements, 'trigger_delete_all_sql') || return (0);
    $logger->debug("All triggers deleted");
    return (1);
}

sub trigger_exist {
    my ($vid, $tid_start, $tid_end, $type, $whitelisted_categories) = @_;

    my $query = db_query_execute(TRIGGER, $trigger_statements, 'trigger_exist_sql', 
        $vid, $tid_start, $tid_end, $type, $whitelisted_categories)
        || return (0);
    my ($val) = $query->fetchrow_array();
    $query->finish();
    return ($val);
}

#
# clean input parameters and add to trigger table
#
sub trigger_add {
    my ($vid, $tid_start, $tid_end, $type, $whitelisted_categories) = @_;
    my $logger = Log::Log4perl::get_logger('pf::trigger');
    if ( trigger_exist( $vid, $tid_start, $tid_end, $type, $whitelisted_categories) ) {
        $logger->error(
            "attempt to add existing trigger $tid_start $tid_end [$type]");
        return (2);
    }
    db_query_execute(TRIGGER, $trigger_statements, 'trigger_add_sql', 
        $vid, $tid_start, $tid_end, $type, $whitelisted_categories)
        || return (0);
    $logger->debug("trigger $tid_start $tid_end added");
    return (1);
}

sub trigger_in_range {
    my ( $range, $trigger ) = @_;
    foreach my $element ( split( /\s*,\s*/, $range ) ) {
        if ( $element eq $trigger ) {
            return (1);
        } elsif ( $element =~ /^\d+\s*\-\s*\d+$/ ) {
            my ( $begin, $end ) = split( /\s*\-\s*/, $element );
            if ( $trigger >= $begin && $trigger <= $end ) {
                return (1);
            }
        } else {
            return (0);
        }
    }
    return;
}

=back

=head1 AUTHOR

David LaPorte <david@davidlaporte.org>

Kevin Amorin <kev@amorin.org>

Dominik Gehl <dgehl@inverse.ca>

Olivier Bilodeau <obilodeau@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005 David LaPorte

Copyright (C) 2005 Kevin Amorin

Copyright (C) 2009,2010 Inverse inc.

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
