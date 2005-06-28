package Astro::HTM::Range;

=head1 NAME

Astro::HTM::Range - Class for dealing with ranges of HTM ids.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;

use Set::Infinite;
use Storable qw/ dclone /;

use Astro::HTM::Constants qw/ :range /;
use Astro::HTM::Functions;

use Class::Struct 'Astro::HTM::Range' => {
                                          range => 'Set::Infinite',
                                         };

our $VERSION = '0.01';

=item B<add_range>

=cut

sub add_range {
  my $self = shift;

  my $lo = shift; # scalar
  my $hi = shift; # scalar

  if( defined( $self->range ) ) {
    my $range = $self->range->union( $lo, $hi );
    $self->range( $range );
  } else {
    my $range = new Set::Infinite( $lo, $hi );
    $self->range( $range );
  }
}

=item B<compare>

=cut

sub compare {
  my $self = shift;

  my $other = shift; # Astro::HTM::Range object

  return( $self->range == $other->range );
}

=item B<is_in>

=cut

sub is_in {
  my $self = shift;

  my $key = shift; # scalar

  return $self->range->contains( $key );
}

=item B<is_in_lohi>

=cut

sub is_in_lohi {
  my $self = shift;

  my $a = shift; # scalar;
  my $b = shift; # scalar;

  my $range = new Set::Infinite( $a, $b );
  $range->integer;

  return $self->is_in_range( $range );
}

=item B<is_in_range>

=cut

sub is_in_range {
  my $self = shift;

  my $other = shift; # Astro::HTM::Range

  my $set1 = $self->range;
  my $set2 = $other->range;

  my $rel;
  if( $set2->is_subset( $set1 ) ) {
    $rel = 1;
  } elsif( $set2->is_disjoint( $set1 ) ) {
    $rel = -1;
  } else {
    $rel = 0;
  }
  return $rel;
}

=item B<merge_range>

=cut

sub merge_range {
  my $self = shift;

  my $lo = shift; # scalar
  my $hi = shift; # scalar

  my $newrange = new Set::Infinite( $lo, $hi );
  if( ! defined( $self->range ) ) {
    $self->range( $newrange->integer );
  } else {
    $self->range( $self->range->union( $newrange->integer ) );
  }
}

=item B<to_string>

This method is currently not implemented.

=cut

sub to_string {
  my $self = shift;

  return;

  my $symb = shift;
  my $which = lc( shift );

  if( ! defined( $symb ) ) {
    $symb = 0;
  }

  if( ! defined( $which ) ||
      length( $which . "" ) == 0 ) {
    $which = "both";
  }

  my $string = '';
  $self->range->iterate( sub {
                           if( ( $which eq 'lows' ) || ( $which eq 'both' ) ) {
                             $string .= ( $symb ?
                                          Astro::HTM::Functions->id_to_name( $_[0]->min ) :
                                          $_[0]->min );
                           }
                           if( $which eq 'both' ) {
                             $string .= " ";
                           }
                           if( $which eq 'highs' || $which eq 'both' ) {
                             $string .= ( $symb ?
                                          Astro::HTM::Functions->id_to_name( $_[0]->max ) :
                                          $_[0]->max );
                           }
                           $string .= "\n";
                         } );

  return $string;
}



1;
