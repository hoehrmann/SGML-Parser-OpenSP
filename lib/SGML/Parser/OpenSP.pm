# OpenSP.pm -- SGML::Parser::OpenSP module
#
# $Id: OpenSP.pm,v 1.13 2004/09/13 13:51:46 hoehrmann Exp $

package SGML::Parser::OpenSP;
use 5.008; 
use strict;
use warnings;
use SGML::Parser::OpenSP::Tools qw();

use base qw(Class::Accessor);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('SGML::Parser::OpenSP', $VERSION);

__PACKAGE__->mk_accessors(qw/
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
/);

# todo: needs documentation

sub split_message
{
    my $self = shift;
    my $mess = shift;
    my $loca = $self->get_location;
    my $name = $loca->{FileName};

    return SGML::Parser::OpenSP::Tools::split_message
    (
        $mess->{Message},
        $loca->{FileName},
        $self->show_open_entities,
        $self->show_error_numbers,
        $self->show_open_elements
    );
}

1;

__END__

=pod

=head1 NAME

SGML::Parser::OpenSP - Parse SGML documents using OpenSP

=head1 SYNOPSIS

  use SGML::Parser::OpenSP;

  my $p = SGML::Parser::OpenSP->new;
  my $h = ExampleHandler->new;

  $p->catalogs(qw(xhtml.soc));
  $p->warnings(qw(xml valid));
  $p->handler($h);

  $p->parse_file("example.xhtml");

=head1 DESCRIPTION

This module provides an interface to the OpenSP SGML parser. OpenSP and
this module are event based. As the parser recognizes parts of the document
(say the start or end of an element), then any handlers registered for that
type of an event are called with suitable parameters.

=head1 CONFIGURATION

=head2 BOOLEAN OPTIONS

=over 4

=item $p->handler([$handler])

Report events to the blessed reference $handler.

=item $p->show_open_entities([$bool])

Describe open entities in error messages. Error messages always include
the position of the most recently opened external entity. The default is
false.

=item $p->show_open_elements([$bool])

Show the generic identifiers of open elements in error messages.
The default is false.

=item $p->show_error_numbers([$bool])

Show message numbers in error messages.

=item $p->output_comment_decls([$bool])

Generate C<comment_decl> events. The default is false.

=item $p->output_marked_sections([$bool])

Generate marked section events (C<marked_section_start>,
C<marked_section_end>, C<ignored_chars>). The default is false.

=item $p->output_general_entities([$bool])

Generate C<general_entity> events. The default is false.

=item $p->map_catalog_document([$bool])

???

=item $p->restrict_file_reading([$bool])

Restrict file reading to the specified directories.
The default is false.

@@state where this is specified.

=back

=head2 OTHER OPTIONS

=over 4

=item $p->catalogs([@catalogs])

Map public identifiers and entity names to system identifiers using the
specified catalog entry files. Multiple catalogs are allowed. If there
is a catalog entry file called C<catalog> in the same place as the
document entity, it will be searched for immediately after those specified.

=item $p->search_dirs([@search_dirs])

Search the specified directories for files specified in system identifiers.
Multiple values options are allowed. See the description of the osfile
storage manager in the OpenSP documentation for more information about file
searching.

=item $p->include_params([@include_params])

For each name in @include_params pretend that 

  <!ENTITY % name "INCLUDE">

occurs at the start of the document type declaration subset in the SGML
document entity. Since repeated definitions of an entity are ignored,
this definition will take precedence over any other definitions of this
entity in the document type declaration. Multiple names are allowed.
If the SGML declaration replaces the reserved name INCLUDE then the new
reserved name will be the replacement text of the entity. Typically the
document type declaration will contain 

  <!ENTITY % name "IGNORE">

and will use %name; in the status keyword specification of a marked
section declaration. In this case the effect of the option will be to
cause the marked section not to be ignored.

=item $p->active_links([@active_links])

???

=back

=head2 ENABLING WARNINGS

Additional warnings can be enabled using

  $p->warnings([@warnings])

The following values can be used to enable warnings:

=over 4

=item xml 

Warn about constructs that are not allowed by XML. 

=item mixed 

Warn about mixed content models that do not allow #pcdata anywhere. 

=item sgmldecl 

Warn about various dubious constructions in the SGML declaration. 

=item should 

Warn about various recommendations made in ISO 8879 that the document
does not comply with. (Recommendations are expressed with ``should'',
as distinct from requirements which are usually expressed with ``shall''.)

=item default 

Warn about defaulted references. 

=item duplicate 

Warn about duplicate entity declarations. 

=item undefined 

Warn about undefined elements: elements used in the DTD but not defined. 

=item unclosed 

Warn about unclosed start and end-tags. 

=item empty 

Warn about empty start and end-tags. 

=item net 

Warn about net-enabling start-tags and null end-tags. 

=item min-tag 

Warn about minimized start and end-tags. Equivalent to combination of
unclosed, empty and net warnings. 

=item unused-map 

Warn about unused short reference maps: maps that are declared with a
short reference mapping declaration but never used in a short reference
use declaration in the DTD. 

=item unused-param 

Warn about parameter entities that are defined but not used in a DTD.
Unused internal parameter entities whose text is C<INCLUDE> or C<IGNORE>
won't get the warning. 

=item notation-sysid 

Warn about notations for which no system identifier could be generated. 

=item all 

Warn about conditions that should usually be avoided (in the opinion of
the author). Equivalent to: C<mixed>, C<should>, C<default>, C<undefined>,
C<sgmldecl>, C<unused-map>, C<unused-param>, C<empty> and C<unclosed>.

=back

=head2 DISABLING WARNINGS

A warning can be disabled by using its name prefixed with C<no->.
Thus calling warnings(qw(all no-duplicate)) will enable all warnings
except those about duplicate entity declarations. 

The following values for C<warnings()> disable errors: 

=over 4

=item no-idref 

Do not give an error for an ID reference value which no element has
as its ID. The effect will be as if each attribute declared as an ID
reference value had been declared as a name. 

=item no-significant 

Do not give an error when a character that is not a significant
character in the reference concrete syntax occurs in a literal in the
SGML declaration. This may be useful in conjunction with certain buggy
test suites. 

=item no-valid 

Do not require the document to be type-valid. This has the effect of
changing the SGML declaration to specify C<VALIDITY NOASSERT> and C<IMPLYDEF
ATTLIST YES ELEMENT YES>. An option of C<valid> has the effect of changing
the SGML declaration to specify C<VALIDITY TYPE> and C<IMPLYDEF ATTLIST NO
ELEMENT NO>. If neither C<valid> nor C<no-valid> are specified, then the
C<VALIDITY> and C<IMPLYDEF> specified in the SGML declaration will be used. 

=back

=head1 PROCESSING FILES

In order to start processing of a document and recieve events, the
C<parse_file> method must be called. It takes one argument specifying
the path to a file (not a file handle). You must set an event handler
using the C<handler> method prior to using this method. The return
value of C<parse_file> is currently undefined.

=head1 EVENT HANDLERS

In order to receive data from the parser you need to write an event
handler. For example,

  package ExampleHandler;

  sub new { bless {}, shift }

  sub start_element
  {
      my ($self, $elem) = @_;
      printf "  * %s\n", $elem->{Name};
  }

This handler would print all the element names as they are found
in the document, for a typical XHTML document this might result in
something like

  * html
  * head
  * title
  * body
  * p
  * ...

The events closely match those in the generic interface to OpenSP,
see L<http://openjade.sf.net/doc/generic.htm> for more
information.

The event names have been changed to lowercase and underscores to separate
words and properties are capitalized. Arrays are represented as Perl array
references. C<Position> information is not passed to the handler but made
available through the C<get_location> method which can be called from event
handlers. Some redundant information has also been stripped and the generic
identifier of an element is stored in the C<Name> hash entry.

For example, for an EndElementEvent the C<end_element> handler gets called
with a hash reference

  {
    Name => 'gi'
  }

The following events are defined:

  * appinfo
  * pi
  * start_element
  * end_element
  * data
  * sdata
  * external_data_entity_ref
  * subdoc_entity_ref
  * start_dtd
  * end_dtd
  * end_prolog
  * general_entity       # set $p->output_general_entities(1)
  * comment_decl         # set $p->output_comment_decls(1)
  * marked_section_start # set $p->output_marked_sections(1)
  * marked_section_end   # set $p->output_marked_sections(1)
  * ignored_chars        # set $p->output_marked_sections(1)
  * error
  * open_entity_change

If the documentation of the generic interface to OpenSP states that
certain data is not valid, it will not be available through this
interface (i.e., the respective key does not exist in the hash ref).

=head1 POSITIONING INFORMATION

Event handlers can call the C<get_location> method on the parser object
to retrieve positioning information, the get_location method will return
a hash reference with the following properties:

  LineNumber   => ..., # line number
  ColumnNumber => ..., # column number
  ByteOffset   => ..., # number of preceding bytes
  EntityOffset => ..., # number of preceding bit combinations
  EntityName   => ..., # name of the external entity
  FileName     => ..., # name of the file

These can be C<undef> or an empty string.

=head1 UNICODE SUPPORT

All strings returned from event handlers and helper routines are UTF-8
encoded with the UTF-8 flag turned on, helper functions like C<split_message>
expect (but don't check) that string arguments are UTF-8 encoded and have
the UTF-8 flag turned on. Behavior of helper functions is undefined when
you pass unexpected input and should be avoided.

C<parse_file> has limited support for binary input, but the binary input
must be compatible with OpenSP's generic interface requirements and you
must specify the encoding through means available to OpenSP to enable it
to properly decode the binary input. Any encoding meta data about such
binary input specific to Perl (such as encoding disciplines for file
handles when you pass a file descriptor) will be ignored. For more specific
information refer to the OpenSP manual.

=over 4

=item * L<http://openjade.sourceforge.net/doc/sysid.htm>

=item * L<http://openjade.sourceforge.net/doc/charset.htm>

=back

=head1 ENVIRONMENT VARIABLES

OpenSP supports a number of environment variables to control specific
processing aspects such as C<SGML_SEARCH_PATH> or C<SP_CHARSET_FIXED>.
Portable applications need to ensure that these are set prior to
loading the OpenSP library into memory which happens when the XS code
is loaded. This means you need to wrap the code into a C<BEGIN> block:

  BEGIN { $ENV{SP_CHARSET_FIXED} = 1; }
  use SGML::Parser::OpenSP;
  # ...

Otherwise changes to the environment might not propagate to OpenSP.
This applies specifically to Win32 systems. 

=over 4

=item SGML_SEARCH_PATH

See L<http://openjade.sourceforge.net/doc/sysid.htm>.

=item SP_HTTP_USER_AGENT

The C<User-Agent> header for HTTP requests.

=item SP_HTTP_ACCEPT

The C<Accept> header for HTTP requests.

=item SP_MESSAGE_FORMAT

Enable run time selection of message format, Value is one of C<XML>,
C<NONE>, C<TRADITIONAL>. Whether this will have an effect depends
on a compile time setting which might not be enabled in your OpenSP
build. This module assumes that no such support was compiled in.

=item SGML_CATALOG_FILES

=item SP_USE_DOCUMENT_CATALOG

See L<http://openjade.sourceforge.net/doc/catalog.htm>.

=item SP_SYSTEM_CHARSET

=item SP_CHARSET_FIXED

=item SP_BCTF

=item SP_ENCODING

See L<http://openjade.sourceforge.net/doc/charset.htm>.

=back

Note that you can use the C<search_dirs> method instead of using
C<SGML_SEARCH_PATH> and the C<catalogs> method instead of using
C<SGML_CATALOG_FILES> and attributes on storage object specifications
for C<SP_BCTF> and C<SP_ENCODING> respectively. For example, if
C<SP_CHARSET_FIXED> is set to C<1> you can use

  $p->parse_file("<OSFILE encoding='UTF-8'>example.xhtml");

to process C<example.xhtml> using the C<UTF-8> character encoding.

=head1 KNOWN ISSUES

OpenSP must be compiled with C<SP_MULTI_BYTE> I<defined> and with
C<SP_WIDE_SYSTEM> I<undefined>, this module will otherwise break
at runtime or not compile.

Individual warnings for -wxml are not listed in this POD.

The typemap is crap.

The Makefile.PL is crap.

=head1 BUG REPORTS

Please report bugs in this module via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SGML-Parser-OpenSP>

Please report bugs in OpenSP via
L<http://sf.net/tracker/?group_id=2115&atid=102115>

Please send comments and questions to the spo-devel mailing list, see
L<http://lists.sf.net/lists/listinfo/spo-devel>
for details.

=head1 SEE ALSO

=over 4

=item * L<http://openjade.sf.net/doc/generic.htm>

=item * L<http://openjade.sf.net/>

=item * L<http://sf.net/projects/spo/>

=back

=head1 AUTHOR AND COPYRIGHT

  Terje Bless <link@cpan.org> wrote version 0.01.
  Bjoern Hoehrmann <bjoern@hoehrmann.de> wrote version 0.02.

  Copyright (c) 2004 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
