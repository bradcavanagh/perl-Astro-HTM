#!perl

use strict;
use Test::More qw/ no_plan /;

require_ok( 'Astro::HTM::Range' );

my $range = new Astro::HTM::Range();

isa_ok( $range, 'Astro::HTM::Range' );

my @los = ( 10, 230, 100000, 800000 );
my @his = ( 50, 330, 200000, 810000 );

for( 0 .. $#los ) {
  $range->add_range( $los[$_], $his[$_] );
}

my $isin = $range->is_in( 200 );
is( $isin, 0, "200 is not in the range" );
$isin = $range->is_in( 250 );
is( $isin, 1, "250 is in the range" );

