package AE::AdHoc;

use warnings;
use strict;

=head1 NAME

AE::AdHoc - Simplified  interface for tests/examples of AnyEvent-related code.

=head1 SYNOPSIS

Suppose we need to test some AnyEvent-related code. To avoid hanging up,
we add a timeout. The resulting code is like:

    use AnyEvent;
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(
        after => 10, cb => sub { $cv->croak("Timeout"); }
    );
    do_something(
        sub{ $cv->send(shift); }, sub{ $cv->croak(shift); }
    );
    my $result = $cv->recv();
    undef $timer;
    analyze_do_something( $result );

Now, the same with AE::AdHoc:

    use AE::AdHoc;

    my $result = ae_recv {
         do_something( ae_send, ae_croak );
    } 10; # timeout
    analyze_do_something( $result );

=head1 EXPORT

Functions C<ae_recv>, C<ae_send>, C<ae_croak>, C<ae_begin> and C<ae_end>
are exported by default.

=head1 SUBROUTINES

B<Note>: Anywhere below, C<$cv> means L<AnyEvent>'s conditional variable
responsible for current event loop. See C<condvar> section of L<AnyEvent>.

=cut

our $VERSION = '0.0203';

use Carp;
use AnyEvent::Strict;
use Scalar::Util qw(weaken);

use Exporter;

BEGIN {
	our @ISA = qw(Exporter);
	our @EXPORT = qw(ae_recv ae_send ae_croak ae_begin ae_end);
};

=head2 ae_recv { CODE; } $timeout;

The main entry point of the module.

Run CODE block, enter event loop and wait for $timeout seconds for callbacks
set up in CODE to fire, than die. Return whatever was sent via C<ae_send>.

$timeout is a real number.

Other functions in this module would die if called outside of C<ae_recv>.

=cut

our $cv;
# $cv is global so that
# 1) everyone sees it
# 2) it can act as lock
# 3) it can be localized

sub ae_recv (&@) { ## no critic
	my $code = shift;
	my $timeout = shift || 0;
	# TODO add %options support

	$cv and croak("Nested calls to ae_recv are not allowed");
	local $cv = AnyEvent->condvar;
	my $timer = AnyEvent->timer( after => $timeout,
		cb => sub { $cv->croak("Timeout after $timeout seconds"); }
	);
	$code->();
	return $cv->recv;
	# on exit, $timer is autodestroyed
	# on exit, $cv is restored => destroyed
};

=head2 ae_send

Create callback for normal event loop ending.

Returns a sub that feeds its first argument to $cv->send().

May be called as ae_send->( ... ) if you want to stop event loop immediately
(i.e. in a handcrafted callback).

=head2 ae_croak

Create callback for event loop termination.

Returns a sub that feeds its first argument to $cv->croak().

=head2 ae_begin ( [ sub { ... } ] )

=head2 ae_end

These subroutines provide ability to wait for several events to complete.

The AnyEvent's condition variable has a counter that is incremented by
C<begin()> and decreased by C<end()>. Optionally, the C<begin()> function
may also set a callback.

Whenever the counter reaches zero, either that callback or just C<send()> is
executed on the condvar.

B<Note>: If you do provide callback and want the event loop to stop there,
consider putting C<ae_send-E<gt>( ... )> somewhere inside the callback.

B<Note>: C<ae_begin()> acts at once, and does NOT return a closure. ae_end,
however, returns a subroutine reference just like C<ae_send>/C<ae_croak> do.

See begin/end section in L<AnyEvent>.

=cut

# set prototypes
sub ae_send (); ## no critic
sub ae_croak (); ## no critic
sub ae_end (); ## no critic

# define ae_send, ae_croak and ae_end at once
foreach my $action (qw(send croak end)) {
	my $name = "ae_$action";
	my $code = sub {
		croak("$name called outside ae_recv") unless $cv;
		my $cvcopy = $cv;
		weaken $cvcopy;
		return sub {
			if ($cvcopy) {
				$cvcopy->$action(shift);
			} else {
				# dying in callback is a bad idea, but a warning should be seen
				carp "warning: $name callback called outside ae_recv";
			};
		}; # end closure
	}; # end generated sub
	no strict 'refs'; ## no critic
	no warnings 'prototype'; ## no critic
	*{$name} = $code;
};

sub ae_begin(@) { ## no critic
	croak("ae_begin called outside ae_recv") unless $cv;

	$cv->begin(@_);
};

=head1 GENERAL NOTES

=over

=item * Correctness is always put ahead of speed. In particular,
L<AnyEvent::Strict> is used.

=item * After the event loop started by ae_recv is terminated, no callbacks
created within that ae_recv's invocation will be executed. Instead they issue
a B<warning> that their home event loop has stopped, because dying in
callback is a bad idea.

=back

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ae-adhoc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AE-AdHoc>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AE::AdHoc


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AE-AdHoc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AE-AdHoc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AE-AdHoc>

=item * Search CPAN

L<http://search.cpan.org/dist/AE-AdHoc/>

=back

=head1 SEE ALSO

L<AnyEvent>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AE::AdHoc
