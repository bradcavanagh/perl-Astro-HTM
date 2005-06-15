use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'DISTNAME' => 'Astro-HTM-Convex',
        'NAME' => 'Astro::HTM::Convex',
        'VERSION_FROM' => 'Convex.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
