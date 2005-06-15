#!perl

use strict;
use Test::More qw/ no_plan /;

use Math::VectorReal;

BEGIN {
  use_ok( 'Astro::HTM::Constants' );
}

require_ok( 'Astro::HTM' );
require_ok( 'Astro::HTM::Constraint' );
require_ok( 'Astro::HTM::Convex' );

# First, set up a default Convex object.
my $convex = new Astro::HTM::Convex();
isa_ok( $convex, "Astro::HTM::Convex" );
