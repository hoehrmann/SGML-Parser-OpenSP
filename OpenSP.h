using namespace std;

/* Error Struct */
struct Error {
  unsigned long line;
  unsigned long column;
  unsigned long offset;
  string message;
};

/* Element Struct */
struct Element {
  string gi;
  vector<map<string, string> > attr;
  vector<Element*> data;
  Element* parent;
};



// Local Variables:
// mode: C++
// End:
