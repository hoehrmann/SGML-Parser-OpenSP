# 17splitmessage.t -- ...
#
# $Id: 17splitmessage.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## newlines in enum attribute
#########################################################

sub TestHandler12::new{bless{p=>$_[1],ok1=>0,ok2=>0,ok3=>0,ok4=>0,
                             ok5=>0,ok6=>0,ok7=>0,ok8=>0},shift}
sub TestHandler12::error
{
    my $s = shift;
    my $e = shift;
    my $p = $s->{p};
    
    return unless defined $s and
                  defined $e and
                  defined $p;
                  
    my $l = $p->get_location;
    
    return unless defined $l;
    $s->{ok1}++;
    my $m;
    
    eval
    {
        $m = $p->split_message($e);
    };
    
    return if $@;
    $s->{ok2}++;
    
    if ($m->{primary_message}{Number} == 122)
    {
        $s->{ok3}++ if $m->{primary_message}{ColumnNumber} == 8;
        $s->{ok4}++ if $m->{primary_message}{LineNumber} == 8;
        $s->{ok5}++ if $m->{primary_message}{Text} =~
          /.+\n.+/;
    }
    elsif ($m->{primary_message}{Number} == 131)
    {
        $s->{ok6}++ if $m->{primary_message}{ColumnNumber} == 13;
        $s->{ok7}++ if $m->{primary_message}{LineNumber} == 8;
        $s->{ok8}++ if $m->{primary_message}{Text} =~
        /.+\n.+/;
    }
}

my $h12 = TestHandler12->new($p);
$p->handler($h12);
$p->catalogs(TEST_CATALOG);
$p->show_error_numbers(1);

lives_ok { $p->parse("<LITERAL>" . <<"__DOC__");
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
</head>
<body>
<p dir="&#xa;">...</p>
</body>
</html>
__DOC__
} 'newlines in enum attr values';

cmp_ok($h12->{ok1}, '>=', 2, 'two errors');
cmp_ok($h12->{ok2}, '>=', 2, 'two errors split');

ok($h12->{ok3}, 'correct col 122');
ok($h12->{ok4}, 'correct lin 122');
ok($h12->{ok5}, 'correct text 122');
ok($h12->{ok6}, 'correct col 131');
ok($h12->{ok7}, 'correct lin 131');
ok($h12->{ok8}, 'correct text 131');

$p->catalogs([]);
$p->show_error_numbers(0);

