use 5.008;
use ExtUtils::MakeMaker;

my %options;

if ($^O eq "MSWin32")
{
    $options{LIBS} = "-l" . prompt("Where is the OpenSP link library?",
                                   "D:\\osp\\lib\\Release\\osp152.lib");
    $options{CC}   =        prompt("Which compiler should be used?",
                                   "cl -TP -EHsc -ID:/osp/");
}
else
{
    # assume some compatible Linux
    $options{LD}   = "g++";
    $options{CC}   = "g++";
    $options{LIBS} = "-lstdc++ -losp";
}

WriteMakefile(
    NAME              => 'SGML::Parser::OpenSP',
    VERSION_FROM      => 'lib/SGML/Parser/OpenSP.pm',
    PREREQ_PM         => {
      Class::Accessor => 0,
      Test::Exception => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/SGML/Parser/OpenSP.pm',
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

    # SP_MULTI_BYTE is needed iff OpenSP is built with SP_MULTI_BYTE
    DEFINE            => '-DSP_MULTI_BYTE=1',

    INC               => '', # e.g., '-I/usr/include/other'
    XSOPT             => '-C++',

    %options
);
