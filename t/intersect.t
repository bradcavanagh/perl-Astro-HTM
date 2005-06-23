#!perl

use strict;
use Test::More qw/ no_plan /;
use Data::Dumper;

require_ok( 'Astro::HTM::Index' );
require_ok( 'Astro::HTM::Functions' );
require_ok( 'Astro::HTM::Constraint' );
require_ok( 'Astro::HTM::Range' );

#my $ra = 135.23;
#my $dec = 45;
#my $radius_arcsec = 10;
#my $radius = $radius_arcsec / 206264;
#my $distance = cos( $radius );
#print "distance: $distance\n";
my $level = 20;
my $index = new Astro::HTM::Index( maxlevel => $level,
                                   buildlevel => 3 );
my $range = new Astro::HTM::Range;
#my $direction = new Math::VectorReal( Astro::HTM::Functions->radec_to_vector( $ra, $dec ) );
#print $direction;
#my $constraint = new Astro::HTM::Constraint( direction => $direction,
#                                             distance => $distance );
#print Dumper $constraint;
my $constraint1 = new Astro::HTM::Constraint( direction => new Math::VectorReal( 0.771516846445334, -0.5455446251029433, 0.327326775061766 ),
                                              distance => 0.8480775301220802 );
my $constraint2 = new Astro::HTM::Constraint( direction => new Math::VectorReal( 0.9984293197709027, 0.007884263528457561, 0.05546829554282793 ),
                                              distance => 0.780775301220802 );
my $constraint3 = new Astro::HTM::Constraint( direction => new Math::VectorReal( 0.49999992263776794, 0.49999992263776794, 0.7071068905932484 ),
                                              distance => 0.634807753012208 );
my $convex = new Astro::HTM::Convex();
$convex->add_constraint( $constraint1 );
$convex->add_constraint( $constraint2 );
$convex->add_constraint( $constraint3 );
print $convex->to_string() . "\n";
my $domain = new Astro::HTM::Domain();
$domain->olevel( $level );
$domain->add_convex( $convex );
#print Dumper $domain;

$domain->intersect( index => \$index,
                    range => \$range,
                    varlen => 1 );
print $range->to_string( 1 );
