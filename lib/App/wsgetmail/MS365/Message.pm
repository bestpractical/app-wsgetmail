package App::wsgetmail::MS365::Message;
use Moo;

=head1 NAME

App::wsgetmail::MS365::Message

=head2 DESCRIPTION

Simple Moo class representing an microsoft/outlook 365 message.

=head2 ACCESSORS

=over 4

=item id

=item status

=item recipients

=back

=cut

has id => (
    is => 'ro',
    required => 1
);

has status => (
    is => 'ro',
    required => 1
);

has recipients => (
    is => 'ro',
    required => 1
);

has _details => (
    is => 'ro',
    required => 1
);

# have client
around BUILDARGS => sub {
  my ( $orig, $class, $details ) = @_;

  my $args = {
      id => $details->{id},
      status => $details->{status},
      recipients => $details->{toRecipients},
      _details => $details
  };

  return $class->$orig($args);
};

=head1 SEE ALSO

=over 4

=item App::wsgetmail::MS365

=back

=head1 AUTHOR

Aaron Trevena, C<< <ast at bestpractical.com> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


1;
