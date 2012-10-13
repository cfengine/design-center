
use Test::More;
use strict;
BEGIN { plan tests => 2 };
BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }
use JSON;
#########################

my $json = JSON->new->allow_nonref;

eval q| $json->decode('{foo:"bar"}') |;

ok($@); # in XS and PP, the error message differs.

$json->allow_barekey;

is($json->decode('{foo:"bar"}')->{foo}, 'bar');


