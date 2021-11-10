use strict;
use warnings;

use Commons::Vote::Fetcher;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Commons::Vote::Fetcher::VERSION, 0.01, 'Version.');
