grammar EM;

@members{
	int isIndex = 0;
}


nlosoc	: ( NL |SEMI | COMMA)+;
nloc	: ( NL |COMMA )+; 
nlos	: ( NL | SEMI )+; 
soc     : ( SEMI | COMMA );


emfile 	
	: function+ 
	| script  
	;

script
	: 
	nlosoc?
	script_body
	nlosoc?
    ;
function
	: NL* FUNCTION func_output? ID func_input? nloc
	  body?
	  END?
	  nlosoc?
	;

func_input
	: LPAREN ( (ID|'~') COMMA? )* RPAREN 
	;
 
func_output
	: ID EQ                             
	| LSBRACE (ID COMMA?)*? RSBRACE EQ  
	;

script_body
	:   statement (nlosoc | EOF)
    |   script_body  statement (nlosoc | EOF)
    ;
body
    :   body_item (nlosoc | EOF)
    |   body  body_item  (nlosoc | EOF)
    ;

//exp_sep :  (NL|','|';')+;

body_item
    :   statement 			
    |  function 
    ;

statement
    : expression
    | if_block
    | switch_block
	| for_block
	| while_block
    | try_catch_block
	| return_exp
	| break_exp
	| continue_exp
	| clear_exp
	| global_exp
	| persistent_exp
   
    ;

// *****************************************************************************************   expressionList       ***********************************************

    

expression
    : assignment 
    | notAssignment 
    ;

assignment
    :   primaryExpression '='  notAssignment
    ;

notAssignment
    : primaryExpression					   					# notAssignment_primaryExpression
    | notAssignment ( '\'' | '.\'')						    #  postfixExpression
    | notAssignment '.^' notAssignment						#  power
    | notAssignment '^' notAssignment						#  mpower
    | notAssignment '.*' notAssignment						#  times
    | notAssignment './' notAssignment						#  rdivide
    | notAssignment '.\\' notAssignment						#  ldivide
    | notAssignment '*' notAssignment						#  mtimes
    | notAssignment '/' notAssignment						#  mrdivide
    | notAssignment '\\' notAssignment						#  mldivide
    | notAssignment ('+'|'-') notAssignment					#  plus_minus
    | notAssignment ('=='|'~=') notAssignment				#  relopEQ_NE
    | notAssignment ('<'|'>'|'<='|'>=') notAssignment		#  relopGL
    | unaryOperator primaryExpression 						#  unaryExpression
    | notAssignment COLON  notAssignment   					#  colonExpression
    | notAssignment '&' notAssignment						#  relopelAND
    | notAssignment '|' notAssignment						#  relopelOR
    | notAssignment '&&' notAssignment						#  relopAND
    | notAssignment '||' notAssignment						#  relopOR
    ;
    
unaryOperator
    :  '+' | '-' | '~' | '!'
    ;



    
primaryExpression
    :   struct_indexing
    |   constant
    |   cell
	|   matrix   
    | 	ignore_value
    ;



struct_indexing
	:  
	 struct_indexing DOT struct_indexing  	   # struct_indexing_expr
	| fun_indexing 							   # s_fun_indexing
	| cell_indexing 							   # s_cell_indexing
	| parenthesedExpression					   # s_parenthesedExpression
	| ID 									   # s_id
	;
parenthesedExpression :'(' notAssignment ')'   ;

fun_indexing
	:	(ID | cell_indexing) LPAREN function_parameter_list? RPAREN
	;

cell_indexing
	:	ID (LBRACE function_parameter_list RBRACE)+
	;	

	
function_parameter_list
	: { isIndex = 1; } function_parameter ( COMMA function_parameter )* { isIndex = 0; }
	;
function_parameter : notAssignment	| COLON	| ignore_value;
//**************************************************************
ignore_value : '~';
constant
    :   Integer
    |   Float
    | {isIndex == 1}? END
    |   string
    |   function_handle
    ;
string
	: '\'' ~('\'')* '\''  
	//  '\'' ( ESC_SEQ | '\'\'' | ~('\\'|'\'' | '\n' | '\r') )* '\''
	;
	
function_handle
	: AT ID 
	| AT func_input expression?
	;
 

Integer : '0'..'9'+ ;

Float
	: ('0'..'9')+ '.' ('0'..'9')* EXPONENT?
	| '.' ('0'..'9')+ EXPONENT?
	| ('0'..'9')+ EXPONENT
	;

//TRANSPOSE : ( '\'' | '.\'');

fragment
EXPONENT
	: ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

/*
fragment
ESC_SEQ
	: '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
	| UNICODE_ESC
	| OCTAL_ESC
	;

fragment
OCTAL_ESC
	: '\\' ('0'..'3') ('0'..'7') ('0'..'7')
	| '\\' ('0'..'7') ('0'..'7')
	| '\\' ('0'..'7')
	;

fragment
UNICODE_ESC
	: '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
	;
fragment
HEX_DIGIT
	: ('0'..'9'|'a'..'f'|'A'..'F') ;
*/

//**************************************************************
cell	: LBRACE horzcat? ( nlos horzcat )* RBRACE ;

// Do not use notAssignement instead of primaryExpression, 
// we do not support binary expression with not parentheses.
//e.g, [x-y] Vs [x -y], the first has one element "(x-y)", the second has two elements "x" and "-y".
horzcat	
	: primaryExpression ( primaryExpression)*
	| notAssignment ( COMMA notAssignment)* 
	;
	
	//{_input.LT(-1).getType() == WS || _input.LT(-1).getType() == COMMA}?
//**************************************************************
matrix	: LSBRACE   horzcat (  nlos  horzcat )*  RSBRACE ;




// *****************************************************************************************   selectionStatement       ***********************************************
if_block
	: IF notAssignment nlosoc body? elseif_block* else_block? END 
	;

elseif_block
	: ELSEIF notAssignment nlosoc body? 
	;
	
else_block
	: ELSE nlosoc body? 
	;
//**************************************************************
switch_block
	: SWITCH notAssignment nlosoc case_block* otherwise_block? END 
	;
	
case_block
	: CASE notAssignment nlosoc body? 
	;

otherwise_block
	: OTHERWISE nlosoc body? 
	;

// *****************************************************************************************   iterations       ***********************************************
for_block
	: FOR ID EQ notAssignment nlosoc body? END
	;
	
while_block
	: WHILE notAssignment nlosoc body? END 
	;
	
// *****************************************************************************************   Other statements       ***********************************************	
try_catch_block
	: TRY nlosoc body? catch_block? END
	;
	
catch_block
    : CATCH ID? nlosoc body?
	;
	
return_exp
	: RETURNS 
	;

break_exp
	: BREAK 
	;
	
continue_exp
	: CONTINUE 
	;

global_exp
	: GLOBAL (ID COMMA?)+ 
	;

persistent_exp
	: PERSISTENT (ID COMMA?)+ 
	;

clear_exp
	: CLEAR (ID COMMA?)* 
	;




// *****************************************************************************************   Others       ***********************************************	
MULTILINECOMMENT
    :   '%{' ~['@'] .*?  '%}' -> skip
	;

LINECOMMENT
    :   '%' ~[@\r\n] ~[\r\n]* -> skip
    ;

THREEDOTS
	: ( '...' NL ) -> channel(HIDDEN)
	;



POW	: '^';
COMMA	: ',';
SEMI	: ';';
NL   : ('\r' '\n' | '\n' | '\r')+;
//NL	: ('\r'? '\n')+  ;//-> skip;
//WS : [ \t\r]+;
WS  : [ \t\r]+ -> skip; //{whitespace_cnt == 0}? -> skip;

// language keywords
BREAK	: 'break';
CASE	: 'case';
CATCH	: 'catch';
CONTINUE: 'continue';
ELSE	: 'else';
ELSEIF	: 'elseif';
END	: 'end';
FOR	: 'for';
FUNCTION: 'function';
GLOBAL	: 'global';
IF	: 'if';
OTHERWISE: 'otherwise';
PERSISTENT: 'persistent';
RETURNS	: 'return'; 
SWITCH	: 'switch';
TRY	: 'try';
VARARGIN: 'varargin';
WHILE	: 'while';
CLEAR	: 'clear';


COLON	: ':';

EQ	: '=';
ID	: ('a'..'z'|'A'..'Z') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')* ;


LPAREN	: '(';
RPAREN	: ')';
LBRACE	: '{';
RBRACE	: '}';
LSBRACE	: '[' ;//{whitespace_cnt = 1;};
RSBRACE	: ']' ;//{whitespace_cnt = 0;};
AT	: '@';
ANNOT : '%@';
DOT	: '.';

