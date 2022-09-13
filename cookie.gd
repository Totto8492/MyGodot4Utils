class_name Cookie
extends RefCounted

const EXPIRE_SESSION = -1
var key := ""
var value := ""
var expires := EXPIRE_SESSION
var domain := ""
var include_subdomain := false
var path := ""


func is_empty() -> bool:
	return key.is_empty()


func is_expired_at(time: int) -> bool:
	assert(time)
	return expires != EXPIRE_SESSION and expires <= time


func is_expired() -> bool:
	var now := Time.get_unix_time_from_system() as int
	return expires != EXPIRE_SESSION and expires <= now


func _match_domain(url: URL) -> bool:
	if url.host == domain:
		return true

	if include_subdomain and url.host.ends_with("." + domain):
		return true

	return false


func _match_path(url: URL) -> bool:
	# RFC 6265 5.1.4
	if url.path == path:
		return true

	if url.path.begins_with(path) and path.ends_with("/"):
		return true

	if url.path.begins_with(path) and path.find("/") == url.path.length() + 1:
		return true

	return false


func can_use_by(url: URL) -> bool:
	if not _match_domain(url):
		return false

	if not _match_path(url):
		return false

	return true


func _to_string() -> String:
	return str([key, value, expires, domain, path])


static func from_header(header: String, time: int) -> Cookie:
	var cookie := new()
	var header_name := header.get_slice(":", 0).to_lower()
	if header_name != "set-cookie":
		return new()

	var base := header.substr(header.find(":") + 1).strip_edges()
	var args := base.split("; ")
	var kv := args[0].split("=")
	cookie.key = kv[0]
	cookie.value = kv[1]
	args.remove_at(0)
	var max_age_time := 0
	for i in args:
		var k := i.get_slice("=", 0).to_lower()
		var v := i.get_slice("=", 1)
		if k == "expires":
			if cookie.expires != EXPIRE_SESSION:
				continue

			var expire_time := get_unix_time_from_rfc7231(v)
			cookie.expires = expire_time

		if k == "max-age":
			max_age_time = v.to_int()
			if max_age_time < 0 or str(max_age_time) != v:
				return null

			cookie.expires = time + max_age_time

		if k == "domain":
			cookie.domain = v.trim_prefix(".").trim_suffix(".")
			cookie.include_subdomain = true

		if k == "path":
			cookie.path = v

		if k == "samesite":
			# I'm very sorry! I didn't know the Public Suffix List!
			return null

	return cookie


static func array_from_response_headers(headers: PackedStringArray, request_url: URL, time: int) -> Array[Cookie]:
	var cookies: Array[Cookie] = []
	for i in headers:
		var cookie := from_header(i, time)
		if cookie.is_empty():
			continue

		if cookie.domain.is_empty():
			cookie.domain = request_url.host

		# RFC 6265 5.1.4
		if cookie.path.is_empty():
			# 1.
			var uri_path := request_url.path.get_slice("?", 0)

			# 2.
			if uri_path.is_empty() or not uri_path.begins_with("/"):
				cookie.path = "/"
				cookies.push_back(cookie)
				continue

			# 3.
			if not uri_path.contains("/"):
				cookie.path = "/"
				cookies.push_back(cookie)
				continue

			# 4.
			if uri_path.length() >= 2:
				cookie.path = uri_path.trim_suffix("/")
				cookies.push_back(cookie)
				continue

			cookie.path = uri_path

		cookies.push_back(cookie)

	return cookies


static func get_string_from_cookies(cookies: Array[Cookie], url: URL) -> String:
	var kvs: Array[String] = []
	for i in cookies:
		if not i.can_use_by(url):
			continue

		kvs.push_back("=".join([i.key, i.value]))

	if kvs.is_empty():
		return ""

	return "cookie: " + "; ".join(kvs)


static func get_unix_time_from_rfc7231(from: String) -> int:
	var regex_string := "^(?<week>\\w{3}), (?<day>\\d{2}) (?<month>\\w{3}) (?<year>\\d{4}) (?<hour>\\d{2}):(?<minute>\\d{2}):(?<second>\\d{2}) GMT$"
	var regex := RegEx.create_from_string(regex_string)
	var result := regex.search(from)
	if result == null:
		return 0

	var dict := {}
	for k in result.names:
		dict[k] = result.strings[result.names[k]]

	var monthly := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_idx := monthly.find(dict["month"]) + 1
	if month_idx == -1:
		return 0

	dict["month"] = str(month_idx)
	return Time.get_unix_time_from_datetime_dict(dict)
