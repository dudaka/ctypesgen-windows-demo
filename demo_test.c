/*
** Simple test program for demolib
*/

#include <stdio.h>
#include "demolib.h"

int main() {
    int a = 1;
    int b = 2;
    int result = trivial_add(a, b);
    
    printf("a %d\n", a);
    printf("b %d\n", b);
    printf("result %d\n", result);
    printf("DB_C_TYPE_STRING %d\n", DB_C_TYPE_STRING);
    
    return 0;
}
