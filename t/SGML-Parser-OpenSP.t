# SGML-Parser-OpenSP.t -- ... 
#
# $Id: SGML-Parser-OpenSP.t,v 1.4 2004/09/10 05:13:21 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 12;
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

__END__

Todo:

  * must die when parse_file called from handler
