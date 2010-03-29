=head1 NAME

App::Milter::Limit::Plugin::BerkeleyDB - Berkeley DB backend for App::Milter::Limit

=head1 SYNOPSIS

 my $milter = App::Milter::Limit->instance('BerkeleyDB');

=head1 DESCRIPTION

This module implements the C<App::Milter::Limit> backend using a BerkeleyDB data
store.

=head1 CONFIGURATION

The C<[driver]> section of the configuration file must specify the following items:

=over 4

=item home

The directory where the database files should be stored.

=item file

The database filename

=item mode [optional]

The file mode for the database files (default 0644).

=back

=cut

package App::Milter::Limit::Plugin::BerkeleyDB;

use strict;
use base qw(App::Milter::Limit::Plugin Class::Accessor);
use App::Milter::Limit::Log;
use BerkeleyDB qw(DB_CREATE DB_INIT_MPOOL DB_INIT_CDB);
use File::Path qw(mkpath);
use Fatal qw(mkpath);

__PACKAGE__->mk_accessors(qw(_db));

sub init {
    my $self = shift;

    $self->init_defaults;

    App::Milter::Limit::Util::make_path($self->config_get('driver', 'home'));

    # db/env creation deferred until child_init
}

sub init_defaults {
    my $self = shift;

    $self->config_defaults('driver',
        home  => $self->config_get('global', 'state_dir'),
        file  => 'bdb-stats.db',
    );
}

sub child_init {
    my $self = shift;

    my $conf = App::Milter::Limit::Config->section('driver');

    my $env = BerkeleyDB::Env->new(
        -Home  => $$conf{home},
        -Flags => DB_CREATE | DB_INIT_MPOOL | DB_INIT_CDB)
            or die "failed to open BerkeleyDB env: $!";

    my $db = BerkeleyDB::Hash->new(
        -Filename => $$conf{file},
        -Env      => $env,
        -Flags    => DB_CREATE) or die "failed to open BerkeleyDB: $!";

    $self->_db($db);

    debug("BerkeleyDB connection initialized");
}

sub query {
    my ($self, $from) = @_;

    my $conf = App::Milter::Limit::Config->global;

    my $db = $self->_db;

    my $val;
    $db->db_get($from, $val);

    unless (defined $val) {
        # initialize new record for sender
        $val = join ':', time, 0;
    }

    my ($start, $count) = split ':', $val;

    # reset counter if it is expired
    if ($start < time - $$conf{expire}) {
        $count = 0;
        $start = time;
    }

    # update database for this sender.
    $val = join ':', $start, ++$count;
    $db->db_put($from, $val);

    return $count;
}

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/milter-limit

 git clone git://github.com/mschout/milter-limit.git

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Schout.

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=cut

1;