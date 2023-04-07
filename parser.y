%{
#include <iostream> // cerr, cout
#include <set> // set
#include "types.h"

using namespace std;
using namespace clukcs;

/* Prototype for a function defined by flex. */
void yylex_destroy();

void yyerror(const char *msg)
{
	cerr << msg << endl;
}

// prototype declaration for convert function
void convert(class symbol_table &symtab, struct parser_val &target, struct parser_val l_val, struct parser_val r_val, char operation);

// prototype declaration for undeclared_error function
void undeclared_error(string variable);

// The unique global symbol table.
symbol_table symtab;

%}

/* Put this into the generated header file, too */
%code requires {
  	#include "types.h"
  	#include "globals.h"
}

/* Semantic value for grammar symbols.  See definition in types.h */
%define api.value.type {clukcs::parser_val}

%token IDENTIFIER INT_LITERAL FLOAT_LITERAL CHAR_LITERAL
%token '+' '-' '*' '/' '%' '=' '(' ')' '{' '}' ';' INT FLOAT CHAR


/* Which non terminal is at the top of the parse tree? */
%start program

/* Precedence */
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UMINUS

%%

program: statement_list {
	cout << "Code:\n" << $1.code;
};

statement_list: statement_list statement {
	$$.code = $1.code + $2.code;
} | %empty {
	$$.code = ""; // code must be empty
};

statement: expression ';' {
	if ($1.addr == nullptr) { // if the expression is incorrect
		undeclared_error($1.code);
		$$.code = "";
	} else {
		$$.code = $1.code;
	}
} | '{' { symtab.push(); }  statement_list '}' {
	$$.code = $3.code;
	symtab.pop();
} | type IDENTIFIER '=' expression ';' {
	Symbol *symbol = symtab.get($2.code);
	if (symbol != nullptr) { // if the variable is already declared
		cerr << "cannot declare the same variable" << endl;
		$$.code = "";
	} else {
		if ($4.addr == nullptr) { // if the expression is incorrect
			undeclared_error($4.code);
			$$.code = "";
		} else {
			symtab.put($2.code, $1.type);
			// change the type
			struct parser_val new_val, l_val, r_val;
			l_val = $1;
			r_val = $4;
			$$.code = r_val.code;
			while (l_val.type < r_val.type) {
				new_val.addr = r_val.addr;
				r_val.type = static_cast<Type>(static_cast<int>(r_val.type) - 1);
				r_val.addr = symtab.make_temp(r_val.type);
				$$.code += r_val.addr->name() + (r_val.type == Type::Int ? " = float2int " : " = int2char ") + new_val.addr->name() + "\n";
			}
			while (l_val.type > r_val.type) {
				new_val.addr = r_val.addr;
				r_val.type = static_cast<Type>(static_cast<int>(r_val.type) + 1);
				r_val.addr = symtab.make_temp(r_val.type);
				$$.code += r_val.addr->name() + (r_val.type == Type::Int ? " = char2int " : " = int2float ") + new_val.addr->name() + "\n";
			}
			$$.code += $2.code + " = " + r_val.addr->name() + "\n";
			$2.code = ""; // identifier's code must be empty after declaration
		}
	}
} | type IDENTIFIER ';' {
	Symbol *symbol = symtab.get($2.code);
	if (symbol != nullptr) { // if the variable is already declared
		cerr << "cannot declare the same variable" << endl;
		$$.code = "";
	} else {
		symtab.put($2.code, $1.type);
		$$.code = "";
		$2.code = "";
	}
} | error ';' { // error is a special token defined by bison
	$$.code = "";
	yyerrok;
};

type: INT {
	$$.type = Type::Int;
} | FLOAT {
	$$.type = Type::Float;
} | CHAR {
	$$.type = Type::Char;
};

expression: expression '+' expression {
	convert(symtab, $$, $1, $3, '+');
} | expression '-' expression {
	convert(symtab, $$, $1, $3, '-');
} | expression '*' expression {
	convert(symtab, $$, $1, $3, '*');
} | expression '/' expression {
	convert(symtab, $$, $1, $3, '/');
} | expression '%' expression {
	if ($1.addr == nullptr || $3.addr == nullptr) { // if the expression is incorrect
		if ($1.addr == nullptr) {
			undeclared_error($1.code);
		}
		if ($3.addr == nullptr) {
			undeclared_error($3.code);
		}
		$$.code = "";
		$$.addr = nullptr;
		$$.type = Type::Unknown;
	} else {
		if ($1.type == Type::Float || $3.type == Type::Float) { // if the type is float
			cerr << "cannot use % to float" << endl;
			$$.code = "";
			$$.addr = nullptr;
			$$.type = Type::Unknown;
		} else {
			convert(symtab, $$, $1, $3, '%');
		}
	}
} | expression '=' expression {
	struct parser_val new_val, l_val, r_val;
	l_val = $1;
	r_val = $3;
	if (l_val.addr == nullptr || r_val.addr == nullptr) { // if the expression is incorrect
		if (l_val.addr == nullptr) {
			undeclared_error(l_val.code);
		}
		if (r_val.addr == nullptr) {
			undeclared_error(r_val.code);
		}
		$$.code = "";
		$$.addr = nullptr;
		$$.type = Type::Unknown;
	} else {
		$$.code = l_val.code + r_val.code;
		// change the type
		while (l_val.type < r_val.type) {
			new_val.addr = r_val.addr;
			r_val.type = static_cast<Type>(static_cast<int>(r_val.type) - 1);
			r_val.addr = symtab.make_temp(r_val.type);
			$$.code += r_val.addr->name() + (r_val.type == Type::Int ? " = float2int " : " = int2char ") + new_val.addr->name() + "\n";
		}
		while (l_val.type > r_val.type) {
			new_val.addr = r_val.addr;
			r_val.type = static_cast<Type>(static_cast<int>(r_val.type) + 1);
			r_val.addr = symtab.make_temp(r_val.type);
			$$.code += r_val.addr->name() + (r_val.type == Type::Int ? " = char2int " : " = int2float ") + new_val.addr->name() + "\n";
		}
		$$.type = l_val.type;
		$$.addr = l_val.addr;
		$$.code += l_val.addr->name() + " = " + r_val.addr->name() + "\n";
	}
} | '-' expression %prec UMINUS {
	if ($2.addr != nullptr) {
		$$.addr = symtab.make_temp($2.type);
		$$.code = $$.addr->name() + " = negate " + $2.addr->name() + "\n";
		$$.type = $2.type;
	} else { // if the expression is incorrect
		undeclared_error($2.code);
		$$.addr = nullptr;
		$$.code = "";
		$$.type = Type::Unknown;
	}
} | '(' expression ')' {
	if ($2.addr != nullptr) {
		$$.code = $2.code;
		$$.addr = $2.addr;
		$$.type = $2.type;
	} else { // if the expression is incorrect
		undeclared_error($2.code);
		$$.addr = nullptr;
		$$.code = "";
		$$.type = Type::Unknown;
	}
} | INT_LITERAL {
	$$.code = "";
	int val = stol($1.code);
	$$.addr = symtab.make_int_const(val);
	$$.type = Type::Int;
} | FLOAT_LITERAL {
	$$.code = "";
	float val = stof($1.code);
	$$.addr = symtab.make_float_const(val);
	$$.type = Type::Float;
} | CHAR_LITERAL {
	$$.code = "";
	char c = $1.code[1];
	$$.addr = symtab.make_char_const(c);
	$$.type = Type::Char;
} | IDENTIFIER {
	$$.addr = symtab.make_variable($1.code);
	if ($$.addr == nullptr) {
		$$.type = Type::Unknown;
		$$.code = $1.code;
	} else {
		$$.type = $$.addr->type();
		$$.code = "";
	}
};


%%

int main() {
	int result = yyparse();
	yylex_destroy();
	return result;
}

/**
 * @brief convert type to match type
 *
 * @param symtab symbol table to get identifiers
 * @param target target expression
 * @param l_val the expression to change a type
 * @param r_val the expression to change a type
 * @param operation operation (+, -, *, /, and %)
 */
void convert(class symbol_table &symtab, struct parser_val &target, struct parser_val l_val, struct parser_val r_val, char operation) {
	if (l_val.addr == nullptr || r_val.addr == nullptr) {
		if (l_val.addr == nullptr) {
			undeclared_error(l_val.code);
		}
		if (r_val.addr == nullptr) {
			undeclared_error(r_val.code);
		}
		target.code = "";
		target.addr = nullptr;
		target.type = Type::Unknown;
	} else {
		struct parser_val new_val;
		target.code = l_val.code + r_val.code;
		while (l_val.type < r_val.type) {
			new_val.addr = l_val.addr;
			l_val.type = static_cast<Type>(static_cast<int>(l_val.type) + 1);
			l_val.addr = symtab.make_temp(l_val.type);
			target.code += l_val.addr->name() + (l_val.type == Type::Int ? " = char2int " : " = int2float ") + new_val.addr->name() + "\n";
		}
		while (l_val.type > r_val.type) {
			new_val.addr = r_val.addr;
			r_val.type = static_cast<Type>(static_cast<int>(r_val.type) + 1);
			r_val.addr = symtab.make_temp(r_val.type);
			target.code += r_val.addr->name() + (r_val.type == Type::Int ? " = char2int " : " = int2float ") + new_val.addr->name() + "\n";
		}
		target.addr = symtab.make_temp(l_val.type);
		target.code += target.addr->name() + " = " + l_val.addr->name() + " " + operation + " " + r_val.addr->name() + "\n";
		target.type = target.addr->type();
	}
}

/**
 * @brief make a standard error for undeclared variables
 *
 * @param variable undeclared variable
 */
void undeclared_error(string variable) {
	static set<string> variables;
	variables.insert("");
	if (variables.find(variable) == variables.end()) {
		cerr << "'" << variable << "'" << " was not declared" << endl;
		variables.insert(variable);
	}
}
