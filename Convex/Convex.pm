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
    $self->test_trixel( $i, $index, $range, $varlen );
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
    $range->merge_range( $htmid, $htmid );
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

  $range->merge_range( $lo, $hi );

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

  $mark = $self->test_node( $id, $index )

  if( $mark == HTM__MARKUP_FULL ) {
    $tid = $index_node->id;
    $self->save_trixel( $tid, $range, $varlen );
    return $mark;
  } elsif( $mark == HTM__MARKUP_REJECT ) {
    $tid = $index_node->id;
    return $mark;
  }

  $child_id = $index_node->get_childid( 0 );
  if( $child_id != 0 ) {

    $tid = $index_node->id;
    $child_id = $index_node->get_childid( 0 );
    $self->test_trixel( $child_id, $index, $range, $varlen );

    $child_id = $index_node->get_childid( 1 );
    $self->test_trixel( $child_id, $index, $range, $varlen );

    $child_id = $index_node->get_childid( 2 );
    $self->test_trixel( $child_id, $index, $range, $varlen );

    $child_id = $index_node->get_childid( 3 );
    $self->test_trixel( $child_id, $index, $range, $varlen );

  } else {

    if( $index->get_addlevel > 0 ) {

      $self->test_partial( $index->addlevel,
                           $index_node->id,
                           $index->get_vertex( $index_node->get_v(0) ),
                           $index->get_vertex( $index_node->get_v(1) ),
                           $index->get_vertex( $index_node->get_v(2) ),
                           0,
                           $index,
                           $range,
                           $varlen );
    } else {
      $self->save_trixel( $index_node->id, $range, $varlen );
    }
  }

  return $mark;
}

1;
