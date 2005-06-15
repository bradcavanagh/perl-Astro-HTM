package Astro::HTM::QuadNode;

=head1 NAME

Astro::HTM::QuadNode - Class for handing HTM QuadNode objects.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Class::Struct;

our $VERSION = '0.01';

=head1 METHODS

=over 4

=item B<new>

Create a new instance of an C<Astro::HTM::QuadNode> object.

  $quadnode = new Astro::HTM::QuadNode( index => $index,
                                        v => @v,
                                        w => @w,
                                        child_id => @child_id,
                                        parent => $parent,
                                        id => $id );

=cut

struct( 'Astro::HTM::QuadNode' => { index => '$',
                                    v => '@',
                                    w => '@',
                                    child_id => '@',
                                    parent => '$',
                                    id => '$',
                                  } );

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
