#include<iostream>
#include<string>
#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<sstream>
#include<stack>

using namespace std;

typedef struct etype
{
	int* True;
	int* False;
	int* next;
	int quad;
	char place[5];
	
	char Operator;
	int registers;
	int isLeftChild;
	
	struct etype* left;
	struct etype* right;
}node;

typedef struct register_stack
{
	string reg;
	struct register_stack *next;
}rstack;

char* Newtemp();
int* Makelist(int nquad);
int* Merge(int* list1,int* list2);
void Backpatch(int* list,int nquad);
void Gen();
node* create_node();
int calc_registers(node *);
void gencode(node *);
void Initialize_rstack();



