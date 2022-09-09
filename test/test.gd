extends Control

const URL := preload("res://url.gd")
const HTTP := preload("res://http.gd")
const DebugUtils := preload("res://debugutils.gd")
const Cookie := preload("res://cookie.gd")

var http: HTTP = null
@onready var bodyLabel := %Body as Label
@onready var statusLabel := %Status as Label


func _ready() -> void:
	test_cookie()


func _process(_delta: float) -> void:
	if not http:
		return

	var debug := DebugUtils.new()
	var busy := http.is_busy()
	var error := http.last_error
	var status := debug.get_enum_key("HTTPClient", "Status", http.get_status())
	var text := "busy: %s\nerror: %s\nstatus: %s" % [busy, error, status]

	statusLabel.text = text
	http.poll()


func test_cookie() -> void:
	const headers := ["Set-Cookie: a=A; HttpOnly", "Set-Cookie: bb=BB; HttpOnly"]

	var cookies := Cookie.make_from_response_headers(headers)
	assert(cookies[0].key == "a")
	assert(cookies[0].value == "A")
	assert(cookies[1].key == "bb")
	assert(cookies[1].value == "BB")

	var header := Cookie.make_string_from_cookies(cookies)
	assert(header == "cookie: a=A; bb=BB")

	var datetime := Cookie.get_unix_time_from_rfc7231("Wed, 21 Oct 2015 07:28:00 GMT")
	assert(datetime == 1445412480)

	var empty_time := Cookie.get_unix_time_from_rfc7231("")
	assert(not empty_time)

	var bad_time := Cookie.get_unix_time_from_rfc7231("jpt82j b2lohrvq")
	assert(not bad_time)

	var expired_cookie_header := "Set-Cookie: foo=bar; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var expired_cookie := Cookie.make_from_header(expired_cookie_header)
	assert(expired_cookie.expires == 1445412480)

	var max_age_cookie_header := "Set-Cookie: foo=bar; Max-Age=100; Expires=Wed, 21 Oct 2015 07:28:00 GMT"
	var now := Time.get_unix_time_from_system() as int
	var max_age_cookie := Cookie.make_from_header(max_age_cookie_header, now)
	var max_age_result := max_age_cookie.expires - now
	assert(max_age_result == 100)

	print_debug("OK")

func test_http() -> void:
	http = HTTP.new()
	const SAMPLE_URL := "https://httpbin.org/get"
	var url := URL.new()
	var err := url.parse(SAMPLE_URL)
	assert(err == OK)
	assert(url.to_string() == SAMPLE_URL)

	var body: PackedByteArray = await http.request(url)
	bodyLabel.text = body.get_string_from_utf8()

	assert(http.get_response_code() == 200)
	print_debug("OK")


func _on_http_test_pressed() -> void:
	test_http()
