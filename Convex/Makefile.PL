use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
              'DISTNAME' => 'Astro-HTM-Convex',
              'NAME' => 'Astro::HTM::Convex',
              'VERSION_FROM' => 'Convex.pm',
              'PREREQ_PM' => {
                              'Class::Struct' => 0,
                              'Math::VectorReal' => 0,
                             },
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM => 'Convex.pm',
                AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
              'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
