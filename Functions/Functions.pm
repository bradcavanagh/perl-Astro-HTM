package Astro::HTM::Functions;

=head1 NAME

Astro::HTM::Functions - provide general functions for HTMs.

=head1 SYNOPSIS

  use Astro::HTM::Functions;

  my $point = Astro::HTM::Functions->id_to_point( $htmID );

=head1 DESCRIPTION

This package provides general purpose routines that are not
associated with any particular class but are needed for implementing
HTM.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Data::Dumper;

use Math::Trig qw/ acos /;
use Math::VectorReal;

use Astro::HTM::Convex;
use Astro::HTM::Constraint;
use Astro::HTM::Domain;
use Astro::HTM::Index;
use Astro::HTM::QuadNode;

use Astro::HTM::Constants qw/ :all /;

# Set up an "Astro::HTM::Base" class.
use Class::Struct 'Astro::HTM::Base' => { name => '$',
                                          ID => '$',
                                          v1 => '$',
                                          v2 => '$',
                                          v3 => '$',
                                        };

our $VERSION = '0.01';
our $DEBUG = 0;

# Set up some global variables.
my @n0 = ( 1, 0, 4 );
my @n1 = ( 4, 0, 3 );
my @n2 = ( 3, 0, 2 );
my @n3 = ( 2, 0, 1 );
my @N_indexes = ( [ @n0 ], [ @n1 ], [ @n2 ], [ @n3 ] );

my @s0 = ( 1, 5, 2 );
my @s1 = ( 2, 5, 3 );
my @s2 = ( 3, 5, 4 );
my @s3 = ( 4, 5, 1 );
my @S_indexes = ( [ @s0 ], [ @s1 ], [ @s2 ], [ @s3 ] );

my @a0 = ( 0, 0, 1 );
my @a1 = ( 1, 0, 0 );
my @a2 = ( 0, 1, 0 );
my @a3 = ( -1, 0, 0 );
my @a4 = ( 0, -1, 0 );
my @a5 = ( 0, 0, -1 );
my @anchor = ( [ @a0 ], [ @a1 ], [ @a2 ], [ @a3 ], [ @a4 ], [ @a5 ] );

my @bases = ( new Astro::HTM::Base( name => 'S2',
                                    ID => 10,
                                    v1 => 3,
                                    v2 => 5,
                                    v3 => 4 ),
              new Astro::HTM::Base( name => 'N1',
                                    ID => 13,
                                    v1 => 4,
                                    v2 => 0,
                                    v3 => 3 ),
              new Astro::HTM::Base ( name => 'S1',
                                     ID => 9,
                                     v1 => 2,
                                     v2 => 5,
                                     v3 => 3 ),
              new Astro::HTM::Base ( name => 'N2',
                                     ID => 14,
                                     v1 => 3,
                                     v2 => 0,
                                     v3 => 2 ),
              new Astro::HTM::Base ( name => 'S3',
                                     ID => 11,
                                     v1 => 4,
                                     v2 => 5,
                                     v3 => 1 ),
              new Astro::HTM::Base ( name => 'N0',
                                     ID => 12,
                                     v1 => 1,
                                     v2 => 0,
                                     v3 => 4 ),
              new Astro::HTM::Base ( name => 'S0',
                                     ID => 8,
                                     v1 => 1,
                                     v2 => 5,
                                     v3 => 2 ),
              new Astro::HTM::Base ( name => 'N3',
                                     ID => 15,
                                     v1 => 2,
                                     v2 => 0,
                                     v3 => 1 )
            );

=head1 METHODS

There are no instance methods, only class (static) methods.

=over 4

=item B<startpane>

=cut

sub startpane {
  my $self = shift;

  my $v1 = shift; # array reference
  my $v2 = shift; # array reference
  my $v3 = shift; # array reference
  my $xin = shift; # real
  my $yin = shift; # real
  my $zin = shift; # real
  my $name_ref = shift; # scalar reference

  my @tvec;
  my $baseID;
  my $baseindex = 0;

  if( ( $xin > 0 ) && ( $yin >= 0 ) ) {
    $baseindex = ( ( $zin >= 0 ) ? HTM__BASE_IN3 : HTM__BASE_IS0 );
  } elsif( ( $xin <= 0 ) && ( $yin > 0 ) ) {
    $baseindex = ( ( $zin >= 0 ) ? HTM__BASE_IN2 : HTM__BASE_IS1 );
  } elsif( ( $xin < 0 ) && ( $yin <= 0 ) ) {
    $baseindex = ( ( $zin >= 0 ) ? HTM__BASE_IN1 : HTM__BASE_IS2 );
  } elsif( ( $xin >= 0 ) && ( $yin < 0 ) ) {
    $baseindex = ( ( $zin >= 0 ) ? HTM__BASE_IN0 : HTM__BASE_IS3 );
  } else {
    croak "Could not assign base index based on xin=$xin, yin=$yin, zin=$zin in Astro::HTM::Functions->startpane()";
  }

  $baseID = $bases[$baseindex]->ID;
  print "baseID = $baseID\n" if $DEBUG;
  print "baseindex = $baseindex\n" if $DEBUG;
  print "bases baseindex v1 = " . $bases[$baseindex]->v1 . "\n" if $DEBUG;
  print "bases baseindex v2 = " . $bases[$baseindex]->v2 . "\n" if $DEBUG;
  print "bases baseindex v3 = " . $bases[$baseindex]->v3 . "\n" if $DEBUG;

  @tvec = @anchor[$bases[$baseindex]->v1];
  print "tvec:\n" if $DEBUG;
  print Dumper \@tvec if $DEBUG;
  $v1->[0] = $tvec[0][0];
  $v1->[1] = $tvec[0][1];
  $v1->[2] = $tvec[0][2];

  @tvec = @anchor[$bases[$baseindex]->v2];
  print "tvec:\n" if $DEBUG;
  print Dumper \@tvec if $DEBUG;
  $v2->[0] = $tvec[0][0];
  $v2->[1] = $tvec[0][1];
  $v2->[2] = $tvec[0][2];

  @tvec = @anchor[$bases[$baseindex]->v3];
  print "tvec:\n" if $DEBUG;
  print Dumper \@tvec if $DEBUG;
  $v3->[0] = $tvec[0][0];
  $v3->[1] = $tvec[0][1];
  $v3->[2] = $tvec[0][2];

  ${$name_ref} .= $bases[$baseindex]->name;
  return $baseID;
}

=item B<distance>

=cut

sub distance {
  my $self = shift;

  my $v1 = shift; # array ref
  my $v2 = shift; # array ref

  my $prod = 0;
  for( my $i = 0; $i < scalar( @$v1 ); $i++ ) {
    $prod += $v1->[$i] * $v2->[$i];
  }
  my $dist = acos( $prod );
  return $dist;
}

=item B<distance_id>

=cut

sub distance_id {
  my $self = shift;

  my $htmid1 = shift; # scalar
  my $htmid2 = shift; # scalar

  my @v1 = Astro::HTM::Functions->id_to_point_id( $htmid1 );
  my @v2 = Astro::HTM::Functions->id_to_point_id( $htmid2 );

  return Astro::HTM::Functions->distance( \@v1, \@v2 );
}

=item B<distance_name>

=cut

sub distance_name {
  my $self = shift;

  my $name1 = shift; # scalar
  my $name2 = shift; # scalar

  my @v1 = Astro::HTM::Functions->id_to_point( $name1 );
  my @v2 = Astro::HTM::Functions->id_to_point( $name2 );

  return Astro::HTM::Functions->distance( \@v1, \@v2 );
}

=item B<id_level>

=cut

sub id_level {
  my $self = shift;

  my $htmid = shift; # scalar

  my $size = 0;
  my $i;

  for( $i = 0; $i < HTM__IDSIZE; $i += 2 ) {
    if( ( ( $htmid << $i ) & HTM__IDHIGHBIT ) > 0 ) {
      last;
    }
  }
  $size = ( HTM__IDSIZE - $i ) >> 1;

  return $size - 2;
}

=item B<id_to_name>

=cut

sub id_to_name {
  my $self = shift;

  my $id = shift; # scalar
print "id = $id\n" if $DEBUG;
  my $size = 0;
  my $i;
  my $c;

  for( $i = 0; $i < HTM__IDSIZE; $i+=2 ) {
print "i = $i\n" if $DEBUG;
    my $x8 = ( ( $id << $i ) & HTM__IDHIGHBIT );
print "calculated x8 = $x8\n" if $DEBUG;
    my $x4 = ( ( $id << $i ) & HTM__IDHIGHBIT2 );
print "calculated x4 = $x4\n" if $DEBUG;
    if( $x8 != 0 ) {
      last;
    }
    if( $x4 != 0 ) {
      croak "ID $id is invalid";
    }
  }

  if( $id == 0 ) {
    croak "ID $id is invalid";
  }

  $size = ( HTM__IDSIZE - $i ) >> 1;
  print "size is $size\n" if $DEBUG;

  my $name = '';
  for( $i = 0; $i < $size - 1; $i++ ) {
print "i = $i\n" if $DEBUG;
    $c = ( ( $id >> ( $i * 2 ) ) & 3 );
print "adding $c to front of $name\n" if $DEBUG;
    $name = $c . $name;
  }
  if( ( ( $id >> ( $size * 2 - 2 ) ) & 1 ) > 0 ) {
    $name = 'N' . $name;
  } else {
    $name = 'S' . $name;
  }

  return $name;
}

=item B<id_to_point>

=cut

sub id_to_point {
  my $self = shift;

  my $htmid = shift; #scalar

  my $name = Astro::HTM::Functions->id_to_name( $htmid );
  return Astro::HTM::Functions->id_to_point_name( $name );
}

=item B<id_to_point_name>

=cut

sub id_to_point_name {
  my $self = shift;

  my $name = shift; # scalar;

  my @ret;

  my @tri = Astro::HTM::Functions->name_to_triangle( $name );

  my ( @v0, @v1, @v2 );
  {
    no warnings;
    @v0 = @tri[0];
    @v1 = @tri[1];
    @v2 = @tri[2];
  }

  my ( $center_x, $center_y, $center_z, $sum );

  $center_x = $v0[0][0] + $v1[0][0] + $v2[0][0];
  $center_y = $v0[0][1] + $v1[0][1] + $v2[0][1];
  $center_z = $v0[0][2] + $v1[0][2] + $v2[0][2];
  $sum = sqrt( $center_x * $center_x + $center_y * $center_y + $center_z * $center_z );
  $center_x /= $sum;
  $center_y /= $sum;
  $center_z /= $sum;

  $ret[0] = $center_x;
  $ret[1] = $center_y;
  $ret[2] = $center_z;

  return @ret;
}

=item B<isinside>

=cut

sub isinside {
  my $self = shift;

  my $p = shift; # array reference
  my $v1 = shift; # array reference
  my $v2 = shift; # array reference
  my $v3 = shift; # array reference

  print "v1:\n" if $DEBUG;
  print Dumper $v1 if $DEBUG;
  print "v2:\n"if $DEBUG;
  print Dumper $v2 if $DEBUG;
  print "v3:\n" if $DEBUG;
  print Dumper $v3 if $DEBUG;

  my $vec1 = vector( @$v1 );
  my $vec2 = vector( @$v2 );
  my $vec3 = vector( @$v3 );
  my $pvec = vector( @$p );

  if( ( $pvec . ( $vec1 x $vec2 ) ) < ( -1.0 * HTM__GEPSILON ) ) {
    print "returning false from 1\n" if $DEBUG;
    return 0;
  }
  if( ( $pvec . ( $vec2 x $vec3 ) ) < ( -1.0 * HTM__GEPSILON ) ) {
    print "returning false from 2\n" if $DEBUG;

    return 0;
  }
  if( ( $pvec . ( $vec3 x $vec1 ) ) < ( -1.0 * HTM__GEPSILON ) ) {
    print "returning false from 3\n" if $DEBUG;
    return 0;
  }
  return 1;
}

=item B<lookup>

=cut

sub lookup {
  my $self = shift;

  my $x = shift; # scalar
  my $y = shift; # scalar
  my $z = shift; # scalar
  my $depth = shift; #scalar
print "x = $x y = $y z = $z\n" if $DEBUG;
  my $rstat = 0;
  my $startID;
  my $name = '';

  my ( @v0, @v1, @v2, @w0, @w1, @w2, @p );
  my $dtmp = 0;

  $p[0] = $x;
  $p[1] = $y;
  $p[2] = $z;

  print "p: \n" if $DEBUG;
  print Dumper \@p if $DEBUG;

  # Get the ID of the level 0 triangle and its starting vertices.
  $startID = Astro::HTM::Functions->startpane( \@v0, \@v1, \@v2, $x, $y, $z, \$name );

  print "v vectors:\n" if $DEBUG;
  print Dumper \@v0 if $DEBUG;
  print Dumper \@v1 if $DEBUG;
  print Dumper \@v2 if $DEBUG;

  # Start searching for the children.
  while( $depth-- > 0 ) {

    print "in lookup: depth = $depth name = $name\n" if $DEBUG;

    Astro::HTM::Functions->m4_midpoint( \@v0, \@v1, \@w2 );
    Astro::HTM::Functions->m4_midpoint( \@v1, \@v2, \@w0 );
    Astro::HTM::Functions->m4_midpoint( \@v2, \@v0, \@w1 );
    if( Astro::HTM::Functions->isinside( \@p, \@v0, \@w2, \@w1 ) ) {
      $name .= '0';
      @v1 = @w2;
      @v2 = @w1;
    } elsif( Astro::HTM::Functions->isinside( \@p, \@v1, \@w0, \@w2 ) ) {
      $name .= '1';
      @v0 = @v1;
      @v1 = @w0;
      @v2 = @w2;
    } elsif( Astro::HTM::Functions->isinside( \@p, \@v2, \@w1, \@w0 ) ) {
      $name .= '2';
      @v0 = @v2;
      @v1 = @w1;
      @v2 = @w0;
    } elsif( Astro::HTM::Functions->isinside( \@p, \@w0, \@w1, \@w2 ) ) {
      $name .= '3';
      @v0 = @w0;
      @v1 = @w1;
      @v2 = @w2;
    } else {
      croak "Could not determine ID at depth $depth in Astro::HTM::Functions->lookup()";
    }
  }

  return $name;
}

=item B<lookup_radec>

=cut

sub lookup_radec {
  my $self = shift;

  my $ra = shift; # scalar
  my $dec = shift; # scalar
  my $depth = shift; # scalar

  my @v = Astro::HTM::Functions->radec_to_vector( $ra, $dec );
  print "Vector as returned from radec_to_vector in lookup_radec:\n" if $DEBUG;
  print Dumper \@v if $DEBUG;
  return Astro::HTM::Functions->lookup( @v, $depth );
}

=item B<lookup_radec_id>

=cut

sub lookup_radec_id {
  my $self = shift;

  my $ra = shift; # scalar
  my $dec = shift; # scalar
  my $depth = shift; # scalar

  my ( $x, $y, $z, $name );
  my $cd = cos( $dec * HTM__PI_RADIANS );
  $x = cos( $ra * HTM__PI_RADIANS ) * $cd;
  $y = sin( $ra * HTM__PI_RADIANS ) * $cd;
  $z = sin( $dec * HTM__PI_RADIANS );

  print "within lookup_radec_id: x = $x y = $y z = $z\n" if $DEBUG;

  return Astro::HTM::Functions->lookup_vector_id( $x, $y, $z, $depth );
}

=item B<lookup_vector_id>

=cut

sub lookup_vector_id {
  my $self = shift;

  my $x = shift; # scalar
  my $y = shift; # scalar
  my $z = shift; # scalar
  my $depth = shift; # scalar

  my $name = Astro::HTM::Functions->lookup( $x, $y, $z, $depth );

print "name within lookup_vector_id: $name\n" if $DEBUG;
  my $rstat = Astro::HTM::Functions->name_to_id( $name );
  return $rstat;
}

=item B<m4_midpoint>

=cut

sub m4_midpoint {
  my $self = shift;

  my $v1 = shift; # array reference
  my $v2 = shift; # array reference
  my $w = shift; # array reference

  $w->[0] = $v1->[0] + $v2->[0];
  $w->[1] = $v1->[1] + $v2->[1];
  $w->[2] = $v1->[2] + $v2->[2];

  my $tmp = sqrt( $w->[0] * $w->[0] + $w->[1] * $w->[1] + $w->[2] * $w->[2] );
print "tmp = $tmp\n" if $DEBUG;
  $w->[0] /= $tmp;
  $w->[1] /= $tmp;
  $w->[2] /= $tmp;
}

=item B<name_to_id>

=cut

sub name_to_id {
  my $self = shift;

  my $name = shift; # scalar

  my $out = 0;
  my $i;
  my $siz = 0;

  if( $name !~ /^[NS]/ ) {
    croak "HTM name must start with either N or S";
  }
  $siz = length( $name );
  if( $siz < 2 ) {
    croak "HTM name must be two or more characters long";
  }
  if( $siz > HTM__HTMNAMEMAX ) {
    croak "HTM name must be fewer than " . HTM__HTMNAMEMAX . " characters long";
  }

  my @name = split //, $name;

  for( $i = $siz - 1; $i > 0; $i-- ) {
    print "Character at index $i is " . $name[$i] . "\n" if $DEBUG;
    if( $name[$i] > 3 || $name[$i] < 0 ) {
      croak "Character " . $name[$i] . " at index $i invalid";
    }
    print "Adding " . ( $name[$i] << ( 2 * ( $siz - $i - 1 ) ) ) . " to out (total so far is $out)\n" if $DEBUG;
    $out += $name[$i] << ( 2 * ( $siz - $i - 1 ) );
  }

  $i = 2;
  if( $name[0] eq 'N' ) {
    $i++;
  }
  my $last = $i << ( 2 * $siz - 2 );
  $out += $last;
  return $out;
}

=item B<name_to_triangle>

=cut

sub name_to_triangle {
  my $self = shift;

  my $name = shift; # scalar

  my @name = split //, $name;

  my $rstat = 0;
  my $dtmp = 0;
  my ( @w0, @w1, @w2, $v0, $v1, $v2 );

  my $k;
  my @anchor_offsets;
  $name =~ /^.(\d)/;
  $k = $1;
  if( $name =~ /^S/ ) {
    $anchor_offsets[0] = $S_indexes[$k][0];
    $anchor_offsets[1] = $S_indexes[$k][1];
    $anchor_offsets[2] = $S_indexes[$k][2];
  } else {
    $anchor_offsets[0] = $N_indexes[$k][0];
    $anchor_offsets[1] = $N_indexes[$k][1];
    $anchor_offsets[2] = $N_indexes[$k][2];
  }

  my @temp = @anchor[$anchor_offsets[0]];
  $v0->[0] = $temp[0][0];
  $v0->[1] = $temp[0][1];
  $v0->[2] = $temp[0][2];
  @temp = @anchor[$anchor_offsets[1]];
  $v1->[0] = $temp[0][0];
  $v1->[1] = $temp[0][1];
  $v1->[2] = $temp[0][2];
  @temp = @anchor[$anchor_offsets[2]];
  $v2->[0] = $temp[0][0];
  $v2->[1] = $temp[0][1];
  $v2->[2] = $temp[0][2];

#  @v1 = @anchor[$anchor_offsets[1]];
#  @v2 = @anchor[$anchor_offsets[2]];
#print Dumper \@v0;
#print Dumper \@v1;
#print Dumper \@v2;

  my $offset = 2;
  my $len = length( $name );
  while( $offset < $len ) {
    my $s = $name[$offset];

    Astro::HTM::Functions->m4_midpoint( $v0, $v1, \@w2 );
    Astro::HTM::Functions->m4_midpoint( $v1, $v2, \@w0 );
    Astro::HTM::Functions->m4_midpoint( $v2, $v0, \@w1 );

    if( $s == 0 ) {
      @$v1 = @w2;
      @$v2 = @w1;
    } elsif( $s == 1 ) {
      @$v0 = @$v1;
      @$v1 = @w0;
      @$v2 = @w2;
    } elsif( $s == 2 ) {
      @$v0 = @$v2;
      @$v1 = @w1;
      @$v2 = @w0;
    } elsif( $s == 3 ) {
      @$v0 = @w0;
      @$v1 = @w1;
      @$v2 = @w2;
    }
    $offset++;
  }

  return ( [ @$v0 ], [ @$v1 ], [ @$v2 ] );
}

=item B<radec_to_vector>

=cut

sub radec_to_vector {
  my $self = shift;

  my $ra = shift; # scalar
  my $dec = shift; # scalar

  my @vec;

  my $cd = cos( $dec * HTM__PI_RADIANS );

  my $diff = 90 - $dec;
  if( ( $diff < HTM__EPSILON ) && ( $diff > -1.0 * HTM__EPSILON ) ) {
    $vec[0] = 1;
    $vec[1] = 0;
    $vec[2] = 1;
    return @vec;
  }

  $diff = -90 - $dec;
  if( ( $diff < HTM__EPSILON ) && ( $diff > -1.0 * HTM__EPSILON ) ) {
    $vec[0] = 1;
    $vec[1] = 0;
    $vec[2] = -1;
    return @vec;
  }

  $vec[2] = sin( $dec * HTM__PI_RADIANS );
  my ( $quadrant, $qint, $iint );
  $quadrant = $ra / 90.0;
  $qint = int( $quadrant + 0.5 );
  if( abs( $qint - $quadrant ) < HTM__EPSILON ) {
    $iint = int( $qint );
    $iint %= 4;
    if( $iint < 0 ) {
      $iint += 4;
    }
    if( $iint == 0 ) {
      $vec[0] = 1;
      $vec[1] = 0;
    } elsif( $iint == 1 ) {
      $vec[0] = 0;
      $vec[1] = 1;
    } elsif( $iint == 2 ) {
      $vec[0] = -1;
      $vec[1] = 0;
    } elsif( $iint == 3 ) {
      $vec[0] = 0;
      $vec[1] = -1;
    }
    return @vec;
  }

  $vec[0] = cos( $ra * HTM__PI_RADIANS ) * $cd;
  $vec[1] = sin( $ra * HTM__PI_RADIANS ) * $cd;

  return @vec;
}

1;
