#!perl

use strict;
use Test::More tests => 40;

BEGIN {
  use_ok( 'Astro::HTM::Constants', qw/ :all / );
}

require_ok( 'Astro::HTM::Functions' );

# Test level 10 HTM name to ID.
  {
    my $name10 = "N32030330012";
    my $id10 = 16305926;
    my $returned_id10 = Astro::HTM::Functions->name_to_id( $name10 );
    ok( $returned_id10 == $id10, "Converting level 10 HTM name to ID via name_to_id()" );
  }

# Test level 20 HTM name to ID (this checks 64-bit integers).
  {
    my $name20 = "N320303300120212220333";
    my $id20 = 17098002819647;
    my $returned_id20 = Astro::HTM::Functions->name_to_id( $name20 );
    ok( $returned_id20 == $id20, "Converting level 20 HTM name to ID via name_to_id()" );
  }

# Test RA/Dec to level 10 HTM ID.
  {
    my $ra10 = 10;
    my $dec10 = 10;
    my $radec_id10 = 16305926;
    my $returned_radec_id10 = Astro::HTM::Functions->lookup_radec_id( $ra10, $dec10, 10 );
    ok( $returned_radec_id10 == $radec_id10, "Converting RA and Dec to level 10 HTM ID via lookup_radec_id()" );
  }

# Test RA/Dec to level 20 HTM ID (this checks 64-bit integers).
  {
    my $ra20 = 10;
    my $dec20 = 10;
    my $radec_id20 = 17098002819647;
    my $returned_radec_id20 = Astro::HTM::Functions->lookup_radec_id( $ra20, $dec20, 20 );
    ok( $returned_radec_id20 == $radec_id20, "Converting RA and Dec to level 20 HTM id via lookup_radec_id()" );
  }

# Test level 10 HTM ID to name.
  {
    my $id10 = 16305926;
    my $name10 = "N32030330012";
    my $returned_name10 = Astro::HTM::Functions->id_to_name( $id10 );
    ok( $returned_name10 eq $name10, "Converting level 10 HTM ID to name via id_to_name()" );
  }

# Test level 20 HTM ID to name.
  {
    my $id20 = 17098002819647;
    my $name20 = "N320303300120212220333";
    my $returned_name20 = Astro::HTM::Functions->id_to_name( $id20 );
    ok( $returned_name20 eq $name20, "Converting level 20 HTM ID to name via id_to_name()" );
  }

# Test some conversions of RA/Dec to level 10 names.
  {
    my $ra = 10;
    my $dec = 10;
    my $level = 10;
    my $name = "N32030330012";
    my $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 45;
    $dec = 45;
    $name = "N33313333303";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 90;
    $dec = -45;
    $name = "S10102012001";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 180;
    $dec = 85;
    $name = "N12200000001";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 275;
    $dec = -85;
    $name = "S31000200223";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );
  }

# Test some conversions of RA/Dec to level 14 names.
  {
    my $ra = 10;
    my $dec = 10;
    my $level = 14;
    my $name = "N320303300120212";
    my $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 45;
    $dec = 45;
    $name = "N333133333033333";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 90;
    $dec = -45;
    $name = "S101020120012010";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 180;
    $dec = 85;
    $name = "N122000000012010";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 275;
    $dec = -85;
    $name = "S310002002230232";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );
  }

# Test some conversions of RA/Dec to level 20 names.
  {
    my $ra = 10;
    my $dec = 10;
    my $level = 20;
    my $name = "N320303300120212220333";
    my $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 45;
    $dec = 45;
    $name = "N333133333033333000033";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 90;
    $dec = -45;
    $name = "S101020120012010021210";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 180;
    $dec = 85;
    $name = "N122000000012010000200";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 275;
    $dec = -85;
    $name = "S310002002230232113202";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 56;
    $dec = 90;
    $name = "N311000000000000000000";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 56;
    $dec = -90;
    $name = "S001000000000000000000";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 0;
    $dec = 30;
    $name = "N322102120010210000002";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 0;
    $dec = -30;
    $name = "S001201210020120000001";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 360;
    $dec = 30;
    $name = "N322102120010210000002";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 360;
    $dec = -30;
    $name = "S001201210020120000001";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 30;
    $dec = 30;
    $name = "N333202322022310012310";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 30;
    $dec = -30;
    $name = "S033001311011320021320";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 180.0000001;
    $dec = 30;
    $name = "N122121212121212121212";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 180.0000001;
    $dec = -30;
    $name = "S201212121212121212121";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 300;
    $dec = 30;
    $name = "N033202322022310012310";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

    $ra = 300;
    $dec = -30;
    $name = "S333001311011320021320";
    $returned_name = Astro::HTM::Functions->lookup_radec( $ra, $dec, $level );
    ok( $returned_name eq $name, "Converting RA/Dec to level $level name via lookup_radec (RA=$ra, Dec=$dec)" );

  }

# Test lookup from vector.
  {
    my $x = -0.0871557427476581;
    my $y = 0;
    my $z = 0.9961946980917455;
    my $level = 20;
    my $name = "N110001002001002001002";
    my $returned_name = Astro::HTM::Functions->lookup( $x, $y, $z, $level );
    ok( $returned_name eq $name, "Converting vector to level $level name via lookup" );
  }

# Test converting from vector to ID and back.
  {
    my $x = 0.6;
    my $y = 0.5;
    my $z = 0.6;
    my $level = 10;

    my $id = Astro::HTM::Functions->lookup_vector_id( $x, $y, $z, $level );
    my @tri = Astro::HTM::Functions->id_to_point( $id );
    my $nid = Astro::HTM::Functions->lookup_vector_id( @tri, $level );
    ok( abs( $x - $tri[0] ) < 0.01, "Converting vector to ID and back to vector for level $level, x component" );
    ok( abs( $y - $tri[1] ) < 0.01, "Converting vector to ID and back to vector for level $level, y component" );
    ok( abs( $z - $tri[2] ) < 0.01, "Converting vector to ID and back to vector for level $level, z component" );
    ok( $nid == $id, "Converting vector to ID to vector to ID for level $level" );

  }
