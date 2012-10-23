use inc::Module::Install;

name 'Test-Fixture-Memcached';
all_from 'lib/Test/Fixture/Memcached.pm';

requires
    'parent'                 => '0.225',
    'YAML::XS'               => '0.38',
    'IO::Socket::INET'       => '1.31',
    'Cache::Memcached::Fast' => '0.19'
;

build_requires 'Test::More', 0.88;

test_requires 'Test::Requires';
tests 't/*.t';

install_script "bin/make_memcached_fixture";

## additional targets
# postamble <<EOM;
# TARGET ::
# \tSCRIPT
# EOM

WriteAll;
