package Astro::HTM::Constraint;

=head1 NAME

Astro::HTM::Constraint - Class for handling HTM Constraint objects.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Math::Trig qw/ acos /;
use Math::VectorReal;

use Astro::HTM::Constants qw/ :all /;

our $VERSION = '0.01';

# Overload stringification.
use overload '""' => 'to_string';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::HTM::Constraint> object.

  $constraint = new Astro::HTM::Constraint( direction => $direction,
                                            distance => $distance );

A Constraint is essentially a cone on the sky-sphere. It is
characterized by its direction and the distance of the cutting plane
from the origin. For the Perl constructor these parameters are defined
by a C<Math::VectorReal> object denoting the direction, and a real number
denoting the distance. Both components must be defined, and the vector
need not be normalized, but it will be normalized internally.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my %args = @_;

  # Check for arguments.
  if( ! defined( $args{'direction'} ) ) {
    croak "Must define direction of vector to create an Astro::HTM::Constraint object";
  } elsif( ! UNIVERSAL::isa( $args{'direction'}, "Math::VectorReal" ) ) {
    croak "Direction vector must be a Math::VectorReal object when forming an Astro::HTM::Constraint object";
  }
  if( ! defined( $args{'distance'} ) ) {
    croak "Must define distance of cutting plane to create an Astro::HTM::Constraint object";
  }

  my $constraint = {};
  $constraint->{DIRECTION} = $args{'direction'}->norm;
  $constraint->{DISTANCE} = $args{'distance'};
  $constraint->{SIGN} = ( $constraint->{DISTANCE} < 0 ? HTM__NEGATIVE : HTM__POSITIVE );

  bless( $constraint, $class );
  return $constraint;
}

=back

=head2 Accessor Methods

=over 4

=item B<angle>

Return the opening angle of the Constraint.

  my $angle = $constraint->angle();

This method returns the angle in radians as a real number.

=cut

sub angle {
  my $self = shift;

  return acos( $self->distance );
}

=item B<direction>

Set or return the direction of the Constraint.

  my $direction = $constraint->direction();
  $constraint->direction( $direction );

This method returns a C<Math::VectorReal> object, and takes
a C<Math::VectorReal> object. The direction is automatically normalized
to a unit vector.

=cut

sub direction {
  my $self = shift;

  if( @_ ) {
    my $direction = shift;
    if( ! UNIVERSAL::isa( $direction, "Math::VectorReal" ) ) {
      croak "Direction vector must be a Math::VectorReal object when setting the direction";
    }
    $self->{DIRECTION} = $direction->norm;
  }

  return $self->{DIRECTION};
}

=item B<distance>

Set or return the distance of the cutting plane.

  my $distance = $constraint->distance();
  $constraint->distance( 0.5  );

This method returns a real number.

=cut

sub distance {
  my $self = shift;

  if( @_ ) {
    my $distance = shift;
    $self->{DISTANCE} = $distance;

    # Set the sign.
    $self->{SIGN} = ( $self->{DISTANCE} < 0 ? HTM__NEGATIVE : HTM__POSITIVE );
  }

  return $self->{DISTANCE};
}

=item B<sign>

Return the sign of the C<Astro::HTM::Constraint> object.

  my $sign = $constraint->sign();

Returns a constant as defined in C<Astro::HTM::Constants>.

Note that this method cannot be used to set the sign; this can only
be done by modifying the distance with the C<distance()> method.

=cut

sub sign {
  my $self = shift;
  return $self->{SIGN};
}

=back

=head2 General Methods

=over 4

=item B<contains>

Check whether a vector is inside the given C<Astro::HTM::Constraint>
object.

  my $contains = $constraint->contains( $vector );

This method requires one argument, a C<Math::VectorReal> object. It
returns true if the vector is contained inside of the constraint, and
false otherwise.

If the vector is not defined or is not a C<Math::VectorReal> object,
this method will return false and throw a warning.

=cut

sub contains {
  my $self = shift;
  my $vector = shift;

  if( ! defined( $vector ) ) {
    carp "Must pass vector to contains() method";
    return 0;
  }
  if( ! UNIVERSAL::isa( $vector, "Math::VectorReal" ) ) {
    carp "Vector passed to contains() method must be a Math::VectorReal object";
    return 0;
  }

  # The requested vector is inside the constraint if the arccosine of the
  # dot product of the two is less than the arccosine of the distance of
  # the cutting plane from the centre of the sphere.
  return ( acos( $self->direction . $vector ) < $self->angle );

}

=item B<invert>

Invert a C<Astro::HTM::Constraint> object.

  $constraint->invert();

This method operates in-place. Inverting a C<Astro::HTM::Constraint>
object essentially flips the sign of the distance.

=cut

sub invert {
  my $self = shift;
  $self->distance( -1 * $self->distance );
}

=item B<test>

Test for constraint relative position - intersect, one inside the other,
or disjoint.

  my $test = $constraint->test( $constraint2 );

The sole mandatory argument must be an C<Astro::HTM::Constraint> object.

This method returns 0 if the two constraints intersect, -1 if they
are disjoint, 1 if $constraint2 is in $constraint, and 2 if $constraint
is in $constraint2 (using the above example).

=cut

sub test {
  my $self = shift;

  my $constraint = shift;
  if( ! defined( $constraint ) ||
      ! UNIVERSAL::isa( $constraint, "Astro::HTM::Constraint" ) ) {
    croak "Must pass Astro::HTM::Constraint to test() method";
  }

  my $phi = ( ( $self->sign == HTM__NEGATIVE ? $self->direction * -1 : $self->direction ) . ( $constraint->sign == HTM__NEGATIVE ? $constraint->direction * -1 : $constraint->direction ) );
  $phi = ( ( $phi <= -1.0 + HTM__EPSILON ) ? HTM__PI : acos( $phi ) );

  my $a1 = ( $self->sign == HTM__POSITIVE ? $self->angle : HTM__PI - $self->angle );
  my $a2 = ( $constraint->sign == HTM__POSITIVE ? $constraint->angle : HTM__PI - $constraint->angle );

  if( $phi > ( $a1 + $a2 ) ) {
    return -1;
  }
  if( $a1 > ( $phi + $a2 ) ) {
    return 1;
  }
  if( $a2 > ( $phi + $a1 ) ) {
    return 2;
  }
  return 0;
}

=item B<to_string>

Stringify an C<Astro::HTM::Constraint> object.

  $constraint->to_string();

An C<Astro::HTM::Constraint> object stringifies into four numbers,
the x, y, and z components of the vector, and the distance.

=cut

sub to_string {
  my $self = shift;
  return $self->direction->stringify( "%g %g %g" ) . " " . $self->distance;
}

=back

=head1 REVISION

$Id$

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
