%{
#include "node.h"
#define START_ADDRESS 100

int yylex(void);
void yyerror(string str);
int nextquad = START_ADDRESS;
char code[100][50];
int var1;
int *var2;

int available_reg;
node *tree_pointer;

stack<string> reg_stack;
int memory_location_num = 0;
%}

%union
{
	char id[10];
	node *eval;
}

%token <id> LETTER INTEGER FLOAT
%token IF ELSE WHILE
%type <eval> PROGRAM BODY ASSIGN STMTS COND LVALUE E M N IF_ELSE OPEN_STMT CLOSED_STMT

%left '|'
%left '&'
%left '!'
%left '<' '>'
%left '+' '-'
%left '*' '/'
%left '(' ')'

%right '='

%start PROGRAM

%%

PROGRAM : STMTS	{ 
					int i;
					Backpatch($1->next,nextquad);
					printf("3 address code : \n");
					for(i=START_ADDRESS;i<nextquad;i++){
						printf("\n%s",code[i-START_ADDRESS]);
					}
					printf("\n%d\n",nextquad);
				}
				;
				
BODY : IF_ELSE {}
	  | WHILE M '(' COND ')' M BODY {
				      $$=create_node();
				      Backpatch($7->next,$2->quad);
				      Backpatch($4->True,$6->quad);
				      $$->next=$4->False;
				      sprintf(code[nextquad-START_ADDRESS],"%d\tgoto %d",nextquad,$2->quad);
				      Gen();
				      }
	  | ASSIGN ';'	{$$=create_node(); $$->next=(int*)malloc(sizeof(int)*15); $$->next[0]=0;}
	  | E { }
	  ;

IF_ELSE : OPEN_STMT	
	 	| CLOSED_STMT
	  	;
	  
OPEN_STMT : IF '(' COND ')' M BODY	{$$ = create_node(); Backpatch($3->True,$5->quad); $$->next=Merge($3->False,$6->next);}	
	  	  | IF '(' COND ')' M CLOSED_STMT N ELSE M OPEN_STMT	{				
											$$ = create_node();
											Backpatch($3->True,$5->quad);
											Backpatch($3->False,$9->quad);
											$$->next=Merge($6->next,$7->next);
											$$->next=Merge($$->next,$10->next);}
	 	  ;
	  
CLOSED_STMT : IF '(' COND ')' M CLOSED_STMT N ELSE M CLOSED_STMT	{			
											$$ = create_node();
											Backpatch($3->True,$5->quad);
											Backpatch($3->False,$9->quad);
											
											$$->next=Merge($6->next,$7->next);
											$$->next=Merge($$->next,$10->next);
											}
	    	| '{' STMTS '}'	{$$=create_node(); $$->next=$2->next;}
	    
	 		 ;  
	  
STMTS : STMTS M BODY	{$$=create_node(); Backpatch($1->next,$2->quad); $$->next=$3->next;}
		   | BODY	{$$=create_node(); $$->next=$1->next;}
		   ;
		   
ASSIGN : LVALUE '=' E	{sprintf(code[nextquad-START_ADDRESS],"%d\t%s = %s",nextquad,$1->place,$3->place); Gen();
			  $3->isLeftChild =1;tree_pointer = $3;printf("Labeling Algorithm (No. of registers required)\n");calc_registers(tree_pointer);printf("Gencode : \n");gencode(tree_pointer);printf("\n");}
	   | E {}	
	   ;

LVALUE : LETTER {$$=create_node(); strcpy($$->place,$1);};

E : '(' E ')' {$$ =create_node(); $$ = $2;}
  
    | E '+' E	{
				$$=create_node();
				strcpy($$->place,Newtemp()); 
				sprintf(code[nextquad-START_ADDRESS],"%d\t%s = %s + %s",nextquad,$$->place,$1->place,$3->place);
				Gen();
				$1->isLeftChild = 1;
				$$->Operator = '+';
				$$->left = $1;
				$$->right = $3;
			}
  | E '-' E	{
				$$=create_node();
				strcpy($$->place,Newtemp());
				sprintf(code[nextquad-START_ADDRESS],"%d\t%s = %s - %s",nextquad,$$->place,$1->place,$3->place);
				Gen();
				$1->isLeftChild = 1;
				$$->Operator = '-';
				$$->left = $1;
				$$->right = $3;
				
			}
  | E '*' E	{
				$$=create_node();
				strcpy($$->place,Newtemp());
				sprintf(code[nextquad-START_ADDRESS],"%d\t%s = %s * %s",nextquad,$$->place,$1->place,$3->place);
				Gen();
				$1->isLeftChild = 1;
				$$->Operator = '*';
				$$->left = $1;
				$$->right = $3;
				
			}
  | E '/' E	{
				$$=create_node();
				strcpy($$->place,Newtemp());
				sprintf(code[nextquad-START_ADDRESS],"%d\t%s = %s / %s",nextquad,$$->place,$1->place,$3->place);
				Gen();
				$1->isLeftChild = 1;
				$$->Operator = '/';
				$$->left = $1;
				$$->right = $3;
				
			}
  | LETTER		{$$ = create_node(); strcpy($$->place,$1);}
  | INTEGER		{$$=create_node(); strcpy($$->place,$1);}
  | FLOAT		{$$=create_node(); strcpy($$->place,$1);}
  ;

COND : COND '&' M COND	{$$=create_node(); Backpatch($1->True,$3->quad); $$->True=$4->True; $$->False=Merge($1->False,$4->False);}
	 | COND '|' M COND	{$$=create_node(); Backpatch($1->False,$3->quad); $$->True=Merge($1->True,$4->True); $$->False=$4->False;}
	 | '!' COND			{$$=create_node(); $$->True=$2->False; $$->False=$2->True;}
	 
	 | E '<' E	{
	 				$$=create_node();
					$$->True=Makelist(nextquad);
					$$->False=Makelist(nextquad+1);
					sprintf(code[nextquad-START_ADDRESS],"%d\tif %s < %s goto ",nextquad,$1->place,$3->place);
					Gen();
					sprintf(code[nextquad-START_ADDRESS],"%d\tgoto ",nextquad);
					Gen();
				}
	 | E '>' E	{
					$$=create_node();
					$$->True=Makelist(nextquad);
					$$->False=Makelist(nextquad+1);
					sprintf(code[nextquad-START_ADDRESS],"%d\tif %s > %s goto ",nextquad,$1->place,$3->place);
					Gen();
					sprintf(code[nextquad-START_ADDRESS],"%d\tgoto ",nextquad);
					Gen();
				}
	 | E		{
					$$=create_node();
					$$->True=Makelist(nextquad);
					$$->False=Makelist(nextquad+1);
					sprintf(code[nextquad-START_ADDRESS],"%d\tif %s goto ",nextquad,$1->place);
					Gen();
					sprintf(code[nextquad-START_ADDRESS],"%d\tgoto ",nextquad);
					Gen();
				}
	 ;

M:	{$$=create_node(); $$->quad=nextquad;};

N:	{
		$$=create_node();
		$$->next=Makelist(nextquad);
		sprintf(code[nextquad-START_ADDRESS],"%d\tgoto ",nextquad);
		Gen();
	};

%%

char* Newtemp()
{
	static int count=1;
	char* ch=(char*)malloc(sizeof(char)*5);
	sprintf(ch,"T%d",count++);
	return ch;
}

int* Makelist(int nquad)
{
	int* list=(int*)malloc(sizeof(int)*15);
	list[0]=nquad;
	list[1]=0;
	return list;
}

int* Merge(int* list1,int* list2)
{
	
	int* temp=list1,count1=0,count2=0,i=0;
	while(list1[count1]!=0) {count1++;}
	while(list2[count2]!=0)
	{
		list1[count1]=list2[count2];
		count1++;
		count2++;
	}
	return temp;
}

void Backpatch(int* list,int nquad)
{
	char addr[10];
	sprintf(addr,"%d",nquad);
	
	while(*list!=0)
	{
		int index = *list++ - START_ADDRESS;
		strcat(code[index],addr);
	}
}

void Gen()
{
	nextquad++;
}

void Initialize_rstack()
{
	int i=0;
	stringstream ss;
	string s;
	for(i=available_reg-1;i>=0;i--)
	{
	      ss<<i;
	      s = "R" + ss.str();
	      reg_stack.push(s);
	      ss.str("");
	}
}

string get_instruction(char op)
{
	string retval;
	switch(op)
	{
	    case '+' : 
		  retval = "ADD";
		  break;
	    case '-' : 
		  retval = "SUB";
		  break;
	    case '*' : 
		  retval = "MUL";
		  break;
	    case '/' : 
		  retval = "DIV";
		  break;
	}
	return retval;
}

void swap_rstack()
{
	string s1, s2;
	s1 = reg_stack.top();
	reg_stack.pop();
	s2 = reg_stack.top();
	reg_stack.pop();
	reg_stack.push(s1);
	reg_stack.push(s2);
}

void gencode(node *temp)
{
	string reg_name;
	node *leftchild = temp->left;
	node *rightchild = temp->right;
	if((leftchild==NULL) && (rightchild==NULL))
	{
	      if(temp->isLeftChild==1)
	      {  
		  	cout << "MOV " + reg_stack.top() + ", " + temp->place << endl;
	      }
	}
	else if(rightchild->registers==0)
	{
	      gencode(leftchild);
	      cout << get_instruction(temp->Operator) << " " << reg_stack.top() << ", " << rightchild->place << endl; 
	}
	else if((leftchild->registers>=1) && (rightchild->registers>=1) && (rightchild->registers < available_reg))
	{
	      gencode(leftchild);
	      reg_name = reg_stack.top();
	      reg_stack.pop();
	      gencode(rightchild);
	      cout << get_instruction(temp->Operator) << " " << reg_name << ", " << reg_stack.top() << endl;
	      reg_stack.push(reg_name);
	}
	else if((leftchild->registers>=1) && (rightchild->registers>=1) && (leftchild->registers < available_reg))
	{
	      swap_rstack();
	      gencode(rightchild);
	      reg_name = reg_stack.top();
	      gencode(leftchild);
	      cout << get_instruction(temp->Operator) << " " << reg_stack.top() << ", " << reg_name << endl;
	      reg_stack.push(reg_name);
	      swap_rstack();
	}
	else if((leftchild->registers >= available_reg) && (rightchild->registers >= available_reg))
	{
	      gencode(rightchild);
	      cout << "SD " << reg_stack.top() << ", " << "MEM" << memory_location_num << endl;
	      memory_location_num++;		//can also push variable in stack
	      gencode(leftchild);
	      memory_location_num--;
	      cout << get_instruction(temp->Operator) << " " << reg_stack.top() << ", " << "MEM" << memory_location_num << endl;
	}
}

int main(int argc, char *argv[])
{
	available_reg = atoi(argv[1]);
	Initialize_rstack();
	yyparse();

	cout << ".........................." << endl;
	return 0;
}

int calc_registers(node *temp)
{
    int retval,reg_for_left, reg_for_right;
    if((temp->left==NULL) && (temp->right==NULL))
    {
		if(temp->isLeftChild==1)
		{
			  retval = 1;
		}
		else
		{
			  retval = 0;
		}
    }
    else
    {	
	//left_child=1;
	reg_for_left = calc_registers(temp->left);
	//left_child=0;
 	reg_for_right = calc_registers(temp->right);
 	if(reg_for_left > reg_for_right)
 	{
	    retval = max(reg_for_left, reg_for_right+1);
	}
	else
	{
	    retval = max(reg_for_right, reg_for_left+1);
	}
    }
    printf("%s\t :\t %d\n",temp->place, retval);
    temp->registers = retval;
    return retval;
}
//use ? :
int max(int x, int y)
{
	int retval;
	if(x>y)
	{
	      retval = x;
	}
	else
	{
	      retval = y;
	}
	return retval;
}

node* create_node()
{
	node *n=(node *) malloc(sizeof(node));
	n->left = NULL;
	n->right = NULL;
	n->registers = 0;
	n->isLeftChild = 0;
	return n;
}

void yyerror(string str)
{
	cout << endl;
	cout << str;
}
