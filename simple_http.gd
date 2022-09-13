extends Node

const MAX_CONNECTIONS := 24
const MAX_CONNECTIONS_SAMESITE := 6
const MAX_REDIRECTIONS := 5
var connection_pool: Array[HTTP] = []
var cookies: Array[Cookie] = []
var user_agent := ""


func _process(_delta: float) -> void:
	for i in connection_pool:
		if i:
			i.poll()


func get_client_from_pool(url: URL) -> HTTP:
	var samesite := 0
	for i in connection_pool:
		if i.is_busy() and not i.is_reconnect_needed(url):
			samesite += 1

	if samesite >= MAX_CONNECTIONS_SAMESITE:
		return null

	for i in connection_pool:
		if not i.is_busy() and not i.is_reconnect_needed(url):
			return i

	for i in connection_pool:
		if not i.is_busy():
			return i

	if connection_pool.size() < MAX_CONNECTIONS:
		var new_connection := HTTP.new()
		connection_pool.push_back(new_connection)
		return new_connection

	return null


func get_debug_info() -> PackedStringArray:
	var s: PackedStringArray = PackedStringArray()
	for i in connection_pool:
		var status := DebugUtils.get_enum_key("HTTPClient", "Status", i.get_status())
		s.append(i.current_url.host + ": " + str(status))

	return s


func has_cookie(key: String, url: URL) -> bool:
	for c in cookies:
		if c.key == key and c.can_use_by(url):
			return true

	return false


func get_cookie(key: String, url: URL) -> Cookie:
	for c in cookies:
		if c.key == key and c.can_use_by(url):
			return c

	return null


func remove_cookie(key: String, url: URL) -> bool:
	for i in cookies.size():
		if cookies[i].key == key and cookies[i].can_use_by(url):
			cookies.remove_at(i)
			return true

	return false


func append_cookies(new_cookies: Array[Cookie]) -> void:
	cookies.append_array(new_cookies)


func strip_expired_cookies(time: int) -> void:
	var new_cookies: Array[Cookie] = []
	new_cookies = cookies.filter(func(i: Cookie): return not i.is_expired_at(time))
	cookies = new_cookies


func request(url: String, method: HTTP.Method = HTTP.Method.GET, query: Dictionary = {}, custom_headers: PackedStringArray = PackedStringArray(), max_redirections: int = MAX_REDIRECTIONS) -> Response:
	var current_url := URL.parse(url)

	for i in max_redirections + 1:
		var http := get_client_from_pool(current_url)
		while not http:
			await get_tree().process_frame
			http = get_client_from_pool(current_url)

		var time := Time.get_unix_time_from_system() as int
		strip_expired_cookies(time)

		var headers := custom_headers
		var cookie_header := Cookie.get_string_from_cookies(cookies, current_url)
		if not cookie_header.is_empty():
			headers.append(cookie_header)

		if not user_agent.is_empty():
			headers.append("User-Agent: " + user_agent)

		var res: Response = await http.request(current_url, method, query, headers)
		if res.error:
			return res

		var new_cookies := Cookie.array_from_response_headers(res.headers, current_url, time)
		for c in new_cookies:
			remove_cookie(c.key, current_url)

		append_cookies(new_cookies)
		if res.code == 302:
			var location := res.get_header_by_name("location")
			if location.is_empty():
				break

			if location.begins_with("http://") or location.begins_with("https://"):
				current_url = URL.parse(location)
				continue

			if location.begins_with("/"):
				current_url.path = location
				continue

			var pos := current_url.path.rfind("/")
			var base := current_url.path.substr(0, pos + 1)
			current_url.path = base + location
			continue

		return res

	return Response.new(ERR_CONNECTION_ERROR)
