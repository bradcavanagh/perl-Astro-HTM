#!perl

use strict;
use Test::More tests => 7;

require_ok( 'Astro::HTM::QuadNode' );

my $index = 2;
my @v = ( 1, 4, 9 );
my @w = ( 16, 25, 36 );
my @child_id = ( 1, 2, 3, 4 );
my $parent = 10;
my $id = 1000;

my $quadnode = new Astro::HTM::QuadNode( index => $index,
                                         v => \@v,
                                         w => \@w,
                                         child_id => \@child_id,
                                         parent => $parent,
                                         id => $id );

ok( $quadnode->index == 2, "QuadNode index is 2" );
ok( $quadnode->parent == 10, "QuadNode parent is 10" );
ok( $quadnode->id == 1000, "QuadNode id is 1000" );

my $returned_v = $quadnode->v;
ok( $returned_v->[2] == 9, "Third QuadNode vertex vector index is 9" );

my $returned_w = $quadnode->w;
ok( $returned_w->[0] == 16, "First QuadNode middlepoint vector index is 16" );

my $returned_child_id = $quadnode->child_id;
ok( $returned_child_id->[1] == 2, "Second QuadNode child ID is 2" );
