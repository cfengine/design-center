#
# このファイルのエンコーディングはUTF-8
#

# copied over from JSON::PC and modified to use JSON
# copied over from JSON::XS and modified to use JSON

use Test::More;
use strict;

BEGIN { plan tests => 17 };

BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }

BEGIN {
    use lib qw(t);
    use _unicode_handling;
}


use utf8;
use JSON;

#########################
my ($js,$obj,$str);

my $pc = new JSON;

$obj = {test => qq|abc"def|};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\"def"}|);

$obj = {qq|te"st| => qq|abc"def|};
$str = $pc->encode($obj);
is($str,q|{"te\"st":"abc\"def"}|);

$obj = {test => qq|abc/def|};   # / => \/
$str = $pc->encode($obj);         # but since version 0.99
is($str,q|{"test":"abc/def"}|); # this handling is deleted.
$obj = $pc->decode($str);
is($obj->{test},q|abc/def|);

$obj = {test => q|abc\def|};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\\\\def"}|);

$obj = {test => "abc\bdef"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\bdef"}|);

$obj = {test => "abc\fdef"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\fdef"}|);

$obj = {test => "abc\ndef"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\ndef"}|);

$obj = {test => "abc\rdef"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\rdef"}|);

$obj = {test => "abc-def"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc-def"}|);

$obj = {test => "abc(def"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc(def"}|);

$obj = {test => "abc\\def"};
$str = $pc->encode($obj);
is($str,q|{"test":"abc\\\\def"}|);


$obj = {test => "あいうえお"};
$str = $pc->encode($obj);
is($str,q|{"test":"あいうえお"}|);

$obj = {"あいうえお" => "かきくけこ"};
$str = $pc->encode($obj);
is($str,q|{"あいうえお":"かきくけこ"}|);


$obj = $pc->decode(q|{"id":"abc\ndef"}|);
is($obj->{id},"abc\ndef",q|{"id":"abc\ndef"}|);

$obj = $pc->decode(q|{"id":"abc\\\ndef"}|);
is($obj->{id},"abc\\ndef",q|{"id":"abc\\\ndef"}|);

$obj = $pc->decode(q|{"id":"abc\\\\\ndef"}|);
is($obj->{id},"abc\\\ndef",q|{"id":"abc\\\\\ndef"}|);

