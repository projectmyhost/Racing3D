# ASSET_REPLACEMENT_GUIDE.md â€” Asset Replacement Procedure
**Standard:** DESIGN.md Â§17

## 14-Step Replacement Procedure

1. **Identify**: Find the target asset file and note its ID in `docs/ASSET_MANIFEST.md`.
2. **Validate format**: GLB (glTF 2.0 binary), PNG, SVG, or TTF/OTF.
3. **Validate scale**: Units in meters. Showcase vehicle dimensions: 4.4â€“5.0 m length, 1.8â€“2.1 m width, ~1.34 m height.
4. **Validate orientation**: Y-up, -Z forward, origin at ground-contact center of wheelbase.
5. **Validate hierarchy**: Node contract names (Â§4.3) must match.
6. **Validate materials**: Slot names match standard `.tres` resources, <= 12 slots.
7. **Validate node names**: VisualRoot, Wheels (FrontLeft, FrontRight, RearLeft, RearRight), Headlights, Taillights, Body.
8. **Find references**: Search codebase for references to the old asset ID.
9. **Backup**: Copy existing assets to `docs/backups/<YYYYMMDD_HHMM>_<asset_id>/`.
10. **Replace**: Place the new asset at the specified path or update reference in the scene wrapper.
11. **Update Manifest**: Record new revision, source, triangle count in `docs/ASSET_MANIFEST.md`.
12. **Validate Scenes**: Check that no resources or materials are missing.
13. **Check Dependencies**: Confirm wheel spin, steering, paint tinting, and lights operate properly.
14. **Report**: Document changes, verification status, and visual captures.
