extends Node

const MAX_CONNECTIONS := 24
const MAX_CONNECTIONS_SAMESITE := 6
const MAX_REDIRECTIONS := 5
var connection_pool: Array[HTTP] = []
var cookies: Array[Cookie] = []


func _ready() -> void:
	for i in MAX_CONNECTIONS:
		connection_pool.push_back(HTTP.new())


func _process(_delta: float) -> void:
	for i in connection_pool:
		if i:
			i.poll()


func get_client_from_pool(url: URL) -> HTTP:
	var samesite := 0
	for i in connection_pool:
		if i.is_busy() and not i.is_reconnect_needed(url):
			samesite += 1

	if samesite > MAX_CONNECTIONS_SAMESITE:
		return null

	for i in connection_pool:
		if not i.is_busy() and not i.is_reconnect_needed(url):
			return i

	for i in connection_pool:
		if not i.is_busy():
			return i

	return null


func get_debug_info() -> Array[HTTP]:
	return connection_pool


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


func request(url: String, max_redirections: int = MAX_REDIRECTIONS) -> Response:
	var current_url := URL.parse(url)

	for i in max_redirections + 1:
		var http := get_client_from_pool(current_url)
		while not http:
			await get_tree().process_frame
			http = get_client_from_pool(current_url)

		var cookie_header := Cookie.make_string_from_cookies(cookies)
		var res: Response = await http.request(current_url, HTTP.Method.GET, {}, [cookie_header])
		if res.error:
			return res

		var new_cookies := Cookie.array_from_response_headers(res.headers, current_url)
		for c in new_cookies:
			remove_cookie(c.key, current_url)

		append_cookies(new_cookies)
		if res.code == 302:
			var location := res.get_header_by_name("location")
			current_url = URL.parse(location)
			continue

		return res

	return HTTP.Response.new(ERR_CONNECTION_ERROR)
