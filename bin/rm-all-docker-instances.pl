#!/usr/bin/perl

use strict;
use warnings;

use feature qw(say);
use Data::Dumper;

my @lines = split '\n', `docker ps -a`;
shift @lines; #remove header line
 
my @names = map { (split( /\s+/, $_))[-1]} @lines ; 
map {say "removing: ".`docker rm $_`} @names;
