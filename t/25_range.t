#!perl

use strict;
use Test::More qw/ no_plan /;
use Algorithm::SkipList;

require_ok( 'Astro::HTM::Range' );

my $my_los1 = new Algorithm::SkipList;
my $my_his1 = new Algorithm::SkipList;

my $range = new Astro::HTM::Range( my_los => $my_los1,
                                   my_his => $my_his1 );

isa_ok( $range, 'Astro::HTM::Range' );

my @los = ( 10, 230, 100000, 800000 );
my @his = ( 50, 330, 200000, 810000 );

for( 0 .. scalar( @los ) ) {
  $range->add_range( $los[$_], $his[$_] );
}

