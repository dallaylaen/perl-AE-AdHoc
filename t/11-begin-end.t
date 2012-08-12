#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;

use AE::AdHoc;

my @trace;
my $val;
my @timers;

plan tests => 5;

lives_ok {
	my $timer;
	ae_recv {
		ae_begin;
		$timer = AnyEvent->timer( after => 0.01, cb => ae_end );
	} 1;
} "A simple begin/end example works";

throws_ok {
	my $timer;
	ae_recv {
		ae_begin;
		ae_begin;
		$timer = AnyEvent->timer( after => 0.01, cb => ae_end );
	} 0.02;
} qr(Timeout), "A simple example with extra begin dies";

lives_ok {
	ae_recv {
		foreach my $delay (0.01, 0.02, 0.03) {
			push @timers, AnyEvent->timer( after => $delay, cb => sub {
				push @trace, $delay;
				ae_end->();
			});
		};
		ae_begin( sub { ae_send->(++$val) } ) for (1,2);
	} 1;
} "More complex example works";

is ($val, 1, "Begin's callback executed once");
is_deeply(\@trace, [0.01, 0.02], "end->() executed twice");

