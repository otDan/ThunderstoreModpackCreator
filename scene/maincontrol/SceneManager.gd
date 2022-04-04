extends Node

# Instance the gdunzip script
var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
var yaml = preload("res://addons/godot-yaml/gdyaml.gdns").new()
var modClass = load('res://scripts/Mod.gd')

export(NodePath) var modDisplayPath
export(NodePath) var codeInputPath
export(NodePath) var responsePath
export(NodePath) var confirmPath
export(NodePath) var modExportPath

export(NodePath) var changePath
export(NodePath) var gridPath
export(NodePath) var scrollPath

export(NodePath) var editPopupPath

export(NodePath) var modpackNameEditPath
export(NodePath) var websiteEditPath
export(NodePath) var descriptionEditPath

export(NodePath) var majorPath
export(NodePath) var minorPath
export(NodePath) var patchPath

export(NodePath) var modpackNamePath
export(NodePath) var websitePath
export(NodePath) var descriptionPath
export(NodePath) var versionPath


onready var modDisplay : Control = get_node(modDisplayPath)
onready var codeInput : LineEdit = get_node(codeInputPath)
onready var response : Label = get_node(responsePath)
onready var confirm : Button = get_node(confirmPath)
onready var modExport : MarginContainer = get_node(modExportPath)

onready var change : Button = get_node(changePath)
onready var grid : GridContainer = get_node(gridPath)
onready var scroll : ScrollContainer = get_node(scrollPath)

onready var editPopup : ConfirmationDialog = get_node(editPopupPath)

onready var modpackNameEdit = get_node(modpackNameEditPath)
onready var websiteEdit = get_node(websiteEditPath)
onready var descriptionEdit : TextEdit = get_node(descriptionEditPath)

onready var major : SpinBox = get_node(majorPath)
onready var minor : SpinBox = get_node(minorPath)
onready var patch : SpinBox = get_node(patchPath)

onready var modpackName = get_node(modpackNamePath)
onready var website = get_node(websitePath)
onready var description = get_node(descriptionPath)
onready var version = get_node(versionPath)

onready var timer = $Timer

var mods : Array = []

func handleConfirm():
	confirm.disabled = true
	var input = codeInput.text
	if input == "":
		response("Input the exported code first.")
		return
	var error = $HTTPRequest.request("https://otdan.com/api/thunderstore?code=" + input)
	if error != OK:
		response("An error occured, try later if problem persists.")

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response : String = body.get_string_from_utf8()
	
	if response == "":
		response("Invalid code")
		return
	
	if response == '{"message":"Paste not found."}':
		response("Invalid code")
		return
	
	if response.begins_with("Cannot GET"):
		response("Invalid code")
		return
		
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
	change.visible = false
	delete_children(grid)

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()

func load_Profile(var profile : String):
	confirm.visible = false
	response.visible = false
	codeInput.editable = false
	modExport.visible = true
	change.visible = true
	
	var value = yaml.parse(profile).result as Dictionary
	var profileName = value["profileName"] 
	
	var mods = value["mods"]
	for loopMod in mods:
		
		if (loopMod["name"]) == "":
			continue
			
		var enabled = loopMod["enabled"]
		var creatorMod = loopMod["name"].split("-")
		var creator = creatorMod[0]
		var mod : String = creatorMod[1]
		var version = loopMod["version"]
		var major : int = version["major"]
		var minor : int = version["minor"]
		var patch : int = version["patch"]
		
		var modInstance = modClass.new(mod, creator, major, minor, patch, enabled)
		self.mods.append(modInstance)
		grid.add_child(modInstance.get_button())

func _on_CodeInput_text_changed(new_text : String):
	var workText : String = new_text
	if workText.length() > 15:
		workText = workText.substr(0, 15)
	if " " in workText:
		workText = workText.replace(" ", "")
		
	codeInput.text = workText
	response.text = ""
	response.visible = false
	codeInput.caret_position = workText.length()

func _on_Confirm_pressed() -> void:
	handleConfirm()
	
func _on_CodeInput_text_entered(new_text):
	if !confirm.disabled:
		handleConfirm()
	
func _on_Change_pressed():
	unload_Profile()
	
func _on_EditInfo_pressed():
	var screenSize = scroll.get_viewport_rect().size
	editPopup.popup_centered(Vector2(screenSize.x / 3, screenSize.y / 2))
	pass # Replace with function body.

func _on_ModDisplay_resized():
	var screenSize = scroll.get_viewport_rect().size
	scroll.rect_min_size = Vector2(screenSize.x / 2, screenSize.y / 2.3 - 50)
	
	grid.columns = screenSize.x / 240
	editPopup.hide()

func _on_Description_text_changed():
	var descriptionText = descriptionEdit.text
	if descriptionText.length() > 250:
		descriptionEdit.text = descriptionText.substr(0, 250)

func _on_ConfirmButton_pressed():
	editPopup.hide()
	pass # Replace with function body.
	
func _ready():
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	var previous_color : Color = modpackName.get_color("font_color_uneditable")
	timer.connect("timeout", self, "change_color_back", [previous_color])
	
func _on_files_dropped(files, screen):
	print(files)

func _on_ConfirmDialog_confirmed():
	modpackName.text = modpackNameEdit.text
	version.text = str(major.value) + "." + str(minor.value) + "." + str(patch.value)
	website.text = websiteEdit.text
	description.text = descriptionEdit.text

func _on_ExportButton_pressed():
	var outDictionary : Dictionary
	var outMods : Array
	for mod in mods:
		if mod.enabled:
			outMods.append(mod.get_mod_string())
	
	if change_color():
		return
	
	outDictionary["name"] = modpackName.text
	outDictionary["version_number"] = version.text
	outDictionary["website_url"] = website.text
	outDictionary["description"] = description.text
	outDictionary["dependencies"] = outMods
	var outJson = JSON.print(outDictionary, "\t")
	
#	var file = File.new()
#	file.open(exportPath.text + "\\manifest.json", file.WRITE)
#	file.store_line(outJson)
#	file.close()
	
	JavaScript.download_buffer(outJson.to_utf8(), "manifest.json")

func change_color() -> bool:
	var change : bool = false
	if modpackName.text == "":
		modpackName.add_color_override("font_color_uneditable", Color(1, 0, 0, 0.8))
		change = true
	if version.text == "":
		version.add_color_override("font_color_uneditable", Color(1, 0, 0, 0.8))
		change = true
	if website.text == "":
		website.add_color_override("font_color_uneditable", Color(1, 0, 0, 0.8))
		change = true
	if description.text == "":
		description.add_color_override("font_color_uneditable", Color(1, 0, 0, 0.8))
		change = true
		
	if change:
		timer.set_wait_time(1)
		timer.start()
		
	return change
	
func change_color_back(var previous_color):
	modpackName.add_color_override("font_color_uneditable", previous_color)
	version.add_color_override("font_color_uneditable", previous_color)
	website.add_color_override("font_color_uneditable", previous_color)
	description.add_color_override("font_color_uneditable", previous_color)
