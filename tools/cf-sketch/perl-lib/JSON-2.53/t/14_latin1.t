# copied over from JSON::XS and modified to use JSON

use Test::More;
use strict;
BEGIN { plan tests => 4 };

BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }

BEGIN {
    use lib qw(t);
    use _unicode_handling;
}

use JSON;

SKIP: {
    skip "UNICODE handling is disabale.", 4 unless $JSON::can_handle_UTF16_and_utf8;

my $xs = JSON->new->latin1->allow_nonref;

ok $xs->encode ("\x{12}\x{89}       ") eq "\"\\u0012\x{89}       \"";
ok $xs->encode ("\x{12}\x{89}\x{abc}") eq "\"\\u0012\x{89}\\u0abc\"";

ok $xs->decode ("\"\\u0012\x{89}\""       ) eq "\x{12}\x{89}";
ok $xs->decode ("\"\\u0012\x{89}\\u0abc\"") eq "\x{12}\x{89}\x{abc}";

}
