package pf::Authentication::Source::GoogleSource;

=head1 NAME

pf::Authentication::Source::GoogleSource

=head1 DESCRIPTION

=cut

use Moose;
extends 'pf::Authentication::Source';

has '+type' => (default => 'Google');
has '+unique' => (default => 1);
has 'client_id' => (isa => 'Str', is => 'rw', required => 1, default => 'YOUR_API_ID.apps.googleusercontent.com');
has 'client_secret' => (isa => 'Str', is => 'rw', required => 1);
has 'site' => (isa => 'Str', is => 'rw', default => 'https://accounts.google.com');
has 'authorize_path' => (isa => 'Str', is => 'rw', default => '/o/oauth2/auth');
has 'access_token_path' => (isa => 'Str', is => 'rw', default => '/o/oauth2/token');
has 'access_token_param' => (isa => 'Str', is => 'rw', default => 'oauth_token');
has 'scope' => (isa => 'Str', is => 'rw', default => 'https://www.googleapis.com/auth/userinfo.email');
has 'protected_resource_url' => (isa => 'Str', is => 'rw', default => 'https://www.googleapis.com/oauth2/v2/userinfo');
has 'redirect_url' => (isa => 'Str', is => 'rw', required => 1, default => 'https://<hostname>/oauth2/google');

=back

=head1 COPYRIGHT

Copyright (C) 2012 Inverse inc.

=head1 LICENSE 

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

__PACKAGE__->meta->make_immutable;
1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start: