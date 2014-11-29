#!/usr/bin/perl -w
#
# `Diff' program in Perl
# Copyright 1998 M-J. Dominus. (mjd-perl-diff@plover.com)
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Altered to output in `context diff' format (but without context)
# September 1998 Christian Murphy (cpm@muc.de)
#
# Command-line arguments and context lines feature added
# September 1998 Amir D. Karger (karger@bead.aecom.yu.edu)
#
# In this file, "item" usually means "line of text", and "item number" usually
# means "line number". But theoretically the code could be used more generally
use strict;

use Algorithm::LCS qw(diff);
use File::stat;
use vars qw ($opt_C $opt_c $opt_u $opt_U);
use Getopt::Std;

my $usage = << "ENDUSAGE";
Usage: $0 [{-c | -u}] [{-C | -U} lines] oldfile newfile
    -c will do a context diff with 3 lines of context
    -C will do a context diff with 'lines' lines of context
    -u will do a unified diff with 3 lines of context
    -U will do a unified diff with 'lines' lines of context
ENDUSAGE

getopts('U:C:cu') or bag("$usage");
bag("$usage") unless @ARGV == 2;
my ($file1, $file2) = @ARGV;
if (defined $opt_C || defined $opt_c) {
    $opt_c = ""; # -c on if -C given on command line
    $opt_u = undef;
} elsif (defined $opt_U || defined $opt_u) {
    $opt_u = ""; # -u on if -U given on command line
    $opt_c = undef;
} else {
    $opt_c = ""; # by default, do context diff, not old diff
}

my ($char1, $char2); # string to print before file names
my $Context_Lines; # lines of context to print
if (defined $opt_c) {
    $Context_Lines = defined $opt_C ? $opt_C : 3;
    $char1 = '*' x 3; $char2 = '-' x 3;
} elsif (defined $opt_u) {
    $Context_Lines = defined $opt_U ? $opt_U : 3;
    $char1 = '-' x 3; $char2 = '+' x 3;
}

# After we've read up to a certain point in each file, the number of items
# we've read from each file will differ by $FLD (could be 0)
my $File_Length_Difference = 0;

open (F1, $file1) or bag("Couldn't open $file1: $!");
open (F2, $file2) or bag("Couldn't open $file2: $!");
my (@f1, @f2);
chomp(@f1 = <F1>);
close F1;
chomp(@f2 = <F2>);
close F2;

# diff yields lots of pieces, each of which is basically a Block object
my $diffs = diff(\@f1, \@f2);
exit 0 unless @$diffs;

my $st = stat($file1);
print "$char1 $file1\t", scalar localtime($st->mtime), "\n";
$st = stat($file2);
print "$char2 $file2\t", scalar localtime($st->mtime), "\n";

my ($lines_subtracted, $lines_added) = (0, 0);
foreach my $piece (@$diffs) {
  print "***************\n";
  do_a_chunk ($piece, \@f1, \@f2, 2);
}
exit 1;

sub do_a_chunk
{
  my ($chunk, $f1, $f2, $context_lines) = @_;
  my (@file1_ops, @file2_ops);
  my (@file1_nos, @file2_nos);
  my $do_op = '!';

  foreach my $line (@$chunk) {
    my ($sign, $line_no, $text) = @$line;
    if ($sign eq '-') {
      $lines_subtracted++;
      push (@file1_ops, $text);
      push (@file1_nos, $line_no);
    } elsif ($sign eq '+') {
      push (@file2_ops, $text);
      push (@file2_nos, $line_no);
      $lines_added++;
    } else {
      die "unknown sign: $sign, stopped at ";
    }
  }
  my $offset = $lines_added - $lines_subtracted;
  unless (@file1_ops) {
  	my $diff_offset = $file2_nos[-1] - $offset;
	$diff_offset = -1 if ($diff_offset < -1);
	push(@file1_nos, $diff_offset);
	$do_op = '+';
  }
  unless (@file2_ops) {
  	my $diff_offset = $file1_nos[-1] + $offset;
	$diff_offset = -1 if ($diff_offset < -1);
	push(@file2_nos, $diff_offset);
	$do_op = '-';
  }
  do_part([], [], $do_op, '-', \@file1_ops, \@file1_nos);
  do_part([], [], $do_op, '+', \@file2_ops, \@file2_nos);
}

sub do_part
{
  my ($context_before, $context_after,
    $do_op, $sign, $file_ops, $file_nos) = @_;
  my $start_context = $file_nos->[0];
  my $end_context = $file_nos->[-1];
  my (@context_before, @context_after);

  print STDOUT ($sign eq '-') ? '***' : '---';
  print ' ';
  if ($start_context == $end_context) {
    print $start_context + 1;
  } else {
    print $start_context + 1, ',', $end_context + 1;
  }
  print ' ';
  print STDOUT ($sign eq '-') ? '***' : '---';
  print "\n";
  for (@$context_before) {
	  print "  ", $_, "\n";
  }
  for (@$file_ops) {
	  print "$do_op ", $_, "\n";
  }
  for (@$context_after) {
	  print "  ", $_, "\n";
  }
}

sub bag {
  my $msg = shift;
  $msg .= "\n";
  warn $msg;
  exit 2;

