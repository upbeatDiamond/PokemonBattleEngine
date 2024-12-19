extends Node

enum CSState {
	BLANK,
	KEYWORD,
	SPACE,
	STRING,
	INTEGER,
	FLOAT,
	END_OF_LINE,
}

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
