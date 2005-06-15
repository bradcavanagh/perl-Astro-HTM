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

use vars qw/ @ISA %EXPORT_TAGS @EXPORT_OK /;

our $VERSION = '0.01';

require Exporter;

@ISA = qw/ Exporter /;

my @sign = qw/ HTM__ZERO HTM__MIXED HTM__NEGATIVE HTM__POSITIVE /;
my @math = qw/ HTM__PI HTM__PI_RADIANS HTM__EPSILON HTM__SQRT_THREE
               HTM__GEPSILON /;
my @id = qw/ HTM__IDSIZE HTM__IDHIGHBIT HTM__IDHIGHBIT2 HTM__HTMNAMEMAX
             HTM__INVALID_ID /;
my @markup = qw/ HTM__MARKUP_DONTKNOW HTM__MARKUP_PARTIAL HTM__MARKUP_SWALLOWED
                 HTM__MARKUP_FULL HTM__MARKUP_REJECT HTM__MARKUP_VTRUE
                 HTM__MARKUP_VFALSE HTM__MARKUP_VUNDEF /;

@EXPORT_OK = ( @sign, @math, @id, @markup );

%EXPORT_TAGS = (
                'all' => [ @EXPORT_OK ],
                'sign' => \@sign,
                'math' => \@math,
                'id' => \@id,
                'markup' => \@markup,
               );

Exporter::export_tags( keys %EXPORT_TAGS );

=head1 CONSTANTS

The following constants are available from this module:

=head2 Sign Constants

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

=head2 Math Constants

=over 4

=item B<HTM__EPSILON>

Define a minimum real number. Currently set to 1.0e-15.

=cut

use constant HTM__EPSILON => 1.0e-15;

=item B<HTM__GEPSILON>

Define a minimum real number. Currently set to 1.0e-15.

=cut

use constant HTM__GEPSILON => 1.0e-15;

=item B<HTM__PI>

Define pi.

=cut

use constant HTM__PI => 3.1415926535897932385;

=item B<HTM__PI_RADIANS>

Define the number of radians in a half-circle.

=cut

use constant HTM__PI_RADIANS => HTM__PI / 180.0;

=item B<HTM__SQRT_THREE>

Define the square root of three.

=cut

use constant HTM__SQRT_THREE => 1.7320508075688772935;

=back

=head2 ID Constants

=over 4

=item B<HTM__IDSIZE>

Define the ID size.

=cut

use constant HTM__IDSIZE => 64;

=item B<HTM__IDHIGHBIT>

Define the high ID bit.

=cut

use constant HTM__IDHIGHBIT => 1 << 63;

=item B<HTM__IDHIGHBIT2>

Define the high ID bit.

=cut

use constant HTM__IDHIGHBIT2 => 1 << 63;

=item B<HTM__HTMNAMEMAX>

Define the maximum HTM name length.

=cut

use constant HTM__HTMNAMEMAX => 32;

=item B<HTM__INVALID_ID>

Define the invalid HTM id.

=cut

use constant HTM__INVALID_ID => 1;

=back

=head2 Markup Constants

=over 4

=item B<HTM__MARKUP_DONTKNOW>

=cut

use constant HTM__MARKUP_DONTKNOW => 0;

=item B<HTM__MARKUP_PARTIAL>

=cut

use constant HTM__MARKUP_PARTIAL => 1;

=item B<HTM__MARKUP_SWALLOWED>

=cut

use constant HTM__MARKUP_SWALLOWED => 4;

=item B<HTM__MARKUP_FULL>

=cut

use constant HTM__MARKUP_FULL => 2;

=item B<HTM__MARKUP_REJECT>

=cut

use constant HTM__MARKUP_REJECT => 3;

=item B<HTM__MARKUP_VTRUE>

=cut

use constant HTM__MARKUP_VTRUE => 1;

=item B<HTM__MARKUP_VFALSE>

=cut

use constant HTM__MARKUP_VFALSE => 2;

=item B<HTM__MARKUP_VUNDEF>

=cut

use constant HTM__MARKUP_VUNDEF => 0;

=back

=head1 TAGS

Individual sets of constants can be imported by including the module with
tags. For example:

  use Astro::HTM::Constants qw/ :sign /;

will import all constants associated with signs.

The available tags are:

=over 4

=item :all

Import all constants.

=item :sign

HTM__POSITIVE, HTM__NEGATIVE, HTM__MIXED, HTM__ZERO.

=item :math

HTM__EPSILON, HTM__GEPSILON, HTM__PI, HTM__PI_RADIANS, HTM__SQRT_THREE.

=item :id

HTM__IDSIZE, HTM__IDHIGHBIT, HTM__IDHIGHBIT2, HTM__HTMNAMEMAX, HTM__INVALID_ID.

=item :markup

HTM__MARKUP_DONTKNOW, HTM__MARKUP_PARTIAL, HTM__MARKUP_SWALLOWED,
HTM__MARKUP_FULL, HTM__MARKUP_REJECT, HTM__MARKUP_VTRUE, HTM__MARKUP_VFALSE,
HTM__MARKUP_VUNDEF.

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
