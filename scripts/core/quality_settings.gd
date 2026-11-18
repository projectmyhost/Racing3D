extends Node

## Graphics Quality Settings Autoload conforming to DESIGN.md Â§16 and Â§18.

enum Tier { LOW = 0, MEDIUM = 1, HIGH = 2 }

signal tier_changed(tier: Tier)

@export var current_tier: Tier = Tier.MEDIUM

func _ready() -> void:
	apply_tier(current_tier)

func apply_tier(tier: Tier) -> void:
	current_tier = tier
	match tier:
		Tier.LOW:
			# Target: iGPU / GTX 750-class
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		Tier.MEDIUM:
			# Target: GTX 1050-1650 class
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
			get_viewport().msaa_3d = Viewport.MSAA_2X
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		Tier.HIGH:
			# Target: GTX 1660+
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
			get_viewport().msaa_3d = Viewport.MSAA_4X
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			
	tier_changed.emit(tier)

func set_tier_by_index(idx: int) -> void:
	apply_tier(clampi(idx, 0, 2) as Tier)
