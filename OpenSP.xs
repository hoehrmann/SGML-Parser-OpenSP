#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#ifdef __cplusplus
}
#endif

// Demoronize Perl headers...
#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif

#include <map>
#include <vector>
#include <string>
#include <OpenSP/ParserEventGeneratorKit.h>
#include "OpenSP.h"

using namespace std;

class OpenSP : public SGMLApplication {
public:
  Element* CurElementPtr;
  vector<Element*> Document;
  vector<Error*>   Messages; // Must be public to let XS see it?
  OpenSP (const char *);
  virtual void _parse();
  virtual SV* getDocTree();
  virtual SV* getDocTree(Element*);
  virtual void error(const ErrorEvent &event);
  virtual void startElement(const StartElementEvent &event);
  virtual void endElement(const EndElementEvent &event);
  virtual string cs2ss(CharString);
  virtual string attr2ss(SGMLApplication::Attribute::Type type);
private:
  const char *fileName;
  EventGenerator *egp;
  OpenEntityPtr *curEntPtr;
  ParserEventGeneratorKit parserKit;
  void openEntityChange(const OpenEntityPtr &event) {
    curEntPtr = (OpenEntityPtr*) &event;
  }
};

OpenSP::OpenSP (const char *file) {
  fileName      = file;
  CurElementPtr = new Element;
  Document.push_back(CurElementPtr);
}

void OpenSP::startElement(const StartElementEvent &event) {
  CurElementPtr->gi = this->cs2ss(event.gi);

  vector<map<string, string> > attrs;
  for (size_t i = 0; i < event.nAttributes; i++) {
    Attribute a = event.attributes[i];
    map<string, string> attr;
    pair<string, string> name;
    pair<string, string> value;
    pair<string, string> type;

    name.first  = "name";
    name.second = this->cs2ss(a.name);
    attr.insert(name);

    value.first  = "value";
    value.second = this->cs2ss(a.name);
    attr.insert(value);

    type.first  = "type";
    type.second = this->attr2ss(a.type);
    //    type.second = this->cs2ss(a.name);
    attr.insert(type);

    attrs.push_back(attr);
  }
  CurElementPtr->attr = attrs;

  Element* e = new Element;
  e->parent = CurElementPtr;
  CurElementPtr->data.push_back(e);
  CurElementPtr = e;
}

void OpenSP::endElement(const EndElementEvent &event) {
  CurElementPtr = CurElementPtr->parent;
}

string OpenSP::attr2ss(SGMLApplication::Attribute::Type type) {
  switch (type) {
  case SGMLApplication::Attribute::invalid:   return "invalid" ;
  case SGMLApplication::Attribute::implied:   return "implied" ;
  case SGMLApplication::Attribute::cdata:     return "cdata" ;
  case SGMLApplication::Attribute::tokenized: return "tokenized" ;
  }
  return "WTF?" ;
}


void OpenSP::_parse () {
  parserKit.setOption(ParserEventGeneratorKit::outputCommentDecls);
  parserKit.setOption(ParserEventGeneratorKit::enableWarning, "xml");
  parserKit.setOption(ParserEventGeneratorKit::showOpenEntities);

  egp = parserKit.makeEventGenerator(1, (char **)&fileName);
  egp->inhibitMessages(true);

  OpenSP *p = const_cast<OpenSP*>(this);
  SGMLApplication *a = static_cast<SGMLApplication*>(p);
  egp->run(*a);
}

void OpenSP::error(const ErrorEvent &event) {
  Location *loc = new Location(*curEntPtr, event.pos);
  Error *err    = new Error;
  err->line     = loc->lineNumber;
  err->column   = loc->columnNumber;
  err->offset   = loc->byteOffset;
  err->message  = this->cs2ss(event.message);
  Messages.push_back(err);
}

string OpenSP::cs2ss(CharString cs) {
  string ss;
  for (size_t i = 0; i < cs.len * 4; i += 4)
    ss += wchar_t(cs.ptr[i]);
  return ss;
}


SV * OpenSP::getDocTree() {
  AV* root = (AV *)sv_2mortal((SV *)newAV());
  SV * doc = this->getDocTree(CurElementPtr);
  av_push(root, newRV((SV *)doc));
  SV* ret = newRV((SV *)root);
  return ret;
}

SV * OpenSP::getDocTree(Element* e) {
  HV* re = (HV *)sv_2mortal((SV *)newHV());
  hv_store(re, "gi", 2, newSVpv(e->gi.c_str(), e->gi.size()), 0);

  HV* attr = (HV *)sv_2mortal((SV *)newHV());
  vector<map<string, string> >::const_iterator attrs;
  for (attrs = e->attr.begin(); attrs != e->attr.end(); ++attrs) {
    map<string, string>::const_iterator a;
    for (a = attrs->begin(); a != attrs->end(); ++a) {
      hv_store(attr, a->first.c_str(), a->first.size(), newSVpv(a->second.c_str(), a->second.size()), 0);
    }
  }
  hv_store(re, "attr", 4, newRV((SV *)attr), 0);

  AV* data = (AV *)sv_2mortal((SV *)newAV());
  vector<Element*>::const_iterator d;
  for (d = e->data.begin(); d != e->data.end(); ++d) {
    Element* foo = *d;
    SV* ne = this->getDocTree(foo);
    av_push(data, newRV((SV *)ne));
  }
  hv_store(re, "data", 4, newRV((SV *)data), 0);

  SV* ret = newRV((SV *)re);
  return ret;
}


MODULE = SGML::Parser::OpenSP		PACKAGE = SGML::Parser::OpenSP

OpenSP *
OpenSP::new(file)
  const char* file

void
OpenSP::DESTROY()

void
OpenSP::_parse()

SV *
OpenSP::getDocTree()

SV *
OpenSP::parse()
  INIT:
    AV* ra;
    HV* rh;
    ra = (AV *)sv_2mortal((SV *)newAV());
    rh = (HV *)sv_2mortal((SV *)newHV());

    THIS->_parse();
  CODE:
    std::vector<Error*>::const_iterator i;
    for (i = THIS->Messages.begin(); i != THIS->Messages.end(); ++i) {
      Error *err = *i;
      hv_store(rh, "Line",    4, newSVnv(err->line),                                 0);
      hv_store(rh, "Column",  6, newSVnv(err->column),                               0);
      hv_store(rh, "Offset",  6, newSVnv(err->offset),                               0);
      hv_store(rh, "Message", 7, newSVpv(err->message.c_str(), err->message.size()), 0);
      av_push(ra, newRV((SV *)rh));
    }
    RETVAL = newRV((SV *)ra);
  OUTPUT:
    RETVAL



# Local Variables:
# mode: C++
# End:
