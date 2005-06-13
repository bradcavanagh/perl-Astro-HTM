package Astro::HTM::Constants;

=head1 NAME

Astro::HTM::Constants - Constants available for Astro::HTM packages.

=head1 SYNOPSIS

use Astro::HTM::Constants;
use Astro::HTM::Constants qw/ :all /;

=head1 DESCRIPTION

Provide access to Astro::HTM constants.

=cut

use strict;
use warnings;

our $VERSION = '0.01';

require Exporter;

@ISA = qw/ Exporter /;

my @all = qw/ HTM__ZERO HTM__MIXED HTM__NEGATIVE HTM__POSITIVE /;

@EXPORT_OK = ( @all );
%EXPORT_TAGS = (
                'all' => [ @EXPORT_OK ],
               );

Exporter::export_tags( keys %EXPORT_TAGS );

=head1 CONSTANTS

The following constants are available from this module:

=over 4

=item B<HTM__ZERO>

This constant denotes an C<Astro::HTM::Constraint> object has a distance
that is zero, or an C<Astro::HTM::Convex> object is made up of only
zero-distance C<Astro::HTM::Constraint> objects.

=cut

use constant HTM__ZERO => 1;

=item B<HTM__MIXED>

This constant denotes an C<Astro::HTM::Convex> object is made up of
positive and negative C<Astro::HTM::Constraint> objects.

=cut

use constant HTM__MIXED => 3;

=item B<HTM__POSITIVE>

This constant denotes an C<Astro::HTM::Constraint> object has a distance
that is either zero or positive, or an C<Astro::HTM::Convex> object is made
up of only zero- or positive-distance C<Astro::HTM::Constraint> objects.

=cut

use constant HTM__POSITIVE => 2;

=item B<HTM__NEGATIVE>

This constant denotes an C<Astro::HTM::Constraint> object has a distance
that is either zero or negative, or an C<Astro::HTM::Convex> object is made
up of only zero- or negative-distance C<Astro::HTM::Constraint> objects.

=cut

use constant HTM__NEGATIVE => 1;

=back

=head1 TAGS

There is only one tag available for this module.

=over 4

=item :all

Import all constants.

=back

=head1 USAGE

The constants can be used as if they are subroutines. For example,
if you want to print the value of HTM__ZERO you can do

  use Astro::HTM::Constants;
  print HTM__ZERO;

or

  use Astro::HTM::Constants ();
  print Astro::HTM::Constants::HTM__ZERO;

=head1 SEE ALSO

L<constants>

=head1 REVISION

$Id$

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 REQUIREMENTS

The C<constants> package must be available. This is a standard
perl package.

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
