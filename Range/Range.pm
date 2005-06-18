package Astro::HTM::Range;

=head1 NAME

Astro::HTM::Range - Class for dealing with ranges of HTM ids.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;

use Algorithm::SkipList;
use Storable qw/ dclone /;

use Astro::HTM::Constants qw/ :range /;

use Class::Struct 'Astro::HTM::Range' => {
                                          range => 'Set::Infinite',
                                         };

=item B<add_range>

=cut

sub add_range {
  my $self = shift;

  my $lo = shift; # scalar
  my $hi = shift; # scalar

  $self->range->union( $lo, $hi );
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

  return $rstat;
}

=item B<is_in_range>

=cut

sub is_in_range {
  my $self = shift;

  my $other = shift; # Astro::HTM::Range

  my $set1 = $self->range;
  my $set2 = $other->range;

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

  $self->range( $self->range->union( $lo, $hi ) );
}

1;
