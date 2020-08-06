package App::wsgetmail;

use Moo;

our $VERSION = '0.03';

=head1 NAME

App::wsgetmail - Fetch mail from the cloud using webservices

=head1 VERSION

0.03

=head1 DESCRIPTION

A simple command line application/script to fetch mail from the cloud
using webservices instead of IMAP and POP.

Configurable to mark fetched mail as read, or to delete it, and with
configurable action with the fetched email.

=head1 SYNOPSIS

wsgetmail365 --configuration path/to/file.json [--debug] [ --dry-run]

=head1 CONFIGURATION

Configuration of the wsgetmail tool needs the following fields specific to the ms365 application:
Application (client) ID,
Directory (tenant) ID

For access to the email account you need:
Account email address
Account password
Folder (defaults to inbox, currently only one folder is supported)

For forwarding to RT via rt-mailgate you need :
RT URL
Path to rt-mailgate
Recipient address (usually same as account email address, could be a shared mailbox or alias)
action on fetching mail : either "mark_as_read" or "delete"

example configuration :
{
   "command": "/path/to/rt/bin/rt-mailgate",
   "command_args": "--url http://rt.example.tld/ --queue general --action correspond",
   "command_timeout": 15,
   "recipient":"rt@example.tld",
   "action_on_fetched":"mark_as_read",
   "username":"rt@example.tld",
   "user_password":"password",
   "tenant_id":"abcd1234-xxxx-xxxx-xxxx-123abcde1234",
   "client_id":"abcd1234-xxxx-xxxx-xxxx-1234abcdef99",
   "folder":"Inbox"
}

an example configuration file is included in the docs/ directory of this package

=cut

use Clone 'clone';
use Module::Load;
use App::wsgetmail::MDA;

has config => (
    is => 'ro',
    required => 1
);

has mda => (
    is => 'rw',
    lazy => 1,
    handles => [ qw(forward) ],
    builder => '_build_mda'
);


has client_class => (
    is => 'ro',
    default => sub { 'MS365' }
);

has client => (
    is => 'ro',
    lazy => 1,
    handles => [ qw( get_next_message
                     get_message_mime_content
                     mark_message_as_read
                     delete_message) ],
    builder => '_build_client'
);


has _post_fetch_action => (
    is => 'ro',
    lazy => 1,
    builder => '_build__post_fetch_action'
);


sub _build__post_fetch_action {
    my $self = shift;
    my $fetched_action_method;
    my $action = $self->config->{action_on_fetched};
    return undef unless (defined $action);
    if (lc($action) eq 'mark_as_read') {
        $fetched_action_method = 'mark_message_as_read';
    } elsif ( lc($action) eq "delete" ) {
        $fetched_action_method = 'delete_message';
    } else {
        $fetched_action_method = undef;
        warn "no recognised action for fetched mail, mailbox not updated";
    }
    return $fetched_action_method;
}


sub process_message {
    my ($self, $message) = @_;
    my $client = $self->client;
    my $filename = $client->get_message_mime_content($message->id);
    unless ($filename) {
        warn "failed to get mime content for message ". $message->id;
        return 0;
    }
    my $ok = $self->forward($message, $filename);
    if ($ok) {
        $ok = $self->post_fetch_action($message);
    }
    if ($self->config->{dump_messages}) {
        warn "dumped message in file $filename" if ($self->config->{debug});
    }
    else {
        unlink $filename or warn "couldn't delete message file $filename : $!";
    }
    return $ok;
}

sub post_fetch_action {
    my ($self, $message) = @_;
    my $method = $self->_post_fetch_action;
    my $ok = 1;
    # check for dry-run option
    if ($self->config->{dry_run}) {
        warn "dry run so not running $method action on fetched mail";
        return 1;
    }
    if ($method) {
        $ok = $self->$method($message->id);
    }
    return $ok;
}

###

sub _build_client {
    my $self = shift;
    my $classname = 'App::wsgetmail::' . $self->client_class;
    load $classname;
    my $config = clone $self->config;
    $config->{post_fetch_action} = $self->_post_fetch_action;
    return $classname->new($config);
}


sub _build_mda {
    my $self = shift;
    my $config = clone $self->config;
    if ( defined $self->config->{username}) {
        $config->{recipient} //= $self->config->{username};
    }
    return App::wsgetmail::MDA->new($config);
}



##


=head1 SEE ALSO

=over 4

=item App::wsgetmail::MDA

=item App::wsgetmail::MS365

=item wsgemail365

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991

=cut

1;
