package pfappserver::Controller::Violation;

=head1 NAME

pfappserver::Controller::Violation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use strict;
use warnings;

use HTTP::Status qw(:constants is_error is_success);
use JSON;
use Moose;
use namespace::autoclean;
use POSIX;

use pf::config;
use pfappserver::Form::Violation;

BEGIN {extends 'Catalyst::Controller'; }

=head1 SUBROUTINES

=head2 auto

Allow only authenticated users

=cut

sub auto :Private {
    my ($self, $c) = @_;

    unless ($c->user_exists()) {
        $c->response->status(HTTP_UNAUTHORIZED);
        $c->response->location($c->uri_for($c->controller('Admin')->action_for('configuration'), 'violations'));
        $c->stash->{template} = 'admin/unauthorized.tt';
        $c->detach();
        return 0;
    }

    return 1;
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for($c->controller('Admin')->action_for('configuration'), ('violations')));
    $c->detach();
}

=head2 create

=cut

sub create :Local {
    my ($self, $c) = @_;

    my ($status, $result);

    $c->stash->{action_uri} = $c->uri_for($c->action);
    if ($c->request->method eq 'POST') {
        my $id = $c->req->params->{id};
        $c->forward('update', [$id]);
    }
    else {
        $c->stash->{template} = 'violation/read.tt';
        $c->forward('read');
    }
}

=head2 object

Violation controller dispatcher

=cut

sub object :Chained('/') :PathPart('violation') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my ($status, $result) = $c->model('Config::Violations')->read_violation($id);
    if (is_error($status)) {
        $c->response->status($status);
        $c->stash->{status_msg} = $c->loc($result);
        $c->stash->{current_view} = 'JSON';
        $c->detach();
    }
    else {
        $c->stash->{violation} = pop @$result;
    }
}

=head2 read

=cut

sub read :Chained('object') :PathPart('read') :Args(0) {
    my ($self, $c) = @_;

    my ($configViolationsModel, $status, $result);
    my ($form, $actions, $violations, $triggers);

    $configViolationsModel = $c->model('Config::Violations');
    ($status, $result) = $configViolationsModel->read_violation('all');
    if (is_success($status)) {
        $violations = $result;
    }
    $actions = $configViolationsModel->availableActions();
    $triggers = $configViolationsModel->list_triggers();
    $c->stash->{trigger_types} = $configViolationsModel->availableTriggerTypes();

    if ($c->stash->{violation} && !$c->stash->{action_uri}) {
        $c->stash->{action_uri} = $c->uri_for($self->action_for('update'), [$c->{stash}->{violation}->{id}]);
    }

    $form = pfappserver::Form::Violation->new(ctx => $c,
                                              init_object => $c->stash->{violation},
                                              actions => $actions,
                                              violations => $violations,
                                              triggers => $triggers);
    $form->process();
    $c->stash->{form} = $form;
}

=head2 update

=cut

sub update :Chained('object') :PathPart('update') :Args(0) {
    my ($self, $c) = @_;

    my ($status, $result);

    if ($c->request->method eq 'POST') {
        my ($form, $configViolationsModel, $actions, $violations, $triggers);

        $configViolationsModel = $c->model('Config::Violations');
        ($status, $result) = $configViolationsModel->read_violation('all');
        if (is_success($status)) {
            $violations = $result;
        }
        $actions = $configViolationsModel->availableActions();
        $triggers = $configViolationsModel->list_triggers();
        $form = pfappserver::Form::Violation->new(ctx => $c,
                                                  actions => $actions,
                                                  violations => $violations,
                                                  triggers => $triggers);
        $form->process(params => $c->req->params);
        if ($form->has_errors) {
            $status = HTTP_BAD_REQUEST;
            $result = $form->field_errors;
        }
        else {
            my $data = $form->value;
            ($status, $result) = $c->model('Config::Violations')->update({ $c->{stash}->{violation}->{id} => $data });
        }
        if (is_error($status)) {
            $c->response->status($status);
            $c->stash->{status_msg} = $result; # TODO: localize error message
        }
        $c->stash->{current_view} = 'JSON';
    }
    else {
        $c->stash->{template} = 'violation/read.tt';
        $c->forward('read');
    }
}

=head2 delete

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;

    my ($status, $result) = $c->model('Config::Violations')->delete_violation($c->stash->{violation}->{id});
    if (is_error($status)) {
        $c->response->status($status);
        $c->stash->{status_msg} = $c->loc($result);
    }

    $c->stash->{current_view} = 'JSON';
}

=head2 preview

Load the associated remediation page in an iframe.

=cut

sub preview :Chained('object') :PathPart('preview') :Args(0) {
    my ($self, $c) = @_;

}

=head2 demo

=cut

sub demo :Chained('object') :PathPart('demo') :Args(0) {
    my ($self, $c) = @_;

    # Create a fake session profile and render the template
    # as in pf::web::generate_violation_page

    my $url = sprintf('violations/%s.html', $c->stash->{violation}->{template});
    $c->stash->{sub_template} = $url;
    $c->stash->{logo} = $Config{'general'}{'logo'};

    $c->stash->{dhcp_fingerprint} = '1,28,2,3,15,6,119,12,44,47,26,121,42';
    $c->stash->{last_switch} = '10.0.0.4';
    $c->stash->{last_port} = '4097';
    $c->stash->{last_vlan} = '102';
    $c->stash->{last_connection_type} = 'Wireless-802.11-EAP';
    $c->stash->{last_ssid} = 'PacketFence-Secure';
    $c->stash->{username} = 'mcrispin';
    $c->stash->{list_help_info} = [{ name => $c->loc('IP'), value => '10.0.0.123' },
                                   { name => $c->loc('MAC'), value => 'c8:bc:c8:ce:65:e1' }];

    $c->stash->{additional_template_paths} = ['../captive-portal/templates/'];
    $c->stash->{template} = 'remediation.html';
}

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
