package Test::Fixture::Memcached;

use strict;
use warnings;
use 5.008_001;
use parent qw(Exporter);
use Carp;
use YAML::XS qw(LoadFile);
use Cache::Memcached::Fast;

our @EXPORT = qw(construct_memcached_fixture);
our $VERSION = '0.01';

sub construct_memcached_fixture {
    my %args = @_;
    my $fixture;

    if (!ref($args{memd}) || ref($args{memd}) && !$args{memd}->isa("Cache::Memcached::Fast")) {
        croak "memd must be Cache::Memcached::Fast instance";
    }

    if (-f $args{fixture}) {
        $fixture = LoadFile($args{fixture});
    } elsif (ref($args{fixture}) eq "ARRAY") {
        $fixture = $args{fixture};
    } else {
        croak "fixture must be YAML file path or ARRAY";
    }
    _validate_fixture($fixture);


    _delete_all($args{memd});
    return _insert($args{memd}, $fixture);
}

sub _delete_all {
    my $memd = shift;
    $memd->flush_all(0);
}

sub _insert {
    my ($memd, $fixture) = @_;
    my @pairs = ();
    for my $ref (@$fixture) {
        push @pairs, [$ref->{key}, $ref->{value}, $ref->{expired}];
    }
    $memd->set_multi(@pairs);
}

sub _validate_fixture {
    my $fixture = shift;
    croak "fixture must be ARRAY reference." unless ref $fixture eq 'ARRAY';
    for my $ref (@$fixture) {
        croak "must set key and value fields." if !$ref->{key} || !defined $ref->{value};
        croak "key must be scalar value." if ref $ref->{key};
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Fixture::Memcached - load fixture data to memcached

=head1 SYNOPSIS

  # in your t/fixture.yaml
  ---
  -
    key: foo
    value: bar
    expired: 300
  -
    key: array
    value:
      - 1
      - 2
      - 3
      - 4
      - 5
  # in your t/*.t
  use Test::Fixture::Memcached;
  ## $memd is Cache::Memcached::Fast instance
  my $fixture = construct_memcached_fixture memd => $memd, fixture => "t/fixture.yaml";

=head1 DESCRIPTION

Test::Fixture::Memcached is fixture data loader for Cache::Memcached::Fast.
This module implements the Test::Fixture::KyotoTycoon helpful.

=head1 METHODS

=head2 construct_memcached_fixture( %specs )

The following is %specs details.

=over

=item memd

Required parameter. memd is L<Cache::Memcached::Fast>'s object

=item fixture

Required parameter. fixture is SCALAR or ARRAYREF, Specify fixture files.

=back

=head1 SEE ALSO

L<Test::Fixture::KyotoTycoon> L<Cache::Memcached::Fast> L<YAML::XS>

=head1 AUTHOR

kwry E<lt>kwry@kwry.infoE<gt>

=head1 COPYRIGHT

Copyright 2012- kwry

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
