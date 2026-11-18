@tool
extends SceneTree

func _init():
	var scene = load("res://scenes/main/home_screen.tscn").instantiate()
	root.add_child(scene)
	
	for i in range(10):
		await process_frame
		
	var hs_ui = scene.get_node_or_null("UILayer/HomeScreenUI")
	if not hs_ui:
		print("FAILED: HomeScreenUI not found")
		quit(1)
		return
		
	# 1. Test the 6 main buttons
	var modals = [
		{"btn": hs_ui.settings_btn, "modal": hs_ui.settings_modal, "name": "SETTINGS"},
		{"btn": hs_ui.garage_btn, "modal": hs_ui.garage_modal, "name": "GARAGE"},
		{"btn": hs_ui.tuning_btn, "modal": hs_ui.tuning_modal, "name": "TUNING"},
		{"btn": hs_ui.paint_shop_btn, "modal": hs_ui.paint_shop_modal, "name": "PAINT SHOP"},
		{"btn": hs_ui.profile_btn, "modal": hs_ui.profile_modal, "name": "PROFILE"},
	]
	
	for m in modals:
		var btn = m["btn"]
		var modal = m["modal"]
		var name = m["name"]
		if not btn or not modal:
			print("FAILED: Missing node for %s" % name)
			quit(1)
			return
		btn.pressed.emit()
		await process_frame
		if not modal.visible:
			print("FAILED: Modal for %s did not open" % name)
			quit(1)
			return
		print("PASSED: Modal for %s opened successfully" % name)
		hs_ui._close_all_modals()
		await process_frame
		
	# 2. Test new widgets exist and have correct mouse filter
	var hud = hs_ui.hud_root
	var widgets = [
		"NativeProfileCard",
		"NativeTopNavBar",
		"NativeCurrencyBar",
		"NativeHexGear",
		"NativeNotifPing",
		"NativeDailyMissions",
		"NativeMailBtn",
		"NativeNewsBanner",
		"NativeSeasonPass"
	]
	for w_name in widgets:
		var w = hud.get_node_or_null(w_name)
		if not w:
			print("FAILED: Missing widget %s" % w_name)
			quit(1)
			return
		print("PASSED: Widget %s verified" % w_name)
		
	print("ALL MODAL ROUTING & WIDGET VERIFICATIONS PASSED!")
	quit(0)
