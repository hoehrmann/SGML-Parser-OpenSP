# SGML-Parser-OpenSP.t -- ... 
#
# $Id: SGML-Parser-OpenSP.t,v 1.5 2004/09/10 10:35:34 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 60;
use Test::Exception;

use constant NO_DOCTYPE => 'samples/no-doctype.xml';

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

lives_ok { $p->parse_file("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comments not reported by default';

#########################################################
## Comments at user option
#########################################################

sub TestHandler3::new         { bless{},shift }
sub TestHandler3::comment     { pass }

my $h3 = TestHandler3->new(1);

isa_ok($h3, 'TestHandler3');

$p->output_comment_decls(1);

is($p->output_comment_decls, 1, 'comments turned on');

lives_ok { $p->parse_file("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comment reported at user option';

$p->output_comment_decls(0);

is($p->output_comment_decls, 0, 'comments turned off');

#########################################################
## Locations for implied document type declarations
#########################################################

#########################################################
## Error reporting
#########################################################

sub TestHandler5::new         { bless{stop=>0},shift }
sub TestHandler5::error
{
    is(scalar(@_), 2, 'two args for error handler');
    like($_[1]->{Message}, qr/:4:13:E:/, 'found right error');
    die if $_[0]->{stop}++
}

$p->handler(TestHandler5->new);
lives_ok { $p->parse_file("<LITERAL>" . <<"__DOC__");
<!DOCTYPE no-doctype [
  <!ELEMENT no-doctype - - (#PCDATA)>
  <!ATTLIST no-doctype x CDATA #REQUIRED>
]><no-doctype></no-doctype>
__DOC__
} 'does properly report erros';


__END__

Todo:

  * must die when parse_file called from handler
