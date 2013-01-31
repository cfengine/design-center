use Test::More;

no warnings;
\&::main::;

plan tests => 1;

eval 'use Mo';

ok !$@, 'Mo works with global sub called "" ' . ($@||'');
