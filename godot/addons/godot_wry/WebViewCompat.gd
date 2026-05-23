## WebViewCompat.gd
##
## A platform-aware WebView node that works identically on:
##   - Android   → delegates to the GodotWry Kotlin plugin (Android WebView)
##   - iOS       → uses the native WRY GDExtension (WKWebView)
##   - Desktop   → uses the native WRY GDExtension (WebView2 / WebKit / WebKitGTK)
##
## Drop this script onto any Control node where you want a WebView.
## Signals and method signatures exactly match the WRY GDExtension API so
## your GDScript code works unchanged on every platform.
##
## Usage:
##   var wv := $WebViewCompat     # <- this node has WebViewCompat.gd attached
##   wv.load_url("https://example.com")
##   wv.connect("ipc_message", _on_ipc_message)
##

@tool
extends Control
class_name WebViewCompat

# ---------------------------------------------------------------------------
# Signals — identical to the native WRY GDExtension
# ---------------------------------------------------------------------------
signal ipc_message(message: String)
signal page_load_started(url: String)
signal page_load_finished(url: String)

# ---------------------------------------------------------------------------
# Exported properties (match native WebView)
# ---------------------------------------------------------------------------
@export var url: String = ""
@export var html: String = ""
@export var transparent: bool = false
@export var autoplay: bool = false
@export var devtools: bool = false
@export var user_agent: String = ""
@export var incognito: bool = false
@export var full_window_size: bool = false
@export var forward_input_events: bool = false

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------
var _platform: String = ""
var _android_plugin = null        # GodotPlugin singleton on Android
var _android_id: int = -1         # WebView id returned by the plugin
var _native_webview = null        # Native WRY WebView node on desktop/iOS

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_platform = OS.get_name()

	if _platform == "Android":
		_init_android()
	else:
		_init_native()

func _init_android() -> void:
	if not Engine.has_singleton("GodotWry"):
		push_error(
			"WebViewCompat: GodotWry Android plugin not found.\n"
			+ "Make sure GodotWry.aar is in android/plugins/ and the plugin is "
			+ "enabled in Project > Export > Android > Plugins."
		)
		return

	_android_plugin = Engine.get_singleton("GodotWry")

	# Connect plugin signals to our own signals.
	_android_plugin.connect("ipc_message",        _on_android_ipc_message)
	_android_plugin.connect("page_load_started",  _on_android_load_started)
	_android_plugin.connect("page_load_finished", _on_android_load_finished)

	_android_id = _android_plugin.create()
	if _android_id < 0:
		push_error("WebViewCompat: Android plugin failed to create a WebView.")
		return

	# Apply initial rect.
	_sync_rect_to_plugin()

	# Load initial content.
	if url != "":
		load_url(url)
	elif html != "":
		load_html(html)

func _init_native() -> void:
	# The native WRY WebView class is registered by godot_wry.gdextension.
	# Check it exists (it won't on Android if the .gdextension is excluded).
	if not ClassDB.class_exists("WebView"):
		push_error(
			"WebViewCompat: Native 'WebView' class not found.\n"
			+ "Ensure the godot_wry GDExtension is compiled for this platform."
		)
		return

	_native_webview = ClassDB.instantiate("WebView")

	# Mirror our exported properties onto the native node before adding it.
	_native_webview.transparent    = transparent
	_native_webview.autoplay       = autoplay
	_native_webview.devtools       = devtools
	_native_webview.user_agent     = user_agent
	_native_webview.incognito      = incognito
	_native_webview.full_window_size = full_window_size
	_native_webview.forward_input_events = forward_input_events
	_native_webview.url            = url
	_native_webview.html           = html

	add_child(_native_webview)
	_native_webview.size_flags_horizontal = SIZE_EXPAND_FILL
	_native_webview.size_flags_vertical   = SIZE_EXPAND_FILL

	# Forward native signals to ours.
	_native_webview.connect("ipc_message",        func(m): ipc_message.emit(m))
	_native_webview.connect("page_load_started",  func(u): page_load_started.emit(u))
	_native_webview.connect("page_load_finished", func(u): page_load_finished.emit(u))

# ---------------------------------------------------------------------------
# Resize / visibility tracking
# ---------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if _platform == "Android" and _android_id >= 0:
		_sync_rect_to_plugin()

func _sync_rect_to_plugin() -> void:
	if _android_plugin == null or _android_id < 0:
		return

	var vp_size  := get_viewport().get_visible_rect().size
	var ctrl_pos := Vector2.ZERO
	var ctrl_size: Vector2

	if full_window_size:
		ctrl_size = vp_size
	else:
		ctrl_pos  = global_position
		ctrl_size = size

	_android_plugin.set_rect(
		_android_id,
		int(ctrl_pos.x), int(ctrl_pos.y),
		int(ctrl_size.x), int(ctrl_size.y)
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if _platform == "Android" and _android_id >= 0:
			_android_plugin.set_visible(_android_id, is_visible_in_tree())
		elif _native_webview:
			_native_webview.update_visibility()

# ---------------------------------------------------------------------------
# Public API — identical to the native WRY WebView class
# ---------------------------------------------------------------------------

func load_url(p_url: String) -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.load_url(_android_id, p_url)
	elif _native_webview:
		_native_webview.load_url(p_url)

func load_html(p_html: String) -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.load_html(_android_id, p_html)
	elif _native_webview:
		_native_webview.load_html(p_html)

func eval(js: String) -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.eval(_android_id, js)
	elif _native_webview:
		_native_webview.eval(js)

func post_message(message: String) -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.post_message(_android_id, message)
	elif _native_webview:
		_native_webview.post_message(message)

func reload() -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.reload(_android_id)
	elif _native_webview:
		_native_webview.reload()

func set_visible(p_visible: bool) -> void:
	visible = p_visible
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.set_visible(_android_id, p_visible)
	elif _native_webview:
		_native_webview.set_visible(p_visible)

func zoom(factor: float) -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.zoom(_android_id, factor)
	elif _native_webview:
		_native_webview.zoom(factor)

func focus() -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.focus(_android_id)
	elif _native_webview:
		_native_webview.focus()

func clear_all_browsing_data() -> void:
	if _platform == "Android":
		if _android_id >= 0: _android_plugin.clear_all_browsing_data(_android_id)
	elif _native_webview:
		_native_webview.clear_all_browsing_data()

func resize() -> void:
	_sync_rect_to_plugin()
	if _native_webview:
		_native_webview.resize()

func update_visibility() -> void:
	_notification(NOTIFICATION_VISIBILITY_CHANGED)

## Desktop/iOS only — no-op on Android.
func open_devtools() -> void:
	if _native_webview: _native_webview.open_devtools()

## Desktop/iOS only — no-op on Android.
func close_devtools() -> void:
	if _native_webview: _native_webview.close_devtools()

## Desktop/iOS only — always returns false on Android.
func is_devtools_open() -> bool:
	if _native_webview: return _native_webview.is_devtools_open()
	return false

## Desktop/iOS only — no-op on Android (use system print dialog).
func print() -> void:
	if _native_webview: _native_webview.print()

func focus_parent() -> void:
	if _native_webview: _native_webview.focus_parent()

# ---------------------------------------------------------------------------
# Android signal handlers → re-emit as our own signals
# ---------------------------------------------------------------------------
func _on_android_ipc_message(message: String) -> void:
	ipc_message.emit(message)

func _on_android_load_started(p_url: String) -> void:
	page_load_started.emit(p_url)

func _on_android_load_finished(p_url: String) -> void:
	page_load_finished.emit(p_url)

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
func _exit_tree() -> void:
	if _platform == "Android" and _android_id >= 0:
		_android_plugin.destroy(_android_id)
		_android_id = -1
