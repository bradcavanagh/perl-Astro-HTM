use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
              'DISTNAME' => 'Astro-HTM-Functions',
              'NAME' => 'Astro::HTM::Functions',
              'VERSION_FROM' => 'Functions.pm',
              'PREREQ_PM' => {
                              'Math::VectorReal' => 0,
                              'Math::Trig' => 0,
                             },
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM => 'Functions.pm',
                AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
              'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
