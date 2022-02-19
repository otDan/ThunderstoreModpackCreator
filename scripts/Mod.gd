extends Node

var enabled : bool
var mod : String
var creator : String
var version = {
	major = 0,
	minor = 0,
	patch = 0
}

func _init(var mod, var creator, var major, var minor, var patch, var enabled):
	self.enabled = enabled
	self.mod = mod
	self.creator = creator
	version["major"] = major
	version["minor"] = minor
	version["patch"] = patch

func get_mod_string() -> String:
	return self.creator + "-" + self.mod + "-" + str(self.version.major) + "." + str(self.version.minor) + "." + str(self.version.patch)
