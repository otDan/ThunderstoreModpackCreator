extends Node

# Instance the gdunzip script
var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()

onready var parent = get_tree().root
export(NodePath) var modDisplayPath
export(NodePath) var codeInputPath
export(NodePath) var responsePath
export(NodePath) var confirmPath
export(NodePath) var resultPath
export(NodePath) var modExportPath

onready var modDisplay : Control = get_node(modDisplayPath)
onready var codeInput : LineEdit = get_node(codeInputPath)
onready var response : Label = get_node(responsePath)
onready var confirm : Button = get_node(confirmPath)
onready var resultText : RichTextLabel = get_node(resultPath)
onready var modExport : MarginContainer = get_node(modExportPath)
	
func _on_CodeInput_text_changed(new_text):
	response.text = ""
	response.visible = false

func _on_Confirm_pressed() -> void:
	handleConfirm()

func _on_Code_text_entered(new_text):
	handleConfirm()

func handleConfirm():
	confirm.disabled = true
	var input = codeInput.text
	if input == "":
		response("Input the exported code first.")
		return
	var error = $HTTPRequest.request("https://r2modman-hastebin.herokuapp.com/documents/" + input)
	if error != OK:
		response("An error occured, try later if problem persists.")

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response : String = body.get_string_from_utf8()
	
	if response.length() < 100:
		response("Invalid code")
		return
		
	var parsed = response.split("#r2modman\\n")[1].split("\"}")[0]
	var poolByteZip = Marshalls.base64_to_raw(parsed)
	
	var file = File.new()
	file.open("user://profile.zip", file.WRITE)
	file.store_buffer(poolByteZip)
	file.close()
	
	var loadedProfile = gdunzip.load('user://profile.zip')
	
	if loadedProfile:
		var profileFile = gdunzip.uncompress('export.r2x')
		if !profileFile:
			response("Failed to load profile.")
		else:
			var fileContent = profileFile.get_string_from_utf8()
			resultText.text = fileContent
			loadedProfile(fileContent)
	else:
		response('Failed to load zip file.')

func response(var out : String):
	response.visible = true
	codeInput.text = ""
	response.text = out
	confirm.disabled = false
	pass
	
func loadedProfile(var profile : String):
	confirm.visible = false
	response.visible = false
	codeInput.editable = false
