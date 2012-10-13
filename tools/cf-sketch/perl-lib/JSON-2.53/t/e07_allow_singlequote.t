
use Test::More;
use strict;
BEGIN { plan tests => 4 };
BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }
use JSON;
#########################

my $json = JSON->new->allow_nonref;

eval q| $json->decode("{'foo':'bar'}") |;

ok($@); # in XS and PP, the error message differs.

$json->allow_singlequote;

is($json->decode(q|{'foo':"bar"}|)->{foo}, 'bar');
is($json->decode(q|{'foo':'bar'}|)->{foo}, 'bar');
is($json->allow_barekey->decode(q|{foo:'bar'}|)->{foo}, 'bar');

