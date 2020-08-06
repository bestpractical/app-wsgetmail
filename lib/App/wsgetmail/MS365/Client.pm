package App::wsgetmail::MS365::Client;

=head1 NAME

App::wsgetmail::MS365 - Fetch mail from Microsoft 365

=cut

use Moo;
use URI::Escape;
use URI;
use JSON;
use LWP::UserAgent;
use Azure::AD::ClientCredentials;

=head1 DESCRIPTION

Fetch mail from Microsoft 365 mailboxes using the Graph REST API

=head1 ATTRIBUTES

=over 4

=item secret

=item client_id

=item tenant_id

=item username

=item user_password

=item global_access

=back

=cut

has secret  => (
    is => 'ro',
    required => 0,
);

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

has global_access => (
    is => 'ro',
    default => sub { return 0 }
);

has resource_url => (
    is => 'ro',
    default => sub { return 'https://graph.microsoft.com/' }
);

has resource_path => (
    is => 'ro',
    default => sub { return 'v1.0' }
);

has debug => (
    is => 'rw',
    default => sub { return 0 }
);

has _ua => (
    builder   => '_build_authorised_ua',
    is => 'ro',
    lazy => 1,
);

has _credentials => (
    is => 'ro',
    lazy => 1,
    builder => '_build__credentials',
);

has _access_token => (
    is => 'ro',
    lazy => 1,
    builder => '_build__access_token',
);

sub BUILD {
    my ($self, $args) = @_;

    if ($args->{global_access}) {
        unless ($args->{secret}) {
            die "secret is required when using global_access";
        }
    }
    else {
        unless ($args->{username} && $args->{user_password}) {
            die "username and user_password are required when not using global_access";
        }
    }
}


=head1 METHODS

=head2 build_rest_uir

=cut

sub build_rest_uri {
    my ($self, @endpoint_parts) = @_;
    my $base_url = $self->resource_url . $self->resource_path;
    return join('/', $base_url, @endpoint_parts);
}

=head2 get_request

=cut

sub get_request {
    my ($self, $parts, $params) = @_;
    # add error handling!
    my $uri = URI->new($self->build_rest_uri(@$parts));
    warn "making GET request to url $uri" if ($self->debug);
    $uri->query_form($params) if ($params);
    return $self->_ua->get($uri);
}

=head2 get_request_by_url

=cut

sub get_request_by_url {
    my ($self, $url) = @_;
    warn "making GET request to url $url" if ($self->debug);
    return $self->_ua->get($url);
}

=head2 delete_request

=cut

sub delete_request {
    my ($self, $parts, $params) = @_;
    my $url = $self->build_rest_uri(@$parts);
    warn "making DELETE request to url $url" if ($self->debug);
    return $self->_ua->delete($url);
}

=head2 post_request

=cut

sub post_request {
    my ($self, $path_parts, $post_data) = @_;
    my $url = $self->build_rest_uri(@$path_parts);
    warn "making POST request to url $url" if ($self->debug);
    return $self->_ua->post($url,$post_data);
}

=head2 patch_request

=cut

sub patch_request {
     my ($self, $path_parts, $patch_params) = @_;
     my $url = $self->build_rest_uri(@$path_parts);
     warn "making PATCH request to url $url" if ($self->debug);
     return $self->_ua->patch($url,%$patch_params);
 }

######

sub _build_authorised_ua {
    my $self = shift;
    my $ua = $self->_new_useragent;
    warn "getting system access token" if ($self->debug);
    $ua->default_header( Authorization => $self->_access_token() );
    return $ua;
}

sub _build__access_token {
    my $self = shift;
    my $access_token;
    if ($self->global_access) {
        $access_token = $self->_credentials->access_token;
    }
    else {
        $access_token = $self->_get_user_access_token;
    }
    return $access_token;
}

sub _get_user_access_token {
    my $self = shift;
    my $ua = $self->_new_useragent;
    my $access_token;
    warn "getting user access token" if ($self->debug);
    my $oauth_login_url = sprintf('https://login.windows.net/%s/oauth2/token', $self->tenant_id);
    my $response = $ua->post( $oauth_login_url,
                              {
                                  resource=> $self->resource_url,
                                  client_id => $self->client_id,
                                  grant_type=>'password',
                                  username=>$self->username,
                                  password=>$self->user_password,
                                  scope=>'openid'
                              }
                          );
    my $raw_message = $response->content;
    # check details
    if ($response->is_success) {
        my $token_details = decode_json( $response->content );
        $access_token = "Bearer " . $token_details->{access_token};
    }
    else {
        # throw error
        warn "auth response from server : $raw_message" if ($self->debug);
        die sprintf('unable to get user access token for user %s request failed with status %s ', $self->username, $response->status_line);
    }
    return $access_token;
}

sub _build__credentials {
    my $self = shift;
    my $creds = Azure::AD::ClientCredentials->new(
        resource_id => $self->resource_url,
        client_id => $self->client_id,
        secret_id => $self->secret,
        tenant_id => $self->tenant_id
    );
    return $creds;
}

sub _new_useragent {
    return LWP::UserAgent->new();
}

=head1 SEE ALSO

=over 4

=item App::wsgetmail::MS365

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


1;
