use strict;
use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
              'DISTNAME' => 'Astro-HTM',
              'NAME' => 'Astro::HTM',
              'VERSION_FROM' => 'HTM.pm',
              'PREREQ_PM' => {
                              'Math::VectorReal' => 0,
                             },
              'DIR' => [
                        'Constants',
                        'Constraint',
                        'Convex',
                        'Domain',
                        'QuadNode',
                       ],
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM => 'HTM.pm',
                AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
              'dist' => { COMPRESS => 'gzip -9f',
                          SUFFIX => 'gz',
                        },
             );