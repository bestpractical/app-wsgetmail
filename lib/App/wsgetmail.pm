package App::wsgetmail;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::wsgetmail - Fetch mail from the cloud using webservices

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

A simple command line application/script to fetch mail from the cloud
using webservices instead of IMAP and POP.

Configurable to mark fetched mail as read, or to delete it, and with
configurable action with the fetched email.

=head1 SYNOPSIS

    use App::wsgetmail;

    my $foo = App::wsgetmail->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

=head1 AUTHOR

Aaron Trevena, C<< <ast at bestpractical.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-wsgetmail at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-wsgetmail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::wsgetmail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-wsgetmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-wsgetmail>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-wsgetmail>

=item * Search CPAN

L<https://metacpan.org/release/App-wsgetmail>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::wsgetmail
