use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'DISTNAME' => 'Astro-HTM-QuadNode',
        'NAME' => 'Astro::HTM::QuadNode',
        'VERSION_FROM' => 'QuadNode.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
