#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Test::Exception;
use AnyEvent::Strict;
use Data::Dumper;

use AE::AdHoc;

my $result;

# We use sub {} in timers here because timer passes random args to its
# callback. See L<::AnyEvent> timer section.

lives_ok {
	my ($t1, $t2);
	$result = ae_recv {
		$t1 = AnyEvent->timer( after => 0.01,
			cb => sub { ae_goal("task1")->() }
		);
		$t2 = AnyEvent->timer( after => 0.01,
			cb => sub { ae_goal("task2", "fixed")->() }
		);
	} 0.02;
} "No timeout - goals complete";

note "Got: ".Dumper($result);

is_deeply ($result,
	{ task1 => [], task2 => [ "fixed" ]},
	"Results as expected (sans timer callback args)"
);
is_deeply (AE::AdHoc->results(), $result, "AE::AdHoc::results consistent");
is_deeply (AE::AdHoc->goals(), {}, "AE::AdHoc::goals is empty (all complete)");

