class_name Cookie extends RefCounted

var key := ""
var value := ""
var expires := ""
var domain := ""
var path := ""


func is_empty() -> bool:
	return key.is_empty()


static func make_from_header(header: String) -> Cookie:
	var cookie := new()
	var header_name := header.get_slice(":", 0).to_lower()
	if header_name != "set-cookie":
		return new()

	var base := header.get_slice(":", 1).strip_edges()
	var args := base.split("; ")
	var kv := args[0].split("=")
	cookie.key = kv[0]
	cookie.value = kv[1]
	return cookie


static func make_from_response_headers(headers: PackedStringArray) -> Array:
	var cookies := []
	for i in headers:
		var cookie := make_from_header(i)
		if not cookie.is_empty():
			cookies.push_back(cookie)

	return cookies


static func make_string_from_cookies(cookies: Array) -> String:
	var kvs := []
	for i in cookies:
		kvs.push_back("=".join([i.key, i.value]))

	return "cookie: " + "; ".join(kvs)
