# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use SGML::Parser::OpenSP;

use Data::Dumper qw(Dumper);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$ENV{SGML_CATALOG_FILES} = 't/xml.soc';
$ENV{SP_ENCODING} = 'XML';
$ENV{SP_CHARSET_FIXED} = 'YES';
$ENV{SP_BCTF} = 'utf-8';

my $p = SGML::Parser::OpenSP->new('t/invalid.xhtml');
ok(defined $p and ref $p, "Made second parser.");

my $r = $p->parse();
ok(defined $r and ref $r eq 'ARRAY' and scalar @{$r} == 0, "Parsed t/invalid.xhtml.");

my $t = $p->getDocTree();
ok(defined $t and ref $t, "Got the Document Tree.");

#open FOO, ">/tmp/foo";
#print FOO Dumper $t;
#close FOO;
#diag(Dumper $t);
