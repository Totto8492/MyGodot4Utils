class_name Cookie extends RefCounted

var key := ""
var value := ""
var expires := ""
var domain := ""
var path := ""


func is_empty() -> bool:
	return key.is_empty()


func _to_string() -> String:
	return str([key, value, expires, domain, path])


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


static func make_iso8601_from_rfc7231(from: String) -> String:
	var regex_string := "^(?<week>\\w{3}), (?<day>\\d{2}) (?<month>\\w{3}) (?<year>\\d{4}) (?<hour>\\d{2}):(?<minute>\\d{2}):(?<second>\\d{2}) GMT$"
	var regex := RegEx.create_from_string(regex_string)
	var result := regex.search(from)
	if result == null:
		return ""

	var dict := {}
	for i in result.names:
		dict[i] = result.strings[result.names[i]]

	var monthly := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_idx := monthly.find(dict["month"]) + 1
	if month_idx == -1:
		return ""

	dict["month"] = str(month_idx)
	return Time.get_datetime_string_from_datetime_dict(dict, false)
