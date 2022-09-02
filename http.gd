extends RefCounted

const URL := preload("res://url.gd")

enum Method {
	GET = HTTPClient.METHOD_GET,
	HEAD = HTTPClient.METHOD_HEAD,
	POST = HTTPClient.METHOD_POST,
	PUT = HTTPClient.METHOD_PUT,
	DELETE = HTTPClient.METHOD_DELETE,
}

var http := HTTPClient.new()
var current_url := URL.new()
var last_error := OK

signal do_poll


func poll() -> int:
	if http.get_status() == HTTPClient.STATUS_DISCONNECTED:
		return OK

	var err := http.poll()
	emit_signal("do_poll")
	return err


func request(url: URL, method: Method = Method.GET, query: Dictionary = Dictionary(), body: PackedStringArray = PackedStringArray()) -> PackedByteArray:
	last_error = OK

	if is_busy():
		last_error = ERR_BUSY
		return PackedByteArray()

	if is_reconnect_needed(url, current_url):
		http.close()

	current_url = url
	var err := OK
	err = http.connect_to_host(url.host, url.port, url.scheme == "https://")
	if err:
		last_error = err
		return PackedByteArray()

	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		await do_poll

	var path_query := http.query_string_from_dict(query)
	if not path_query.is_empty():
		path_query = "?" + path_query

	err = http.request(method, url.path + path_query, body)
	if err:
		last_error = err
		return PackedByteArray()

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		await do_poll

	if not http.has_response():
		return PackedByteArray()

	var rb := PackedByteArray()
	while http.get_status() == HTTPClient.STATUS_BODY:
		var chunk = http.read_response_body_chunk()
		if chunk.size() == 0:
			await do_poll
			continue

		rb.append_array(chunk)

	return rb


func is_busy() -> bool:
	match http.get_status():
		HTTPClient.STATUS_DISCONNECTED:
			return false
		HTTPClient.STATUS_CONNECTED:
			return false

	return true


func is_reconnect_needed(a: URL, b: URL) -> bool:
	return a.scheme != b.scheme || a.host != b.host || a.port != b.port


func has_error() -> bool:
	return last_error != OK


func get_status() -> int:
	return http.get_status()
