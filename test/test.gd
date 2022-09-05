extends Control

var Cookie := preload("res://cookie.gd")


func _ready() -> void:
	const headers := ["Set-Cookie: a=A; HttpOnly", "Set-Cookie: bb=BB; HttpOnly"]

	var cookies := Cookie.make_from_response_headers(headers)
	assert(cookies[0].key == "a")
	assert(cookies[0].value == "A")
	assert(cookies[1].key == "bb")
	assert(cookies[1].value == "BB")
	print(cookies)
	print_debug("OK")

	var header := Cookie.make_string_from_cookies(cookies)
	assert(header == "cookie: a=A; bb=BB")
	print(header)
	print_debug("OK")

	var datetime := Cookie.make_iso8601_from_rfc7231("Wed, 21 Oct 2015 07:28:00 GMT")
	assert(datetime == "2015-10-21T07:28:00")
	print(datetime)
	print_debug("OK")

	var empty_time := Cookie.make_iso8601_from_rfc7231("")
	assert(empty_time.is_empty())
	print_debug("OK")

	var bad_time := Cookie.make_iso8601_from_rfc7231("jpt82j b2lohrvq")
	assert(bad_time.is_empty())
	print_debug("OK")
