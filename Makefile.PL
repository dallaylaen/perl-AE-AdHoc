use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AE::AdHoc',
    AUTHOR              => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM        => 'lib/AE/AdHoc.pm',
    ABSTRACT_FROM       => 'lib/AE/AdHoc.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'AnyEvent' => 0,
        'AnyEvent::Strict' => 0,
	'Scalar::Util' => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/dallaylaen/perl-AE-AdHoc.git',
                web => 'https://github.com/dallaylaen/perl-AE-AdHoc',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AE-AdHoc-*' },
);
