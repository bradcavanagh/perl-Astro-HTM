use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'DISTNAME' => 'Astro-HTM-Domain',
        'NAME' => 'Astro::HTM::Domain',
        'VERSION_FROM' => 'Domain.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
