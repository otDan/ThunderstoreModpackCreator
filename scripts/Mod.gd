extends Node

var enabled : bool
var mod : String
var creator : String
var version = {
	major = 0,
	minor = 0,
	patch = 0
}
var modCheckButton : CheckButton

func _init(var mod, var creator, var major, var minor, var patch, var enabled):
	self.enabled = enabled
	self.mod = mod
	self.creator = creator
	version["major"] = major
	version["minor"] = minor
	version["patch"] = patch
	modCheckButton = CheckButton.new()
	modCheckButton.set_name(get_mod_string())
	if mod.length() > 15:
		modCheckButton.text = mod.substr(0, 15)
	else:
		modCheckButton.text = mod
	modCheckButton.pressed = enabled

func get_mod_string() -> String:
	return self.creator + "-" + self.mod + "-" + str(self.version.major) + "." + str(self.version.minor) + "." + str(self.version.patch)

func get_button() -> CheckButton:
	return modCheckButton
