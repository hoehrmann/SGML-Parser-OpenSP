# 20passfd.t -- ...
#
# $Id: 20passfd.t,v 1.1 2005/08/14 14:57:49 tbe Exp $

use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');


#
# Check default and return values.

# Default.
my $ret = $p->pass_file_descriptor;
ok(defined $ret, 'default is set');
ok($ret == 1, 'default is true');

# Set true.
$ret = 0; $ret = $p->pass_file_descriptor(1);
ok(defined $ret, 'set true returns defined value');
ok($ret == 1, 'set true returns value');

# Set false.
$ret = 1; $ret = $p->pass_file_descriptor(0);
ok(defined $ret, 'set false returns defined value');
ok($ret == 0, 'set false returns value');

# Cleanup parser.
undef $p;


#
# Check pass as filename (should work on all platforms).
$p = new SGML::Parser::OpenSP;
$p->handler(bless{}, 'NullHandler');
$p->pass_file_descriptor(0);
lives_ok { $p->parse(NO_DOCTYPE) } 'parse by filename';
undef $p;

#
# Check pass as file descriptor (not on Win32).
SKIP: {
  skip 'fd not supported on this platform.', 2 if $^O eq 'Win32';
  $p = new SGML::Parser::OpenSP;
  $p->handler(bless{}, 'NullHandler');
  $p->pass_file_descriptor(1);
  lives_ok { $p->parse(NO_DOCTYPE) } 'parse by filename';
  undef $p;
}


