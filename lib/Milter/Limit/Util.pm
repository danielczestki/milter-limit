=head1 NAME

Milter::Limit::Util - utility functions for Milter::Limit

=head1 SYNOPSIS

 use Milter::Limit::Util;

 Milter::Limit::Util::daemonize();

=head1 DESCRIPTION

This module provides utility functions for Milter::Limit.

=cut

package Milter::Limit::Util;

use strict;
use POSIX qw(setsid);

=head1 FUNCTIONS

=over 4

=item daemonize()

This daemonizes the program.  When you call this, the program will fork(),
detach from the controlling TTY, close STDIN, STDOUT, and STDERR, and change to
the root directory.

=cut

sub daemonize {
    my $pid = fork and exit 0;

    my $sid = setsid();

    # detach from controlling TTY
    $SIG{HUP} = 'IGNORE';
    $pid = fork and exit 0;

    # clear umask
    umask 0;

    chdir '/' or die "can't chdir: $!";

    open STDIN,  '+>/dev/null';
    open STDOUT, '+>&STDIN';
    open STDERR, '+>&STDIN';

    return $sid;
}

=item get_uid($username): int

lookup the UID for a username

=cut

sub get_uid {
    my $user = shift;

    unless ($user =~ /^\d+$/) {
        my $uid = getpwnam($user);
        unless (defined $uid) {
            die qq{no such user "$user"\n};
        }

        return $uid;
    }
    else {
        return $user;
    }
}

=item get_gid($groupname): int

lookup the GID for a group name

=cut

sub get_gid {
    my $group = shift;

    unless ($group =~ /^\d+$/) {
        my $gid = getgrnam($group);
        unless (defined $gid) {
            die qq{no such group "$group"\n};
        }

        return $gid;
    }
    else {
        return $group;
    }
}

=back

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Michael Schout.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The full text of this license can be found in
the LICENSE file included with this module.

=cut

1;
