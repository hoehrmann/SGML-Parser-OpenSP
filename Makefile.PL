use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# TODO:
#
# On non-win32 systems
#
#   CC   => 'g++',
#   LD   => 'g++',
#   LIBS => '[-lstdc++ -losp]',
#

WriteMakefile(
    NAME              => 'SGML::Parser::OpenSP',

    VERSION_FROM      => 'lib/SGML/Parser/OpenSP.pm',

    PREREQ_PM         => {
      Class::Accessor => 0,
    },

    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/SGML/Parser/OpenSP.pm',
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

    # SP_MULTI_BYTE is needed iff OpenSP is built with SP_MULTI_BYTE
    DEFINE            => '-DSP_MULTI_BYTE=1',

    INC               => '', # e.g., '-I/usr/include/other'

    XSOPT             => '-C++',

    LIBS              => ['-lD:\\osp\\lib\\Release\\osp152.lib'], # e.g., '-lm'

    CC                => 'cl -TP -EHsc -ID:/osp/',

);
