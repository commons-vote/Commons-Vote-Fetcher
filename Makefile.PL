use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'commons.vote fetcher for comunication between app and Wikimedia Commons.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Commons-Vote-Fetcher';
readme_from 'Fetcher.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Commons-Vote-Fetcher/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Commons-Vote-Fetcher';
resources 'repository' => 'git://github.com/michal-josef-spacek/Commons-Vote-Fetcher';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.03;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
