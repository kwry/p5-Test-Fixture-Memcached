use strict;
use Test::More;
use Test::Fixture::Memcached;
use Cache::Memcached::Fast;
use YAML::XS qw(LoadFile);

my $fixture_yaml = "t/fixture.yaml";
my $arrayref     = LoadFile($fixture_yaml);

eval "use Test::TCP";
if ($@) {
    plan skip_all => 'Test::TCP does not installed. skip all';
}

# find memcached
chomp(my $path = readpipe "which memcached 2>/dev/null");
my $exit_value = $? >> 8;
if ($exit_value != 0) {
    $path = $ENV{MEMCACHED_PATH};
}
if(!$path) {
    plan skip_all => 'memcached can not find. If it is installed in a location path is not passed, set the case memcached path to MEMCACHED_PATH environ variable';
}

my $memcached = Test::TCP->new(
    code => sub {
        my $port = shift;
        exec "$path -l 127.0.0.1 -p $port";
        die "cannot execute $path: $!";
    },
    port => Test::TCP::empty_port(11978)
);

my $memd = Cache::Memcached::Fast->new({ servers => ["127.0.0.1:".$memcached->port] });

subtest 'load fixture' => sub {
    foreach my $src ($fixture_yaml, $arrayref) {
        construct_fixture memd => $memd, fixture => $src;

        # foo
        is $memd->get("foo"), "bar", "foo is bar";
        # array
        my $array = $memd->get("array");
        is ref($array), "ARRAY", "array is ARRAY reference";
        is_deeply $array, [1,2,3,4,5], "array deep match";
        # hash
        my $hash = $memd->get("hash");
        is ref($hash), "HASH", "hash is HASH reference";
        is_deeply $hash, { apple => "red", banana => "yellow" }, "hash deep match";
        # expired key
        is $memd->get("expired"), "bar", "x key value match";
        sleep 4;
        is $memd->get("expired"), undef, "x key is not exists. expired 3 sec";
    }
};

subtest 'cleard fixture' => sub {
    construct_fixture memd => $memd, fixture => [{ key => 'foo', value => 'bar' }];
    # foo
    is $memd->get("foo"), "bar", "foo is bar";
    construct_fixture memd => $memd, fixture => [{ key => 'bar', value => 'foo' }];
    # bar
    is $memd->get("bar"), "foo", "bar is foo";
    is $memd->get("foo"), undef, "foo is undef";
};

done_testing;
