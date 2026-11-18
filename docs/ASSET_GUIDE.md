# ASSET_GUIDE.md â€” Sunset Street Racing Asset Standards
**Standard:** DESIGN.md Â§4, Â§5, Â§10, Â§14

## 1. 3D Asset Guidelines
- Units: 1 Godot unit = 1 meter.
- Coordinate system: +Y up, -Z forward, +X right.
- Origins: Ground-contact center of wheelbase for vehicles; ground base for props; world center for terrain.
- Budgets: Hero vehicle <= 120k tris (LOD0); fallback <= 6k tris; total scene tris on screen <= 600k (Medium).
- Materials: Max 12 material slots per vehicle. Shared `.tres` materials preferred over embedded materials.

## 2. Vehicle Node Hierarchy Contract
Any replacement vehicle must provide the following node names:
```
VehicleRoot (Node3D)
â”œâ”€â”€ VisualRoot (Node3D)
â”‚   â”œâ”€â”€ Body (MeshInstance3D)
â”‚   â”œâ”€â”€ Hood (MeshInstance3D)
â”‚   â”œâ”€â”€ FrontBumper (MeshInstance3D)
â”‚   â”œâ”€â”€ RearBumper (MeshInstance3D)
â”‚   â”œâ”€â”€ Spoiler (MeshInstance3D)
â”‚   â”œâ”€â”€ Windows (MeshInstance3D)
â”‚   â”œâ”€â”€ Headlights (Node3D)
â”‚   â”œâ”€â”€ Taillights (Node3D)
â”‚   â”œâ”€â”€ Mirrors (Node3D)
â”‚   â””â”€â”€ Wheels (Node3D)
â”‚       â”œâ”€â”€ FrontLeft (Node3D, pivot)
â”‚       â”œâ”€â”€ FrontRight (Node3D, pivot)
â”‚       â”œâ”€â”€ RearLeft (Node3D, pivot)
â”‚       â””â”€â”€ RearRight (Node3D, pivot)
â”œâ”€â”€ CollisionRoot (Node3D)
â”œâ”€â”€ WheelAnchors (Node3D)
â””â”€â”€ VehicleEffects (Node3D)
```

## 3. UI Guidelines
- Native Godot `Control` nodes positioned according to DESIGN.md Â§3.2.
- Skew angle: -12Â° for navigation buttons.
- Yellow highlight: #FFC928.
- Dark translucent panels: #15171D @ 75%-80% opacity.
- Responsive anchoring with 32 px safe margins.
