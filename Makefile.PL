use lib qw(.);
use inc::Module::Install;
all_from 'lib/App/wsgetmail.pm';
license 'gpl_2';

requires 'Azure::AD::ClientCredentials';
requires 'Test::LWP::UserAgent';
requires 'Test::More';
requires 'LWP::UserAgent' => '6.42';
requires 'URI::Escape';
requires 'URI';
requires 'Moo';
requires 'JSON';
requires 'IPC::Run';

install_script('bin/wsgetmail');
auto_install();
sign;
WriteAll;
