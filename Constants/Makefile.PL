use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'DISTNAME' => 'Astro-HTM-Constants',
        'NAME' => 'Astro::HTM::Constants',
        'VERSION_FROM' => 'Constants.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
