"""
RACEZONE - Avatar Portrait Generator
Generates at least 4 distinct 2D racing avatar portraits (256x256):
- avatar_1.png: Helmeted Driver
- avatar_2.png: Female Racer
- avatar_3.png: Veteran Driver
- avatar_4.png: Rookie Racer
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SCALE = 2 # Supersampling factor
SIZE = 256 * SCALE

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    return hex_to_rgb(h) + (a,)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def draw_frame_background(draw, accent_col):
    # Hexagonal / Chamfered racing portrait frame
    pad = 12 * SCALE
    chamfer = 28 * SCALE
    w, h = SIZE, SIZE

    frame_pts = [
        (pad + chamfer, pad), (w - pad - chamfer, pad),
        (w - pad, pad + chamfer), (w - pad, h - pad - chamfer),
        (w - pad - chamfer, h - pad), (pad + chamfer, h - pad),
        (pad, h - pad - chamfer), (pad, pad + chamfer)
    ]

    # Background gradient inside frame
    draw.polygon(frame_pts, fill=(24, 26, 38, 255))
    # Subtle diagonal racing stripes inside card
    for d in range(-h, w, 24 * SCALE):
        draw.line([(d, 0), (d + h, h)], fill=(32, 35, 52, 100), width=8 * SCALE)

    return frame_pts

def draw_frame_border(draw, frame_pts, accent_col):
    # Outer stroke
    draw.polygon(frame_pts, outline=(45, 48, 65, 255), width=4 * SCALE)
    # Inner accent corner highlights
    draw.line([frame_pts[0], frame_pts[1]], fill=accent_col, width=3 * SCALE)
    draw.line([frame_pts[4], frame_pts[5]], fill=accent_col, width=3 * SCALE)

def create_avatar_1(): # Helmeted Driver
    print("Generating avatar_1.png (Helmeted Driver)...")
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = SIZE // 2, SIZE // 2

    frame_pts = draw_frame_background(draw, hex_to_rgba("#FFB51B"))

    # Racing Suit Shoulders (bottom of portrait)
    suit_pts = [
        (40 * SCALE, SIZE - 12 * SCALE),
        (cx - 35 * SCALE, cy + 50 * SCALE),
        (cx + 35 * SCALE, cy + 50 * SCALE),
        (SIZE - 40 * SCALE, SIZE - 12 * SCALE)
    ]
    draw.polygon(suit_pts, fill=(235, 238, 245, 255))
    # Red racing harness / stripes
    draw.polygon([
        (cx - 30 * SCALE, cy + 50 * SCALE), (cx - 15 * SCALE, cy + 50 * SCALE),
        (cx - 45 * SCALE, SIZE - 12 * SCALE), (cx - 65 * SCALE, SIZE - 12 * SCALE)
    ], fill=(200, 35, 45, 255))
    draw.polygon([
        (cx + 15 * SCALE, cy + 50 * SCALE), (cx + 30 * SCALE, cy + 50 * SCALE),
        (cx + 65 * SCALE, SIZE - 12 * SCALE), (cx + 45 * SCALE, SIZE - 12 * SCALE)
    ], fill=(200, 35, 45, 255))

    # Helmet Outer Shell
    h_r = 62 * SCALE
    h_cy = cy - 8 * SCALE
    draw.ellipse([(cx - h_r, h_cy - h_r), (cx + h_r, h_cy + h_r)], fill=(245, 248, 252, 255))
    # Helmet Chin Bar
    chin_pts = [
        (cx - h_r + 6 * SCALE, h_cy),
        (cx + h_r - 6 * SCALE, h_cy),
        (cx + h_r * 0.7, h_cy + h_r * 0.95),
        (cx - h_r * 0.7, h_cy + h_r * 0.95)
    ]
    draw.polygon(chin_pts, fill=(240, 242, 248, 255))
    # Helmet Top Fin / Aero ridge
    draw.polygon([(cx - 8 * SCALE, h_cy - h_r - 4 * SCALE), (cx + 8 * SCALE, h_cy - h_r - 4 * SCALE),
                  (cx + 4 * SCALE, h_cy - h_r + 15 * SCALE), (cx - 4 * SCALE, h_cy - h_r + 15 * SCALE)],
                 fill=(200, 35, 45, 255))

    # Helmet Visor (Wide iridescent curved shield)
    visor_pts = [
        (cx - h_r + 8 * SCALE, h_cy - 16 * SCALE),
        (cx + h_r - 8 * SCALE, h_cy - 16 * SCALE),
        (cx + h_r - 12 * SCALE, h_cy + 22 * SCALE),
        (cx - h_r + 12 * SCALE, h_cy + 22 * SCALE)
    ]
    draw.polygon(visor_pts, fill=(20, 22, 30, 255))
    
    # Visor iridescent gold/amber reflection
    v_refl = [
        (cx - h_r + 12 * SCALE, h_cy - 12 * SCALE),
        (cx + 10 * SCALE, h_cy - 12 * SCALE),
        (cx - 15 * SCALE, h_cy + 16 * SCALE),
        (cx - h_r + 16 * SCALE, h_cy + 16 * SCALE)
    ]
    draw.polygon(v_refl, fill=(255, 185, 30, 220))
    # Bright specular glare streak
    draw.line([(cx - h_r + 25 * SCALE, h_cy - 8 * SCALE), (cx - 10 * SCALE, h_cy + 10 * SCALE)],
              fill=(255, 255, 255, 230), width=3 * SCALE)

    # Visor tear-off post & pivot screws
    draw.ellipse([(cx - h_r + 10 * SCALE, h_cy - 2 * SCALE), (cx - h_r + 18 * SCALE, h_cy + 6 * SCALE)], fill=(180, 190, 205, 255))
    draw.ellipse([(cx + h_r - 18 * SCALE, h_cy - 2 * SCALE), (cx + h_r - 10 * SCALE, h_cy + 6 * SCALE)], fill=(180, 190, 205, 255))

    # Chin vents
    for vx in [-18, -6, 6, 18]:
        draw.line([(cx + vx * SCALE, h_cy + 42 * SCALE), (cx + vx * SCALE, h_cy + 50 * SCALE)], fill=(30, 34, 46, 255), width=2 * SCALE)

    draw_frame_border(draw, frame_pts, (255, 181, 27, 255))
    im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS).save("assets/art/avatars/avatar_1.png", "PNG")
    print("-> Saved assets/art/avatars/avatar_1.png")

def create_avatar_2(): # Female Racer
    print("Generating avatar_2.png (Female Racer)...")
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = SIZE // 2, SIZE // 2

    frame_pts = draw_frame_background(draw, hex_to_rgba("#00D2D3"))

    # Racing Suit (Teal and Dark Navy)
    draw.polygon([
        (38 * SCALE, SIZE - 12 * SCALE),
        (cx - 30 * SCALE, cy + 58 * SCALE),
        (cx + 30 * SCALE, cy + 58 * SCALE),
        (SIZE - 38 * SCALE, SIZE - 12 * SCALE)
    ], fill=(24, 32, 48, 255))
    # Teal collar trim & chest badge
    draw.polygon([
        (cx - 24 * SCALE, cy + 58 * SCALE), (cx + 24 * SCALE, cy + 58 * SCALE),
        (cx + 10 * SCALE, SIZE - 12 * SCALE), (cx - 10 * SCALE, SIZE - 12 * SCALE)
    ], fill=(0, 210, 211, 255))

    # Neck
    draw.rectangle([(cx - 16 * SCALE, cy + 30 * SCALE), (cx + 16 * SCALE, cy + 62 * SCALE)], fill=(245, 195, 170, 255))

    # Head / Face
    draw.ellipse([(cx - 38 * SCALE, cy - 35 * SCALE), (cx + 38 * SCALE, cy + 38 * SCALE)], fill=(255, 205, 180, 255))
    # Chin taper
    draw.polygon([(cx - 32 * SCALE, cy + 15 * SCALE), (cx + 32 * SCALE, cy + 15 * SCALE),
                  (cx + 18 * SCALE, cy + 42 * SCALE), (cx - 18 * SCALE, cy + 42 * SCALE)], fill=(255, 205, 180, 255))

    # Hair (Dark brown/black stylish hair & high ponytail)
    # Back ponytail
    draw.polygon([(cx + 25 * SCALE, cy - 25 * SCALE), (cx + 72 * SCALE, cy - 10 * SCALE),
                  (cx + 65 * SCALE, cy + 35 * SCALE), (cx + 25 * SCALE, cy + 5 * SCALE)], fill=(40, 28, 24, 255))
    # Hair band (Teal)
    draw.ellipse([(cx + 28 * SCALE, cy - 18 * SCALE), (cx + 42 * SCALE, cy - 4 * SCALE)], fill=(0, 210, 211, 255))
    # Front hair bangs & sides
    draw.polygon([
        (cx - 42 * SCALE, cy - 15 * SCALE), (cx - 38 * SCALE, cy - 48 * SCALE),
        (cx + 38 * SCALE, cy - 48 * SCALE), (cx + 44 * SCALE, cy - 10 * SCALE),
        (cx + 25 * SCALE, cy - 15 * SCALE), (cx, cy - 18 * SCALE),
        (cx - 30 * SCALE, cy - 10 * SCALE)
    ], fill=(45, 32, 28, 255))

    # Eyes & Eyebrows (Confident expression)
    # Left eye
    draw.ellipse([(cx - 25 * SCALE, cy + 2 * SCALE), (cx - 11 * SCALE, cy + 10 * SCALE)], fill=(35, 40, 50, 255))
    draw.line([(cx - 27 * SCALE, cy - 4 * SCALE), (cx - 9 * SCALE, cy - 2 * SCALE)], fill=(40, 28, 24, 255), width=2 * SCALE)
    # Right eye
    draw.ellipse([(cx + 11 * SCALE, cy + 2 * SCALE), (cx + 25 * SCALE, cy + 10 * SCALE)], fill=(35, 40, 50, 255))
    draw.line([(cx + 9 * SCALE, cy - 2 * SCALE), (cx + 27 * SCALE, cy - 4 * SCALE)], fill=(40, 28, 24, 255), width=2 * SCALE)
    # Catchlight glints
    draw.point((cx - 18 * SCALE, cy + 5 * SCALE), fill=(255, 255, 255, 255))
    draw.point((cx + 18 * SCALE, cy + 5 * SCALE), fill=(255, 255, 255, 255))

    # Smile & Nose
    draw.line([(cx, cy + 12 * SCALE), (cx + 3 * SCALE, cy + 20 * SCALE)], fill=(215, 160, 135, 255), width=2 * SCALE)
    draw.line([(cx - 10 * SCALE, cy + 28 * SCALE), (cx + 10 * SCALE, cy + 28 * SCALE)], fill=(200, 90, 85, 255), width=2 * SCALE)

    # Communications Headset & Boom Mic
    # Headband
    draw.arc([(cx - 44 * SCALE, cy - 50 * SCALE), (cx + 44 * SCALE, cy + 10 * SCALE)], start=160, end=340, fill=(180, 185, 195, 255), width=3 * SCALE)
    # Earpiece (left ear)
    draw.ellipse([(cx - 46 * SCALE, cy - 2 * SCALE), (cx - 36 * SCALE, cy + 18 * SCALE)], fill=(25, 28, 38, 255), outline=(0, 210, 211, 255), width=2 * SCALE)
    # Boom mic curve towards mouth
    draw.line([(cx - 40 * SCALE, cy + 14 * SCALE), (cx - 22 * SCALE, cy + 30 * SCALE), (cx - 8 * SCALE, cy + 30 * SCALE)], fill=(180, 185, 195, 255), width=2 * SCALE)
    draw.ellipse([(cx - 8 * SCALE, cy + 27 * SCALE), (cx - 2 * SCALE, cy + 33 * SCALE)], fill=(30, 32, 42, 255))

    draw_frame_border(draw, frame_pts, (0, 210, 211, 255))
    im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS).save("assets/art/avatars/avatar_2.png", "PNG")
    print("-> Saved assets/art/avatars/avatar_2.png")

def create_avatar_3(): # Veteran Driver
    print("Generating avatar_3.png (Veteran Driver)...")
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = SIZE // 2, SIZE // 2

    frame_pts = draw_frame_background(draw, hex_to_rgba("#E58E26"))

    # Vintage Leather Racing Jacket (Warm Brown)
    draw.polygon([
        (38 * SCALE, SIZE - 12 * SCALE),
        (cx - 32 * SCALE, cy + 55 * SCALE),
        (cx + 32 * SCALE, cy + 55 * SCALE),
        (SIZE - 38 * SCALE, SIZE - 12 * SCALE)
    ], fill=(85, 52, 35, 255))
    # Cream racing stripes on jacket shoulder
    draw.polygon([(cx + 25 * SCALE, cy + 55 * SCALE), (cx + 38 * SCALE, cy + 55 * SCALE),
                  (SIZE - 45 * SCALE, SIZE - 12 * SCALE), (SIZE - 62 * SCALE, SIZE - 12 * SCALE)],
                 fill=(235, 225, 205, 255))

    # Neck
    draw.rectangle([(cx - 18 * SCALE, cy + 30 * SCALE), (cx + 18 * SCALE, cy + 60 * SCALE)], fill=(240, 185, 155, 255))

    # Head / Face (Strong jaw, subtle stubble)
    draw.ellipse([(cx - 40 * SCALE, cy - 35 * SCALE), (cx + 40 * SCALE, cy + 38 * SCALE)], fill=(250, 195, 165, 255))
    draw.polygon([(cx - 34 * SCALE, cy + 15 * SCALE), (cx + 34 * SCALE, cy + 15 * SCALE),
                  (cx + 24 * SCALE, cy + 44 * SCALE), (cx - 24 * SCALE, cy + 44 * SCALE)], fill=(250, 195, 165, 255))

    # Salt & Pepper Hair (Distinguished grey / charcoal)
    hair_pts = [
        (cx - 44 * SCALE, cy - 5 * SCALE), (cx - 42 * SCALE, cy - 48 * SCALE),
        (cx - 10 * SCALE, cy - 54 * SCALE), (cx + 30 * SCALE, cy - 52 * SCALE),
        (cx + 44 * SCALE, cy - 35 * SCALE), (cx + 42 * SCALE, cy - 5 * SCALE),
        (cx + 36 * SCALE, cy - 25 * SCALE), (cx + 10 * SCALE, cy - 32 * SCALE),
        (cx - 30 * SCALE, cy - 30 * SCALE)
    ]
    draw.polygon(hair_pts, fill=(115, 120, 130, 255))
    # Hair highlights (silver streaks)
    draw.line([(cx - 25 * SCALE, cy - 45 * SCALE), (cx + 20 * SCALE, cy - 45 * SCALE)], fill=(195, 200, 210, 255), width=2 * SCALE)

    # Eyes & Eyebrows (Focused, seasoned look)
    draw.line([(cx - 28 * SCALE, cy - 2 * SCALE), (cx - 10 * SCALE, cy - 6 * SCALE)], fill=(85, 90, 100, 255), width=3 * SCALE)
    draw.line([(cx + 10 * SCALE, cy - 6 * SCALE), (cx + 28 * SCALE, cy - 2 * SCALE)], fill=(85, 90, 100, 255), width=3 * SCALE)
    draw.ellipse([(cx - 24 * SCALE, cy + 4 * SCALE), (cx - 12 * SCALE, cy + 11 * SCALE)], fill=(40, 44, 52, 255))
    draw.ellipse([(cx + 12 * SCALE, cy + 4 * SCALE), (cx + 24 * SCALE, cy + 11 * SCALE)], fill=(40, 44, 52, 255))

    # Nose & Smirk
    draw.line([(cx, cy + 10 * SCALE), (cx - 2 * SCALE, cy + 22 * SCALE)], fill=(205, 150, 120, 255), width=2 * SCALE)
    # Confident slight smirk
    draw.line([(cx - 12 * SCALE, cy + 30 * SCALE), (cx + 14 * SCALE, cy + 28 * SCALE)], fill=(160, 95, 80, 255), width=2 * SCALE)

    # 5 o'clock shadow / stubble
    draw.polygon([(cx - 24 * SCALE, cy + 26 * SCALE), (cx + 24 * SCALE, cy + 26 * SCALE),
                  (cx + 20 * SCALE, cy + 43 * SCALE), (cx - 20 * SCALE, cy + 43 * SCALE)], fill=(140, 120, 110, 45))

    draw_frame_border(draw, frame_pts, (229, 142, 38, 255))
    im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS).save("assets/art/avatars/avatar_3.png", "PNG")
    print("-> Saved assets/art/avatars/avatar_3.png")

def create_avatar_4(): # Rookie Racer
    print("Generating avatar_4.png (Rookie Racer)...")
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = SIZE // 2, SIZE // 2

    frame_pts = draw_frame_background(draw, hex_to_rgba("#FF5E36"))

    # Bright Neon Orange Hoodie
    draw.polygon([
        (38 * SCALE, SIZE - 12 * SCALE),
        (cx - 30 * SCALE, cy + 54 * SCALE),
        (cx + 30 * SCALE, cy + 54 * SCALE),
        (SIZE - 38 * SCALE, SIZE - 12 * SCALE)
    ], fill=(255, 94, 54, 255))
    # Hoodie drawstring collar
    draw.ellipse([(cx - 26 * SCALE, cy + 45 * SCALE), (cx + 26 * SCALE, cy + 65 * SCALE)], fill=(35, 38, 48, 255))
    # White drawstrings
    draw.line([(cx - 10 * SCALE, cy + 55 * SCALE), (cx - 10 * SCALE, SIZE - 15 * SCALE)], fill=(250, 250, 250, 255), width=2 * SCALE)
    draw.line([(cx + 10 * SCALE, cy + 55 * SCALE), (cx + 10 * SCALE, SIZE - 25 * SCALE)], fill=(250, 250, 250, 255), width=2 * SCALE)

    # Neck
    draw.rectangle([(cx - 16 * SCALE, cy + 30 * SCALE), (cx + 16 * SCALE, cy + 55 * SCALE)], fill=(255, 210, 180, 255))

    # Face
    draw.ellipse([(cx - 36 * SCALE, cy - 30 * SCALE), (cx + 36 * SCALE, cy + 36 * SCALE)], fill=(255, 215, 185, 255))

    # Backward Racing Cap (Black with yellow trim)
    # Cap Dome
    draw.ellipse([(cx - 42 * SCALE, cy - 50 * SCALE), (cx + 42 * SCALE, cy - 10 * SCALE)], fill=(24, 26, 34, 255))
    # Cap Visor (pointing backward/up)
    draw.polygon([(cx - 30 * SCALE, cy - 46 * SCALE), (cx + 30 * SCALE, cy - 46 * SCALE),
                  (cx + 25 * SCALE, cy - 60 * SCALE), (cx - 25 * SCALE, cy - 60 * SCALE)], fill=(255, 181, 27, 255))
    # Front hair tufts peeking out from under cap
    draw.polygon([(cx - 32 * SCALE, cy - 20 * SCALE), (cx - 15 * SCALE, cy - 10 * SCALE),
                  (cx - 5 * SCALE, cy - 22 * SCALE), (cx + 12 * SCALE, cy - 8 * SCALE),
                  (cx + 28 * SCALE, cy - 22 * SCALE)], fill=(50, 35, 30, 255))

    # Sunglasses propped on cap
    draw.polygon([(cx - 32 * SCALE, cy - 38 * SCALE), (cx - 8 * SCALE, cy - 38 * SCALE),
                  (cx - 10 * SCALE, cy - 26 * SCALE), (cx - 30 * SCALE, cy - 26 * SCALE)], fill=(15, 18, 25, 255))
    draw.polygon([(cx + 8 * SCALE, cy - 38 * SCALE), (cx + 32 * SCALE, cy - 38 * SCALE),
                  (cx + 30 * SCALE, cy - 26 * SCALE), (cx + 10 * SCALE, cy - 26 * SCALE)], fill=(15, 18, 25, 255))
    draw.line([(cx - 8 * SCALE, cy - 32 * SCALE), (cx + 8 * SCALE, cy - 32 * SCALE)], fill=(255, 181, 27, 255), width=2 * SCALE)

    # Eyes (Youthful and eager)
    draw.ellipse([(cx - 22 * SCALE, cy + 2 * SCALE), (cx - 12 * SCALE, cy + 10 * SCALE)], fill=(35, 40, 50, 255))
    draw.ellipse([(cx + 12 * SCALE, cy + 2 * SCALE), (cx + 22 * SCALE, cy + 10 * SCALE)], fill=(35, 40, 50, 255))
    draw.point((cx - 16 * SCALE, cy + 5 * SCALE), fill=(255, 255, 255, 255))
    draw.point((cx + 18 * SCALE, cy + 5 * SCALE), fill=(255, 255, 255, 255))

    # Nose & Grin
    draw.line([(cx, cy + 10 * SCALE), (cx + 2 * SCALE, cy + 18 * SCALE)], fill=(215, 160, 130, 255), width=2 * SCALE)
    # Wide grin
    draw.polygon([(cx - 14 * SCALE, cy + 25 * SCALE), (cx + 14 * SCALE, cy + 25 * SCALE),
                  (cx + 10 * SCALE, cy + 32 * SCALE), (cx - 10 * SCALE, cy + 32 * SCALE)], fill=(255, 255, 255, 255))
    draw.line([(cx - 15 * SCALE, cy + 25 * SCALE), (cx + 15 * SCALE, cy + 25 * SCALE)], fill=(180, 70, 60, 255), width=2 * SCALE)

    draw_frame_border(draw, frame_pts, (255, 94, 54, 255))
    im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS).save("assets/art/avatars/avatar_4.png", "PNG")
    print("-> Saved assets/art/avatars/avatar_4.png")

if __name__ == "__main__":
    create_avatar_1()
    create_avatar_2()
    create_avatar_3()
    create_avatar_4()
    print("All avatar portraits generated successfully!")
