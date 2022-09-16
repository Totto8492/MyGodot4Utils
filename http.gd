class_name HTTP
extends RefCounted

enum Method {
	GET = HTTPClient.METHOD_GET,
	HEAD = HTTPClient.METHOD_HEAD,
	POST = HTTPClient.METHOD_POST,
	PUT = HTTPClient.METHOD_PUT,
	DELETE = HTTPClient.METHOD_DELETE,
}

var http := HTTPClient.new()
var current_url := URL.new()
var canceling := false
var cycle := 0

signal do_poll


func poll() -> int:
	if http.get_status() == HTTPClient.STATUS_DISCONNECTED:
		return OK

	var err := http.poll()
	emit_signal("do_poll")
	return err


func request(url: URL, method: Method = Method.GET, query: Dictionary = {}, headers: PackedStringArray = PackedStringArray(), body: String = "") -> Response:
	if is_busy():
		return Response.new(ERR_BUSY)

	var err := OK
	if is_reconnect_needed(url):
		cycle = 0
		current_url = url
		http.close()
		err = http.connect_to_host(url.host, url.port, url.scheme == "https://")
		if err:
			return Response.new(err)
	else:
		cycle += 1

	current_url = url
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		await do_poll
		if canceling:
			canceling = false
			return Response.new()

	var path_query := http.query_string_from_dict(query)
	if not path_query.is_empty():
		path_query = "?" + path_query

	err = http.request(method, url.path + path_query, headers, body)
	if err:
		return Response.new(err)

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		await do_poll
		if canceling:
			canceling = false
			return Response.new()

	if not http.has_response():
		return Response.new()

	var rb := PackedByteArray()
	while http.get_status() == HTTPClient.STATUS_BODY:
		var chunk = http.read_response_body_chunk()
		if chunk.size() == 0:
			await do_poll
			if canceling:
				canceling = false
				break

			continue

		rb.append_array(chunk)

	canceling = false
	return Response.new(OK, http.get_response_code(), http.get_response_headers(), rb)


func cancel() -> void:
	canceling = true
	cycle = 0
	current_url = URL.new()
	http.close()
	emit_signal("do_poll")


func is_busy() -> bool:
	match http.get_status():
		HTTPClient.STATUS_DISCONNECTED:
			return false
		HTTPClient.STATUS_CONNECTED:
			return false

	return true


func is_reconnect_needed(url: URL) -> bool:
	if http.get_status() == HTTPClient.STATUS_DISCONNECTED:
		return true

	return url.scheme != current_url.scheme || url.host != current_url.host || url.port != current_url.port


func get_status() -> int:
	return http.get_status()
