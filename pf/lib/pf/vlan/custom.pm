package pf::vlan::custom;

=head1 NAME

pf::vlan::custom - Object oriented module for VLAN isolation oriented functions 

=head1 SYNOPSIS

The pf::vlan::custom module implements VLAN isolation oriented functions that are custom 
to a particular setup.

This module extends pf::vlan

=cut

use strict;
use warnings;
use diagnostics;
use Log::Log4perl;

use base ('pf::vlan');

=head1 AUTHOR

Dominik Gehl <dgehl@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Inverse inc.

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
