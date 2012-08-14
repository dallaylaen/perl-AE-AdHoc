#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;

use AE::AdHoc;

my @warn;
$SIG{__WARN__} = sub { push @warn, shift };

plan tests => 2;

throws_ok {
	ae_recv{ };
} qr(Timeout), "Timeout issued for empty body";

is (scalar @warn, 0, "no warnings");
note "warning: $_" for @warn;
