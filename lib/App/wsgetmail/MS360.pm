package App::wsgetmail::MS360;

=head1 NAME

App::wsgetmail::MS360 - Fetch mail from Microsoft 360

=head1 DESCRIPTION

Fetch mail from Microsoft 360 mailboxes using the Graph REST API

=cut

use strict;
use Moo;

use Azure::AD::ClientCredentials;
use URI::Escape;
use URI::Query;
use JSON;


=head1 ATTRIBUTES

=over 4

=item client - 

=back

=cut

has client => (
    isa => 'App::wsgetmail::MS360::Client',
    is => 'rw'
);


=head1 METHODS

=head2 get_message_list

=cut

sub get_message_list {
    my ($self, $username) = @_;
    # add error handling!
    my $response = $self->ua->get_request('users', $username, 'messages');
    my $message_list = decode_json( $response->content );
    return $message_list;
}

=head2 get_message_mime_content

=cut

sub get_message_mime_content {
    my ($self, $username, $message_id) = @_;
    my $response = $self->ua->get_request('users', $username, 'messages', $message_id, '$value');
    my $raw_message = $response->content;
    return $raw_message;
}



=head1 SEE ALSO

=over 4

=item App::wsgetmail::MS360::Client

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


1;
