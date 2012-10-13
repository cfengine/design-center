# copied over from JSON::XS and modified to use JSON

use Test::More;
use strict;
BEGIN { plan tests => 2432 };

BEGIN { $ENV{PERL_JSON_BACKEND} = "JSON::backportPP"; }

BEGIN {
    use lib qw(t);
    use _unicode_handling;
}

use JSON;

SKIP: {
    skip "UNICODE handling is disabale.", 2432 unless $JSON::can_handle_UTF16_and_utf8;

sub test($) {
   my $js;

   $js = JSON->new->allow_nonref(0)->utf8->ascii->shrink->encode ([$_[0]]);
   ok ($_[0] eq ((decode_json $js)->[0]));
   $js = JSON->new->allow_nonref(0)->utf8->ascii->encode ([$_[0]]);
   ok ($_[0] eq (JSON->new->utf8->shrink->decode($js))->[0]);

   $js = JSON->new->allow_nonref(0)->utf8->shrink->encode ([$_[0]]);
   ok ($_[0] eq ((decode_json $js)->[0]));
   $js = JSON->new->allow_nonref(1)->utf8->encode ([$_[0]]);
   ok ($_[0] eq (JSON->new->utf8->shrink->decode($js))->[0]);

   $js = JSON->new->allow_nonref(1)->ascii->encode ([$_[0]]);
   ok ($_[0] eq JSON->new->decode ($js)->[0]);
   $js = JSON->new->allow_nonref(0)->ascii->encode ([$_[0]]);
   ok ($_[0] eq JSON->new->shrink->decode ($js)->[0]);

   $js = JSON->new->allow_nonref(1)->shrink->encode ([$_[0]]);
   ok ($_[0] eq JSON->new->decode ($js)->[0]);
   $js = JSON->new->allow_nonref(0)->encode ([$_[0]]);
   ok ($_[0] eq JSON->new->shrink->decode ($js)->[0]);
}

srand 0; # doesn't help too much, but its at leats more deterministic

#for (1..768) {
for (1..64, 125..129, 255..257, 512, 704, 736, 768) {
   test join "", map chr ($_ & 255), 0..$_;
   test join "", map chr rand 255, 0..$_;
   test join "", map chr ($_ * 97 & ~0x4000), 0..$_;
   test join "", map chr (rand (2**20) & ~0x800), 0..$_;
}

}
