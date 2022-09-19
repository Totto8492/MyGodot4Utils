class_name Request
extends RefCounted

var url: URL
var method: HTTP.Method
var query: Dictionary
var headers: PackedStringArray
var body: String
var file_path: String


func  _init(_url: URL, _method: HTTP.Method = HTTP.Method.GET, _query: Dictionary = {}, _headers: PackedStringArray = PackedStringArray(), _body: String = "") -> void:
	url = _url
	method = _method
	query = _query
	headers = _headers
	body = _body
	file_path = ""

static func from_string(_url: String, _method: HTTP.Method = HTTP.Method.GET, _query: Dictionary = {}, _headers: PackedStringArray = PackedStringArray(), _body: String = "") -> Request:
	var ret := new(URL.parse(_url), _method, _query, _headers, _body)
	return ret
