extends SceneTree

func _init() -> void:
	await process_frame
	var qs := get_root().get_node_or_null("QualitySettings")
	if qs == null:
		printerr("FAIL: QualitySettings autoload missing")
		quit(1)
		return
	qs.apply_tier(qs.Tier.ULTRA, false)
	var vp := get_root()
	if not vp.use_taa:
		printerr("FAIL: ULTRA must preserve TAA")
		quit(1)
		return
	if vp.msaa_3d != Viewport.MSAA_DISABLED:
		printerr("FAIL: ULTRA must not stack MSAA_2X on top of TAA, got %d" % vp.msaa_3d)
		quit(1)
		return
	var u_cfg: Dictionary = qs.TIER_PROFILES[qs.Tier.ULTRA]
	if not u_cfg["ssao_half"]:
		printerr("FAIL: ULTRA SSAO should use half-res while keeping HIGH quality")
		quit(1)
		return
	if float(u_cfg["shadow_max_dist"]) > 180.0:
		printerr("FAIL: Shadow max distance should focus atlas density <= 180m, got %.1f" % float(u_cfg["shadow_max_dist"]))
		quit(1)
		return
	if not bool(u_cfg.get("shadow_blend_splits", false)):
		printerr("FAIL: ULTRA must keep shadow_blend_splits enabled to prevent hard cascade seam lines")
		quit(1)
		return
	if u_cfg["shadow_mode"] != DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS:
		printerr("FAIL: Expected 2-split seamless high-density shadow mode for smooth GTA V/VI shadows at low GPU cost")
		quit(1)
		return
	if u_cfg["shadow_quality"] != RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM:
		printerr("FAIL: Expected SOFT_MEDIUM 16-tap Vogel shadow filter")
		quit(1)
		return
	print("PASS: QualitySettings Tier.ULTRA eliminates MSAA+TAA redundancy & tightens shadows")
	quit(0)
