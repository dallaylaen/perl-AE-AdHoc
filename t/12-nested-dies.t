#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;

use AE::AdHoc;

plan tests => 1;
throws_ok {
	ae_recv {
		ae_recv {
		} 1;
	} 2;
} qr(nested)i, "Nested calls not allowed";
