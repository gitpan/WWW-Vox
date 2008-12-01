use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Vox',
    AUTHOR        => 'Mark Paschal <mark@sixapart.com>',
    VERSION_FROM  => 'lib/WWW/Vox.pm',
    ABSTRACT_FROM => 'lib/WWW/Vox.pm',
    PREREQ_PM => {
        'JSON::Any'         => 1,
        'Image::Info'       => 1,
        'URI'               => 0,
        'HTTP::Request'     => 0,
        'LWP::UserAgent'    => 0,
        'Test::MockObject'  => '0.15',
    },
);

