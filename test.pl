# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
$^W++;
use lib qw(blib lib);
use Algorithm::Diff qw(diff LCS traverse_sequences);
use Data::Dumper;
use Test;

BEGIN
{
	$|++;
	plan tests => 0;
	$SIG{__DIE__} = sub# breakpoint on die
	{
		$DB::single = 1;
		die @_;
	  }
}

my @a = qw(a b c e h j l m n p);
my @b = qw(b c d e f j k l m r s t);
my @correctResult = qw(b c e j l m);
my $correctResult = join(' ', @correctResult);
my $skippedA = 'a h n p';
my $skippedB = 'd f k r s t';

# From the Algorithm::Diff manpage:
my $correctDiffResult = [
	[ [ '-', 0, 'a' ] ],

	[ [ '+', 2, 'd' ] ],

	[ [ '-', 4, 'h' ], [ '+', 4, 'f' ] ],

	[ [ '+', 6, 'k' ] ],

	[
		[ '-', 8,  'n' ], [ '-', 9,  'p' ],
		[ '+', 9,  'r' ], [ '+', 10, 's' ],
		[ '+', 11, 't' ],
	]
];

my @result = Algorithm::Diff::_longestCommonSubsequence( \@a, \@b );
ok( scalar(@result), 8, "length of _longestCommonSubsequence" );

# result has b[] line#s keyed by a[] line#
# print "result =", join(" ", map { defined($_) ? $_ : 'undef' } @result), "\n";

my @aresult = map { defined( $result[$_] ) ? $a[$_] : () } 0 .. $#result;
my @bresult =
  map { defined( $result[$_] ) ? $b[ $result[$_] ] : () } 0 .. $#result;

ok( "@aresult", $correctResult, "A results" );
ok( "@bresult", $correctResult, "B results" );

my ( @matchedA, @matchedB, @discardsA, @discardsB, $finishedA, $finishedB );

sub match
{
	my ( $a, $b ) = @_;
	push ( @matchedA, $a[$a] );
	push ( @matchedB, $b[$b] );
}

sub discard_b
{
	my ( $a, $b ) = @_;
	push ( @discardsB, $b[$b] );
}

sub discard_a
{
	my ( $a, $b ) = @_;
	push ( @discardsA, $a[$a] );
}

sub finished_a
{
	$finishedA = shift;
}

sub finished_b
{
	$finishedB = shift;
}

traverse_sequences(
	\@a,
	\@b,
	{
		MATCH     => \&match,
		DISCARD_A => \&discard_a,
		DISCARD_B => \&discard_b
	}
);

ok( "@matchedA", $correctResult);
ok( "@matchedB", $correctResult);
ok( "@discardsA", $skippedA);
ok( "@discardsB", $skippedB);

@matchedA = @matchedB = @discardsA = @discardsB = ();
$finishedA = $finishedB = undef;

traverse_sequences(
	\@a,
	\@b,
	{
		MATCH      => \&match,
		DISCARD_A  => \&discard_a,
		DISCARD_B  => \&discard_b,
		A_FINISHED => \&finished_a,
		B_FINISHED => \&finished_b,
	}
);

ok( "@matchedA", $correctResult);
ok( "@matchedB", $correctResult);
ok( "@discardsA", 'a h');
ok( "@discardsB", 'd f k');
ok( $finishedA, 8 );
ok( $finishedB, 9 );

my @lcs = LCS( \@a, \@b );
ok( "@lcs", $correctResult );

# Compare the diff output with the one from the Algorithm::Diff manpage.
my $diff = diff( \@a, \@b );
$Data::Dumper::Indent = 0;
my $cds = Dumper($correctDiffResult);
my $dds = Dumper($diff);
ok( $dds, $cds );
