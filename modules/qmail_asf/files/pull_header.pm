# USAGE: use pull_header; # provides the pull_header sub once, to the first user

no warnings; # perl warns when you return control from a subroutine via redo

# Populate $_ with the full header, excecute the caller's code, and return
# control to the start of the main LINE loop from -n or -p with the next line
# preread into $_.

sub pull_header (&) {
    my $code = shift;
    my $next_line;
    do {
        $next_line = <>;
    } while defined $next_line and $next_line =~ /^\s+\S/ and $_ .= $next_line;

    $code->();
    $_ = $next_line;
    redo LINE;
}

1;
