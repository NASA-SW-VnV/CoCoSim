grammar EM;


nlosoc	: ( NL |SEMI | COMMA)+;
nloc	: ( NL |COMMA )+; 
nlos	: ( NL | SEMI )+; 
soc     : ( SEMI | COMMA )+;

emfile 	
	: function+
	| script  
	;

script
	: contract?
	  nlosoc?
	  script_body
      nlosoc?
    ;
function
	: FUNCTION func_output? ID func_input? nloc
	  contract?
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
	:   script_body_item (nlosoc | EOF)
    |   script_body  script_body_item (nlosoc | EOF)
    ;
script_body_item
    :  statement 			
    |  annotation 		
    ;
body
    :   body_item (nlosoc | EOF)
    |   body  body_item (nlosoc | EOF)
    ;

body_item
    :  statement 			
    |  function 
    |  annotation 		
    ;
annotation
    : declare_type  
    ;
    
declare_type
    : ANNOT DeclareType ID COLON dataType nlos
    ;

DeclareType: 'DeclareType'
	;
dataType : BASETYPE (POW dimension)*
	;

dimension :ID | Integer
	;

BASETYPE
    : 'int' //| 'int8' | 'uint8' |'int16' | 'uint16' |'int32' | 'uint32'
    | 'real' //| 'single' | 'double'
    | 'bool' //| 'boolean'
    ;

contract :  CONTRACT  contract_item+ '%}'
	;
 
contract_item
	: CONST ID (COLON dataType)? EQ coco_expression SEMI 	#CONTRACT_CONST
    | VAR ID COLON dataType EQ coco_expression SEMI			#CONTRACT_VAR
    | ASSUME coco_expression SEMI							#CONTRACT_ASSUME
    | GUARANTEE coco_expression SEMI						#CONTRACT_GUARANTEE 
    | coco_mode												#CONTRACT_MODE
    | NL+													#CONTRACT_NL
  	;
coco_mode: MODE ID LPAREN require* ensure* RPAREN SEMI?
	;
require:
	 REQUIRE coco_expression nlos
    ;
ensure: ENSURE coco_expression nlos
	;  
	
coco_expression 
	: expression
	| NOT coco_expression
	| PRE coco_expression
	| coco_expression INIT coco_expression
	| coco_expression IMPLIES coco_expression
	| LPAREN nlosoc? coco_expression nlosoc? RPAREN
	| coco_expression LUS_NEQ coco_expression
	| coco_expression LUS_AND_OR coco_expression
	;
	
CONTRACT : '%{@contract';
CONST : 'const';
VAR : 'var';
ASSUME : 'assume';
GUARANTEE : 'guarantee';
MODE : 'mode';
REQUIRE : 'require';
ENSURE : 'ensure';
NOT : 'not';
PRE : 'pre';
INIT : '->';
IMPLIES : '=>';
LUS_NEQ : '<>';
LUS_AND_OR : 'and'|'or';

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
    :   assignment 
    |   notAssignment
    ;

assignment
    :   unaryExpression assignmentOperator notAssignment
    ;

assignmentOperator
    :   '=' 		
    ;
notAssignment
    :   relopOR
    ;

relopOR
    :   relopAND
    |   relopOR '||' relopAND
    ;
relopAND
    :   relopelOR
    |   relopAND '&&' relopelOR
    ;

relopelOR
    :   relopelAND
    |   relopelOR '|' relopelAND
    ;

relopelAND
    :   relopEQ_NE
    |   relopelAND '&' relopEQ_NE
    ;
relopEQ_NE
    :   relopGL
    |   relopEQ_NE '==' relopGL
    |   relopEQ_NE '~=' relopGL
    ;
relopGL
    :   plus_minus
    |   relopGL '<' plus_minus
    |   relopGL '>' plus_minus
    |   relopGL '<=' plus_minus
    |   relopGL '>=' plus_minus
    ;

plus_minus
    :   mtimes
    |   plus_minus '+' mtimes
    |   plus_minus '-' mtimes
    ;

mtimes
    :   mrdivide
    |   mtimes '*' mrdivide
    ;

mrdivide
    :   mldivide
    |   mrdivide '/' mldivide
    ;

mldivide
    :   mpower
    |   mldivide '\\' mpower
    ;

mpower
    :   times
    |   mpower '^' times
    ;

times
    :   rdivide
    |   times '.*' rdivide
    ;

rdivide
    :   ldivide
    |   rdivide './' ldivide
    ;

ldivide
    :   power
    |   ldivide '.\\' power
    ;

power
    :   colonExpression
    |   power '.^' colonExpression
    ;

colonExpression
    :   unaryExpression
    |   colonExpression ':' unaryExpression
    ;

unaryExpression
    :   postfixExpression
    |   unaryOperator unaryExpression
    ;

unaryOperator
    :   '&' | '*' | '+' | '-' | '~' | '!'
    ;


postfixExpression
    :   primaryExpression
    |   postfixExpression TRANSPOSE
    ;
TRANSPOSE :   ( '\'' | '.\'')
    ;

primaryExpression
    :   ID
	|	indexing
    |   constant
    |   '(' expression ')'  
    |   cell
	|   matrix   
    |   ignore_value
    ;

indexing
	:	fun_indexing
    |   cell_indexing
    |   struct_indexing
    ;
fun_indexing
	:	ID LPAREN function_parameter_list? RPAREN
	;

cell_indexing
	:	ID (LBRACE function_parameter_list RBRACE)+
	;	
	
struct_indexing
	:	ID 
    ( 
        DOT indexing
	)+
	;

function_parameter_list
	: function_parameter ( COMMA function_parameter )*
	;
function_parameter : notAssignment	| COLON	| ignore_value;
//**************************************************************
ignore_value : '~';
constant
    :   Integer
    |   Float
    |   String
    |   function_handle
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

String
	: '\'' ( ESC_SEQ | ~('\\'|'\'') )* '\''
//	: '\'' ( ESC_SEQ | ~('\\'|'%'|'\'') )* '\''
	;

fragment
EXPONENT
	: ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

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


//**************************************************************
cell	: LBRACE horzcat? ( nlos horzcat )* RBRACE ;
horzcat	:	expression ( COMMA? expression )*? ;
//**************************************************************
matrix	: LSBRACE horzcat ( nlos horzcat )* RSBRACE ;




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
//NL	: ('\r'? '\n')+  -> skip;
WS  : [ \t\r]+ -> skip;

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
LSBRACE	: '[';
RSBRACE	: ']';
AT	: '@';
ANNOT : '%@';
DOT	: '.';

