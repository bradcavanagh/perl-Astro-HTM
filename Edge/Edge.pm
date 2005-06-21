package Astro::HTM::Edge;

use strict;
use warnings;
use warnings::register;

use Carp;

use Astro::HTM::Index;
use Astro::HTM::Layer;

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $edge = bless { _START => undef,
                     _END => undef,
                     MID => undef,
                     TREE => undef,
                     LTABS => [],
                     EDGES => [],
                     INDEX => undef,
                     LAYER => undef,
                   };

  my %args = @_;

  if( defined( $args{'tree'} ) &&
      UNIVERSAL::isa( $args{'tree'}, "Astro::HTM::Index" ) ) {
    $edge->{TREE} = $args{'tree'};

    if( defined( $args{'layerindex'} ) ) {
      $edge->{LAYER} = $edge->{TREE}->get_layer( $args{'layerindex'} );
      $edge->{INDEX} = $edge->{LAYER}->number_of_vertices;
    }
  }
  return $edge;
}

sub edges {
  my $self = shift;
  return $self->{EDGES};
}

sub end {
  my $self = shift;
  if( @_ ) {
    $self->{_END} = shift;
  }
  return $self->{_END};
}

sub index {
  my $self = shift;
  if( @_ ) {
    $self->{INDEX} = shift;
  }
  return $self->{INDEX};
}

sub layer {
  my $self = shift;
  if( @_ ) {
    $self->{LAYER} = shift;
  }
  return $self->{LAYER};
}

sub ltabs {
  my $self = shift;
  return $self->{LTABS};
}

sub mid {
  my $self = shift;
  if( @_ ) {
    $self->{MID} = shift;
  }
  return $self->{MID};
}

sub start {
  my $self = shift;
  if( @_ ) {
    $self->{_START} = shift;
  }
  return $self->{_START};
}

sub tree {
  my $self = shift;
  if( @_ ) {
    $self->{TREE} = shift;
  }
  return $self->{TREE};
}

sub add_edge {
  my $self = shift;

  my $i = shift;
  my $em = shift;

  if( $i > scalar( @{$self->{EDGES}} ) ) {
    $ {$self->{EDGES}}[$i] = $em;
  } else {
    splice( @{$self->{EDGES}},
            $i,
            ( -1 - $i ),
            ( $em, @{$self->{EDGES}}[$i+1..-1] ) );
  }
}

sub add_ltab {
  my $self = shift;

  my $i = shift;
  my $ltab = shift;

  if( $i > scalar( @{$self->{LTABS}} ) ) {
    ${$self->{LTABS}}[$i] = $ltab;
  } else {
    splice( @{$self->{LTABS}},
            $i,
            ( -1 - $i ),
            ( $ltab, @{$self->{LTABS}}[$i+1..-1] ) );
  }
}

sub make_midpoints {
  my $self = shift;

  my $index = $self->layer->first_index;
  my $c = 0;

  for( my $i = 0; $i < $self->layer->number_of_nodes; $i++ ) {
    $c = $self->new_edge( $c, $index, 0 );
    $c = $self->new_edge( $c, $index, 1 );
    $c = $self->new_edge( $c, $index, 2 );
    $index++;
  }
}

sub new_edge {
  my $self = shift;

  my $emindex = shift;
  my $index = shift;
  my $k = shift;

  my ( $en, $em, $swap );
  $em = new Astro::HTM::Edge;
  $self->add_edge( $emindex, $em );

  my $node = $self->tree->get_node( $index );

  my $v = $node->v;
  my $w = $node->w;
  if( $k == 0 ) {
    $em->start( $v->[1] );
    $em->end( $v->[2] );
  } elsif( $k == 2 ) {
    $em->start( $v->[0] );
    $em->end( $v->[2] );
  } else {
    $em->start( $v->[0] );
    $em->end( $v->[1] );
  }

  if( $em->start > $em->end ) {
    $swap = $em->start;
    $em->start( $em->end );
    $em->end( $swap );
  }

  my $return = $self->edge_match( $em );
  if( $return != 0 ) {
    return $emindex;
  }

  $self->insert_lookup( $em );
  $em->mid( $self->get_midpoint( $em ) );
  $emindex++;
  return $emindex;
}

sub insert_lookup {
  my $self = shift;
  my $em = shift;

  my $j = 6 * $em->start;
  my $i;
  for( $i = 0; $i < 6; $i++ ) {

    my $ltab = $self->ltabs;
    if( ! defined( $ltab->[$j] ) ) {
      $self->add_ltab( $j, $em );
      return;
    }

    $j++;
  }
}

sub edge_match {
  my $self = shift;
  my $em = shift;

  my $i = 6 * $em->start;
  my $ltab = $self->ltabs;
  while( defined( $ltab->[$i] ) ) {
    if( $em->end == $ltab->[$i]->end ) {
      return $ltab->[$i];
    }
    $i++;
  }
  return 0;
}

sub get_midpoint {
  my $self = shift;
  my $em = shift;

  my $v = $self->tree->get_vertex( $em->start ) + $self->tree->get_vertex( $em->end );
  if( $v->length != 0 ) {
    $v->norm;
  }
  $self->tree->add_vertex( $self->index, $v );
  $self->index( $self->index + 1 );
  return $self->index;
}

1;
