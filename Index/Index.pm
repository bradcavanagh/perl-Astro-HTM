package Astro::HTM::Index;

=head1 NAME

Astro::HTM::Index - class to handle sky indexing routines.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;

use Class::Struct layer => { level => '$',
                             number_of_vertices => '$',
                             number_of_nodes => '$',
                             number_of_edges => '$',
                             first_index => '$',
                             first_vertex => '$',
                           };

use Math::Trig qw/ acos atan /;
use Math::VectorReal;

use Astro::HTM::QuadNode;

our $VERSION = '0.01';

use constant IOFFSET => 9;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $index = bless { ADDLEVEL => undef,
                      BUILDLEVEL => undef,
                      INDEX => undef,
                      LEAVES => undef,
                      MAXLEVEL => undef,
                      NODES => [],
                      NUMBER_OF_NODES => undef,
                      NUMBER_OF_VERTICES => undef,
                      STORED_LEAVES => undef,
                      VERTICES => [],
                    }, $class;

  my %args = @_;

  my $maxlevel;
  my $buildlevel;

  if( defined( $args{'resolution'} ) ) {
    my $htmwidth = 2.8125;
    my $resolution = $args{'resolution'};
    my $lev = 5;
    while ( $htmwidth > $resolution && $lev < 25 ) {
      $htmwidth /= 2;
      $lev = $lev + 1;
    }
    $maxlevel = $lev;
    $buildlevel = 5;
  } else {
    if( ! defined( $args{'maxlevel'} ) ) {
      $maxlevel = 20;
    } else {
      $maxlevel = $args{'maxlevel'};
    }
    if( ! defined( $args{'buildlevel'} ) ) {
      $buildlevel = 5;
    } else {
      $buildlevel = $args{'buildlevel'};
    }
  }

  $index->configure( maxlevel => $maxlevel,
                     buildlevel => $buildlevel );

  return $index;
}

=item B<configure>

=cut

sub configure {
  my $self = shift;

  # Deal with arguments.
  my %args = @_;
  my ( $maxlevel, $buildlevel );
  if( ! defined( $args{'maxlevel'} ) ) {
    $maxlevel = 20;
  } else {
    $maxlevel = $args{'maxlevel'};
  }
  if( ! defined( $args{'buildlevel'} ) ) {
    $buildlevel = 5;
  } else {
    $buildlevel = $args{'buildlevel'};
  }

  if( $buildlevel == 0 || $buildlevel > $maxlevel ) {
    $buildlevel = $maxlevel;
  }

  $self->addlevel( $maxlevel - $buildlevel );
  $self->v_max();

  my $n0 = new Astro::HTM::QuadNode();
  $n0->index( 0 );
  $self->add_node( $n0 );

  my $l0 = new layer;
  $l0->level( 0 );
  $l0->number_of_vertices( 6 );
  $l0->number_of_nodes( 8 );
  $l0->number_of_edges( 12 );
  $l0->first_index( 1 );
  $l0->first_vertex( 0 );
  $self->add_layer( $l0 );

  # Set the first six vertices.
  my @v = [ [ 0, 0, 1 ],
            [ 1, 0, 0 ],
            [ 0, 1, 0 ],
            [ -1, 0, 0 ],
            [ 0, -1, 0 ],
            [ 0, 0, -1 ] ];

  for( my $i = 0; $i < 6; $i++ ) {
    my $sv = vector( $v[$i] );
    $self->add_vertex( $sv );
  }

  # Create the first eight nodes, index one through 8.
  $self->index( 1 );
  $self->new_node( 1, 5, 2, 8, 0 );
  $self->new_node( 2, 5, 3, 9, 0 );
  $self->new_node( 3, 5, 4, 10, 0 );
  $self->new_node( 4, 5, 1, 11, 0 );
  $self->new_node( 1, 0, 4, 12, 0 );
  $self->new_node( 4, 0, 3, 13, 0 );
  $self->new_node( 3, 0, 2, 14, 0 );
  $self->new_node( 2, 0, 1, 15, 0 );

  my $pl = 0;
  my $level = $self->buildlevel;
  while( $level-- > 0 ) {
    my $edge = new Astro::HTM::Edge( $self, $pl );
    $edge->make_midpoints();
    $self->make_new_layer( $pl );
    $pl++;
  }

  $self->sort_index;

  return $self;
}

=back

=head2 Accessor Methods

=over 4

=item B<addlevel>

=cut

sub addlevel {
  my $self = shift;
  if( @_ ) {
    my $addlevel = shift;
    $self->{ADDLEVEL} = $addlevel;
  }
  return $self->{ADDLEVEL};
}

=item B<buildlevel>

=cut

sub buildlevel {
  my $self = shift;
  if( @_ ) {
    my $buildlevel = shift;
    $self->{BUILDLEVEL} = $buildlevel;
  }
  return $self->{BUILDLEVEL};
}

=item B<index>

=cut

sub index {
  my $self = shift;
  if( @_ ) {
    my $index = shift;
    $self->{INDEX} = $index;
  }
  return $self->{INDEX};
}

=item B<leaves>

=cut

sub leaves {
  my $self = shift;
  if( @_ ) {
    my $leaves = shift;
    $self->{LEAVES} = $leaves;
  }
  return $self->{LEAVES};
}

=item B<maxlevel>

=cut

sub maxlevel {
  my $self = shift;
  if( @_ ) {
    my $maxlevel = shift;
    $self->{MAXLEVEL} = $maxlevel;
  }
  return $self->{MAXLEVEL};
}

=item B<number_of_nodes>

=cut

sub number_of_nodes {
  my $self = shift;
  if( @_ ) {
    my $number = shift;
    $self->{NUMBER_OF_NODES} = $number;
  }
  return $self->{NUMBER_OF_NODES};
}

=item B<number_of_vertices>

=cut

sub number_of_vertices {
  my $self = shift;
  if( @_ ) {
    my $number = shift;
    $self->{NUMBER_OF_VERTICES} = $number;
  }
  return $self->{NUMBER_OF_VERTICES};
}

=item B<stored_leaves>

=cut

sub stored_leaves {
  my $self = shift;
  if( @_ ) {
    my $stored = shift;
    $self->{STORED_LEAVES} = $stored;
  }
  return $self->{STORED_LEAVES};
}

=back

=head2 General Methods

=over 4

=item B<add>

=cut

sub add {
  my $self = shift;
  my $vector = shift;
  my $i = shift;

  $

=item B<add_node>

=cut

sub add_node {
  my $self = shift;
  my $node = shift;

  push @{$self->{NODES}}, $node;
}

=item B<add_vertex>

=cut

sub add_vertex {
  my $self = shift;
  my $vertex = shift;

  push @{$self->{VERTICES}}, $vertex;
}

=item B<area>

=cut

sub area {
  my $self = shift;
  my $n0 = shift;
  my $n1 = shift;
  my $n2 = shift;

  my $a = acos( $n0 . $n1 );
  my $b = acos( $n1 . $n2 );
  my $c = acos( $n2 . $n0 );

  my $s = ( $a + $b + $c ) / 2;
  my $area = 4 * atan( sqrt( tan( $s / 2 ) *
                             tan( ( $s - $a ) / 2 ) *
                             tan( ( $s - $b ) / 2 ) *
                             tan( ( $s - $c ) / 2 ) ) );

  return $area;
}

=item B<area_name>

=cut

sub area_name {
  my $self = shift;
  my $htmname = shift;

  my $n = name_to_triangle( $htmname );
  my @vec;
  for( my $v = 0; $v < 3; $v++ ) {
    my $vn = $n->[$v];
    $vec[$v] = vector( $vn );
  }
  return area( $vec[0], $vec[1], $vec[2] );
}

=item B<get_layer>

=cut

sub get_layer {
  my $self = shift;
  my $index = shift;

  my $layers = $self->layers;

  return $layers->[$index];
}

=item B<get_node>

=cut

sub get_node {
  my $self = shift;
  my $index = shift;

  my $nodes = $self->nodes;

  return $nodes->[$index];
}

=item B<get_vertex>

=cut

sub get_vertex {
  my $self = shift;
  my $x = shift;

  my $vertices = $self->vertices;

  return $vertices->[$x];
}



=item B<id_by_leaf_number>

=cut

sub id_by_leaf_number {
  my $self = shift;
  my $leaf = shift;

  return ( scalar( $self->leaves ) + $leaf );
}

=item B<leaf_number_by_id>

=cut

sub leaf_number_by_id {
  my $self = shift;
  my $id = shift;

  return ( $id - scalar( $self->leaves ) );
}

=item B<lookup>

=cut

sub lookup {
  my $self = shift;
  my $ra = shift;
  my $dec = shift;

  return lookup( $ra, $dec, $self->maxlevel );
}

=item B<lookup_id>

=cut

sub lookup_id {
  my $self = shift;
  my $ra = shift;
  my $dec = shift;

  return lookup_id( $ra, $dec, $self->maxlevel );
}

=item B<make_new_layer>

=cut

sub make_new_layer {
  my $self = shift;
  my $oldlayer = shift;

  my $index;
  my $id;
  my $newlayer = $oldlayer + 1;

  my $newl = new layer;
  $self->add_layer( $newlayer, $newl );

  my $oldl = $self->get_layer( $oldlayer );
  $newl->level( $oldl->level + 1 );
  $newl->number_of_vertice( $oldl->number_of_vertices + $oldl->number_of_edges );
  $newl->number_of_nodes( 4 * $oldl->number_of_nodes );
  $newl->number_of_edges( $newl->number_of_nodes + $newl->number_of_vertices - 1 );
  $newl->first_index( $self->index );
  $newl->first_vertex( $oldl->first_vertex + $oldl->number_of_vertices );

  my $ioffset = $oldl->first_index;
  for( $index = $ioffset; $index < $ioffset + $oldl->number_of_nodes; $index++ ) {
    my $N = $self->get_node( $index );
    $id = $N->id << 2;
    my $childid = $N->child_id;
    my $v = $N->v;
    my $w = $N->w;
    $childid->[0] = $self->new_node( $v->[0], $w->[2], $w->[1], $id++, $index );
    $childid->[1] = $self->new_node( $v->[1], $w->[0], $w->[2], $id++, $index );
    $childid->[2] = $self->new_node( $v->[2], $w->[1], $w->[0], $id++, $index );
    $childid->[3] = $self->new_node( $w->[0], $w->[1], $w->[2], $id++, $index );
  }
}

=item B<name_by_leaf_number>

=cut

sub name_by_leaf_number {
  my $self = shift;
  my $id = shift;

  return id_to_name( $self->id_by_leaf_number( $id ) );
}

=item B<new_node>

=cut

sub new_node {
  my $self = shift;
  my $v1 = shift;
  my $v2 = shift;
  my $v3 = shift;
  my $id = shift;
  my $parent = shift;

  my $last = new Astro::HTM::QuadNode;
  my @v = ( $v1, $v2, $v3 );
  $last->v( \@v );
  $last->w( [ 0, 0, 0 ] );
  $last->child_id( [ 0, 0, 0, 0 ] );
  $last->id( $id );
  $last->index( $self->index );
  $last->parent( $parent );

  $self->add_node( $self->index, $last );
  $self->index( $self->index + 1 );
  return( $self->index );
}

=item B<node_vertex>

=cut

sub node_vertex {
  my $self = shift;
  my $leaf = shift;

  my @ret;

  if( $self->buildlevel == $self->maxlevel ) {
    my $idx = $leaf + IOFFSET;
    my $N = $self->get_node( $idx );
    for( my $i = 0; $i < 3; $i++ ) {
      my $N_v = $N->v;
      $ret[$i] = $self->get_vertex( $N_v->[$i] );
    }
    return @ret;
  }

  my $id = $self->id_by_leaf_number( $leaf );
  my $sid = $id >> ( ( $self->maxlevel - $self->buildlevel ) * 2 );
  my $idx = $sid - $self->stored_leaves + IOFFSET;
  my $N = $self->get_node( $idx );
  for( my $i = 0; $i < 3; $i++ ) {
    my $N_v = $N->v;
    $ret[$i] = $self->get_vertex( $N_v->[$i] );
  }

  my $name = $self->name_by_leaf_number( $leaf );
  my @letters = split //, $name;
  for( my $i = $self->buildlevel + 2; $i < $self->maxlevel + 2; $i++ ) {
    my $w0 = $ret[1] + $ret[2];
    $w0->norm;
    my $w1 = $ret[0] + $ret[2];
    $w1->norm;
    my $w2 = $ret[1] + $ret[0];
    $w2->norm;

    if( $letters[$i] eq '0' ) {
      $ret[1] = $w2;
      $ret[2] = $w1;
    } elsif( $letters[$i] eq '1' ) {
      $ret[0] = $ret[1];
      $ret[1] = $w0;
      $ret[2] = $w2;
    } elsif( $letters[$i] eq '2' ) {
      $ret[0] = $ret[2];
      $ret[1] = $w1;
      $ret[2] = $w0;
    } elsif( $letters[$i] eq '3' ) {
      $ret[0] = $w0;
      $ret[1] = $w1;
      $ret[2] = $w2;
    }
  }

  return @ret;
}

=item B<node_vertex_ids>

=cut

sub node_vertex_ids {
  my $self = shift;
  my $index = shift;

  my $node = $self->get_node( $index );
  return @{$node->v};
}

=item B<show_vertices>

=cut

sub show_vertices {
  my $self = shift;

  foreach my $vertex ( @{$self->{VERTICES}} ) {
    print $vertex->stringify( "%g %g %g\n" );
  }
}

=item B<sort_index>

=cut

sub sort_index {
  my $self = shift;

  my $oldnodes = $self->nodes;
  my ( $index, $nonleaf, $leaf );

  for( $index = IOFFSET, $leaf = IOFFSET, $nonleaf = ( scalar( $self->nodes ) - 1 );
       $index < scalar( $self->nodes );
       $index++ ) {
    my $childid = $oldnodes->[$index]->childid;
    if( $childid->[0] == 0 ) {
      $self->set_nodes( $leaf, $oldnodes->[$index] );
      for( my $i = 0; $i < 4; $i++ ) {
        my $leafn = $self->get_node( $leaf );
        my $parent = $self->get_node( $leafn->parent );
        my $parent_childid = $parent->child_id;
        if( $parent_childid->[$i] == $index ) {
          $parent_childid->[$i] = $leaf;
          last;
        }
      }
      $leaf++;
    } else {
      my $N = $oldnodes->[$index];
      my $N_childid = $N->child_id;
      $self->set_node( $nonleaf, $N );
      $oldnodes->[$N_childid->[0]]->parent( $nonleaf );
      $oldnodes->[$N_childid->[1]]->parent( $nonleaf );
      $oldnodes->[$N_childid->[2]]->parent( $nonleaf );
      $oldnodes->[$N_childid->[3]]->parent( $nonleaf );

      for( my $i = 0; $i < 4; $i++ ) {
        my $pn1 = $self->get_nodes( $N->parent );
        my $pn1_childid = $pn1->child_id;
        if( $pn1_childid->[$i] == $index ) {
          $pn1->childid->[$i] = $nonleaf;
          last;
        }
      }
      $nonleaf--;
    }
  }
  $self->last_saved_leaf_index( $leaf );
}

=item B<V>

=cut

sub V {
  my $self = shift;
  my $index = shift;
  my $x = shift;

  my $node = $self->get_node( $index );
  my $node_v = $node->v;
  my $node_v_x = $node_v->[$x];

  my $vertex = $self->get_vertex( $node_v_x );
  return $vertex;
}

=item B<v_max>

=cut

sub v_max {
  my $self = shift;

  my $nv = 6;
  my $ne = 12;
  my $nf = 8;
  my $i = $self->buildlevel;
  $self->number_of_nodes( $nf );

  while( $i-- > 0 ) {
    $nv += $ne;
    $nf *= 4;
    $ne = $nf + $nv - 2;
    $self->number_of_nodes( $self->number_of_nodes + $nf );
  }

  $self->number_of_vertices( $nv );
  $self->stored_leaves( $nf );

  $i = $self->maxlevel - $self->buildlevel;
  while( $i-- > 0 ) {
    $nf *= 4;
  }
  $self->leaves( $nf );
}

1;
