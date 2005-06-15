use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'DISTNAME' => 'Astro-HTM-Constraint',
        'NAME' => 'Astro::HTM::Constraint',
        'VERSION_FROM' => 'Constraint.pm',
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
