package App::wsgetmail::MS365;

=head1 NAME

App::wsgetmail::MS365 - Fetch mail from Microsoft 365

=cut

use Moo;
use JSON;

use App::wsgetmail::MS365::Client;
use App::wsgetmail::MS365::Message;
use File::Temp;

=head1 DESCRIPTION

Moo class providing methods to connect to and fetch mail from Microsoft 365
 mailboxes using the Graph REST API.

=head1 ATTRIBUTES

=over 4

=item client_id

=item tenant_id

=item username

=item user_password

=item global_access

=item secret

=item folder

=back

=cut

has client_id => (
    is => 'ro',
    required => 1,
);

has tenant_id => (
    is => 'ro',
    required => 1,
);

has username => (
    is => 'ro',
    required => 0
);

has user_password => (
    is => 'ro',
    required => 0
);

has folder => (
    is => 'ro',
    required => 0,
    default => sub { 'Inbox' }
);

has global_access => (
    is => 'ro',
    default => sub { return 0 }
);

has secret => (
    is => 'ro',
    required => 0,
);

has post_fetch_action => (
    is => 'ro',
    required => 1
);

has debug => (
    is => 'rw',
    default => sub { return 0 }
);

###

has _client => (
    is => 'ro',
    lazy => 1,
    builder => '_build_client',
);

has _fetched_messages => (
    is => 'rw',
    required => 0,
    default => sub { [ ] }
);

has _have_messages_to_fetch => (
    is => 'rw',
    required => 0,
    default => sub { 1 }
);

has _next_fetch_url => (
    is => 'rw',
    required => 0,
    default => sub { '' }
);


my @config_fields = qw(client_id tenant_id username user_password global_access secret folder post_fetch_action debug);
around BUILDARGS => sub {
  my ( $orig, $class, $config ) = @_;

  my $attributes = { map { $_ => $config->{$_} } @config_fields };
  return $class->$orig($attributes);
};


=head1 METHODS

=head2 new

Class constructor method, returns new App::wsgetmail::MS365 object

=head2 get_next_message

Object method, returns the next message as an App::wsgetmail::MS365::Message object if there is one.

Will lazily fetch messages until the list is exhausted.

=cut

sub get_next_message {
    my ($self) = @_;
    my $next_message;

    # check for already fetched messages, otherwise fetch more
    my $message_details = shift @{$self->_fetched_messages};
    unless ( $message_details ) {
        if ($self->_have_messages_to_fetch) {
            $self->_fetch_messages();
            $message_details = shift @{$self->_fetched_messages};
        }
    }
    if (defined $message_details) {
        $next_message = App::wsgetmail::MS365::Message->new($message_details);
    }
    return $next_message;
}

=head2 get_message_mime_content

Object method, takes message id and returns filename of fetched raw mime file for that message.

=cut

sub get_message_mime_content {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id, '$value') : ('me', 'messages', $message_id, '$value');

    my $response = $self->_client->get_request([@path_parts]);
    unless ($response->is_success) {
        warn "failed to fetch message $message_id " . $response->status_line;
        return undef;
    }

    # can we just write straight to file from response?
    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mime' );
    print $tmp $response->content;
    return $tmp->filename;
}

=head2 delete_message

Object method, takes message id and deletes that message from the outlook365 mailbox

=cut

sub delete_message {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id) : ('me', 'messages', $message_id);
    my $response = $self->_client->delete_request([@path_parts]);
    unless ($response->is_success) {
        warn "failed to mark message as read " . $response->status_line;
    }

    return $response;
}

=head2 mark_message_as_read

Object method, takes message id and marks that message as read in the outlook365 mailbox

=cut

sub mark_message_as_read {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id) : ('me', 'messages', $message_id);
    my $response = $self->_client->patch_request([@path_parts],
                                                 {'Content-type'=> 'application/json',
                                                  Content => encode_json({isRead => $JSON::true }) });
    unless ($response->is_success) {
        warn "failed to mark message as read " . $response->status_line;
    }

    return $response;
}


=head2 get_folder_details

Object method, returns hashref of details of the configured mailbox folder.

=cut

sub get_folder_details {
    my $self = shift;
    my $folder_name = $self->folder;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'mailFolders' ) : ('me', 'mailFolders');
    my $response = $self->_client->get_request(
        [@path_parts], { '$filter' => "DisplayName eq '$folder_name'" }
    );
    unless ($response->is_success) {
        warn "failed to fetch folder detail " . $response->status_line;
        return undef;
    }

    my $folders = decode_json( $response->content );
    return $folders->{value}[0];
}


##############

sub _fetch_messages {
    my ($self, $filter) = @_;
    my $messages = [ ];
    my $fetched_count = 0;
    # check if expecting to fetch more using result paging
    my ($decoded_response);
    if ($self->_next_fetch_url) {
        my $response = $self->_client->get_request_by_url($self->_next_fetch_url);
        unless ($response->is_success) {
            warn "failed to fetch messages " . $response->status_line;
            $self->_have_messages_to_fetch(0);
            return 0;
        }
        $decoded_response = decode_json( $response->content );
    } else {
        my $fields = [qw(id subject sender isRead sentDateTime toRecipients parentFolderId categories)];
        $decoded_response = $self->_get_message_list($fields, $filter);
    }

    $messages = $decoded_response->{value};
    if ($decoded_response->{'@odata.nextLink'}) {
        $self->_next_fetch_url($decoded_response->{'@odata.nextLink'});
        $self->_have_messages_to_fetch(1);
    } else {
        $self->_have_messages_to_fetch(0);
    }
    $self->_fetched_messages($messages);
    return $fetched_count;
}

sub _get_message_list {
    my ($self, $fields, $filter) = @_;

    my $folder = $self->get_folder_details;
    unless ($folder) {
        warn "unable to fetch messages, can't find folder " . $self->folder;
        return { '@odata.count' => 0, value => [ ] };
    }

    # don't request list if folder has no items
    unless ($folder->{totalItemCount} > 0) {
        return { '@odata.count' => 0, value => [ ] };
    }
    $filter ||= $self->_get_message_filters;

    #TODO: handle filtering multiple folders using filters
    my @path_parts = ($self->global_access) ? ( 'users', $self->username, 'mailFolders', $folder->{id}, 'messages' ) : ( 'me', 'mailFolders', $folder->{id}, 'messages' );

    # get oldest first, filter (i.e. unread) if filter provided
    my $response = $self->_client->get_request(
        [@path_parts],
        {
            '$count' => 'true', '$orderby' => 'sentDateTime',
            ( $fields ? ('$select' => join(',',@$fields)  ) : ( )),
            ( $filter ? ('$filter' => $filter ) : ( ))
        }
    );

    unless ($response->is_success) {
        warn "failed to fetch messages " . $response->status_line;
        return { value => [ ] };
    }

    return decode_json( $response->content );
}

sub _get_message_filters {
    my $self = shift;
    #TODO: handle filtering multiple folders
    my $filters = [ ];
    if ( $self->post_fetch_action && ($self->post_fetch_action eq 'mark_message_as_read')) {
        push(@$filters, 'isRead eq false');
    }

    my $filter = join(' ', @$filters);
    return $filter;
 }

sub _build_client {
    my $self = shift;
    my $client = App::wsgetmail::MS365::Client->new( {
        client_id => $self->client_id,
        username => $self->username,
        user_password => $self->user_password,
        secret => $self->secret,
        client_id => $self->client_id,
        tenant_id => $self->tenant_id,
        global_access => $self->global_access,
        debug => $self->debug,
    } );
    return $client;

}

=head1 CONFIGURATION

=head2 Setting up mail API integration in microsoft365

Active Directory application configuration

From Azure Active directory admin center.

=over 4

=item 1.

Go to App Registrations and then "New registration", select single tenant and register.

=item 2.

Go to certificates and secrets, add a new client secret.

=item 3.

Go to API permissions and add the following delegated rights for Microsoft Graph:

=over 6

=item * Mail.Read Delegated right

=item * Mail.Read.Shared Delegated right

=item * Mail.ReadWrite Delegated right

=item * Mail.ReadWrite.Shared Delegated right

=item * openid  Delegated right

=item * User.Read  Delegated right

=back

=item 4.

Once the rights have been added, grant admin consent to allow the API client to use them.

=item 5.

Then go to authentication, and change "Treat application as a public client." to "yes".

=back

=head1 SEE ALSO

=over 4

=item App::wsgetmail::MS365::Client

=item App::wsgetmail::MS365::Message

=item L<https://docs.microsoft.com/en-gb/azure/active-directory/develop/quickstart-register-app>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


1;
