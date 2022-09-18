class_name HTTP
extends RefCounted

enum Method {
	GET = HTTPClient.METHOD_GET,
	HEAD = HTTPClient.METHOD_HEAD,
	POST = HTTPClient.METHOD_POST,
	PUT = HTTPClient.METHOD_PUT,
	DELETE = HTTPClient.METHOD_DELETE,
}

var _http := HTTPClient.new()
var _current_url := URL.new()
var _canceling := false
var _busy := false

signal do_poll


func poll() -> int:
	if _http.get_status() == HTTPClient.STATUS_DISCONNECTED:
		return OK

	var err := _http.poll()
	emit_signal("do_poll")
	return err


func request_with_callback(callback: Callable, url: URL, method: Method = Method.GET, query: Dictionary = {}, headers: PackedStringArray = PackedStringArray(), body: String = "") -> Response:
	if is_busy():
		return Response.new(ERR_BUSY)

	_busy = true
	var err := OK
	if is_reconnect_needed(url):
		_current_url = url
		_http.close()
		err = _http.connect_to_host(url.host, url.port, url.scheme == "https://")
		if err:
			_busy = false
			return Response.new(err)

	_current_url = url
	while _http.get_status() == HTTPClient.STATUS_CONNECTING or _http.get_status() == HTTPClient.STATUS_RESOLVING:
		await do_poll
		if _canceling:
			_canceling = false
			_busy = false
			return Response.new()

	var path_query := _http.query_string_from_dict(query)
	if not path_query.is_empty():
		path_query = "?" + path_query

	err = _http.request(method, url.path + path_query, headers, body)
	if err:
		_busy = false
		return Response.new(err)

	while _http.get_status() == HTTPClient.STATUS_REQUESTING:
		await do_poll
		if _canceling:
			_canceling = false
			_busy = false
			return Response.new()

	if not _http.has_response():
		return Response.new()

	var rb := PackedByteArray()
	while _http.get_status() == HTTPClient.STATUS_BODY:
		var chunk = _http.read_response_body_chunk()
		if chunk.size() == 0:
			await do_poll
			if _canceling:
				_canceling = false
				break

			continue

		var ret = callback.call(chunk)
		if ret is PackedByteArray:
			rb.append_array(ret as PackedByteArray)

	_canceling = false
	_busy = false
	return Response.new(OK, _http.get_response_code(), _http.get_response_headers(), rb)


func request(url: URL, method: Method = Method.GET, query: Dictionary = {}, headers: PackedStringArray = PackedStringArray(), body: String = "") -> Response:
	var callback := func(chunk: PackedByteArray):
		return chunk

	var res: Response = await request_with_callback(callback, url, method, query, headers, body)
	return res


func request_and_save_to_file(file_path: String, url: URL, method: Method = Method.GET, query: Dictionary = {}, headers: PackedStringArray = PackedStringArray(), body: String = "") -> Response:
	var file := File.new()
	var err := file.open(file_path, File.WRITE)
	if err:
		return Response.new(err)

	var callback := func(chunk: PackedByteArray):
		file.store_buffer(chunk)

	var res: Response = await request_with_callback(callback, url, method, query, headers, body)
	file.close()
	return res


func cancel() -> void:
	if _busy:
		_canceling = true
		emit_signal("do_poll")

	_current_url = URL.new()
	_http.close()


func is_busy() -> bool:
	return _busy


func is_reconnect_needed(url: URL) -> bool:
	if _http.get_status() == HTTPClient.STATUS_DISCONNECTED:
		return true

	return url.scheme != _current_url.scheme || url.host != _current_url.host || url.port != _current_url.port


func get_status() -> int:
	return _http.get_status()


func get_current_url() -> URL:
	return _current_url
