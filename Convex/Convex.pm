package Astro::HTM::Convex;

=head1 NAME

Astro::HTM::Convex - Class for handling HTM Convex objects.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Math::VectorReal;
use Math::Trig qw/ acos /;

use Astro::HTM::Constraint;
use Astro::HTM::Constants qw/ :all /;

our $VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::HTM::Convex> object.

  $convex = new Astro::HTM::Convex();

This method can take zero, three or four arguments. If three or four
arguments are given, they must all be C<Math::VectorReal> objects.

If three arguments are given, the vectors mark three vertices of
a triangle on the unit sphere.

If four arguments are given, the vectors mark four corners of a rectangle
on the unit sphere. If one of the four vectors lies within the triangle
formed by the other three, then it is assumed that the three vectors form
a triangle on the unit sphere and the fourth internal vector is ignored.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my @args = @_;

  if( scalar( @args ) != 0 &&
      scalar( @args ) != 3 &&
      scalar( @args ) != 4 ) {
    croak "Astro::HTM::Convex constructor must have zero, three or four arguments";
  }

  my $convex = {};

  # Set up some defaults.
  my $constraints = [];
  my $corners = [];
  my $bounding_circle = undef;
  my $olevel = 20;
  my $sign = HTM__ZERO;

  # Do some calculations for the three-argument case.
  if( scalar( @args ) == 3 ) {
    my $v1 = shift;
    my $v2 = shift;
    my $v3 = shift;

    # Set the directions of the half-spheres.
    my $a1 = $v2 x $v3;
    my $a2 = $v3 x $v1;
    my $a3 = $v1 x $v2;

    # We really only need the signs of these half-spheres.
    my $s1 = $a1 . $v1;
    my $s2 = $a2 . $v2;
    my $s3 = $a3 . $v3;

    # If the three vectors fall on one line, then multiplying
    # the three dot products together will give zero.
    if( ( $s1 * $s2 * $s3 ) > 0 ) {

      # Change sign if necessary.
      if( $s1 < 0 ) { $a1 *= -1; }
      if( $s2 < 0 ) { $a2 *= -1; }
      if( $s3 < 0 ) { $a3 *= -1; }

      # Push these into the constraints array as new Constraint objects.
      push @$constraints, new Astro::HTM::Constraint( $a1, 0 );
      push @$constraints, new Astro::HTM::Constraint( $a2, 0 );
      push @$constraints, new Astro::HTM::Constraint( $a3, 0 );

    }

    $sign = HTM__ZERO;
  } elsif( scalar( @args ) == 4 ) {

    my $v1 = shift;
    my $v2 = shift;
    my $v3 = shift;
    my $v4 = shift;
    my @v = [ $v1, $v2, $v3, $v4 ];
    my @d;
    my @s;

    # The following is essentially copied from the Java implementation
    # of the Convex constructor.
    my $i;
    my $j;
    my $k;
    my $l;
    my $m;
    for( $i = 0, $k = 0 ; $i < 4 ; $i++ ) {
      for( $j = $i+1; $j < 4; $j++, $k++ ) {
        $d[$k] = $v[$i] x $v[$j];
        $d[$k]->norm;
        for( $l = 0, $m = 0; $l < 4; $l++ ) {
          if( $l != $i && $l != $j ) {
            $s[$k][$m++] = $d[$k] . $v[$l];
          }
        }
      }
    }
    for( $i = 0; $i < 6; $i++ ) {
      if( ( $s[$i][0] * $s[$i][1] ) > 0 ) {
        push @$constraints, new Astro::HTM::Constraint( ( ( $s[$i][0] > 0 ) ?
                                                          $d[$i] :
                                                          $d[$i] * -1 ),
                                                        0 );
      }
    }
    if( scalar( @$constraints ) == 2 ) {
      for( $i = 0; $i < 6; $i++ ) {
        if( $s[$i][0] == 0 || $s[$i][1] == 0 ) {
          push @$constraints, new Astro::HTM::Constraint( ( ( $s[$i][0] + $s[$i][1] > 0 ) ?
                                                            $d[$i] :
                                                            $d[$i] * -1 ),
                                                          0 );
          last;
        }
      }
    }
    $sign = HTM__ZERO;
  }

  $convex->{CONSTRAINTS} = $constraints;
  $convex->{CORNERS} = $corners;
  $convex->{BOUNDING_CIRCLE} = $bounding_circle;
  $convex->{OLEVEL} = $olevel;
  $convex->{SIGN} = $sign;

  bless( $convex, $class );

  $convex->simplify();

  return $convex;
}

=back

=head2 Accessor Methods

=over 4

=item B<bounding_circle>

Set or return the bounding circle for the C<Astro::HTM::Convex> object.

  my $bounding_circle = $convex->bounding_circle;
  $convex->bounding_circle( $bounding_circle );

A bounding circle is...

This method returns an C<Astro::HTM::Constraint> object, and takes the
same.

=cut

sub bounding_circle {
  my $self = shift;
  if( @_ ) {
    my $bounding_circle = shift;
    if( UNIVERSAL::isa( $bounding_circle, "Astro::HTM::Constraint" ) ) {
      $self->{BOUNDING_CIRCLE} = $bounding_circle;
    }
  }
  return $self->{BOUNDING_CIRCLE};
}

=item B<constraints>

Return the set of all C<Astro::HTM::Constraint> objects associated with this
C<Astro::HTM::Convex> object.

  my $constraints = $convex->constraints;
  my @constraints = $convex->constraints;

When called in scalar context, this method will return the list as
an array reference. When called in list context, this method will
return the list as a list.

=cut

sub constraints {
  my $self = shift;

  if( wantarray ) { return @{$self->{CONSTRAINTS}}; } else { return $self->{CONSTRAINTS}; }
}

=item B<corners>

Return the set of all C<Math::VectorReal> objects that define the corners
of this C<Astro::HTM::Convex> object.

  my $corners = $convex->corners;
  my @corners = $convex->corners;

When called in scalar context, this method will return the list as
an array reference. When called in list context, this method will
return the list as a list.

=cut

sub corners {
  my $self = shift;

  if( wantarray ) { return @{$self->{CORNERS}}; } else { return $self->{CORNERS}; }
}

=item B<olevel>

Set or return the output level for the ranges contained by this
C<Astro::HTM::Convex> object.

  my $olevel = $domain->olevel();
  $domain->olevel( 15 );

This method returns an integer. If the output level has not been
defined, it will default to 20.

=cut

sub olevel {
  my $self = shift;
  if( @_ ) {
    my $olevel = shift;
    $self->{OLEVEL} = $olevel;
  }
  if( ! defined( $self->{OLEVEL} ) ) {
    $self->{OLEVEL} = 20;
  }
  return $self->{OLEVEL};
}

=item B<sign>

Return the sign of the C<Astro::HTM::Convex> object.

  my $sign = $convex->sign();

Returns a constant as defined in C<Astro::HTM::Constants>.

Note that this method cannot be used to set the sign; this can only
be done by adding a constraint of the proper sign.

=cut

sub sign {
  my $self = shift;
  return $self->{SIGN};
}

=back

=head2 General Methods

=over 4

=item B<add_constraint>

Add an C<Astro::HTM::Constraint> object to the C<Astro::HTM::Convex> object.

  $convex->add_constraint( $constraint );

The argument must be an C<Astro::HTM::Constraint> object. This method will
croak if the argument is not defined or is not an C<Astro::HTM::Constraint>
object.

This method returns nothing and modifies the C<Astro::HTM::Convex> object
in-place.

When the constraint is added, the constraints are re-ordered by ascending
opening angle.

=cut

sub add_constraint {
  my $self = shift;

  my $constraint = shift;
  if( ! defined( $constraint ) ||
      ! UNIVERSAL::isa( $constraint, "Astro::HTM::Constraint" ) ) {
    croak "Must supply Astro::HTM::Constraint object to add_constraint() method";
  }

  # Push the constraint onto our list.
  push @{$self->{CONSTRAINTS}}, $constraint;

  # And re-order.
  for( my $i = scalar( $self->constraints ) - 1; $i > 0; $i-- ) {
    my $ci = $self->get_constraint( $i );
    my $ch = $self->get_constraint( $i - 1 );
    if( $ci->angle < $ch->angle ) {
      ${$self->{CONSTRAINTS}}[$i] = $ch;
      ${$self->{CONSTRAINTS}}[$i-1] = $ci;
    }
  }

  # If this is the first constraint in the convex, set the sign of the convex
  # to be that of the constraint.
  if( scalar( $self->constraints ) == 1 ) {
    $self->{SIGN} = $constraint->sign;
  } else {
    # Otherwise, check to see what our current sign is. If it's different from
    # that of the given constraint, our sign needs to be set to HTM__MIXED, but
    # only if our current sign is either HTM__POSITIVE or HTM__NEGATIVE. If it's
    # already HTM__MIXED it stays like that, and if it's HTM__ZERO it gets set
    # to the sign of the constraint.
    if( $self->sign == HTM__POSITIVE && $constraint->sign == HTM__NEGATIVE ) {
      $self->{SIGN} = HTM__MIXED;
    } elsif( $self->sign == HTM__NEGATIVE && $constraint->sign == HTM__POSITIVE ) {
      $self->{SIGN} = HTM__MIXED;
    } elsif( $self->sign == HTM__ZERO ) {
      $self->{SIGN} = $constraint->sign;
    }
  }
}

=item B<add_corner>

Add a C<Math::VectorReal> object to the list of corners.

  $convex->add_corner( $corner );

The argument must be an C<Math::VectorReal> object. This method will
croak if the argument is not defined or is not an C<Math::VectorReal>
object.

This method returns nothing and modifies the C<Astro::HTM::Convex> object
in-place.

=cut

sub add_corner {
  my $self = shift;
  my $corner = shift;

  if( ! defined( $corner ) ||
      ! UNIVERSAL::isa( $corner, "Math::VectorReal" ) ) {
    croak "Must supply Math::VectorReal object to add_constraint() method";
  }

  # Push the corner onto our list.
  push @{$self->{CORNERS}}, $corner;
}

=item B<clear_constraints>

Remove all constraints from the C<Astro::HTM::Convex> object.

  $convex->clear_constraints;

This method operates on the C<Astro::HTM::Convex> object in-place.

=cut

sub clear_constraints {
  my $self = shift;
  $self->{CONSTRAINTS} = [];
}

=item B<clear_corners>

Remove all corners from the C<Astro::HTM::Convex> object.

  $convex->clear_corners;

This method operates on the C<Astro::HTM::Convex> object in-place.

=cut

sub clear_corners {
  my $self = shift;
  $self->{CORNERS} = [];
}

=item B<contains>

Check whether a C<Math::VectorReal> object is inside any of the
C<Astro::HTM::Constraint> objects contained by this C<Astro::HTM::Convex>
object.

  my $contains = $convex->contains( $vector );

This method requires one argument, a C<Math::VectorReal> object. It
returns true of the vector is contained within any of the C<Astro::HTM::Constraint>
objects contained by this C<Astro::HTM::Convex> object by calling the
C<contains> method from C<Astro::HTM::Constraint>. The method returns
false if the given C<Math::VectorReal> object is not contained by
any of the C<Astro::HTM::Constraint> objects.

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

  # Go through list of Astro::HTM::Constraint objects.
  foreach my $constraint ( $self->constraints ) {
    if( $constraint->contains( $vector ) ) {
      return 1;
    }
  }

  return 0;
}

=item B<esolve>

Solve the quadratic equation for the edge given by endpoints vector1, vector2,
of the constraint at a given index.

  my $solution = $self->esolve( vector1 => $vector1,
                                vector2 => $vector2,
                                cindex => $cindex );

This method returns true if a solution can be found, false otherwise.

=cut

sub esolve {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::esolve() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::esolve() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'cindex'} ) ) {
    croak "cindex must be passed to Astro::HTM::Convex::esolve()";
  }
  my $cindex = $args{'cindex'};

  my $con = $self->get_constraint( $cindex );
  my $gamma1 = $vector1 . $con->direction;
  my $gamma2 = $vector2 . $con->direction;
  my $mu = $vector1 . $vector2;
  my $u2 = ( 1 - $mu ) / ( 1 + $mu );

  my $a = -1.0 * $u2 * ( $gamma1 + $con->distance );
  my $b = $gamma1 * ( $u2 - 1 ) + $gamma2 * ( $u2 + 1 );
  my $c = $gamma1 - $con->distance;

  my $D = $b * $b - 4 * $a * $c;

  if( $D < 0 ) {
    return 0;
  }

  my $q = -0.5 * ( $b + ( ( $b > 0 ? -1 : ( $b > 0 ? 1 : 0 ) ) * sqrt( $D ) ) );

  my $root1 = -1;
  my $root2 = -1;
  my $i = 0;

  if( $a > HTM__GEPSILON || $a < -1.0 * HTM__GEPSILON ) {
    $root1 = $q / $a;
    $i++;
  }
  if( $q > HTM__GEPSILON || $q < -1.0 * HTM__GEPSILON ) {
    $root2 = $c / $q;
    $i++;
  }

  if( $i == 0 ) {
    return 0;
  }
  if( ( $root1 >= 0 ) && ( $root1 <= 1 ) ) {
    return 1;
  }
  if( $i == 2 && ( ( ( $root1 >= 0 ) && ( $root1 <= 1 ) ) ||
                   ( ( $root2 >= 0 ) && ( $root2 <= 1 ) ) ) ) {
    return 1;
  }

  return 0;
}


=item B<get_constraint>

Get a constraint by index.

  my $constraint = $convex->get_constraint( $i );

This method returns an C<Astro::HTM::Constraint> object. If the index
is out of bounds on the array, this method will return undef;

=cut

sub get_constraint {
  my $self = shift;
  my $index = shift;

  if( $index > scalar( $self->constraints ) ||
      $index < 0 ) {
    return undef;
  }
  return $self->{CONSTRAINTS}->[$index];
}

=item B<get_corner>

Get a corner by index.

  my $corner = $convex->get_corner( $i );

This method returns a C<Math::VectorReal> object. If the index
is out of bounds on the array, this method will return undef;

=cut

sub get_corner {
  my $self = shift;
  my $index = shift;

  if( $index > scalar( $self->corners ) ||
      $index < 0 ) {
    return undef;
  }
  return $self->{CORNERS}->[$index];
}

=item B<intersect>

Intersect with an HTM Index.

  $convex->intersect( index => $index,
                      range => $range,
                      varlen => $varlen );

The index and range named arguments are mandatory. The index must be
an C<Astro::HTM::Index> object, and the range must be an
C<Astro::HTM::Range> object. The varlen argument is optional; if varlen
is true then variable-length trixels can be returned. It defaults
to false.

=cut

sub intersect {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'index'} ) ||
      ! UNIVERSAL::isa( $args{'index'}, "Astro::HTM::Index" ) ) {
    croak "Index must be passed to Astro::HTM::Convex::intersect() as an Astro::HTM::Index object";
  }
  my $index = $args{'index'};
  if( ! defined( $args{'range'} ) ||
      ! UNIVERSAL::isa( $args{'range'}, "Astro::HTM::Range" ) ) {
    croak "Range must be passed to Astro::HTM::Convex::intersect() as an Astro::HTM::Range object";
  }
  my $range = $args{'range'};
  my $varlen;
  if( ! defined( $args{'varlen'} ) ) {
    $varlen = 0;
  } else {
    $varlen = $args{'varlen'};
  }

  # If we have no Constraints, we can't do anything.
  if( scalar( $self->constraints ) == 0 ) {
    return;
  }

  for( my $i = 1; $i <= 8; $i++ ) {
    $self->test_trixel( id => $i,
                        index => $index,
                        range => $range,
                        varlen => $varlen );
  }
}

=item B<print_sign>

Print the convex's size.

  my $string = $convex->print_sign();

=cut

sub print_sign {
  my $self = shift;

  if( $self->sign == HTM__POSITIVE ) {
    return "pOS";
  }
  if( $self->sign == HTM__NEGATIVE ) {
    return "nEG";
  }
  if( $self->sign == HTM__MIXED ) {
    return "mIXED";
  }
  if( $self->sign == HTM__ZERO ) {
    return "zERO";
  }
}

=item B<remove_constraint>

Remove a constraint from the C<Astro::HTM::Convex> object.

  $convex->remove_constraint( $i );

The index is as for an array -- starts at zero.

This method operates on the C<Astro::HTM::Convex> object in-place.

=cut

sub remove_constraint {
  my $self = shift;
  my $remove = shift;

  return if ( ! defined( $remove ) );

  splice @{$self->{CONSTRAINTS}}, $remove;

  # I note that the original Java code does not reset the sign of the
  # Convex object, which doesn't make much sense to me. What happens
  # if you had a MIXED Convex and deleted the only NEGATIVE Constraint?
  # Shouldn't the Convex be a POSITIVE or ZERO one now?
  #
  # I'll leave this until later. Don't have time to implement it right now.
}

=item B<remove_corner>

Remove a corner from the C<Astro::HTM::Convex> object.

  $convex->remove_corner( $i );

The index is as for an array -- starts at zero.

This method operates on the C<Astro::HTM::Convex> object in-place.

=cut

sub remove_corner {
  my $self = shift;
  my $remove = shift;

  return if ( ! defined( $remove ) );

  splice @{$self->{CORNERS}}, $remove;
}

=item B<save_trixel>

This method adds the given trixel to the HTM::Range.

  $convex->save_trixel( htmid => $htmid,
                        range => $range,
                        varlen => $varlen );

The htmid and range named arguments are mandatory. The htmid must be
an integer denoting the HTM ID of the trixel to add, and the range must be an
C<Astro::HTM::Range> object. The varlen argument is optional; if varlen
is true then variable-length trixels can be returned. It defaults
to false.

=cut

sub save_trixel {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'htmid'} ) ) {
    croak "HTM ID must be passed to Astro::HTM::Convex::intersect()";
  }
  my $htmid = $args{'htmid'};
  if( ! defined( $args{'range'} ) ||
      ! UNIVERSAL::isa( $args{'range'}, "Astro::HTM::Range" ) ) {
    croak "Range must be passed to Astro::HTM::Convex::intersect() as an Astro::HTM::Range object";
  }
  my $range = $args{'range'};
  my $varlen;
  if( ! defined( $args{'varlen'} ) ) {
    $varlen = 0;
  } else {
    $varlen = $args{'varlen'};
  }

  my ( $level, $i, $shifts, $lo, $hi );

  if( $varlen ) {
    $range->merge_range( htmid1 => $htmid,
                         htmid2 => $htmid );
    return;
  }

  for( $i = 0; $i < HTM__IDSIZE; $i += 2 ) {
    if( ( ( $htmid << $i ) & HTM__IDHIGHBIT ) != 0 ) {
      last;
    }
  }
  $level = ( HTM__IDSIZE - 1 ) >> 1;
  $level -= 2;
  if( $level < $self->olevel ) {

    # Size is the length of the string representing the name
    # of the trixel, the level is ( size - 2 ).
    $shifts = ( $self->olevel - $level ) << 1;
    $lo = $htmid << $shifts;
    $hi = $lo + ( 1 << $shifts ) - 1;
  } else {
    $lo = $hi = $htmid;
  }

  $range->merge_range( htmid1 => $lo,
                       htmid2 => $hi );

}

=item B<simplify>

Simplify an C<Astro::HTM::Convex> object.

  $convex->simplify();

This method operates on the object in-place.

Simplification of an C<Astro::HTM::Convex> object means:

Test two constraints against each other. If:

=item * both constraints are HTM__POSITIVE:

=over 4

=item * If they intersect, keep both.

=item * If one lies in the other, drop the larger one.

=item * Otherwise, disjunct. Empty out the convex and stop.

=back

=item * both constraints are HTM__NEGATIVE:

=over 4

=item * If they intersect or are disjunct, keep both.

=item * Otherwise, one lies in the other, so drop the smaller one.

=back

=item * one constraint is HTM__POSITIVE, the other HTM__NEGATIVE:

=over 4

=item * If there is no intersection, drop the HTM__POSITIVE one.

=item * If they intersect, keep both.

=item * If the HTM__POSITIVE one lies within the HTM__NEGATIVE one,
empty out the convex and stop.

=item * If the HTM__NEGATIVE one lies within the HTM__POSITIVE one,
keep both.

=back

=cut

sub simplify {
  my $self = shift;

  # If we have a HTM__ZERO convex, use simplify_zero instead.
  if( $self->sign == HTM__ZERO ) {
    $self->simplify_zero();
    return;
  }

  my ( $i, $j, $number_of_constraints, $redundancy );
  $redundancy = 1;

  # The following simplification code is essentially verbatim the
  # Java implementation.

  while( $redundancy ) {
    $redundancy = 0;
    $number_of_constraints = scalar( $self->constraints );

    for( $i = 0; $i < $number_of_constraints; $i++ ) {
      for( $j = 0; $j < $i; $j++ ) {

        my $test;
        my $ci = $self->get_constraint( $i );
        my $cj = $self->get_constraint( $j );

        # Don't bother with two zero constraints.
        next if( $ci->sign == HTM__ZERO && $cj->sign == HTM__ZERO );

        # Both positive or zero.
        if( ( $ci->sign == HTM__POSITIVE || $ci->sign == HTM__ZERO ) &&
            ( $cj->sign == HTM__POSITIVE || $cj->sign == HTM__ZERO ) ) {

          # Test for possible intersection.
          $test = $ci->test( $cj );

          # Intersection.
          if( $test == 0 ) {
            next;
          }
          if( $test < 0 ) {
            # Disjoint, empty the constraints and return.
            $self->clear_constraints;
            return;
          }
          if( $test == 1 ) {
            # Remove $cj from the list of constraints.
            $self->remove_constraint( $j );
          }
          if( $test == 2 ) {
            # Remove $ci from the list of constraints.
            $self->remove_constraint( $i );
          }

          $redundancy = 1;
          last;
        }

        if( ( $ci->sign == HTM__NEGATIVE ) &&
            ( $cj->sign == HTM__NEGATIVE ) ) {

          # Test for possible intersection.
          $test = $ci->test( $cj );

          if( $test <= 0 ) {
            next;
          }
          if( $test == 1 ) {
            # Remove $cj from the list of constraints.
            $self->remove_constraint( $j );
          }
          if( $test == 2 ) {
            # Remove $ci from the list of constraints.
            $self->remove_constraint( $i );
          }

          $redundancy = 1;
          last;
        }

        # At this point, we've got one negative and one positive/zero.
        # Do another test for intersection.
        $test = $ci->test( $cj );
        if( $test == 0 ) {
          next;
        }
        if( $test < 0 ) {
          # The negative one is redundant, remove it.
          if( $ci->sign == HTM__NEGATIVE ) {
            # Remove $ci from the list of constraints.
            $self->remove_constraint( $i );
          } else {
            # Remove $cj from the list of constraints.
            $self->remove_constraint( $j );
          }
          $redundancy = 1;
          last;
        }
        if( ( $ci->sign == HTM__NEGATIVE && $test == 2 ) ||
            ( $cj->sign == HTM__NEGATIVE && $test == 1 ) ) {
          next;
        }
        # Positive constraint in negative: convex is empty.
        $self->clear_constraints;
        return;
      } # loop over $j
      if( $redundancy ) { last; }
    } # loop over $i
  } # while redundancy loop

  # Reset the sign of the convex.
  my $sign = $self->get_constraint( 0 )->sign;
  for( my $i = 1; $i < scalar( $self->constraints ); $i++ ){
    my $ci = $self->get_constraint( $i );
    if( $sign == HTM__NEGATIVE ) {
      if( $ci->sign == HTM__POSITIVE ) {
        $self->{SIGN} = HTM__MIXED;
        last;
      }
    } elsif( $sign == HTM__POSITIVE ) {
      if( $ci->sign == HTM__NEGATIVE ) {
        $self->{SIGN} = HTM__MIXED;
        last;
      }
    } elsif( $sign == HTM__ZERO ) {
      $self->{SIGN} = $ci->sign;
      last;
    }
  }
}

=back

=item B<simplify_zero>

=cut

sub simplify_zero {
  my $self = shift;

  if( scalar( $self->constraints ) == 1 ) {

    # We have one constraint, so set that to be the bounding circle.
    $self->bounding_circle( $self->get_constraint( 0 ) );
    return;
  } elsif( scalar( $self->constraints ) == 2 ) {

    # We have two constraints. Check to see if they're equal. If they
    # are, remove the second one, set the first one to be the bounding
    # circle and return.
    my $c1 = $self->get_constraint( 0 );
    my $c2 = $self->get_constraint( 1 );
    my $v1 = $c1->direction;
    my $v2 = $c2->direction;
    if( ( $v1->x == $v2->x ) &&
        ( $v1->y == $v2->y ) &&
        ( $v1->z == $v2->z ) ) {
      $self->remove_constraint( 1 );
      return;
    }

    if( ( $v1->x == -1.0 * $v2->x ) &&
        ( $v1->y == -1.0 * $v2->y ) &&
        ( $v1->z == -1.0 * $v2->z ) ) {
      $self->clear_constraints();
      return;
    }

    my $v = $v1 + $v2;
    $v->norm;
    $self->bounding_circle( new Astro::HTM::Constraint( direction => $v,
                                                        distance => 0 ) );
  }

  my ( $i, $j, $k );
  my ( $vi1, $vi2 );
  my @corner_constr1;
  my @corner_constr2;
  my @remove_constr;
  my @corner;

  # As for simplify(), this code is taken pretty much verbatim from
  # the Java implementation.
  for( $i = 0; $i < scalar( $self->constraints ); $i++ ) {

    my $ruledout = 1;
    for( $j = $i+1; $j < scalar( $self->constraints ); $j++ ) {

      my $ci = $self->get_constraint( $i );
      my $cj = $self->get_constraint( $j );
      $vi1 = $ci->direction x $cj->direction;

      if( $vi1->length == 0 ) {
        # i and j are the same constraint.
        last;
      }
      $vi1->norm;
      $vi2 = $vi1 * -1;
      my $vi1ok = 1;
      my $vi2ok = 1;

      # Now test whether vi1 or vi2 or both are inside every other
      # constraint. If yes, store them in the corner array.
      for( $k = 0; $k < scalar( $self->constraints ); $k++ ) {
        if( $k == $i || $k == $j ) {
          next;
        }
        my $ck = $self->get_constraint( $k );
        if( $vi1ok && ( $vi1 . $ck->direction ) <= 0 ) {
          $vi1ok = 0;
        }
        if( $vi2ok && ( $vi2 . $ck->direction ) <= 0 ) {
          $vi2ok = 0;
        }
        if( ! $vi1ok && ! $vi2ok ) {
          last;
        }
      }
      if( $vi1ok ) {
        push @corner, $vi1;
        push @corner_constr1, $i;
        push @corner_constr2, $j;
        $ruledout = 0;
      }
      if( $vi2ok ) {
        push @corner, $vi2;
        push @corner_constr1, $i;
        push @corner_constr2, $j;
        $ruledout = 0;
      }
    }

    if( $ruledout ) {
      push @remove_constr, $i;
    }

  }

  # Now set the corners into their correct order, which is an
  # anti-clockwise walk around the polygon. Start at any corner,
  # so take the first.
  $self->clear_corners();
  $self->add_corner( $corner[0] );

  # The trick is now to start off into the correct direction. This
  # corner has two edges it can walk. We have to take the one where
  # the convex lies on its left side.

  # The i'th constraint and j'th constraint intersect at the 0'th corner.
  $i = $corner_constr1[0];
  $j = $corner_constr2[0];

  my $c1 = 0;
  my $c2 = 0;
  my $k1 = 0;
  my $k2 = 0;
  for( $k = 1; $k < scalar( @corner_constr1 ); $k++ ) {

    if( $corner_constr1[$k] == $i ) {
      $vi1 = $corner[$k];
      $c1 = $corner_constr2[$k];
      $k1 = $k;
    }
    if( $corner_constr2[$k] == $i ) {
      $vi1 = $corner[$k];
      $c1 = $corner_constr1[$k];
      $k1 = $k;
    }
    if( $corner_constr1[$k] == $j ) {
      $vi2 = $corner[$k];
      $c2 = $corner_constr2[$k];
      $k2 = $k;
    }
    if( $corner_constr2[$k] == $j ) {
      $vi2 = $corner[$k];
      $c2 = $corner_constr1[$k];
      $k2 = $k;
    }
  }

  # Now test the i'th constraint edge (corner 0 and corner k) whether
  # it is on the correct side (left)
  #
  # ( ( corner(k) - corner(0) ) x constraint(i) ) corner(0)
  #
  # ...is > 0 if yes, < 0 if no.
  my ( $c, $current_corner );
  my $ci = $self->get_constraint( $i );
  if( ( ( ( $vi1 - $corner[0] ) x ( $ci->direction ) ) . ( $corner[0] ) ) > 0 ) {
    $self->add_corner( $vi1 );
    $c = $c1;
    $current_corner = $k1;
  } else {
    $self->add_corner( $vi2 );
    $c = $c2;
    $current_corner = $k2;
  }

  # Now append the corners that match the index $c until we get corner 0
  # again. $current_corner holds the current corner's index. $c holds the
  # index of the constraint that has just been intersected with.
  # So:
  #  - We are on a constraint now ($i or $j from before), the second
  #    corner is the one intersecting with constraint $c.
  #  - Find the other corner for constraint $c.
  #  - Save that corner, and set $c to the constraint that intersects with
  #    $c at that corner.
  #  - Set $current_corner to that corner's index.
  #  - Loop until 0th corner is reached.
  while( $current_corner != 0 ) {
    for( $k = 0; $k < scalar( @corner_constr1 ); $k++ ) {
      if( $k == $current_corner ) {
        next;
      }
      if( $corner_constr1[$k] == $c ) {
        if( ( $current_corner = $k ) == 0 ) {
          last;
        }
        $self->add_corner( $corner[$k] );
        $c = $corner_constr2[$k];
        last;
      }
      if( $corner_constr2[$k] == $c ) {
        if( ( $current_corner = $k ) == 0 ) {
          last;
        }
        $self->add_corner( $corner[$k] );
        $c = $corner_constr1[$k];
      }
    }
  }

  # Remove all redundant constraints.
  for( $i = 0; $i < scalar( @remove_constr ); $i++ ) {
    $self->remove_constraint( $remove_constr[$i] );
  }

  # Now calculate the bounding circle for the convex.
  # We take it as the bounding circle of the triangle with
  # the widest opening angle. All triangles made out of three
  # corners are considered.
  if( scalar( $self->constraints ) >= 3 ) {
    $self->bounding_circle( new Astro::HTM::Constraint( direction => vector( 0, 0, 0 ),
                                                        distance => 1.0 ) );
    for( $i = 0; $i < scalar( $self->corners ); $i++ ) {
      for( $j = $i+1; $j < scalar( $self->corners ); $j++ ) {
        for( $k = $j+1; $j < scalar( $self->corners ); $k++ ) {

          my $v = ( $self->get_corner( $j ) - $self->get_corner( $i ) ) x
                  ( $self->get_corner( $k ) - $self->get_corner( $j ) );
          $v->norm;

          # Set the correct opening angle. Since the plane cutting
          # out of the triangle also correctly cuts out the bounding
          # cap of the triangle on the sphere, we can take any corner
          # to calculate the opening angle. Take the one denoted by
          # index $i.
          my $d = $v . $self->get_corner( $i );
          my $current_bc = $self->bounding_circle;
          if( $current_bc->distance > $d ) {
            $self->bounding_circle( new Astro::HTM::Constraint( direction => $v,
                                                                distance => $d ) );
          }
        }
      }
    }
  }
}

=item B<test_bounding_circle>

Test if a bounding circle intersects with a constraint.

  my $test = $convex->test_bounding_circle( vector1 => $vector1,
                                            vector2 => $vector2,
                                            vector3 => $vector3 );

This method returns true if a constraint contained by the convex
intersects with the bounding circle defined by the three vectors,
and false otherwise.

=cut

sub test_bounding_circle {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  # Set the correct direction: the normal vector to the triangle plane.
  my $c = ( $vector2 - $vector1 ) x ( $vector3 - $vector2 );
  $c->norm;

  # Set the correct opening angle.
  my $d = acos( $c . $vector1 );

  if( $self->sign == HTM__NEGATIVE ) {
    my $bc = $self->bounding_circle;
    my $tst = $c . $bc->direction;
    if( ( ( $tst < ( -1.0 + HTM__GEPSILON ) ) ? HTM__PI : acos( $tst ) ) >
        ( $d + $bc->angle ) ) {
      return 0;
    } else {
      return 1;
    }
  }

  my $i;
  for( $i = 0; $i < scalar( $self->constraints ); $i++ ) {
    my $ci = $self->get_constraint( $i );
    my $cci = $c . $ci->direction;
    if( ( ( $cci < ( -1.0 + HTM__GEPSILON ) ) ? HTM__PI : acos( $cci ) ) >
        ( $d + $ci->angle ) ) {
      return 0;
    }
  }
  return 1;
}

=item B<test_constraint_inside>

Test for a constraint lying inside or outside of the triangle denoted by the
three vectors:

  my $test = $self->test_constraint_inside( vector1 => $vector1,
                                            vector2 => $vector2,
                                            vector3 => $vector3,
                                            cindex => $cindex );

Returns true if the constraint denoted by index cindex lies inside the triangle,
false otherwise.

=cut

sub test_constraint_inside {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  if( ! defined( $args{'cindex'} ) ) {
    croak "cindex must be passed to Astro::HTM::Convex::test_constraint_inside()";
  }
  my $cindex = $args{'cindex'};

  my $constraint = $self->get_constraint( $cindex );

  return $self->test_vector_inside( vector1 => $vector1,
                                    vector2 => $vector2,
                                    vector3 => $vector3,
                                    vector4 => $constraint->direction );
}

=item B<test_edge>

Test if a constraint intersects with one of the edges of the node
with corners vector1, vector2, vector3:

  my $test = $convex->test_edge( vector1 => $vector1,
                                 vector2 => $vector2,
                                 vector3 => $vector3 );

This method returns true if a constraint contained by the convex intersects
with one of the edges of the given node, and false otherwise.

=cut

sub test_edge {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  for( my $i = 0; $i < scalar( $self->constraints ); $i++ ) {
    my $constraint = $self->get_constraint( $i );

    # Only test holes. (why?)
    if( $constraint->sign == HTM__NEGATIVE ) {
      if( $self->esolve( vector1 => $vector1,
                         vector2 => $vector2,
                         cindex => $i ) ) {
        return 1;
      }
      if( $self->esolve( vector1 => $vector2,
                         vector2 => $vector3,
                         cindex => $i ) ) {
        return 1;
      }
      if( $self->esolve( vector1 => $vector3,
                         vector2 => $vector1,
                         cindex => $i ) ) {
        return 1;
      }
    }
  }
  return 0;
}

=item B<test_edge_constraint>

Test if a constraint intersects the edges:

  my $test = $convex->test_edge_constraint( vector1 => $vector1,
                                            vector2 => $vector2,
                                            vector3 => $vector3,
                                            cindex => $cindex );

This method returns true if the constraint given by index cindex intersects
with one of the edges of the node with the corners given by the three vectors,
and false otherwise.

=cut

sub test_edge_constraint {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  if( ! defined( $args{'cindex'} ) ) {
    croak "cindex must be passed to Astro::HTM::Convex::test_edge_constraint()";
  }
  my $cindex = $args{'cindex'};

  if( $self->esolve( vector1 => $vector1,
                     vector2 => $vector2,
                     cindex => $cindex ) ) {
    return 1;
  }
  if( $self->esolve( vector1 => $vector2,
                     vector2 => $vector3,
                     cindex => $cindex ) ) {
    return 1;
  }
  if( $self->esolve( vector1 => $vector3,
                     vector2 => $vector1,
                     cindex => $cindex ) ) {
    return 1;
  }
  return 0;
}

=item B<test_edge_zero>

Test the edges of a triangle against the edges of an HTM__ZERO convex.

  my $test = $convex->test_edge_zero( vector1 => $vector1,
                                      vector2 => $vector2,
                                      vector3 => $vector3 );

This method returns true or false.

=cut

sub test_edge_zero {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  # Create an 'edge_struct' structure.
  use Class::Struct edge_struct => { e => 'Math::VectorReal',
                                     l => '$',
                                     e1 => 'Math::VectorReal',
                                     e2 => 'Math::VectorReal',
                                   };

  my @edge;
  for( my $i = 0; $i < 3; $i++ ) {
    $edge[$i] = new edge_struct;
  }

  # Fill the edge structure for each side of the triangle.
  $edge[0]->e( $vector1 x $vector2 );
  $edge[0]->e1( $vector1 );
  $edge[0]->e2( $vector2 );
  $edge[0]->l( acos( $vector1 . $vector2 ) );
  $edge[1]->e( $vector2 x $vector3 );
  $edge[1]->e1( $vector2 );
  $edge[1]->e2( $vector3 );
  $edge[1]->l( acos( $vector2 . $vector3 ) );
  $edge[2]->e( $vector3 x $vector1 );
  $edge[2]->e1( $vector3 );
  $edge[2]->e1( $vector1 );
  $edge[2]->l( acos( $vector3 . $vector1 ) );

  for( my $i = 0; $i < scalar( $self->corners ); $i++ ) {
    my $j = 0;
    if( $i < scalar( $self->corners ) - 1 ) {
      $j = $i + 1;
    }
    my $ci = $self->get_corner( $i );
    my $cj = $self->get_corner( $j );
    my $cedgelen = acos( $ci . $cj );

    for( my $iedge = 0; $iedge < 3; $iedge++ ) {

      my $a1 = $edge[$iedge]->e x ( $ci x $cj );
      $a1->norm;

      # If the intersection $a1 is inside the edge of the convex,
      # its distance to the corners is smaller than the edgelength.
      # This test has to be done for both the edge of the convex and
      # the edge of the triangle.
      for( my $k = 0; $k < 2; $k++ ) {
        my $l1 = acos( $ci . $a1 );
        my $l2 = acos( $cj . $a1 );
        if( ( $l1 - $cedgelen <= HTM__GEPSILON ) &&
            ( $l2 - $edge[$iedge]->l <= HTM__GEPSILON ) ) {
          $l1 = acos( $edge[$iedge]->e1 . $a1 );
          $l2 = acos( $edge[$iedge]->e2 . $a1 );
          if( ( $l1 - $edge[$iedge]->l <= HTM__GEPSILON ) &&
              ( $l2 - $edge[$iedge]->l <= HTM__GEPSILON ) ) {

            return 1;
          }
        }
        $a1 = $a1 * -1; # Do the same for the other intersection.
      }
    }
  }

  return $self->test_vector_inside( vector1 => $vector1,
                                    vector2 => $vector2,
                                    vector3 => $vector3,
                                    vector4 => $self->get_corner( 0 ) );

}

=item B<test_hole>

Test for negative constraints that have their centres inside the node with the three
corners v0, v1, and v2:

  my $hole = $self->test_hole( vector1 => $vector1,
                               vector2 => $vector2,
                               vector3 => $vector3 );

This method returns true or false.

=cut

sub test_hole {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  my $test = 0;
  for( my $i = 0; $i < scalar( $self->constraints ); $i++ ) {
    my $ci = $self->get_constraint( $i );
    if( $ci->sign == HTM__NEGATIVE ) {

      if( ( ( $vector1 x $vector2 ) . $ci->direction ) > 0.0 ) {
        next;
      }
      if( ( ( $vector2 x $vector3 ) . $ci->direction ) > 0.0 ) {
        next;
      }
      if( ( ( $vector3 x $vector1 ) . $ci->direction ) > 0.0 ) {
        next;
      }
      $test = 1;
      last;
    }
  }

  return $test;

}

=item B<test_node>

  my $mark = $convex->test_node( node_index => $node_index,
                                 index => $index );

The node_index argument is an integer, and the index argument is an C<Astro::HTM::Index>
object.

This method returns a markup constant as described in the :markup tag section of
C<Astro::HTM::Constants>.

=cut

sub test_node {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'node_index'} ) ) {
    croak "Node index must be passed to Astro::HTM::Convex::test_node()";
  }
  my $node_index = $args{'node_index'};

  if( ! defined( $args{'index'} ) ||
      ! UNIVERSAL::isa( $args{'index'}, "Astro::HTM::Index" ) ) {
    croak "Index must be passed to Astro::HTM::Convex::test_node() as an Astro::HTM::Index object";
  }
  my $index = $args{'index'};

  # Start with testing the vertices for the QuadNode with this index.
  my $N = $index->get_node( $node_index );

  my $quadnode_vertices = $N->v;
  my $quadnode_childids = $N->child_id;

  my $V0 = $index->get_vertex( $quadnode_vertices->[0] );
  my $V1 = $index->get_vertex( $quadnode_vertices->[1] );
  my $V2 = $index->get_vertex( $quadnode_vertices->[2] );

  my $vsum = $self->test_vertex( vector => $V0 ) +
             $self->test_vertex( vector => $V1 ) +
             $self->test_vertex( vector => $V2 );

  my $mark = $self->test_triangle( vector1 => $V0,
                                   vector2 => $V1,
                                   vector3 => $V2,
                                   vsum => $vsum );

  # If we are down at the leaf nodes here, $mark will be HTM__MARKUP_DONTKNOW
  # really, but since these are the leaf nodes here and we want to be on the
  # safe side, mark them as HTM__MARKUP_PARTIAL.
  if( ( $quadnode_childids->[0] == 0 ) && ( $mark == HTM__MARKUP_DONTKNOW ) ) {
    $mark = HTM__MARKUP_PARTIAL;
  }

  return $mark;
}

=item B<test_node_vectors>

Test three vectors.

  my $mark = $self->test_node_vectors( vector1 => $vector1,
                                       vector2 => $vector2,
                                       vector3 => $vector3 );

The three arguments are all mandatory and must be C<Math::VectorReal> objects.

This method returns a markup constant as described in the :markup tag section of
C<Astro::HTM::Constants>.

=cut

sub test_node_vectors {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  my $vsum = $self->test_vertex( vector => $vector1 ) + $self->test_vertex( vector => $vector2 ) + $self->test_vertex( vector => $vector3 );
  my $mark = $self->test_triangle( vector1 => $vector1,
                                   vector2 => $vector2,
                                   vector3 => $vector3,
                                   vsum => $vsum );

  if( $mark == HTM__MARKUP_DONTKNOW ) {
    $mark = HTM__MARKUP_PARTIAL;
  }

  return $mark;

}

=item B<test_other_pos_none>

Find a positive constraint that does not intersect the edges of the node given
by three vectors:

  my $constraint_index = $convex->test_other_pos_none( vector1 => $vector1,
                                                       vector2 => $vector2,
                                                       vector3 => $vector3 );

Returns the constraint index if one is found, 0 otherwise.

=cut

sub test_other_pos_none {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_node_vectors() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  my $i = 1;
  if( scalar( $self->constraints ) > 1 ) {
    my $constraint = $self->get_constraint( $i );
    while( ( $i < scalar( $self->constraints ) ) &&
           ( $constraint->sign == HTM__POSITIVE ) ) {

      if( ! $self->test_edge_constraint( vector1 => $vector1,
                                         vector2 => $vector2,
                                         vector3 => $vector3,
                                         cindex => $i ) ) {
        return $i;
      }
      $i++;
      $constraint = $self->get_constraint( $i );
    }
  }

  return 0;
}

=item B<test_partial>

  $convex->test_partial( level => $level,
                         id => $id,
                         vector1 => $vector1,
                         vector2 => $vector2,
                         vector3 => $vector3,
                         pprev => $pprev,
                         index => $index,
                         range => $range,
                         varlen => $varlen );

The level, id, pprev, and varlen arguments are integers, vector0, vector1, and
vector2 are C<Math::VectorReal> objects, index is an C<Astro::HTM::Index> object,
and range is an C<Astro::HTM::Range> object.

=cut

sub test_partial {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'level'} ) ) {
    croak "Level must be passed to Astro::HTM::Convex::test_partial()";
  }
  my $level = $args{'level'};

  if( ! defined( $args{'id'} ) ) {
    croak "ID must be passed to Astro::HTM::Convex::test_partial()";
  }
  my $id = $args{'id'};

  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_partial() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_partial() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_partial() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  if( ! defined( $args{'pprev'} ) ) {
    croak "pprev must be passed to Astro::HTM::Convex::test_partial()";
  }
  my $pprev = $args{'pprev'};

  if( ! defined( $args{'index'} ) ||
      ! UNIVERSAL::isa( $args{'index'}, "Astro::HTM::Index" ) ) {
    croak "Index must be passed to Astro::HTM::Convex::test_trixel() as an Astro::HTM::Index object";
  }
  my $index = $args{'index'};

  if( ! defined( $args{'range'} ) ||
      ! UNIVERSAL::isa( $args{'range'}, "Astro::HTM::Range" ) ) {
    croak "Range must be passed to Astro::HTM::Convex::test_trixel() as an Astro::HTM::Range object";
  }
  my $range = $args{'range'};

  my $varlen;
  if( ! defined( $args{'varlen'} ) ) {
    $varlen = 0;
  } else {
    $varlen = $args{'varlen'};
  }

  # Done with arguments, now set up some variables.
  my ( @ids, $id0, $m, $P, $F, @m );
  $P = 0;
  $F = 0;

  my $w0 = $vector2 + $vector3;
  my $w1 = $vector1 + $vector3;
  my $w2 = $vector2 + $vector1;
  $w0->norm;
  $w1->norm;
  $w2->norm;

  $ids[0] = $id0 = $id << 2;
  $ids[1] = $id0 + 1;
  $ids[2] = $id0 + 2;
  $ids[3] = $id0 + 3;

  $m[0] = $self->test_node_vectors( vector1 => $vector1,
                                    vector2 => $w2,
                                    vector3 => $w1 );
  $m[1] = $self->test_node_vectors( vector1 => $vector2,
                                    vector2 => $w0,
                                    vector3 => $w2 );
  $m[2] = $self->test_node_vectors( vector1 => $vector3,
                                    vector2 => $w1,
                                    vector3 => $w0 );
  $m[3] = $self->test_node_vectors( vector1 => $w0,
                                    vector2 => $w1,
                                    vector3 => $w2 );

  for( my $i = 0; $i < 4; $i++ ) {
    if( $m[$i] == HTM__MARKUP_FULL ) {
      $F++;
    }
    if( $m[$i] == HTM__MARKUP_PARTIAL ) {
      $P++;
    }
  }

  # Several interesting cases for saving this (the parent) trixel.
  # Case P==4, all four children are partials, so pretend parent is full, we save
  # and return.
  # Case P==3, and F==1, most of the parent is in, so pretend that parent is
  # full again
  # Case P==2 or 3, but the previous testPartial had three partials, so parent
  # was in an arc as opposed to previous partials being fewer, so parent was in
  # a tiny corner...
  if( ( $level-- <= 0 ) ||
      ( ( $P == 4 ) ||
        ( $F >= 2 ) ||
        ( $P == 3 && $F == 1 ) ||
        ( $P > 1 && $pprev == 3 ) ) ) {
    $self->save_trixel( htmid => $id,
                        range => $range,
                        varlen => $varlen );
    return;
  } else {
    for( my $i = 0; $i < 4; $i++ ) {
      if( $m[$i] == HTM__MARKUP_FULL ) {
        $self->save_trixel( htmid => $ids[$i],
                            range => $range,
                            varlen => $varlen );
      }
    }

    # Look at the four kids again for partials.
    if( $m[0] == HTM__MARKUP_PARTIAL ) {
      $self->test_partial( level => $level,
                           id => $ids[0],
                           vector1 => $vector1,
                           vector2 => $w2,
                           vector3 => $w1,
                           pprev => $P,
                           index => $index,
                           range => $range,
                           varlen => $varlen );
    }
    if( $m[1] == HTM__MARKUP_PARTIAL ) {
      $self->test_partial( level => $level,
                           id => $ids[1],
                           vector1 => $vector2,
                           vector2 => $w0,
                           vector3 => $w2,
                           pprev => $P,
                           index => $index,
                           range => $range,
                           varlen => $varlen );
    }
    if( $m[2] == HTM__MARKUP_PARTIAL ) {
      $self->test_partial( level => $level,
                           id => $ids[2],
                           vector1 => $vector3,
                           vector2 => $w1,
                           vector3 => $w2,
                           pprev => $P,
                           index => $index,
                           range => $range,
                           varlen => $varlen );
    }
    if( $m[3] == HTM__MARKUP_PARTIAL ) {
      $self->test_partial( level => $level,
                           id => $ids[3],
                           vector1 => $w0,
                           vector2 => $w1,
                           vector3 => $w2,
                           pprev => $P,
                           index => $index,
                           range => $range,
                           varlen => $varlen );
    }
  }
}

=item B<test_triangle>

Test a triangle given by three vertices if it intersects the convex.

  $test = $convex->test_triangle( vector1 => $vector1,
                                  vector2 => $vector2,
                                  vector3 => $vector3,
                                  vsum => $vsum );

The three vectors must be C<Math::VectorReal> objects. vsum must be an integer.

This method returns a markup constant as described in the :markup tag section of
C<Astro::HTM::Constants>.

=cut

sub test_triangle {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_triangle() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_triangle() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_triangle() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  if( ! defined( $args{'vsum'} ) ) {
    croak "vsum must be passed to Astro::HTM::Convex::test_triangle()";
  }
  my $vsum = $args{'vsum'};

  # Quick check for partial.
  if( $vsum == 1 || $vsum == 2 ) {
    return HTM__MARKUP_PARTIAL;
  }

  # Check for vsum == 3.
  if( $vsum == 3 ) {
    if( $self->sign == HTM__POSITIVE || $self->sign == HTM__ZERO ) {
      return HTM__MARKUP_FULL;
    }
    if( $self->test_hole( vector1 => $vector1,
                          vector2 => $vector2,
                          vector3 => $vector3 ) ) {
      return HTM__MARKUP_PARTIAL;
    }
    if( $self->test_edge( vector1 => $vector1,
                          vector2 => $vector2,
                          vector3 => $vector3 ) ) {
      return HTM__MARKUP_PARTIAL;
    }
    return HTM__MARKUP_FULL;
  }

  # If we've reached this far, we have vsum == 0.
  if( ! $self->test_bounding_circle( vector1 => $vector1,
                                     vector2 => $vector2,
                                     vector3 => $vector3 ) ) {
    return HTM__MARKUP_REJECT;
  }
  if( ( $self->sign == HTM__POSITIVE ) ||
      ( $self->sign == HTM__MIXED ) ||
      ( $self->sign == HTM__ZERO && scalar( $self->constraints ) == 2 ) ) {
    if( $self->test_edge_constraint( vector1 => $vector1,
                                     vector2 => $vector2,
                                     vector3 => $vector3,
                                     cindex => 0 ) ) {

      my $cindex = $self->test_other_pos_none( vector1 => $vector1,
                                               vector2 => $vector2,
                                               vector3 => $vector3 );
      if( $cindex > 0 ) {

        my $cindex_constraint = $self->get_constraint( $cindex );

        if( $self->test_constraint_inside( vector1 => $vector1,
                                           vector2 => $vector2,
                                           vector3 => $vector3,
                                           cindex => $cindex ) ) {
          return HTM__MARKUP_PARTIAL;
        } elsif( $cindex_constraint->contains( $vector1 ) ) {
          return HTM__MARKUP_PARTIAL;
        } else {
          return HTM__MARKUP_REJECT;
        }
      } else {
        if( $self->sign == HTM__POSITIVE || $self->sign == HTM__ZERO ) {
          return HTM__MARKUP_PARTIAL;
        } else {
          return HTM__MARKUP_DONTKNOW;
        }
      }
    } else {
      if( $self->sign == HTM__POSITIVE || $self->sign == HTM__ZERO ) {
        if( $self->test_constraint_inside( vector1 => $vector1,
                                           vector2 => $vector2,
                                           vector3 => $vector3,
                                           cindex => 0 ) ) {
          return HTM__MARKUP_PARTIAL;
        } else {
          return HTM__MARKUP_REJECT;
        }
      } else {
        return HTM__MARKUP_DONTKNOW;
      }
    }
  } elsif( $self->sign == HTM__ZERO ) {
    if( scalar( $self->corners ) > 0 && $self->test_edge_zero( vector1 => $vector1,
                                                               vector2 => $vector2,
                                                               vector3 => $vector3 ) ) {
      return HTM__MARKUP_PARTIAL;
    } else {
      return HTM__MARKUP_REJECT;
    }
  }

  return HTM__MARKUP_PARTIAL;

}

=item B<test_trixel>

This is the main test of a trixel vs. a Convex.

  $test = $convex->test_trixel( id => $id,
                                index => $index,
                                range => $range,
                                varlen => $varlen );

The id, index and range named arguments are mandatory. The id must be
an integer denoting the ID of the node in the Index to test, the index
must be an C<Astro::HTM::Index> object, and the range must be an
C<Astro::HTM::Range> object. The varlen argument is optional; if varlen
is true then variable-length trixels can be returned. It defaults
to false.

=cut

sub test_trixel {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'id'} ) ) {
    croak "ID must be passed to Astro::HTM::Convex::test_trixel()";
  }
  my $id = $args{'id'};
  if( ! defined( $args{'index'} ) ||
      ! UNIVERSAL::isa( $args{'index'}, "Astro::HTM::Index" ) ) {
    croak "Index must be passed to Astro::HTM::Convex::test_trixel() as an Astro::HTM::Index object";
  }
  my $index = $args{'index'};
  if( ! defined( $args{'range'} ) ||
      ! UNIVERSAL::isa( $args{'range'}, "Astro::HTM::Range" ) ) {
    croak "Range must be passed to Astro::HTM::Convex::test_trixel() as an Astro::HTM::Range object";
  }
  my $range = $args{'range'};
  my $varlen;
  if( ! defined( $args{'varlen'} ) ) {
    $varlen = 0;
  } else {
    $varlen = $args{'varlen'};
  }

  my ( $mark, $child_id, $tid );

  my $index_node = $index->get_node( $id );

  $mark = $self->test_node( id => $id, index => $index );

  if( $mark == HTM__MARKUP_FULL ) {
    $tid = $index_node->id;
    $self->save_trixel( htmid => $tid,
                        range => $range,
                        varlen => $varlen );
    return $mark;
  } elsif( $mark == HTM__MARKUP_REJECT ) {
    $tid = $index_node->id;
    return $mark;
  }

  $child_id = $index_node->get_childid( 0 );
  if( $child_id != 0 ) {

    $tid = $index_node->id;
    $child_id = $index_node->get_childid( 0 );
    $self->test_trixel( id => $child_id,
                        index => $index,
                        range => $range,
                        varlen => $varlen );

    $child_id = $index_node->get_childid( 1 );
    $self->test_trixel( id => $child_id,
                        index => $index,
                        range => $range,
                        varlen => $varlen );

    $child_id = $index_node->get_childid( 2 );
    $self->test_trixel( id => $child_id,
                        index => $index,
                        range => $range,
                        varlen => $varlen );

    $child_id = $index_node->get_childid( 3 );
    $self->test_trixel( id => $child_id,
                        index => $index,
                        range => $range,
                        varlen => $varlen );

  } else {

    if( $index->get_addlevel > 0 ) {

      $self->test_partial( level => $index->addlevel,
                           id => $index_node->id,
                           vector1 => $index->get_vertex( $index_node->get_v(0) ),
                           vector2 => $index->get_vertex( $index_node->get_v(1) ),
                           vector3 => $index->get_vertex( $index_node->get_v(2) ),
                           pprev => 0,
                           index => $index,
                           range => $range,
                           varlen => $varlen );
    } else {
      $self->save_trixel( htmid => $index_node->id,
                          range => $range,
                          varlen => $varlen );
    }
  }

  return $mark;
}

=item B<test_vector_inside>

Test if a given vector lies within a triangle whose corners are
three other vectors.

  my $test = $self->test_vector_inside( vector1 => $vector1,
                                        vector2 => $vector2,
                                        vector3 => $vector3,
                                        vector4 => $vector4 );

This method returns true if vector4 lies within the triangle whose
corners are the other three vectors, and false otherwise.

=cut

sub test_vector_inside {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector1'} ) ||
      ! UNIVERSAL::isa( $args{'vector1'}, "Math::VectorReal" ) ) {
    croak "vector1 must be passed to Astro::HTM::Convex::test_vector_inside() as a Math::VectorReal object";
  }
  my $vector1 = $args{'vector1'};

  if( ! defined( $args{'vector2'} ) ||
      ! UNIVERSAL::isa( $args{'vector2'}, "Math::VectorReal" ) ) {
    croak "vector2 must be passed to Astro::HTM::Convex::test_vector_inside() as a Math::VectorReal object";
  }
  my $vector2 = $args{'vector2'};

  if( ! defined( $args{'vector3'} ) ||
      ! UNIVERSAL::isa( $args{'vector3'}, "Math::VectorReal" ) ) {
    croak "vector3 must be passed to Astro::HTM::Convex::test_vector_inside() as a Math::VectorReal object";
  }
  my $vector3 = $args{'vector3'};

  if( ! defined( $args{'vector4'} ) ||
      ! UNIVERSAL::isa( $args{'vector4'}, "Math::VectorReal" ) ) {
    croak "vector4 must be passed to Astro::HTM::Convex::test_vector_inside() as a Math::VectorReal object";
  }
  my $vector4 = $args{'vector4'};

  if( ( ( ( $vector1 x $vector2 ) . $vector4 ) < 0 ) ||
      ( ( ( $vector2 x $vector3 ) . $vector4 ) < 0 ) ||
      ( ( ( $vector3 x $vector1 ) . $vector4 ) < 0 ) ) {
    return 0;
  }
  return 1;
}

=item B<test_vertex>

Test if a given vertex is inside the vertex.

  my $test = $self->test_vertex( vector => $vector );

Returns true or false.

=cut

sub test_vertex {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  if( ! defined( $args{'vector'} ) ||
      ! UNIVERSAL::isa( $args{'vector'}, "Math::VectorReal" ) ) {
    croak "Vector passed to Astro::HTM::Convex::test_vertex() must be a Math::VectorReal object";
  }
  my $vector = $args{'vector'};

  for( my $i = 0; $i < scalar( $self->constraints ); $i++ ) {
    my $ci = $self->get_constraint( $i );
    if( $ci->direction . $vector < $ci->distance ) {
      return 0;
    }
  }
  return 1;
}

=item B<to_string>

Stringify an C<Astro::HTM::Convex> object.

  my $string = $convex->to_string();

=cut

sub to_string {
  my $self = shift;

  my $string = "#CONVEX\n" . scalar( $self->constraints ) . " " . $self->print_sign() . "\n";
  foreach my $constraint ( $self->constraints ) {
    $string .= "$constraint\n";
  }

  return $string;
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
