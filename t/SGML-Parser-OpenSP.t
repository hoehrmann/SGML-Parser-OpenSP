# SGML-Parser-OpenSP.t -- ... 
#
# $Id: SGML-Parser-OpenSP.t,v 1.7 2004/09/11 07:55:08 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 146;
use Test::Exception;
use Encode qw();
use File::Spec qw();
use Cwd qw();

use constant NO_DOCTYPE => (File::Spec->catfile('samples', 'no-doctype.xml'));

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

sub TestHandler1::new { bless{},shift }
sub TestHandler1::start_element {
    isa_ok($_[0], 'TestHandler1');

    # Name
    ok(defined $_[1], 'got an element');
    ok(exists $_[1]->{Name}, 'element has name');
    like($_[1]->{Name}, qr/no-doctype/i, 'name is no-doctype');
    
    # Attributes
    ok(exists $_[1]->{Attributes}, 'has attribute hash');
    isa_ok($_[1]->{Attributes}, "HASH", 'attribute hash is hash ref');
    is(scalar(keys(%{$_[1]->{Attributes}})), 0, 'sample has no attributes');
    
    # Included
    ok(exists $_[1]->{Included}, 'has included property');
    is($_[1]->{Included}, 0, 'included is 0');
}

my $h1 = TestHandler1->new;

isa_ok($h1, 'TestHandler1');

$p->handler($h1);

lives_ok { $p->parse_file(NO_DOCTYPE) }
  'basic parser test';

#########################################################
## Read from a <LITERAL>
#########################################################

lives_ok { $p->parse_file("<LITERAL><no-doctype></no-doctype>") }
  'reading from a <literal>';

#########################################################
## Comments not default
#########################################################

sub TestHandler2::new         { bless{},shift }
sub TestHandler2::comment     { die }

my $h2 = TestHandler2->new(0);

isa_ok($h2, 'TestHandler2');

$p->handler($h2);

lives_ok { $p->parse_file("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comments not reported by default';

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
    die unless @_ == 2;
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

sub TestHandler8::new{bless{},shift}
sub TestHandler8::start_element{die}

$p->handler(TestHandler8->new);
$p->restrict_file_reading(1);

lives_ok { $p->parse_file("samples/../samples/no-doctype.xml") }
  'must not read paths with ..';
  
lives_ok { $p->parse_file("./samples/no-doctype.xml") }
  'must not read paths with ./';

my $sd = File::Spec->catfile(File::Spec->rel2abs('.'), 'samples');

$p->search_dirs($sd);

dies_ok { $p->parse_file(File::Spec->catfile($sd, 'no-doctype.xml')) }
  'allow to read sample dir in restricted mode';

$p->search_dirs([]);
$p->restrict_file_reading(0);

#########################################################
## parse_file from handler
#########################################################



#########################################################
## show_error_numbers
#########################################################


#########################################################
## SGML::Parser::OpenSP::Tools
#########################################################

#########################################################
## newlines in enum attribute
#########################################################




__END__

Todo:

  * must die when parse_file called from handler
  * need to fix some tests so that handler don't ok()

