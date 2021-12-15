%{
/* without this struct defined here I get an error that the struct Node is not defined */
  typedef struct Node {
    enum { PLUS, MINUS, MULT, N } op;
    int number;
    struct Node *left, *right;
  } Node;

#include "y.tab.h"

%}

%%
var               {  return V;}
".."	            {  return POINT;}
"is"              {  return IS;}
"not"             {  return IS_NOT;}
[0-9]+            { yylval.num = atoi(yytext); return NUMBER; }
[a-z]             { yylval.id = yytext[0]-'a'; return VAR; }
[ \t\n]           ;
.                 { return yytext[0]; }

%%
int yywrap (void)  {return 1;}
