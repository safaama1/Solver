%{
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

void yyerror (char *);
int yylex (void);

#define NUM_VARS 26
#define MAX_CONS 100 /* the maximum number of constraint */

/*
   definition = var <variable_name> “:” <range_from> “..” <range_to> “;”
   constraint = <expression> (is | is not) <number> “;”
*/
int vars_max_digits[NUM_VARS] = {0};
int count_vars =0;
int vars[NUM_VARS] = {0};
int definition_size[NUM_VARS] = {0};
int *vars_values[NUM_VARS] = {0};
int is_used[NUM_VARS] = {0};
int max_digit =0;

typedef struct Node {
  enum { PLUS, MINUS, MULT,  N ,NUM} op;
  int number,old_var;
  struct Node *left, *right;
} Node;

Node* array_trees[MAX_CONS];
int constraint_v[MAX_CONS] = {0}; /* the value of every constraint */
int not[MAX_CONS] = {0}; /* value 1-> the tree with the same index has the the word not in the constraint
                            value 0-> the tree with the same index doesn't has the the word not in the constraint*/
int count_trees=0;
%}


%union   {int num, id; Node* node;}

%start program
%token <num> NUMBER
%token <id> VAR
%token V
%token POINT
%token IS
%token IS_NOT
%type <node> expression
%right '='
%left '+' '-'
%left '*' '/'

%%

program			    : /* empty */
                | statement program
            	  ;

statement		    : definition ';'              { }
				        | constraint ';'              { }
          		  ;

constraint      : expression IS NUMBER        {
                                                array_trees[count_trees]= $1;
                                                constraint_v[count_trees]=$3;
                                                count_trees++;
                                              }
                | expression IS IS_NOT NUMBER    {
                                                not[count_trees]=1;
                                                array_trees[count_trees]= $1;
                                                constraint_v[count_trees]=$4;
                                                count_trees++;
                                              }
                ;


expression      : NUMBER        {
                                   Node *n1 = malloc(sizeof(Node));
                                   n1->op=NUM;
                                   n1->number=$1;
                                   n1->old_var=-1;
                                   $$ = n1;
                               }
                 | VAR         {
                                  if(is_used[$1]==0){
                                     printf ("variable %c not defined\n",'a'+$1);
                                     exit(-1);
                                   }
                                  Node *n1 = malloc(sizeof(Node));
                                  n1->op=N;
                                  n1->number=$1;
                                  n1->old_var=-1;
                                  $$ = n1;
                                }

                | '(' expression ')'          { $$ = $2; }

                | expression '*' expression   { Node *node = malloc(sizeof(Node));
                                                node->op = MULT;
                                                node->right =$3;
                                                node->left = $1;
                                                $$ = node;
                                              }

                | expression '+' expression   { Node *node = malloc(sizeof(Node));
                                                node->op = PLUS;
                                                node->right =$3;
                                                node->left = $1;
                                                $$ = node;
                                              }

                | expression '-' expression   { Node *node = malloc(sizeof(Node));
                                                node->op = MINUS;
                                                node->right =$3;
                                                node->left = $1;
                                                $$ = node;
                                              }


				        ;

definition  : V VAR ':' NUMBER POINT NUMBER  {
                                  assert($2>=0 && $2<NUM_VARS);
        												  if(is_used[$2]==1){
        												  	printf ("variable is already declared\n");
                                    exit(-1);
        												  }
        												  else{
                                    count_vars++;
        												  	int size= $6 - $4 + 1;
                                    definition_size[$2]=size;
        												  	vars_values[$2]= (int*)malloc((size)*sizeof(int));
        												  	is_used[$2]=1;
        												  	int i,num= $4;
        												  	for(i=0;i<size;i++){
        												  		vars_values[$2][i]=num++;
        												 	 }
                                   int n= $6,count=0;
                                   while (n != 0) {
                                      n /= 10;
                                      ++count;
                                  }
                                  //this is to know how many
                                  //digits we will take from the number
                                  max_digit+=count;
        												 }
        												}
			;
%%

void yyerror (char *s) {printf("parse error\n");
 exit(-1);}

int eval_tree(Node *tree) {
  if (tree->op == NUM) return tree->number;
  int left = eval_tree(tree->left);
  int right = eval_tree(tree->right);
  switch (tree->op) {
  case PLUS: return left+right;
  case MINUS: return left-right;
  case MULT: return left*right;
  default:    exit(-1);
  }
}

/* check_in_definition -> returns 1 if all the digits belongs
   to its variable definition , otherwise returns 0  */
int check_in_definition(int *digit_array){
  int i;
  for(i=0;i<NUM_VARS;i++){
    if(is_used[i] != 0)
      if(digit_array[i] > vars_values[i][definition_size[i] -1] || digit_array[i] < vars_values[i][0] )
        return 0;
  }
  return 1;
}

void put_digits_in_tree(Node *tree,int *digit_array){
  assert(tree);
  if(tree->op == N ){
    tree->op=NUM;
    tree->old_var=tree->number;
    tree->number=digit_array[tree->number];
    return;
  }
  if (tree->op == NUM) {
    if(tree->old_var != -1)
      tree->number=digit_array[tree->old_var];
    return;
  }
  put_digits_in_tree(tree->left,digit_array);
  put_digits_in_tree(tree->right,digit_array);
}

void print_vars(int *digit_array){
  int i,count=0;
  for(i=0;i<NUM_VARS;i++){
   if(is_used[i] != 0 ){
    if(count == count_vars-1 ){
     printf("%c=%d\n",'a'+i,digit_array[i]);
    }
    else{
      count++;
      printf("%c=%d, ",'a'+i,digit_array[i]);
    }
   }
  }
}

int power(int base, int exponent)
{
  int result=1;
  int k;
  for(k=exponent; k>0; k--){
    result = result * base;
  }
  return result;
}

void put_digits(int *digit_array,int n){
  int i;
  int count_digits=1;
  int number ;
  for(i=0;i<NUM_VARS;i++){
    if(is_used[i] != 0 ){
      number=vars_values[i][definition_size[i]-1];
      while (number != 0) {
        number /= 10;
        ++count_digits;
      }
      if(count_digits==1) {
        count_digits = 1 ;
      }
      else{
        count_digits--;
      }
      vars_max_digits[i]=count_digits;
      count_digits=1;
    }
  }
  /* now put the digits in the array in the same index of the variable
     in the variables array  for example : digit_array[0] =7 then
     the number 7 goes to the variable 'a' (if it was defined)*/
  int temp=NUM_VARS;
  int n2 = n;
  int n_g,x=0,m=0;
  while(temp-- != 0){
    if(is_used[temp] != 0){
      n_g = vars_max_digits[temp];
      /* the while loop for the variables that can
         get more than one digit .
          for example if we defined x as : var x : 1 .. 20
          so x can get 10,11,...,20 (so we take two digits from the number)*/
      while(n_g-- != 0){
        m  = n2 % 10;
        m *= (power(10,vars_max_digits[temp] - n_g - 1));
        x += m;
        m = x;
        n2 /= 10;
      }
      digit_array[temp] = m;
      x=0;
      m=0;
    }
  }
}
int find_max_digit(){
  int i,max_d=0;
  for(i=0;i<NUM_VARS;i++){
    if(is_used[i] != 0 )
      if(vars_max_digits[i]>max_d)
        max_d =vars_max_digits[i];
  }
  printf("%d",max_d);
  return max_d;
}

int main (void) {
  if(yyparse()!=-1){
    /*
    now check every number until 10^(number of the vars)
    for example if we have two variables then we will check 2^10 numbers
    so every digit is for specific variable
    if the number is 45 and we have x,y as variables
    so the 4 goes to the x
    and the 5 goes for the y
    the number with one digit goes to the last variable ( 1 -> y in the last example)
    */
    int count_sol=0;
    int digit_array[NUM_VARS]={0}; // array to put every digit in the variable place
    int i1,j1;
    int is_ok=0;
    int to=power(10,max_digit);
    for(i1=0; i1<to ;i1++){
      put_digits(digit_array,i1);
      for(j1=0; j1< count_trees; j1++){
        if(check_in_definition(digit_array) != 0){
          put_digits_in_tree(array_trees[j1],digit_array);
          if(not[j1]!=1){
            if(eval_tree(array_trees[j1]) != constraint_v[j1]){
              is_ok=0;
              j1=count_trees;
            }
            else{
              is_ok=1;
            }
          }
          //if the constraint has the word not
          else if(not[j1] ==1){
            if(eval_tree(array_trees[j1]) == constraint_v[j1]){
              is_ok=0;
              j1=count_trees;
            }
            else{
              is_ok=1;
            }
          }
        }
      }
      //if the numbers we checked are ok
      if(is_ok == 1 ){
        count_sol++;
        print_vars(digit_array);
        is_ok=0;
      }
    }
    if(count_sol == 0 && array_trees[0] != NULL){
      printf("No solution\n");
    }
  }
  return 0 ;
}
