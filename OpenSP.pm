package SGML::Parser::OpenSP;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ('all' => [qw()]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT = qw();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('SGML::Parser::OpenSP', $VERSION);

1;
__END__
=head1 NAME

SGML::Parser::OpenSP - Parse SGML Using the OpenSP Generic API

=head1 SYNOPSIS

  use SGML::Parser::OpenSP;

  my $Parser = SGML::Parser::OpenSP->new('example.html');
  my $Result = $Parser->parse();

  # $Result now contains a data structure representing the
  # document tree (nothing so fancy as a DOM, just a tree).

=head1 ABSTRACT

  SGML::Parser::OpenSP is a Perl XS interface to the OpenSP "generic"
  API. This is a limited interface to the OpenSP SGML and XML Parser
  from <http://openjade.sf.net/>.

=head1 DESCRIPTION

  This isn't even alpha quality code yet. Released only in the hopes of
  garnering patches to actually make it do something usefull. :-)

  In fact, this was my project to learn a little C++ and XS so you can
  pretty much imagine what the code looks like. So when I say patches
  are welcome, I mean patches are *welcome*! :-)

=head2 LIMITATIONS

  This code is pretty much all non-functional as yet!

  For one thing it will only parse XML (which is weird since OpenSP is
  mainly an SGML Parser) and has very few facilities for managing SGML
  Declarations, DTDs, and Catalogs.

  As it stands there is very little chance that you will be able to
  actually use this module in a program; it passes its own tests (in
  the t/ directory) but that is pretty much all it's usefull for.

  You shouldn't bother looking at this module unless you want to help
  improve it to the point where it can actually be used for something.

  If you want a module like this but cannot help developing it, please
  drop me a note (email is below) and let me know! I need this module
  for my own projects but it has low priority for me; if others were to
  express an interest it might make me spend more time on improving it.

=head2 EXPORT

  None by default.

=head1 SEE ALSO

  The OpenJade project - <http://openjade.sf.net/>

  The "onsgmls" man page.

=head1 AUTHOR

Terje Bless E<lt>link@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Terje Bless

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
