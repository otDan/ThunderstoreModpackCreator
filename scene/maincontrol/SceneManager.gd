extends Node

# Instance the gdunzip script
var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
var yaml = preload("res://addons/godot-yaml/gdyaml.gdns").new()
var modClass = load('res://scripts/Mod.gd')

export(NodePath) var modDisplayPath
export(NodePath) var codeInputPath
export(NodePath) var responsePath
export(NodePath) var confirmPath
export(NodePath) var resultPath
export(NodePath) var modExportPath

export(NodePath) var editPath
export(NodePath) var gridPath

onready var modDisplay : Control = get_node(modDisplayPath)
onready var codeInput : LineEdit = get_node(codeInputPath)
onready var response : Label = get_node(responsePath)
onready var confirm : Button = get_node(confirmPath)
onready var resultText : RichTextLabel = get_node(resultPath)
onready var modExport : MarginContainer = get_node(modExportPath)

onready var edit : Button = get_node(editPath)
onready var grid : GridContainer = get_node(gridPath)

var mods : Array
	
func _on_CodeInput_text_changed(new_text : String):
	codeInput.text = new_text.replace(" ", "")
	response.text = ""
	response.visible = false

func _on_Confirm_pressed() -> void:
	handleConfirm()
	
func _on_CodeInput_text_entered(new_text):
	handleConfirm()
	
func _on_Edit_pressed():
	unload_Profile()

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
			load_Profile(fileContent)
	else:
		response('Failed to load zip file.')

func response(var out : String):
	response.visible = true
	codeInput.text = ""
	response.text = out
	confirm.disabled = false
	
func unload_Profile():
	confirm.disabled = false
	confirm.visible = true
	codeInput.editable = true
	codeInput.text = ""
	modExport.visible = false
	edit.visible = false
	
func load_Profile(var profile : String):
	confirm.visible = false
	response.visible = false
	codeInput.editable = false
	modExport.visible = true
	edit.visible = true
	
	var value : Dictionary = yaml.parse(profile)
	var profileName = value["profileName"]
	
	var mods = value["mods"]
	for loopMod in mods:
		print(loopMod["name"])
		var enabled = loopMod["enabled"]
		var creatormod = loopMod["name"].split("-")
		if (loopMod["name"]) == "":
			continue
		var creator = creatormod[0]
		var mod = creatormod[1]
		var version = loopMod["version"]
		var major = version["major"]
		var minor = version["minor"]
		var patch = version["patch"]
		
		var modInstance = modClass.new(mod, creator, major, minor, patch, enabled)
		mods.append(modInstance)
		var modCheckButton : CheckButton = CheckButton.new()
		modCheckButton.set_name(modInstance.get_mod_string())
		modCheckButton.text = mod
		modCheckButton.pressed = enabled
		grid.add_child(modCheckButton)
#		print(modInstance.get_mod_string())
