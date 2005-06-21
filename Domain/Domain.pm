package Astro::HTM::Domain;

=head1 NAME

Astro::HTM::Domain - Class for handling HTM Domains.

=head1 DESCRIPTION

An C<Astro::HTM::Domain> manages a group of C<Astro::HTM::Convex> objects.
This is the data structure that can define any area on the sphere. With
the C<intersect> method, the HTM index returns the trixels that intersect
with the area specified by the current C<Astro::HTM::Domain> instance.
There are two lists returned: one for the nodes fully contained in the
area and one for the triangles which lie only partially in the domain.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

our $VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::HTM::Domain> object.

  my $domain = new Astro::HTM::Domain();

This method takes no arguments.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $domain = {};
  $domain->{CONVEXES} = [];
  $domain->{OLEVEL} = undef;

  bless( $domain, $class );
  return $domain;
}

=back

=head2 Accessor Methods

=over 4

=item B<convexes>

Return the set of all C<Astro::HTM::Convex> objects contained by this
C<Astro::HTM::Domain> object.

  my $convexes = $self->convexes;
  my @convexes = $self->convexes;

When called in scalar context, this method will return the list as
an array reference. When called in list context, this method will
return the list as a list.

=cut

sub convexes {
  my $self = shift;

  if( wantarray ) {
    return @{$self->{CONVEXES}};
  } else {
    return $self->{CONVEXES};
  }
}

=item B<olevel>

Set or return the output level for the ranges contained by this
C<Astro::HTM::Domain> object.

  my $olevel = $domain->olevel();
  $domain->olevel( 15 );

This method returns an integer. If the output level has not been
defined, it will default to 20.

This method also sets the output level for all contained convexes
to the desired output level.

=cut

sub olevel {
  my $self = shift;
  if( @_ ) {
    my $olevel = shift;
    $self->{OLEVEL} = $olevel;

    foreach my $convex ( $self->convexes ) {
      $convex->olevel( $olevel );
    }
  }
  if( ! defined( $self->{OLEVEL} ) ) {
    $self->{OLEVEL} = 20;
    foreach my $convex ( $self->convexes ) {
      $convex->olevel( 20 );
    }
  }
  return $self->{OLEVEL};
}

=back

=head2 General Methods

=over 4

=item B<add_convex>

Add a C<Astro::HTM::Convex> object to this C<Astro::HTM::Domain> object.

  $domain->add_convex( $convex );

The argument must be an C<Astro::HTM::Convex> object. This method will
croak if the argument is not defined or is not an C<Astro::HTM::Convex>
object.

This method returns nothing and modifies the C<Astro::HTM::Domain> object
in-place.

=cut

sub add_convex {
  my $self = shift;

  my $convex = shift;
  if( ! defined( $convex ) ||
      ! UNIVERSAL::isa( $convex, "Astro::HTM::Convex" ) ) {
    croak "Must supply Astro::HTM::Convex object to add_convex() method";
  }

  # Set the convex's output level to the domain's output level.
  $convex->olevel( $self->olevel );

  push @{$self->{CONVEXES}}, $convex;

}

=item B<add_domain>

Add one C<Astro::HTM::Domain> object to another, essentially doing a simple
union.

  $domain->add_domain( $domain2 );

The argument must be an C<Astro::HTM::Domain> object. This method will
croak if the argument is not defined or is not an C<Astro::HTM::Domain>
object.

This method returns nothing and modifies the C<Astro::HTM::Domain> object
in-place. The C<Astro::HTM::Domain> object passed as an argument to this
method is not modified.

=cut

sub add_domain {
  my $self = shift;

  my $domain = shift;
  if( ! defined( $domain ) ||
      ! UNIVERSAL::isa( $domain, "Astro::HTM::Domain" ) ) {
    croak "Must supply Astro::HTM::Domain object to add_domain() method";
  }

  my @convexes = $domain->convexes;

  push @{$self->{CONVEXES}}, @convexes;
}

=item B<clear>

Clear the C<Astro::HTM::Domain> object by removing all C<Astro::HTM::Convex>
objects.

  $domain->clear();

This method returns nothing and modifies the C<Astro::HTM::Domain> object
in-place.

=cut

sub clear {
  my $self = shift;
  $self->{CONVEXES} = [];
}

=item B<contains>

Check whether a C<Math::VectorReal> object is inside any of the
C<Astro::HTM::Convex> objects contained by this C<Astro::HTM::Domain>
object.

  my $contains = $domain->contains( $vector );

This method requires one argument, a C<Math::VectorReal> object. It
returns true of the vector is contained within any of the C<Astro::HTM::Convex>
objects contained by this C<Astro::HTM::Domain> object by calling the
C<contains> method from C<Astro::HTM::Convex>. The method returns
false if the given C<Math::VectorReal> object is not contained by
any of the C<Astro::HTM::Convex> objects.

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

  # Go through the list of Astro::HTM::Convex objects.
  foreach my $convex ( $self->convexes ) {
    if( $convex->contains( $vector ) ) {
      return 1;
    }
  }

  return 0;
}

=item B<get_convex>

Get a convex by index.

  my $convex = $domain->get_convex( $i );

This method returns an C<Astro::HTM::Convex> object. If the index
is out of bounds on the array, this method will return undef;

=cut

sub get_convex {
  my $self = shift;
  my $index = shift;

  if( ! defined( $index ) ) {
    croak "Convex index must be passed to Astro::HTM::Domain::get_convex()";
  }

  if( $index > scalar( $self->convexes ) ||
      $index < 0 ) {
    return undef;
  }

  return $self->{CONVEXES}->[$index];
}

=item B<intersect>

Return the range set of the nodes that are intersected by this
C<Astro::HTM::Domain> object.

  $domain->intersect( index => $index,
                      range => $range,
                      varlen => $varlen );

The index must be defined as an C<Astro::HTM::Index> object, the
range must be defined as an C<Astro::HTM::Range> object, and the
varlen must be 0 or 1.

Setting varlen to true (1) makes this method adaptive, giving
HTM ranges of different levels suiting the shape of the area.

=cut

sub intersect {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;

  if( ! defined( $args{'index'} ) ||
      ! UNIVERSAL::isa( ${$args{'index'}}, "Astro::HTM::Index" ) ) {
    croak "Index must be passed to Astro::HTM::Convex::intersect() as a reference to an Astro::HTM::Index object";
  }
  my $index_ref = $args{'index'};

  if( ! defined( $args{'range'} ) ||
      ! UNIVERSAL::isa( ${$args{'range'}}, "Astro::HTM::Range" ) ) {
    croak "Range must be passed to Astro::HTM::Convex::intersect() as a reference to an Astro::HTM::Range object";
  }
  my $range_ref = $args{'range'};

  my $varlen;
  if( ! defined( $args{'varlen'} ) ) {
    $varlen = 0;
  } else {
    $varlen = $args{'varlen'};
  }

  my $i;
  for( $i = 0; $i < scalar( @{$self->convexes} ); $i++ ) {
print "calling convex::intersect for convex $i\n";
    my $convex = $self->get_convex( $i );
    $convex->intersect( index => $index_ref,
                        range => $range_ref,
                        varlen => $varlen );
  }

  return 1;
}

=item B<simplify>

Call the C<Astro::HTM::Convex::simplify()> method for all convexes.

  $domain->simplify();

This method takes no arguments.

=cut

sub simplify {
  my $self = shift;
  foreach my $convex ( $self->convexes ) {
    $convex->simplify();
  }
}

=item B<to_string>

Stringify an C<Astro::HTM::Domain> object.

  my $string = $domain->to_string();

=cut

sub to_string {
  my $self = shift;

  my $string = "#DOMAIN\n" . scalar( $self->convexes ) . "\n";
  foreach my $convex ( $self->convexes ) {
    $string .= $convex->to_string;
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
