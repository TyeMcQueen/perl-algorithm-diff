# -*- perl -*-
#
# Longest Common Subsequence algorithm
# Copyright 1998 M-J. Dominus. (mjd-perl-diff@plover.com)
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

# Algorithm: See `Longest Common Subsequences', at
# http://www.ics.uci.edu/~eppstein/161/960229.html
# 
# The function `LCS_matrix' constructs the matrix described by this
# reference; then `traverse sequences' traverses the graph implied by
# this matrix and invokes callback functions on each traversed matrix
# element.
#
# $Id: LCS.pm,v 1.7 1998/08/13 00:39:53 mjd Exp mjd $;
#

package Algorithm::Diff;
use strict;
$Algorithm::Diff::VERSION = '0.55';


%Algorithm::Diff::EXPORT_OK = (LCS => 1,
			     diff => 1,
			     traverse_sequences => 1,
			     );

sub import {
  no strict;
  my $package = shift;
  my $caller = caller;
  foreach $func (@_) {
    unless ($ {$package . '::EXPORT_OK'}{$func}) {
      require Carp;
      Carp::croak("$package does not export function `$func'; aborting");
    }
    *{"$ {caller}::$func"} = \&{"$ {package}::$func"};
  }
  1;
}


sub LCS_matrix {
  my @x;
  my $a;				# Sequence #1
  my $b;				# Sequence #2

  $a = shift or usage();
  $b = shift or usage();
  (ref $a eq 'ARRAY') or usage();
  (ref $b eq 'ARRAY') or usage();
  my $eq = shift;
  
  my ($al, $bl);			# Lengths of sequences
  $al = @$a;
  $bl = @$b;

  my ($i, $j);

  $x[0] = [(0) x ($bl+1)];
  for ($i=1; $i<=$al; $i++) {
    my $r = $x[$i] = [];
    $r->[0] = 0;
    for ($j=1; $j<=$bl; $j++) {
      # If the first two items are the same...
      if (defined $eq 
	  ? $eq->($a->[-$i], $b->[-$j])
	  : $a->[-$i] eq $b->[-$j]
	 ) { 
	$r->[$j] = 1 + $x[$i-1][$j-1];
      } else {
	my $pi = $x[$i][$j-1];
	my $pj = $x[$i-1][$j];
	$r->[$j] = ($pi > $pj ? $pi : $pj);
      }
    }
  }

  \@x;
}

sub traverse_sequences {
  my $dispatcher = shift;
  my $a = shift;
  my $b = shift;
  my $equal = shift;
  my $x = LCS_matrix($a, $b, $equal);

  my ($al, $bl) = (scalar(@$x)-1, scalar(@{$x->[0]})-1);
  my ($ap, $bp) = ($al, $bl);
  my $dispf;
  while (1) {
    $dispf = undef;
    my ($ai, $bi) = ($al-$ap, $bl-$bp);
    if ($ap == 0) {
      $dispf = $dispatcher->{A_FINISHED} || $dispatcher->{DISCARD_B};
      $bp--;			# Where to put this?
    } elsif ($bp == 0) {
      $dispf = $dispatcher->{B_FINISHED} || $dispatcher->{DISCARD_A};
      $ap--;			# Where to put this?
    } elsif (defined($equal) 
	     ? $equal->($a->[$ai], $b->[$bi])
	     : $a->[$ai] eq $b->[$bi]
	    ) {
      $dispf = $dispatcher->{MATCH};
      $ap--; 
      $bp--;
    } else {
      if ($x->[$ap][$bp] == $x->[$ap-1][$bp] + 1) {
	$dispf = $dispatcher->{DISCARD_B};
	$bp--;
      } else {
	$dispf = $dispatcher->{DISCARD_A};
	$ap--;
      }
    }
    $dispf->($ai, $bi, @_) if defined $dispf;
    return 1 if $ap == 0 && $bp == 0;
  }
}

sub LCS {
  my $lcs = [];
  my ($a, $b);
  my $functions = { MATCH => sub {push @$lcs, $a->[$_[0]]} };
  
  traverse_sequences($functions, @_);
  wantarray ? @$lcs : $lcs;
}

sub diff {
  my ($a, $b) = @_;
  my @cur_diff = ();
  my @diffs = ();

  my $functions =
    { DISCARD_A => sub {push @cur_diff, ['-', $_[0], $a->[$_[0]]]},
      DISCARD_B => sub {push @cur_diff, ['+', $_[1], $b->[$_[1]]]},
      MATCH => sub { push @diffs, [@cur_diff] if @cur_diff; 
		     @cur_diff = ()
		   },
    };

  traverse_sequences($functions, @_);
  push @diffs, \@cur_diff if @cur_diff;
  wantarray ? @diffs : \@diffs;
}

sub usage {
  require Carp;
  Carp::croak("Usage: LCS([...], [...]); aborting");
}

1;

=head1 NAME

Algorithm::Diff - Compute `intelligent' differences between two files / lists

=head1 SYNOPSIS

  use Algorithm::Diff qw(diff LCS trverse_sequences);

  @lcs = LCS(\@seq1, \@seq2, $comparison_function);

  @diffs = diff(\@seq1, \@seq2, $comparison_function);
  
  traverse_sequences(\@seq1, \@seq2,
                     { MATCH => $callback,
                       DISCARD_A => $callback,
                       DISCARD_B => $callback,
                     },
                     $comparison_function);

=head1 INTRODUCTION

I once read an article written by the authors of C<diff>; they said
that they hard worked very hard on the algorithm until they found the
right one.

I think what they ended up using (and I hope someone will correct me,
because I am not very confident about this) was the `longest common
subsequence' method.  in the LCS problem, you have two sequences of
items:

        a b c d f g h j q z

        a b c d e f g i j k r x y z

and you want to find the longest sequence of items that is present in
both original sequences in the same order.  That is, you want to find
a new sequence I<S> which can be obtained from the first sequence by
deleting some items, and from the secend sequence by deleting other
items.  You also want I<S> to be as long as possible.  In this case
I<S> is

        a b c d f g j z

From there it's only a small step to get diff-like output:

        e   h i   k   q r x y 
        +   - +   +   - + + +

This module solves the LCS problem.  It also includes a canned
function to generate C<diff>-like output.

It might seem from the example above that the LCS of two sequences is
always pretty obvious, but that's not always the case, especially when
the two sequences have many repeated elements.  For example, consider

	a x b y c z p d q
	a b c a x b y c z

A naive approach might start by matching up the C<a> and C<b> that
appear at the beginning of each sequence, like this:

	a x b y c         z p d q
	a   b   c a b y c z

This finds the common subsequence C<a b c z>.  But actually, the LCS
is C<a x b y c z>:

	      a x b y c z p d q
	a b c a x b y c z

=head1 USAGE

This module exports three functions, which we'll deal with in
ascending order of difficulty: C<LCS>, C<diff>, and
C<traverse_sequences>.

=head2 C<LCS>

Given references to two lists of items, C<LCS> returns a list
containing their longest common subsequence.  In scalar context, it
returns a reference to such a list. 

  @lcs    = LCS(\@seq1, \@seq2, $comparison_function);
  $lcsref = LCS(\@seq1, \@seq2, $comparison_function);


C<$comparison_function>, if supplied, should be a function that gets
an item from each input list and returns true if they are considered
equal.  It is optional, and if omitted, defaults to `eq'. 

=head2 C<diff>

  @diffs     = diff(\@seq1, \@seq2, $comparison_function);
  $diffs_ref = diff(\@seq1, \@seq2, $comparison_function);

C<diff> computes the smallest set of additions and deletions necessary
to turn the first sequence into the second, and returns a description
of these changes.  The description is a list of I<hunks>; each hunk
represents a contiguous section of items which should be added,
deleted, or replaced.  The return value of C<diff> is a list of
hunks, or, in scalar context, a reference to such a list.

Here is an example:  The diff of the following two sequences:

  a b c e h j l m n p
  b c d e f j k l m r s t

Result:

 [ 
   [ [ '-', 0, 'a' ] ],       

   [ [ '+', 2, 'd' ] ],

   [ [ '-', 4, 'h' ] , 
     [ '+', 4, 'f' ] ],

   [ [ '+', 6, 'k' ] ],

   [ [ '-', 8, 'n' ], 
     [ '-', 9, 'p' ], 
     [ '+', 9, 'r' ], 
     [ '+', 10, 's' ], 
     [ '+', 11, 't' ],
   ]
 ]


There are five hunks here.  The first hunk says that the C<a> at
position 0 of the first sequence should be deleted (C<->).  The second
hunk says that the C<d> at position 2 of the second sequence should
be inserted (C<+>).  The third hunk says that the C<h> at position 4
of the first sequence should be removed and replaced with the C<f>
from position 4 of the second sequence.  The other two hunks similarly. 

C<diff> accepts an optional comparison function; if specified, it will
be called with pairs of elements and is expected to return true if the
elements are considered equal.  If not specified, it defaults to
C<eq>.

=head2 C<traverse_sequences>

C<traverse_sequences> is the most general facility provided by this
module; C<diff> and C<LCS> are implemented as calls to it.

Imagine that there are two arrows.  Arrow A points to an element of
sequence A, and arrow B points to an element of the sequence B.
Initially, the arrows point to the first elements of the respective
sequences.  C<traverse_sequences> will advance the arrows through the
sequences one element at a time, calling an appropriate user-specified
callback function before each advance.  It willadvance the arrows in
such a way that if there are equal elements C<$A[$i]> and C<$B[$j]>
which are equal and which are part of the LCS, there will be some
moment during the execution of C<traverse_sequences> when arrow A is
pointing to C<$A[$i]> and arrow B is pointing to C<$B[$j]>.  When this
happens, C<traverse_sequences> will call the C<MATCH> callback
function and then it will advance both arrows. 

Otherwise, one of the arrows is pointing to an element of its sequence
that is not part of the LCS.  C<traverse_sequences> will advance that
arrow and will call the C<DISCARD_A> or the C<DISCARD_B> callback,
depending on which arrow it advanced.  If both arrows point to
elements that are not part of the LCS, then C<traverse_sequences> will
advance one of them and call the appropriate callback, but it is not
specified which it will call.

The arguments to C<traverse_sequences> are the two sequences to
traverse, and a callback which specifies the callback functions, like
this:

  traverse_sequences(\@seq1, \@seq2,
                     { MATCH => $callback_1,
                       DISCARD_A => $callback_2,
                       DISCARD_B => $callback_3,
                     },
                    );

Callbacks are invoked with at least the indices of the two arrows as
their arguments.  They are not expected to return any values.  If a
callback is omitted from the table, it is not called.

If arrow A reaches the end of its sequence, before arrow B does,
C<traverse_sequences> will call the C<A_FINISHED> callback when it
advances arrow B, if there is such a function; if not it will call
C<DISCARD_B> instead.  Similarly if arrow B finishes first.
C<traverse_sequences> returns when both arrows are at the ends of
their respective sequences.  It returns true on success and false on
failure.  At present there is no way to fail.

C<traverse_sequences> accepts an optional comparison function; if
specified, it will be called with pairs of elements and is expected to
return true if the elements are considered equal.  If not specified,
or if C<undef>,  it defaults to C<eq>.

Any additional arguments to C<travese_sequences> are passed to the
callback functions.

For examples of how to use this, see the code.  the C<LCS> and C<diff>
functions are implemented on top of C<traverse_sequences>.

=head1 MAILING LIST

To join a low-volume mailing list for announcements related to diff
and Algorithm::Diff, send an empty mail message to
mjd-perl-diff-request@plover.com.

=head1 AUTHOR

Mark-Jason Dominus, mjd-perl-diff@plover.com.  

Visit my diff/LCS web page at http://www.plover.com/~mjd/perl/diff/.



