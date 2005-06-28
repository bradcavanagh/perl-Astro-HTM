#!perl

use strict;
use Test::More qw/ no_plan /;

require_ok( 'Astro::HTM::Range' );

my $range = new Astro::HTM::Range();

isa_ok( $range, 'Astro::HTM::Range' );

my @los = ( 10, 230, 100000, 800000 );
my @his = ( 50, 330, 200000, 810000 );

for( 0 .. scalar( @los ) ) {
  $range->add_range( $los[$_], $his[$_] );
}

