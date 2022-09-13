class_name URL
extends RefCounted

var scheme := ""
var host := ""
var port := -1
var path := ""


# import from core/string/ustring.cpp: parse_url()
static func parse(url: String) -> URL:
	var base := url
	var r_scheme := ""
	var r_host := ""
	var r_port := -1
	var r_path := ""

	var pos := base.find("://")
	# Scheme
	if pos != -1:
		r_scheme = base.substr(0, pos + 3).to_lower()
		base = base.substr(pos + 3, base.length() - pos - 3)

	pos = base.find("/");
	# Path
	if pos != -1:
		r_path = base.substr(pos, base.length() - pos)
		base = base.substr(0, pos)

	# Host
	pos = base.find("@")
	if pos != -1:
		# Strip credentials
		base = base.substr(pos + 1, base.length() - pos - 1)

	if base.begins_with("["):
		# Literal IPv6
		pos = base.rfind("]")
		if pos == -1:
			return null

		r_host = base.substr(1, pos - 1)
		base = base.substr(pos + 1, base.length() - pos - 1)
	else:
		# Anything else
		if base.get_slice_count(":") > 2:
			return null

		pos = base.rfind(":")
		if pos == -1:
			r_host = base
			base = ""
		else:
			r_host = base.substr(0, pos)
			base = base.substr(pos, base.length() - pos)

	if r_host.is_empty():
		return null

	r_host = r_host.to_lower()
	# Port
	if base.begins_with(":"):
		base = base.substr(1, base.length() - 1)
		if !base.is_valid_int():
			return null

		r_port = base.to_int()
		if r_port < 1 || r_port > 65535:
			return null

	if r_port == -1:
		match r_scheme:
			"http://": r_port = 80
			"https://": r_port = 443

	var new_url := URL.new()
	new_url.scheme = r_scheme
	new_url.host = r_host
	new_url.port = r_port
	new_url.path = r_path
	return new_url


func _to_string() -> String:
	if port < 1 || port > 65535:
		return "%s%s%s" % [scheme, host, path]

	return "%s%s:%s%s%s" % [scheme, host, port, path]
