# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SGML-Parser-OpenSP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
use Test::Exception;

BEGIN { use_ok('SGML::Parser::OpenSP') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

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

    split_message
/);

ok(exists $p->{__o},
  "pointer to C++ object");

isnt($p->{__o}, 0,
  "C++ object pointer not null-pointer");

dies_ok { $p->get_location }
  'must die when calling get_location while not parsing';

dies_ok { $p->parse_file() }
  'must die when no file name specified for parse_file';



__END__

Todo:

  * must not die when handler cannot handle a method
  * must die when no file name specified for parse_file
  * must die when no handler specified
  * must die when parse_file called from handler
  * must die when handler not an object
