class_name Request
extends RefCounted

enum Method {
	GET = HTTPClient.METHOD_GET,
	HEAD = HTTPClient.METHOD_HEAD,
	POST = HTTPClient.METHOD_POST,
	PUT = HTTPClient.METHOD_PUT,
	DELETE = HTTPClient.METHOD_DELETE,
}

var url: URL
var method: Method
var query: Dictionary
var headers: PackedStringArray
var body: String
var file_path: String


func  _init(_url: URL, _method: Method = Method.GET, _query: Dictionary = {}, _headers: PackedStringArray = PackedStringArray(), _body: String = "") -> void:
	url = _url
	method = _method
	query = _query
	headers = _headers
	body = _body
	file_path = ""

static func from_string(_url: String, _method: Method = Method.GET, _query: Dictionary = {}, _headers: PackedStringArray = PackedStringArray(), _body: String = "") -> Request:
	var ret := new(URL.parse(_url), _method, _query, _headers, _body)
	return ret
