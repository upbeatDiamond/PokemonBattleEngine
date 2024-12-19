extends Node

enum CSToken {
	ABSTRACT,
	AS,
	BASE,
	BOOL,
	BREAK,
	BYTE,
	CASE,
	CATCH,
	CHAR,
	CHECKED,
	CLASS,
	CONST,
	CONTINUE,
	DECIMAL,
	DEFAULT,
	DELEGATE,
	DO,
	DOUBLE,
	ELSE,
	ENUM,
	EVENT,
	EXPLICIT,
	EXTERN,
	FALSE,
	FINALLY,
	FIXED,
	FLOAT,
	FOR,
	FOREACH,
	GOTO,
	IF,
	IMPLICIT,
	IN,
	INT,
	INTERFACE,
}

enum CSState {
	BLANK, ## The initial state
	KEYWORD, ## Reserved words, or where they ought to be
	CLASS_NAME, ## Declaration of class name
	SPACE, ## Dummy state; used to cache/reset the symbol, and query next state
	STRING, ## While in a string, the only way out is an unescaped "
	STRING_ESCAPE, ## An escape character
	INTERPOLATED_STRING, ## Looks like $"...{x}", and can be replaced with str("...", x)
	INTEGER, ## A number with no fancy suffixes
	DECIMAL, ## A number with a decimal separator detected
	FLOAT, ## A DECIMAL followed by 'f'
	ARGUMENT, ## When waiting for type or 'out'
	ARGUMENT_TYPE, ## After an 'out', looks for type
	PARAMETER,
	END_OF_LINE,
}

const KEYWORDS := ["abstract", "as", "base", "bool", "break", "byte", "case", 
		"catch", "char", "checked", "class", "const", "continue", "decimal",
		"default", "delegate", "do", "double", "else", "enum", "event",
		"explicit", "extern", "false", "finally", "fixed", "float", "for",
		"foreach", "goto", "if", "implicit", "in", "int", "interface", 
		"internal", "is", "lock", "long", "namespace", "new", "null", "while",
		"object", "operator", "out", "override", "params", "private",
		"protected", "public", "readonly", "ref", "return", "sbyte", "sealed",
		"short", "sizeof", "stackalloc", "static", "string", "struct",
		"switch", "this", "throw", "true", "try", "typeof", "uint", "ulong",
		"unchecked", "unsafe", "ushort", "using", "virtual", "void", "volatile",
]

var scope := 1
var state := CSState.BLANK
var symbol := ""

func cs_to_gd(input_path:String, output_path:String):
	
	## Get access to the file, if exists.
	var file_exists = FileAccess.file_exists(input_path)
	assert(file_exists, str("File ", input_path, " does not exist?") )
	if not file_exists:
		return
	
	file_exists = FileAccess.file_exists(output_path)
	assert(not file_exists, str("File ", output_path, " already exists?") )
	if file_exists:
		return
	
	var input_file = FileAccess.open(input_path, FileAccess.READ)
	var output_file = FileAccess.open(output_path, FileAccess.WRITE_READ)
	
	scope = 1
	state = CSState.BLANK
	symbol = ""
	
	## So long as there is more data in the original file...
	while input_file.get_position() < input_file.get_length():
		## ... get the line, and iterate over its characters.
		var line = input_file.get_line().split()
		for char in line:
			pass ## Check for character category, then change state as a result.
	
	pass

func change_state(new_state:CSState):
	pass
