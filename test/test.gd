extends Control

@onready var simple_http := SimpleHTTP.new()
var http: HTTP = null
@onready var body_label := %Body as Label
@onready var status_label := %Status as Label
var last_status := ""


func _ready() -> void:
	test_cookie()
	test_path_contained_cookie()
	add_child(simple_http)


func _process(_delta: float) -> void:
	var debug_info := simple_http.get_debug_info()
	status_label.text = "\n".join(debug_info)

	if not http:
		return

	var debug := DebugUtils.new()
	var busy := http.is_busy()
	var status := debug.get_enum_key("HTTPClient", "Status", http.get_status())
	var text := "busy: %s\nstatus: %s" % [busy, status]

	status_label.text = text
	http.poll()


func test_cookie() -> void:
	const headers := ["Set-Cookie: a=A; HttpOnly", "Set-Cookie: bb=BB; HttpOnly"]
	var example_url := URL.parse("https://example.com/")
	var example_url_with_path := URL.parse("https://example.com/foobar")
	var bad_url := URL.parse("https://example.org/")
	var time := Time.get_unix_time_from_system() as int
	var cookies := Cookie.array_from_response_headers(headers, example_url, time)
	assert(cookies[0].key == "a")
	assert(cookies[0].value == "A")
	assert(cookies[1].key == "bb")
	assert(cookies[1].value == "BB")
	assert(cookies[0].can_use_by(example_url))
	assert(cookies[0].can_use_by(example_url_with_path))
	assert(not cookies[0].can_use_by(bad_url))

	var header := Cookie.get_string_from_cookies(cookies, example_url)
	assert(header == "cookie: a=A; bb=BB")

	var bad_header := Cookie.get_string_from_cookies(cookies, bad_url)
	assert(bad_header.is_empty())

	var datetime := Cookie.get_unix_time_from_rfc7231("Wed, 21 Oct 2015 07:28:00 GMT")
	assert(datetime == 1445412480)

	var empty_time := Cookie.get_unix_time_from_rfc7231("")
	assert(not empty_time)

	var bad_time := Cookie.get_unix_time_from_rfc7231("jpt82j b2lohrvq")
	assert(not bad_time)

	var expired_cookie_header := "Set-Cookie: foo=bar; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var expired_cookie := Cookie.from_header(expired_cookie_header, time)
	assert(expired_cookie.expires == 1445412480)

	var max_age_cookie_header := "Set-Cookie: foo=bar; Max-Age=100; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var now := Time.get_unix_time_from_system() as int
	var max_age_cookie := Cookie.from_header(max_age_cookie_header, now)
	assert(not max_age_cookie.is_expired_at(now))
	var max_age_result := max_age_cookie.expires - now
	assert(max_age_result == 100)

	print_debug("OK")


func test_path_contained_cookie() -> void:
	var url := URL.parse("https://example.com/efg/")
	var header := "Set-Cookie: abc=def"
	var time := Time.get_unix_time_from_system() as int
	var cookie := Cookie.array_from_response_headers([header], url, time)
	assert(cookie.size() == 1)
	assert(cookie[0].path == "/efg")

	print_debug("OK")


func test_http() -> void:
	http = HTTP.new()
	const SAMPLE_URL := "https://httpbin.org/get"
	var url := URL.parse(SAMPLE_URL)
	assert(url != null)
	assert(url.to_string() == SAMPLE_URL)

	var res: Response = await http.request(Request.new(url))

	body_label.text = res.body.get_string_from_utf8()
	assert(res.code == 200)
	print_debug("OK")


func test_http_and_cookie() -> void:
	const SAMPLE_URL := "https://httpbin.org/cookies/set?freeform=foo"
	var res: Response = await simple_http.request(Request.from_string(SAMPLE_URL))
	var freeform_cookie: Cookie = simple_http.get_cookie("freeform", URL.parse(SAMPLE_URL))

	body_label.text = res.body.get_string_from_utf8()
	assert(freeform_cookie)
	assert(freeform_cookie.value == "foo")
	assert(res.code == 200)
	print_debug("OK")


func _on_http_test_pressed() -> void:
	test_http()


func _on_http_and_cookie_test_pressed() -> void:
	test_http_and_cookie()


func _on_http_reset_pressed() -> void:
	simple_http.close_all()
