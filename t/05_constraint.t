#!perl

use strict;
use Test::More tests => 5;

use Math::VectorReal;

BEGIN {
  use_ok( 'Astro::HTM::Constants', qw/ :all / );
}

require_ok( 'Astro::HTM' );
require_ok( 'Astro::HTM::Constraint' );

my $direction = vector( 1, 2, 3 );
my $distance = 0.5;

my $constraint = new Astro::HTM::Constraint( direction => $direction,
                                             distance => $distance );

isa_ok( $constraint, "Astro::HTM::Constraint" );

# Check the angle. It should be equal to 1.04719755 to eight decimal places.
my $angle = sprintf( "%.8f", $constraint->angle );
ok( $angle == 1.04719755, "Angle is 1.04719755 radians" );

# Check the distance. It should be 0.5.
my $distance = $constraint->distance;
ok( $distance == 0.5, "Distance is 0.5" );

# Check the directional vector. Its length should be 1. Stringifying
# it using the format "[ %.5f %.5f %.5f ]" should give
# "[ 0.26726 0.53452 0.80178 ]"
my $direction = $constraint->direction;
ok( $direction->length == 1, "Direction vector length is 1" );
ok( $direction->stringify( "[ %.5f %.5f %.5f ]" ) eq
    "[ 0.26726 0.53452 0.80178 ]", "Direction vector is [ 0.26726 0.53452 0.80178 ]" );

# Check the sign. It should be equal to the constant HTM__POSITIVE.
my $sign = $constraint->sign;
ok( $sign == HTM__POSITIVE, "Sign is HTM__POSITIVE" );

# Define a new vector, [1,1,1], and check to see if it's contained
# by this constraint.
my $newvector = vector( 1, 1, 1 );
ok( $constraint->contains( $newvector ), "Constraint contains [ 1, 1, 1 ]" );

# Check stringification, with both the method and auto-stringify.
my $to_string = $constraint->to_string;
ok( $to_string eq '0.267261 0.534522 0.801784 0.5', "to_string results in \"0.267261 0.534522 0.801784 0.5\"");
my $stringify = "$constraint";
ok( $stringify eq '0.267261 0.534522 0.801784 0.5', "stringify results in \"0.267261 0.534522 0.801784 0.5\"");

# Invert, then check sign, distance, and directional vector again. Sign
# and distance should be flipped, directional vector should be the same.
$constraint->invert;
my $invert_sign = $constraint->sign;
ok( $invert_sign == HTM__NEGATIVE, "Inverted sign is HTM__NEGATIVE" );
my $invert_dist = $constraint->distance;
ok( $invert_dist == -0.5, "Inverted distance is -0.5" );
my $invert_dir = $constraint->direction;
ok( $direction->stringify( "[ %.5f %.5f %.5f ]" ) eq
    "[ 0.26726 0.53452 0.80178 ]", "Inverted direction vector is [ 0.26726 0.53452 0.80178 ]" );

