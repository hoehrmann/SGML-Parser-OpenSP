# SGML-Parser-OpenSP.t -- ... 
#
# $Id: SGML-Parser-OpenSP.t,v 1.11 2004/09/13 05:40:50 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 180;
use Test::Exception;
use Encode qw();
use File::Spec qw();
use Cwd qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

#########################################################
## Basic Tests
#########################################################

BEGIN { use_ok('SGML::Parser::OpenSP') };

require_ok('SGML::Parser::OpenSP');

my $p = SGML::Parser::OpenSP->new;

isa_ok($p, 'SGML::Parser::OpenSP');

can_ok($p, qw/
    handler
    show_open_entities
    show_open_elements
    show_error_numbers
    output_comment_decls
    output_marked_sections
    output_general_entities
    map_catalog_document
    restrict_file_reading
    warnings
    catalogs
    search_dirs
    include_params
    active_links

    parse_file

    split_message
/);

#########################################################
## XS integrity
#########################################################

ok(exists $p->{__o},
  "pointer to C++ object");

isnt($p->{__o}, 0,
  "C++ object pointer not null-pointer");

#########################################################
## Exceptions
#########################################################

dies_ok { $p->get_location }
  'must die when calling get_location while not parsing';

dies_ok { $p->parse_file }
  'must die when no file name specified for parse_file';

dies_ok { $p->parse_file(NO_DOCTYPE) }
  'must die when no handler specified';

#########################################################
## Accessors
#########################################################

$p->handler(7);

is($p->handler, 7, 'accessor');

#########################################################
## More Exceptions
#########################################################

dies_ok { $p->parse_file(NO_DOCTYPE) }
  'must die when handler not an object';

$p->handler(bless{}, 'NullHandler');

lives_ok { $p->parse_file(NO_DOCTYPE) }
  'must not die when handler cannot handle a method';

#########################################################
## Simple Event Handler
#########################################################

# todo: do not call ok from handler, the handler might not
# be called at all!

sub TestHandler1::new { bless{ok1=>0,ok2=>0,ok3=>0,ok4=>0,ok5=>0,
                              ok6=>0,ok7=>0,ok8=>0,ok9=>0,oka=>0},shift }
sub TestHandler1::start_element {
    my $s = shift;
    my $e = shift;
    
    return unless defined $s;
    return unless defined $e;
    
    $s->{ok1}++ if UNIVERSAL::isa($s, 'TestHandler1');

    # Name
    $s->{ok2}++ if exists $e->{Name};
    $s->{ok3}++ if $e->{Name} =~ /no-doctype/i;
    
    # Attributes
    $s->{ok4}++ if exists $e->{Attributes};
    $s->{ok5}++ if UNIVERSAL::isa($e->{Attributes}, "HASH");
    $s->{ok6}++ if scalar(keys(%{$_[1]->{Attributes}})) == 0;
    
    # Included
    $s->{ok7}++ if exists $e->{Included};
    $s->{ok8}++ if $e->{Included} == 0;
    
    # ContentType
    $s->{ok9}++ if exists $e->{ContentType};
}

my $h1 = TestHandler1->new;

isa_ok($h1, 'TestHandler1');

$p->handler($h1);

lives_ok { $p->parse_file(NO_DOCTYPE) }
  'basic parser test';

ok($h1->{ok1}, 'self to handler');
ok($h1->{ok2}, 'has name');
ok($h1->{ok3}, 'proper name');
ok($h1->{ok4}, 'has attrs');
ok($h1->{ok5}, 'attrs hash ref');
ok($h1->{ok6}, 'proper attrs');
ok($h1->{ok7}, 'has included');
ok($h1->{ok8}, 'included == 0');
ok($h1->{ok9}, 'has content type');

#########################################################
## Read from a <LITERAL>
#########################################################

$h1 = TestHandler1->new;

$p->handler($h1);
lives_ok { $p->parse_file("<LITERAL><no-doctype></no-doctype>") }
  'reading from a <literal>';

ok($h1->{ok1}, 'self to handler');
ok($h1->{ok2}, 'has name');
ok($h1->{ok3}, 'proper name');
ok($h1->{ok4}, 'has attrs');
ok($h1->{ok5}, 'attrs hash ref');
ok($h1->{ok6}, 'proper attrs');
ok($h1->{ok7}, 'has included');
ok($h1->{ok8}, 'included == 0');
ok($h1->{ok9}, 'has content type');

#########################################################
## Comments not default
#########################################################

sub TestHandler2::new         { bless{ok1=>0},shift }
sub TestHandler2::comment     { $_->{ok1}-- }

my $h2 = TestHandler2->new;
isa_ok($h2, 'TestHandler2');

$p->handler($h2);

lives_ok { $p->parse_file("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comments not reported by default';

is($h2->{ok1}, 0, 'comments not default');

#########################################################
## Comments at user option
#########################################################

sub TestHandler3::new         { bless{ok=>0},shift }
sub TestHandler3::comment_decl{ $_[0]->{ok}++ }

my $h3 = TestHandler3->new(1);

isa_ok($h3, 'TestHandler3');

$p->handler($h3);

$p->output_comment_decls(1);

is($p->output_comment_decls, 1, 'comments turned on');

lives_ok { $p->parse_file("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comment reported at user option';
  
isnt($h3->{ok}, 0, 'comments ok');

$p->output_comment_decls(0);

is($p->output_comment_decls, 0, 'comments turned off');

#########################################################
## Locations for implied document type declarations
#########################################################

# OpenSP 1.5.1 generates random numbers for the locations

sub TestHandler4::new { bless{p=>$_[1],ok1=>0,ok2=>0,ok3=>0,ok4=>0},shift }
sub TestHandler4::start_dtd
{
    my $s = shift;
    return unless defined $s;
    my $l = $s->{p}->get_location;
    return unless defined $l;
    
    $s->{ok1}++ if $l->{ColumnNumber} == 3;
    $s->{ok2}++ if $l->{LineNumber} == 2;
    $s->{ok3}++ if $l->{EntityOffset} == 7;
}
sub TestHandler4::end_dtd
{
    my $s = shift;
    return unless defined $s;
    my $l = $s->{p}->get_location;
    return unless defined $l;
    
    $s->{ok4}++ if $l->{ColumnNumber} == 3;
    $s->{ok4}++ if $l->{LineNumber} == 2;
    $s->{ok4}++ if $l->{EntityOffset} == 7;
}

my $h4 = TestHandler4->new($p);

$p->handler($h4);

lives_ok { $p->parse_file("<LITERAL>\n  \n  <no-doctype></no-doctype>") }
  'implied dtd locations';

is($h4->{ok1}, 1, "implied col");
is($h4->{ok2}, 1, "implied line");
is($h4->{ok3}, 1, "implied offset");
is($h4->{ok4}, 3, "implied end_dtd");

#########################################################
## Error reporting
#########################################################

sub TestHandler5::new         { bless{ok=>0},shift }
sub TestHandler5::error
{
    return unless @_ == 2;
    $_[0]->{ok}++ if $_[1]->{Message} =~ /:4:13:E:/;
}

my $h5 = TestHandler5->new;
$p->handler($h5);
lives_ok { $p->parse_file("<LITERAL>" . <<"__DOC__");
<!DOCTYPE no-doctype [
  <!ELEMENT no-doctype - - (#PCDATA)>
  <!ATTLIST no-doctype x CDATA #REQUIRED>
]><no-doctype></no-doctype>
__DOC__
} 'does properly report erros';

is($h5->{ok}, 1, 'found right error message');

#########################################################
## Lots of parsers
#########################################################

my @parser;

for (1..20)
{
    my $p = SGML::Parser::OpenSP->new;

    isa_ok($p, 'SGML::Parser::OpenSP');

    ok(exists $p->{__o},
      'pointer to C++ object');

    isnt($p->{__o}, 0,
      'C++ object pointer not null-pointer');
    
    $p->handler(bless{},'TestHandler6');

    lives_ok { $p->parse_file("<LITERAL><no-doctype></no-doctype>") }
      'reading from a <literal>';
    
    push @parser, $p;
}

is(scalar(@parser), 20, 'all parsers loaded');

lives_ok { undef @parser } 'parser destructors';

#########################################################
## UTF-8 flags
#########################################################

sub TestHandler7::new         { bless{ok0=>0,ok1=>0,ok2=>0,ok3=>0,ok4=>0,
                                      ok5=>0,ok6=>0,ok7=>0,ok8=>0,ok9=>0,
                                      oka=>0,okb=>0,okc=>0,
                                      data=>""},shift }
sub TestHandler7::start_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    my @k = keys %{$e->{Attributes}};
    $s->{ok1}++ if Encode::is_utf8($e->{Name});
    $s->{ok2}++ if Encode::is_utf8($e->{Name}, 1);
    return unless @k;
    $s->{ok8}++ if @k == 1;
    $s->{ok9}++ if Encode::is_utf8($k[0]);
    $s->{oka}++ if Encode::is_utf8($k[0], 1);
    $s->{okb}++ if Encode::is_utf8($e->{Attributes}{$k[0]}->{Name});
    $s->{okc}++ if Encode::is_utf8($e->{Attributes}{$k[0]}->{Name}, 1);
}
sub TestHandler7::end_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    $s->{ok3}++ if Encode::is_utf8($e->{Name});
    $s->{ok4}++ if Encode::is_utf8($e->{Name}, 1);
    $s->{ok5}++ if Encode::is_utf8($s->{data});
    $s->{ok6}++ if Encode::is_utf8($s->{data}, 1);
    $s->{ok7}++ if $s->{data} =~ /^Bj\x{F6}rn$/;
}
sub TestHandler7::data
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    return unless exists $e->{Data};
    $s->{ok0}-- unless Encode::is_utf8($e->{Data});
    $s->{ok0}-- unless Encode::is_utf8($e->{Data}, 1);
    $s->{data}.=$e->{Data};
}

my $h7 = TestHandler7->new;

$p->handler($h7);

lives_ok { $p->parse_file("<LITERAL><no-doctype x='y'>Bj&#246;rn</no-doctype>") }
  'utf8 flags';

is($h7->{ok0}, 0, 'utf8 pcdata');
is($h7->{ok1}, 1, 'utf8 element name');
is($h7->{ok2}, 1, 'utf8 element name check');
is($h7->{ok8}, 1, 'attributes');
is($h7->{ok9}, 1, 'attribute hash key utf8');
is($h7->{oka}, 1, 'attribute hash key utf8 check');
is($h7->{okb}, 1, 'attribute name utf8');
is($h7->{okc}, 1, 'attribute name utf8 check');
is($h7->{ok3}, 1, 'end element name');
is($h7->{ok4}, 1, 'end element name');
is($h7->{ok5}, 1, 'complete data');
is($h7->{ok6}, 1, 'complete data');
is($h7->{ok7}, 1, 'correct data');

#########################################################
## restricted reading
#########################################################

sub TestHandler8::new{bless{ok1=>0,ok2=>0},shift}
sub TestHandler8::error {
    my $s = shift;
    my $e = shift;
    
    return unless defined $s and defined $e;
    
    $s->{ok2}++ if $e->{Message} =~ /^E:\s+/ and
                   $e->{Type} eq 'otherError';
}
sub TestHandler8::start_element{shift->{ok1}--}

my $h8 = TestHandler8->new;

$p->handler($h8);
$p->restrict_file_reading(1);

lives_ok { $p->parse_file("samples/../samples/no-doctype.xml") }
  'must not read paths with ..';

is($h8->{ok1}, 0, 'must not read paths with ..');
isnt($h8->{ok2}, 0, 'must not read paths with ..');
$h8->{ok1} = 0;
$h8->{ok2} = 0;

lives_ok { $p->parse_file("./samples/no-doctype.xml") }
  'must not read paths with ./';

is($h8->{ok1}, 0, 'must not read paths with ./');
isnt($h8->{ok2}, 0, 'must not read paths with ./');
$h8->{ok1} = 0;
$h8->{ok2} = 0;

my $sd = File::Spec->catfile(File::Spec->rel2abs('.'), 'samples');

$p->search_dirs($sd);

lives_ok { $p->parse_file(File::Spec->catfile($sd, 'no-doctype.xml')) }
  'allow to read sample dir in restricted mode';

isnt($h8->{ok1}, 0, 'allow to read sample dir in restricted mode');
is($h8->{ok2}, 0, 'allow to read sample dir in restricted mode');

$p->search_dirs([]);
$p->restrict_file_reading(0);

#########################################################
## parse_file from handler
#########################################################

sub TestHandler9::new{bless{p=>$_[1],ok1=>0},shift}
sub TestHandler9::start_element
{
    my $s = shift;
    
    eval
    {
        $s->{p}->parse_file(NO_DOCTYPE)
    };
        
    $s->{ok1}-- unless $@;
}

my $h9 = TestHandler9->new($p);

$p->handler($h9);

lives_ok { $p->parse_file(NO_DOCTYPE) }
  'parse_file must not be called from handler';

is($h9->{ok1}, 0, 'parse_file from handler croaks');

#########################################################
## non-scalar to parse_file
#########################################################

sub TestHandler10::new{bless{},shift}

my $h10 = TestHandler10->new;
$p->handler($h10);

dies_ok { $p->parse_file({}) }
  'non-scalar to parse_file';

dies_ok { $p->parse_file([]) }
  'non-scalar to parse_file';

ok(open(F, '<', NO_DOCTYPE), 'can open no-doctype.xml');

dies_ok { $p->parse_file(\*F) }
  'file handle to parse_file';

ok(close(F), 'can close no-doctype.xml');

#########################################################
## SGML Catalogs
#########################################################

sub TestHandler11::new{bless{ok1=>0,ok2=>0,ok3=>0,ok4=>0,ok5=>0},shift}
sub TestHandler11::start_dtd
{
    my $s = shift;
    my $d = shift;
    
    return unless defined $s;
    return unless defined $d;
    
    my $e = $d->{ExternalId};
    
    return unless defined $e;
    
    $s->{ok1}++;
    
    $s->{ok2}++ if exists $e->{SystemId} and $e->{SystemId} eq
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";
      
    $s->{ok3}++ if exists $e->{PublicId} and $e->{PublicId} eq
      "-//W3C//DTD XHTML 1.0 Strict//EN";
      
    # this might fail in case of conflicting catalogs :-(
    $s->{ok4}++ if exists $e->{GeneratedSystemId} and
      $e->{GeneratedSystemId} =~ /^<OSFILE>/i;
      
    $s->{ok5}++ if exists $d->{Name} and
      $d->{Name} eq "html";
}

my $h11 = TestHandler11->new;

$p->catalogs(TEST_CATALOG);
$p->handler($h11);

lives_ok { $p->parse_file("<LITERAL>" . <<"__DOC__");
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
} 'catalogs';

ok($h11->{ok1}, 'proper dtd event');
ok($h11->{ok2}, 'proper sys id');
ok($h11->{ok3}, 'proper pub id');

# todo: fails for some reason on Debian
ok($h11->{ok4}, 'proper osfile gen id');
ok($h11->{ok5}, 'proper root element');

# reset catalogs
$p->catalogs([]);

#########################################################
## show_error_numbers
#########################################################

# ...

#########################################################
## SGML::Parser::OpenSP::Tools
#########################################################

ok(!$p->show_error_numbers, 'show_error_numbers turned off');
ok(!$p->show_open_entities, 'show_open_entities turned off');
ok(!$p->show_open_elements, 'show_open_elements turned off');

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

lives_ok { $p->parse_file("<LITERAL>" . <<"__DOC__");
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

#########################################################
## Parser refcounting
#########################################################

# this is not exactly what I want, the issue here is that
# I would like to tell whether in this cleanup process is
# an attempt to free an unreferenced scalar for which Perl
# would not croak but write to STDERR

lives_ok
{
    my $x = SGML::Parser::OpenSP->new;
    my $y = \$x;
    undef $x;
    undef $y;
} 'parser refcounting 1';

lives_ok
{
    my $x = SGML::Parser::OpenSP->new;
    my $y = \$x;
    undef $y;
    undef $x;
} 'parser refcounting 2';

__END__

Todo:

  * need to fix some tests so that handler don't ok()
  * 
