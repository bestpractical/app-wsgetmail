package App::wsgetmail::MDA;
use Moo;

use IPC::Run qw( run timeout );

has command => (
    is => 'ro',
    required => 1,
);
has command_args => (
    is => 'ro',
    required => 1,
);

has command_timeout => (
    is => 'ro',
    default => sub { 30; }
);

# extension and recipient were used in previous versions, but the code was
# buggy and has since been removed. They're only here for backwards API
# compatibility.
has extension => (
    is => 'ro',
    required => 0
);

has recipient => (
    is => 'ro',
    required => 0,
);

has debug => (
    is => 'ro',
    default => sub { 0 }
);



my @config_fields = qw( command command_args command_timeout debug );
around BUILDARGS => sub {
    my ( $orig, $class, $config ) = @_;
    my $attributes = { map { $_ => $config->{$_} } @config_fields };
    return $class->$orig($attributes);
};


###

sub forward {
    my ($self, $message, $filename) = @_;
    return $self->_run_command($filename);
}


sub _run_command {
    my ($self, $filename) = @_;
    open my $fh, "<$filename"  or die $!;
    my ($input, $output, $error);
    unless ($self->command) {
        warn "no action to delivery message, command option is empty or null" if ($self->debug);
        return 1;
    }
    my $ok = run ([ $self->command, _split_command_args($self->command_args, 1)], $fh, \$output, \$error, timeout( $self->command_timeout + 5 ) );
    unless ($ok) {
        warn sprintf('failed to run command "%s %s" for file %s : %s',
                     $self->command,
                     ($self->debug ? join(' ', _split_command_args($self->command_args)) : '' ),
                     $filename, $?);
        warn "output : $output\nerror:$error\n" if ($self->debug);
    }
    close $fh;
    return $ok;
}


#TODO: make into a simple cpan module
# Loosely based on https://metacpan.org/pod/Parse::CommandLine
sub _split_command_args {
    my ($line, $strip_quotes) = @_;

    # strip leading/trailing spaces
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my (@args, $quoted, $escape_next, $next_arg);
    foreach my $character (split('', $line) ) {
        if ($escape_next) {
            $next_arg .= $character;
            $escape_next = undef;
            next;
        }

        if ($character =~ m|\\|) {
            $next_arg .= $character;
            if ($quoted) {
                $escape_next = 1;
            }
            next;
        }

        if ($character =~ m/\s/) {
            if ($quoted) {
                $next_arg .= $character;
            }
            else {
                push @args, $next_arg if defined $next_arg;
                undef $next_arg;
            }
            next;
        }

        if ($character =~ m/['"]/) {
            if ($quoted) {
                if ($character eq $quoted) {
                    $quoted = undef;
                    $next_arg .= $character unless ($strip_quotes);
                } else {
                    $next_arg .= $character;
                }
            }
            else {
                $quoted = $character;
                $next_arg .= $character unless ($strip_quotes);
            }
            next;
        }
        $next_arg .= $character;
    }
    push @args, $next_arg if defined $next_arg;
    return @args;
}

1;
