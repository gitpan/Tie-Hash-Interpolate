use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Tie::Hash::Interpolate') }

tie my %lut, 'Tie::Hash::Interpolate';

## fetch-store non-numbers

eval { $lut{foo} = 1 };
ok($@, "STORE non-number key");

eval { $lut{1} = 'bar' };
ok($@, "STORE non-number value");

eval { my $foo = $lut{'foo'} };
ok($@, "FETCH non-number key");

## fetch-store numbers

$lut{1} = 2;
ok(1, "STORE number key-value");

is($lut{1}, 2, "FETCH number key");

## interpolation tests

eval { undef = $lut{2} };
ok($@, "too few keys");

$lut{3} = 4;

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1,  "extrapolate 0 -> 1");
is($lut{-0}, 1, "extrapolate -0 -> 1");
is($lut{-1}, 0, "extrapolate -1 -> 0");
is($lut{4}, 5,  "extrapolate 4 -> 5");

$lut{-1} = 1;

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1.5,  "extrapolate 0 -> 1.5");
is($lut{-0}, 1.5, "extrapolate -0 -> 1.5");
is($lut{-1}, 1, "extrapolate -1 -> 1");
is($lut{-2}, 0.5, "extrapolate -2 -> 0.5");
is($lut{4}, 5,  "extrapolate 4 -> 5");

my @keys = sort keys %lut;
is_deeply(\@keys, [-1, 1, 3], "keys - deeply");

ok(exists $lut{1}, "exists - ok");
ok(!exists $lut{2}, "exists - not ok");

delete $lut{-1};

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1,  "extrapolate 0 -> 1");
is($lut{-0}, 1, "extrapolate -0 -> 1");
is($lut{-1}, 0, "extrapolate -1 -> 0");
is($lut{4}, 5,  "extrapolate 4 -> 5");

undef %lut;
@keys = sort keys %lut;
is_deeply(\@keys, [], "clear");

## flip the slope

$lut{2} = 0;
$lut{1} = 1;

is($lut{0}, 2,  "extrapolate 0 -> 2");
is($lut{3}, -1,  "extrapolate 3 -> -1");
