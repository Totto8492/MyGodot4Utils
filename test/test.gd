extends Control

var Cookie := preload("res://cookie.gd")


func _ready() -> void:
	const headers := ["Set-Cookie: a=A; HttpOnly", "Set-Cookie: bb=BB; HttpOnly"]

	var cookies := Cookie.make_from_response_headers(headers)
	assert(cookies[0].key == "a")
	assert(cookies[0].value == "A")
	assert(cookies[1].key == "bb")
	assert(cookies[1].value == "BB")
	print_debug("OK")

	var header := Cookie.make_string_from_cookies(cookies)
	assert(header == "cookie: a=A; bb=BB")
	print_debug("OK")

	var datetime := Cookie.get_unix_time_from_rfc7231("Wed, 21 Oct 2015 07:28:00 GMT")
	assert(datetime == 1445412480)
	print_debug("OK")

	var empty_time := Cookie.get_unix_time_from_rfc7231("")
	assert(not empty_time)
	print_debug("OK")

	var bad_time := Cookie.get_unix_time_from_rfc7231("jpt82j b2lohrvq")
	assert(not bad_time)
	print_debug("OK")

	var expired_cookie_header := "Set-Cookie: foo=bar; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var expired_cookie := Cookie.make_from_header(expired_cookie_header)
	assert(expired_cookie.expires == 1445412480)
	print_debug("OK")

	var max_age_cookie_header := "Set-Cookie: foo=bar; Max-Age=100; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var max_age_cookie := Cookie.make_from_header(max_age_cookie_header)
	var max_age_result := Time.get_unix_time_from_system() - max_age_cookie.expires
	assert(max_age_result <= 100)
	print_debug("OK")
