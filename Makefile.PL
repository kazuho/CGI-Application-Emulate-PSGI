use inc::Module::Install;

all_from 'lib/CGI/Application/Emulate/PSGI.pm';
readme_from 'lib/CGI/Application/Emulate/PSGI.pm';

test_requires 'Test::More'       => 0.94;
build_requires 'Test::More';

auto_include;
WriteAll;
