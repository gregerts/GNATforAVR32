#! /usr/bin/perl

use strict;

my $in = 0;
my $out = 0;
my $max = $ARGV[0] + 0;

while (<STDIN>) {
    $in++;
    if (/^([\dA-F]+):([\dA-F]+):([\dA-F]+):([\dA-F]+)$/) {
	my $a = hex($1);
	my $b = hex($2);
	my $c = hex($3);
	if (hex($4) == ($a ^ ($b ^ $c))) {
	    $out++;
	    printf("%d %d %d\n", $a, $b, $c);
	    next if $out < $max;
	    exit;
	}
    } 
    print STDERR $in, ":\t", $_;
}
