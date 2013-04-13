#!/usr/bin/perl
# Read a JSON file in relaxed more, output it in strict mode, to fix
# non-compliant JSON. Replaces the file in place.
# CFEngine AS, April 2013

use JSON::PP;

$coder = JSON::PP->new()->allow_barekey()->relaxed()->utf8()->allow_nonref();
$ccoder = JSON::PP->new()->canonical()->utf8()->allow_nonref();

$file = shift @ARGV;

{
    local $/;
    open($ifh, '<', $file);
    $json_text = <$ifh>;
    $json = $coder->decode($json_text);
    close $ifh;
}

open($ofh, '>', $file);
print $ofh $ccoder->pretty->encode($json);
close $ofh;
