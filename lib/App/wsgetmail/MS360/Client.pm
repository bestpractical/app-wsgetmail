package App::wsgetmail::MS360::Client;

=head1 NAME

App::wsgetmail::MS360 - Fetch mail from Microsoft 360

=cut

use Moo;
use LWP::UserAgent;
use Azure::AD::ClientCredentials;

=head1 DESCRIPTION

Fetch mail from Microsoft 360 mailboxes using the Graph REST API
=head1 SYNOPSIS


=head1 ATTRIBUTES

=over 4

=item ua

=item secret

=item client_id

=item tenant_id

=item credentials

=item access_token

=back

=cut

has ua => (
    isa => 'LWP::UserAgent',
    builder   => '_build_authorised_ua',
    is => 'ro',
    lazy => 1,
);

has secret  => (
    is => 'ro',
    required => 1,
);

has client_id => (
    is => 'ro',
    required => 1,
);

has tenant_id => (
    is => 'ro',
    required => 1,
);

has credentials => (
    is => 'ro',
    lazy => 1,
    builder => '_build_credentials',
);

has access_token => (
    is => 'ro',
    lazy => 1,
    builder => '_build_access_token',
);

my $graph_v1_url = 'https://graph.microsoft.com/v1.0/';

=head1 METHODS

=head2 build_rest_uir

=cut

sub build_rest_uri {
    my ($self, @endpoint_parts) = @_;
    return join('/', $graph_v1_url, @endpoint_parts);
}

=head2 get_request

=cut

sub get_request {
    my ($self, $parts) = @_;
    # add error handling!
    my $url = $self->build_rest_uri(@$parts);
    return $self->ua->get($url);
}

# sub post_request {
#     my ($self, $path_parts, $post_data) = @_;
#     my $url = $self->build_rest_uri(@$path_parts);
#     return $self->ua->post($url,$post_data);
# }

# sub patch_request {
#     my ($self, $path_parts, $patch_data) = @_;
#     my $url = $self->build_rest_uri(@$path_parts);
#     return $self->ua->patch($url,$patch_data);
# }

######

sub _build_authorised_ua {
    my $ua = LWP::UserAgent->new();
    $ua->default_header( Authorization => $self->access_token() );
    return $ua;
}

sub _build_access_token {
    my $self = shift;
    my $access_token = $self->credentials->access_token;
    return $access_token;
}

sub _build_credentials {
    my $self = shift;
    my $creds = Azure::AD::ClientCredentials->new(
        resource_id => 'https://graph.microsoft.com/',
        client_id => $self->client_id,
        secret_id => $self->secret,
        tenant_id => $self->tenant_id
    );
    return $creds;
}




=head1 SEE ALSO

=over 4

=item App::wsgetmail::Client

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


1;
