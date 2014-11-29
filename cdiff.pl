#!/usr/bin/perl -w
#
# `Diff' program in Perl
# Copyright 1998 M-J. Dominus. (mjd-perl-diff@plover.com)
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# hacked to do context diffs, cpm sep 1998
#
use strict;

use Algorithm::LCS qw(diff);
use File::stat;

bag("Usage: $0 oldfile newfile") unless @ARGV == 2;

my ($file1, $file2) = @ARGV;

open (F1, $file1) or bag("Couldn't open $file1: $!");
open (F2, $file2) or bag("Couldn't open $file2: $!");
my (@f1, @f2);
chomp(@f1 = <F1>);
close F1;
chomp(@f2 = <F2>);
close F2;

my $diffs = diff(\@f1, \@f2);
exit 0 unless @$diffs;

my $st = stat($file1);
print "*** $file1\t", scalar localtime($st->mtime), "\n";
$st = stat($file2);
print "--- $file2\t", scalar localtime($st->mtime), "\n";

my ($lines_subtracted, $lines_added) = (0, 0);
foreach my $chunk (@$diffs) {
  print "***************\n";
  do_a_chunk ($chunk, \@f1, \@f2, 2);
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
}
