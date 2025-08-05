/*
** Trivial ctypesgen demo library
**  from http://code.google.com/p/ctypesgen
*/

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT
#endif

#define DB_C_TYPE_STRING             1

DLLEXPORT int trivial_add(int a, int b);
