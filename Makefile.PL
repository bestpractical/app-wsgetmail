use lib qw(.);
use Config;
use inc::Module::Install;
readme_from 'lib/App/wsgetmail.pm', 0, 'md';
all_from 'lib/App/wsgetmail.pm';
license 'gpl_2';

perl_version '5.010';

requires 'Azure::AD::ClientCredentials';
requires 'Clone';
requires 'FindBin';
requires 'File::Slurp';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'IPC::Run';
requires 'JSON';
requires 'LWP::UserAgent' => '6.42';
requires 'Module::Load';
requires 'Moo';
requires 'MIME::Parser';
requires 'Pod::Usage';
requires 'strict';
requires 'Test::LWP::UserAgent';
requires 'Test::More';
requires 'URI::Escape';
requires 'URI';
requires 'warnings';

install_script('bin/wsgetmail');
auto_install();
sign;
WriteAll;
