class_name Response extends RefCounted

var error: int = OK
var code: int = 0
var headers: PackedStringArray = PackedStringArray()
var body: PackedByteArray = PackedByteArray()


func _init(_error: int = OK, _code: int = 0, _headers: PackedStringArray = PackedStringArray(), _body: PackedByteArray = PackedByteArray()) -> void:
	error = _error
	code = _code
	headers = _headers
	body = _body


func get_response_header_by_name(name: String) -> String:
	# Workaround, HTTPClient's get_response_headers() clear headers...
	for i in headers:
		var pos = i.find(":")
		var key := i.substr(0, pos).strip_edges().to_lower()
		if key == name.to_lower():
			return i.substr(pos + 1).strip_edges()

	return ""
