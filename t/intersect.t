#!perl

use strict;
use Test::More qw/ no_plan /;
use Data::Dumper;

require_ok( 'Astro::HTM::Index' );
require_ok( 'Astro::HTM::Functions' );
require_ok( 'Astro::HTM::Constraint' );
require_ok( 'Astro::HTM::Range' );

my $ra = 25.23;
my $dec = 0.9;
my $radius_arcsec = 10;
my $radius = $radius_arcsec / 206264;
my $distance = cos( $radius );
print "distance: $distance\n";
my $level = 5;
my $index = new Astro::HTM::Index( maxlevel => $level,
                                   buildlevel => 5 );
my $range = new Astro::HTM::Range;
my $direction = new Math::VectorReal( Astro::HTM::Functions->radec_to_vector( $ra, $dec ) );
print $direction;
my $constraint = new Astro::HTM::Constraint( direction => $direction,
                                             distance => $distance );
#print Dumper $constraint;
my $convex = new Astro::HTM::Convex();
$convex->add_constraint( $constraint );
my $domain = new Astro::HTM::Domain();
$domain->olevel( $level );
$domain->add_convex( $convex );
print Dumper $domain;

$domain->intersect( index => \$index,
                    range => \$range,
                    varlen => 1 );
#print $range->to_string;
