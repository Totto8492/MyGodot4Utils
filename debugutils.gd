extends RefCounted


func get_enum_key_value(cls: StringName, name: StringName) -> Dictionary:
	var result := {}
	var constants := ClassDB.class_get_enum_constants(cls, name)
	for key in constants:
		var value := ClassDB.class_get_integer_constant(cls, key)
		result[key] = value

	return result


func get_enum_key(cls: StringName, name: StringName, value: int) -> String:
	var constants := ClassDB.class_get_enum_constants(cls, name)
	for key in constants:
		if ClassDB.class_get_integer_constant(cls, key) == value:
			return key

	return ""
