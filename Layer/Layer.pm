package Astro::HTM::Layer;

use strict;
use warnings;
use warnings::register;

our $VERSION = '0.01';

use Class::Struct 'Astro::HTM::Layer' => { level => '$',
                                           number_of_vertices => '$',
                                           number_of_nodes => '$',
                                           number_of_edges => '$',
                                           first_index => '$',
                                           first_vertex => '$',
                                         };


1;
