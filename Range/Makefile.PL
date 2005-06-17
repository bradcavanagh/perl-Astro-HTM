use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
              'DISTNAME' => 'Astro-HTM-Range',
              'NAME' => 'Astro::HTM::Range',
              'VERSION_FROM' => 'Range.pm',
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM => 'Range.pm',
                AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
              'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
