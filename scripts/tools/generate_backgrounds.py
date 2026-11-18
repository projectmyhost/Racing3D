"""
RACEZONE - Background Asset Generator
Generates layered 2D pit-lane & sunset circuit assets matching reference_home.png:
- sunset_sky.png
- city_skyline.png
- pit_lane_track.png
- floodlights.png
- fence_overlay.png
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter

WIDTH = 1672
HEIGHT = 941

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    return hex_to_rgb(h) + (a,)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def create_sunset_sky():
    print("Generating sunset_sky.png...")
    im = Image.new("RGBA", (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(im)

    # Color stops: (position 0.0 to 1.0, hex color)
    stops = [
        (0.00, "#121324"), # deep midnight sky
        (0.20, "#1F1A3A"), # deep indigo
        (0.40, "#372252"), # dusk purple
        (0.55, "#682B61"), # magenta twilight
        (0.68, "#BA3C4D"), # crimson sunset
        (0.80, "#EE5E32"), # fiery orange
        (0.90, "#FFA52C"), # warm gold
        (1.00, "#FFD67D"), # horizon glow
    ]

    for y in range(HEIGHT):
        t = y / (HEIGHT - 1)
        # Find segment
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i+1]
            if t0 <= t <= t1:
                seg_t = (t - t0) / (t1 - t0)
                # smoothstep
                seg_t = seg_t * seg_t * (3.0 - 2.0 * seg_t)
                col = lerp_color(hex_to_rgb(c0), hex_to_rgb(c1), seg_t)
                draw.line([(0, y), (WIDTH, y)], fill=col + (255,))
                break

    # Add sun disk & glow near horizon (center-left around x=700, y=650)
    sun_x, sun_y = 680, 640
    sun_glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(sun_glow)
    
    # Large radial gradient for sun bloom
    for r in range(450, 0, -5):
        alpha = int(45 * (1.0 - r / 450)**1.8)
        glow_draw.ellipse(
            [(sun_x - r, sun_y - r * 0.6), (sun_x + r, sun_y + r * 0.6)],
            fill=(255, 200, 100, alpha)
        )
    # Bright sun core
    for r in range(120, 0, -2):
        alpha = int(120 * (1.0 - r / 120)**1.2)
        glow_draw.ellipse(
            [(sun_x - r, sun_y - r * 0.7), (sun_x + r, sun_y + r * 0.7)],
            fill=(255, 240, 180, alpha)
        )
    
    im = Image.alpha_composite(im, sun_glow)

    # Add soft layered sunset clouds
    cloud_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(cloud_layer)
    
    # 5 cloud bands with soft rounded puffs
    cloud_bands = [
        (320, 35, "#301E42", 110),
        (420, 45, "#4E2150", 120),
        (510, 40, "#7E2B4B", 130),
        (590, 30, "#B8433A", 140),
        (660, 25, "#E26C35", 130),
    ]
    
    for base_y, height_var, col_hex, max_alpha in cloud_bands:
        col = hex_to_rgb(col_hex)
        # Generate series of overlapping ellipses across width
        x = -100
        while x < WIDTH + 100:
            w = random.randint(220, 480)
            h = random.randint(height_var, height_var * 2)
            y_off = random.randint(-15, 15)
            c_draw.ellipse(
                [(x, base_y + y_off - h//2), (x + w, base_y + y_off + h//2)],
                fill=col + (max_alpha,)
            )
            # Golden sunset under-rim highlight
            if base_y > 450:
                c_draw.ellipse(
                    [(x + 10, base_y + y_off + h//4), (x + w - 10, base_y + y_off + h//2 + 8)],
                    fill=(255, 175, 80, int(max_alpha * 0.5))
                )
            x += random.randint(120, 260)
            
    cloud_layer = cloud_layer.filter(ImageFilter.GaussianBlur(14))
    im = Image.alpha_composite(im, cloud_layer)
    
    im.save("assets/art/background/sunset_sky.png", "PNG")
    print("-> Saved assets/art/background/sunset_sky.png")

def create_city_skyline():
    print("Generating city_skyline.png...")
    im = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    random.seed(42)

    # 1. Distant layer (lighter purple silhouette)
    distant_col = hex_to_rgba("#2B2244", 220)
    x = 0
    while x < WIDTH:
        w = random.randint(35, 90)
        h = random.randint(160, 280)
        y = 680 - h
        draw.rectangle([(x, y), (x + w, 700)], fill=distant_col)
        # Antenna / spire
        if random.random() < 0.4:
            draw.line([(x + w//2, y), (x + w//2, y - random.randint(20, 50))], fill=distant_col, width=2)
        x += w - random.randint(0, 10)

    # 2. Midground layer (deep navy silhouette with glowing windows)
    mid_col = hex_to_rgba("#18192A", 255)
    windows_img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(windows_img)

    x = -20
    building_list = []
    while x < WIDTH + 40:
        w = random.randint(45, 120)
        h = random.randint(180, 360)
        # Some special building shapes
        b_type = random.choice(["flat", "spire", "angled", "stepped"])
        y = 690 - h
        building_list.append((x, y, w, h, b_type))
        x += w - random.randint(5, 15)

    # Draw mid buildings
    for bx, by, bw, bh, btype in building_list:
        if btype == "flat":
            draw.rectangle([(bx, by), (bx + bw, 700)], fill=mid_col)
        elif btype == "spire":
            draw.rectangle([(bx, by + 40), (bx + bw, 700)], fill=mid_col)
            draw.polygon([(bx, by + 40), (bx + bw, by + 40), (bx + bw//2, by)], fill=mid_col)
            # Spire antenna
            draw.line([(bx + bw//2, by), (bx + bw//2, by - 35)], fill=mid_col, width=3)
            # Flashing red beacon at tip
            w_draw.ellipse([(bx + bw//2 - 3, by - 37), (bx + bw//2 + 3, by - 31)], fill=(255, 50, 50, 230))
        elif btype == "angled":
            draw.polygon([(bx, by + 30), (bx + bw, by), (bx + bw, 700), (bx, 700)], fill=mid_col)
        elif btype == "stepped":
            draw.rectangle([(bx, by + 50), (bx + bw, 700)], fill=mid_col)
            draw.rectangle([(bx + 12, by + 20), (bx + bw - 12, by + 50)], fill=mid_col)
            draw.rectangle([(bx + 24, by), (bx + bw - 24, by + 20)], fill=mid_col)

        # Distant windows in clusters
        win_colors = [
            (255, 220, 130, 210), # warm amber
            (255, 180, 80, 190),  # golden orange
            (140, 220, 255, 180), # cyan office
            (255, 255, 255, 220), # white
        ]
        
        start_y = by + 35
        for row_y in range(start_y, 670, 12):
            if random.random() < 0.25:
                continue # dark floor
            for col_x in range(bx + 8, bx + bw - 8, 10):
                if random.random() < 0.65:
                    win_col = random.choice(win_colors)
                    w_draw.rectangle([(col_x, row_y), (col_x + 5, row_y + 6)], fill=win_col)

    # Soft glow for windows
    windows_glow = windows_img.filter(ImageFilter.GaussianBlur(1))
    im = Image.alpha_composite(im, windows_img)
    im = Image.alpha_composite(im, windows_glow)

    # Distant haze at horizon level
    haze = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(haze)
    for y in range(630, 720):
        alpha = int(90 * (1.0 - abs(y - 680) / 50.0))
        h_draw.line([(0, y), (WIDTH, y)], fill=(240, 110, 50, max(0, alpha)))
    im = Image.alpha_composite(im, haze)

    im.save("assets/art/background/city_skyline.png", "PNG")
    print("-> Saved assets/art/background/city_skyline.png")

def create_pit_lane_track():
    print("Generating pit_lane_track.png...")
    im = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Track ground begins at y=675 down to y=941
    ground_top = 675

    # 1. Asphalt base gradient
    for y in range(ground_top, HEIGHT):
        t = (y - ground_top) / (HEIGHT - ground_top)
        # dark tarmac with perspective shading
        tarmac_rgb = lerp_color(hex_to_rgb("#1F212D"), hex_to_rgb("#14151E"), t)
        draw.line([(0, y), (WIDTH, y)], fill=tarmac_rgb + (255,))

    # Add subtle asphalt grain texture
    random.seed(123)
    grain = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(grain)
    for _ in range(12000):
        gx = random.randint(0, WIDTH - 1)
        gy = random.randint(ground_top, HEIGHT - 1)
        val = random.randint(30, 70)
        g_draw.point((gx, gy), fill=(val, val, val + 10, 14))
    im = Image.alpha_composite(im, grain)
    draw = ImageDraw.Draw(im)

    # 2. Pit Wall / Crash Barrier along y=660 to y=695
    # Concrete base
    barrier_top = 650
    barrier_h = 32
    draw.rectangle([(0, barrier_top), (WIDTH, barrier_top + barrier_h)], fill=hex_to_rgba("#2A2C3E", 255))
    # Bevel top highlight
    draw.line([(0, barrier_top), (WIDTH, barrier_top)], fill=hex_to_rgba("#505470", 255), width=2)
    # Bottom shadow on ground
    draw.line([(0, barrier_top + barrier_h), (WIDTH, barrier_top + barrier_h)], fill=hex_to_rgba("#0C0D13", 255), width=3)

    # Alternating Red & White racing chevron blocks along pit wall
    block_w = 48
    x = 0
    idx = 0
    while x < WIDTH + block_w:
        col = hex_to_rgba("#C83B43", 255) if (idx % 2 == 0) else hex_to_rgba("#F0F2F6", 255)
        # Chamfered racing stripe polygon
        pts = [
            (x, barrier_top + barrier_h - 2),
            (x + 22, barrier_top + 4),
            (x + block_w + 22, barrier_top + 4),
            (x + block_w, barrier_top + barrier_h - 2)
        ]
        draw.polygon(pts, fill=col)
        x += block_w
        idx += 1

    # Red apex kerbing curb at foreground transition (y=690 to 705)
    curb_y = barrier_top + barrier_h + 2
    curb_w = 36
    curb_idx = 0
    cx = 0
    while cx < WIDTH + curb_w:
        ccol = hex_to_rgba("#C83B43", 240) if (curb_idx % 2 == 0) else hex_to_rgba("#FFFFFF", 240)
        draw.rectangle([(cx, curb_y), (cx + curb_w, curb_y + 12)], fill=ccol)
        # 3D bevel on kerb
        draw.line([(cx, curb_y), (cx + curb_w, curb_y)], fill=(255, 255, 255, 120), width=1)
        cx += curb_w
        curb_idx += 1

    # 3. Pit lane demarcation line (bright yellow/orange line)
    draw.line([(0, 725), (WIDTH, 725)], fill=hex_to_rgba("#FFB51B", 230), width=4)
    draw.line([(0, 727), (WIDTH, 727)], fill=hex_to_rgba("#FF7B25", 140), width=2)

    # 4. Checkered pit box strip / start line (e.g. angled across x=200 to x=950 at y=760-785)
    chk_h = 24
    chk_size = 18
    chk_y = 765
    for row in range(2):
        ry = chk_y + row * chk_size
        for col_i in range(0, WIDTH // chk_size + 2):
            rx = col_i * chk_size
            if (row + col_i) % 2 == 0:
                draw.rectangle([(rx, ry), (rx + chk_size, ry + chk_size)], fill=(245, 245, 250, 180))
            else:
                draw.rectangle([(rx, ry), (rx + chk_size, ry + chk_size)], fill=(20, 22, 30, 200))
    # Framing lines for checkered strip
    draw.line([(0, chk_y), (WIDTH, chk_y)], fill=(255, 255, 255, 190), width=2)
    draw.line([(0, chk_y + chk_size * 2), (WIDTH, chk_y + chk_size * 2)], fill=(255, 255, 255, 190), width=2)

    # 5. Tire skid marks (authentic high-speed drifting rubber)
    skid_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(skid_layer)
    skid_paths = [
        [(240, 840), (460, 810), (750, 790), (980, 785), (1200, 780)],
        [(250, 870), (490, 835), (780, 815), (1020, 805), (1240, 800)],
        [(150, 910), (380, 890), (620, 875), (880, 870), (1150, 865)],
        [(160, 935), (410, 915), (650, 900), (910, 895), (1180, 890)],
    ]
    for pts in skid_paths:
        for i in range(len(pts) - 1):
            s_draw.line([pts[i], pts[i+1]], fill=(10, 11, 16, 120), width=16)
            s_draw.line([pts[i], pts[i+1]], fill=(5, 6, 9, 70), width=24)
    skid_layer = skid_layer.filter(ImageFilter.GaussianBlur(3))
    im = Image.alpha_composite(im, skid_layer)
    draw = ImageDraw.Draw(im)

    # 6. Pit Box stencil markings ("PIT 01", speed limit circle, arrow)
    # Stencil text lines in white paint with worn texture
    draw.line([(320, 740), (440, 740)], fill=(240, 240, 245, 170), width=3)
    draw.line([(320, 740), (320, 755)], fill=(240, 240, 245, 170), width=3)
    draw.line([(440, 740), (440, 755)], fill=(240, 240, 245, 170), width=3)

    im.save("assets/art/background/pit_lane_track.png", "PNG")
    print("-> Saved assets/art/background/pit_lane_track.png")

def create_floodlights():
    print("Generating floodlights.png...")
    im = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Soft glowing light cones
    light_cones = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    cone_draw = ImageDraw.Draw(light_cones)

    # Define 2 light gantries: Left (x=160) and Right (x=1080)
    gantries = [
        (160, 110, 660, 1),   # (x, top_y, bottom_y, direction)
        (1080, 130, 660, -1),
    ]

    for gx, gy, g_base_y, facing in gantries:
        # Steel lattice tower
        truss_w = 24
        # Vertical steel legs
        draw.line([(gx - truss_w//2, gy + 30), (gx - truss_w, g_base_y)], fill=(32, 34, 48, 240), width=4)
        draw.line([(gx + truss_w//2, gy + 30), (gx + truss_w, g_base_y)], fill=(32, 34, 48, 240), width=4)
        # Cross braces
        y_step = 35
        for cy in range(gy + 40, g_base_y - 20, y_step):
            draw.line([(gx - truss_w//2, cy), (gx + truss_w//2, cy + y_step)], fill=(40, 42, 58, 200), width=2)
            draw.line([(gx + truss_w//2, cy), (gx - truss_w//2, cy + y_step)], fill=(40, 42, 58, 200), width=2)
            draw.line([(gx - truss_w//2, cy), (gx + truss_w//2, cy)], fill=(45, 48, 65, 220), width=2)

        # Floodlight bank platform
        p_w = 88
        p_h = 36
        draw.rectangle([(gx - p_w//2, gy), (gx + p_w//2, gy + p_h)], fill=(24, 26, 36, 255))
        draw.rectangle([(gx - p_w//2, gy), (gx + p_w//2, gy + p_h)], outline=(60, 64, 85, 255), width=2)

        # 8 bright halogen/LED lamps in 2 rows of 4
        lamp_centers = []
        for row in range(2):
            for col in range(4):
                lx = gx - p_w//2 + 12 + col * 20
                ly = gy + 9 + row * 18
                lamp_centers.append((lx, ly))
                # Lamp housing
                draw.rectangle([(lx - 7, ly - 6), (lx + 7, ly + 6)], fill=(15, 16, 22, 255), outline=(50, 55, 70, 255))
                # Glowing emitter
                draw.rectangle([(lx - 5, ly - 4), (lx + 5, ly + 4)], fill=(255, 250, 220, 255))

        # Light beam / atmospheric cone spreading toward ground
        cone_pts = [
            (gx - 30, gy + 30),
            (gx + 30, gy + 30),
            (gx + facing * 450 + 200, 780),
            (gx + facing * 450 - 250, 780),
        ]
        cone_draw.polygon(cone_pts, fill=(255, 240, 190, 28))

        # Radial bloom around lamp head
        for r in range(160, 0, -5):
            a = int(35 * (1.0 - r / 160.0)**1.5)
            cone_draw.ellipse([(gx - r, gy + 15 - r//2), (gx + r, gy + 15 + r//2)], fill=(255, 235, 170, a))

    light_cones = light_cones.filter(ImageFilter.GaussianBlur(10))
    im = Image.alpha_composite(im, light_cones)

    im.save("assets/art/background/floodlights.png", "PNG")
    print("-> Saved assets/art/background/floodlights.png")

def create_fence_overlay():
    print("Generating fence_overlay.png...")
    im = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    fence_top = 510
    fence_bot = 660

    # 1. Vertical steel fence posts with curved overhang towards track
    post_spacing = 110
    for px in range(15, WIDTH + post_spacing, post_spacing):
        # Main vertical post
        draw.line([(px, fence_bot), (px, fence_top + 30)], fill=(45, 48, 62, 240), width=4)
        # Angled top crash overhang
        draw.line([(px, fence_top + 30), (px + 18, fence_top)], fill=(45, 48, 62, 240), width=4)
        # Base mount
        draw.rectangle([(px - 6, fence_bot - 4), (px + 6, fence_bot + 4)], fill=(30, 32, 42, 255))

    # 2. Horizontal tension cables
    cables_y = [fence_top + 2, fence_top + 30, fence_top + 75, fence_top + 115, fence_bot - 2]
    for cy in cables_y:
        draw.line([(0, cy), (WIDTH, cy)], fill=(65, 70, 90, 200), width=2)
        # Highlight on wire
        draw.line([(0, cy), (WIDTH, cy)], fill=(120, 130, 160, 110), width=1)

    # 3. Diamond wire mesh pattern
    mesh = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mesh)
    grid_size = 14
    # Diagonal lines 45 deg
    for d in range(-HEIGHT, WIDTH + HEIGHT, grid_size):
        m_draw.line([(d, fence_top + 30), (d + (fence_bot - fence_top - 30), fence_bot)], fill=(75, 80, 100, 65), width=1)
        m_draw.line([(d, fence_bot), (d + (fence_bot - fence_top - 30), fence_top + 30)], fill=(75, 80, 100, 65), width=1)

    im = Image.alpha_composite(im, mesh)
    im.save("assets/art/background/fence_overlay.png", "PNG")
    print("-> Saved assets/art/background/fence_overlay.png")

if __name__ == "__main__":
    create_sunset_sky()
    create_city_skyline()
    create_pit_lane_track()
    create_floodlights()
    create_fence_overlay()
    print("All background layers generated successfully!")
