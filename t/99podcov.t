# 99pod.t -- Minimally check POD for code coverage.
#
# $Id: 99podcov.t,v 1.1 2005/12/11 19:02:00 tbe Exp $

use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 2;
pod_coverage_ok('SGML::Parser::OpenSP');
pod_coverage_ok('SGML::Parser::OpenSP::Tools');

