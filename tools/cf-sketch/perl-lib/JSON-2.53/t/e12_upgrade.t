use strict;
use Test::More;

BEGIN { plan tests => 3 };

BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }

use JSON;

BEGIN {
    use lib qw(t);
    use _unicode_handling;
}

my $json = JSON->new->allow_nonref->utf8;
my $str  = '\\u00c8';

my $value = $json->decode( '"\\u00c8"' );

#use Devel::Peek;
#Dump( $value );

is( $value, chr 0xc8 );

SKIP: {
    skip "UNICODE handling is disabale.", 1 unless $JSON::can_handle_UTF16_and_utf8;
    ok( utf8::is_utf8( $value ) );
}

eval { $json->decode( '"' . chr(0xc8) . '"' ) };
ok( $@ =~ /malformed UTF-8 character in JSON string/ );

