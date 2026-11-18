"""
RACEZONE - Car Sprite & Customization Generator
Generates high-fidelity 2D car sprites:
Side-view:
  - car_starter_gt.png
  - car_apex_cruiser.png
  - car_phantom_turbo.png
Top-down:
  - car_top_starter.png
  - car_top_apex.png
  - car_top_phantom.png
Customization:
  - decal_stripes.png
  - decal_checkered.png
  - decal_flame.png
  - wheel_sport.png
  - wheel_aero.png
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SCALE = 2 # Supersampling factor for crystal-clear antialiasing
SIDE_W = 800 * SCALE
SIDE_H = 300 * SCALE

# Standard wheel coordinates on side-view car (facing LEFT)
FRONT_WHEEL_X = 210 * SCALE
REAR_WHEEL_X = 610 * SCALE
WHEEL_Y = 230 * SCALE
WHEEL_R = 52 * SCALE

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    return hex_to_rgb(h) + (a,)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def draw_wheel(draw, cx, cy, radius, style="sport", caliper_col=(200, 30, 40)):
    # 1. Tire (outer rubber)
    draw.ellipse([(cx - radius, cy - radius), (cx + radius, cy + radius)], fill=(18, 19, 23, 255))
    # Tire tread highlight
    draw.ellipse([(cx - radius + 2*SCALE, cy - radius + 2*SCALE), 
                  (cx + radius - 2*SCALE, cy + radius - 2*SCALE)], outline=(35, 38, 46, 255), width=3*SCALE)
    
    # 2. Rim outer lip
    rim_r = radius - 10 * SCALE
    draw.ellipse([(cx - rim_r, cy - rim_r), (cx + rim_r, cy + rim_r)], fill=(30, 32, 40, 255))
    draw.ellipse([(cx - rim_r, cy - rim_r), (cx + rim_r, cy + rim_r)], outline=(180, 190, 205, 255), width=2*SCALE)

    # 3. Brake Rotor (drilled steel disc)
    rotor_r = rim_r - 8 * SCALE
    draw.ellipse([(cx - rotor_r, cy - rotor_r), (cx + rotor_r, cy + rotor_r)], fill=(110, 115, 125, 255))
    # Brake Rotor holes
    for a_deg in range(0, 360, 30):
        rad = math.radians(a_deg)
        hx = cx + (rotor_r * 0.65) * math.cos(rad)
        hy = cy + (rotor_r * 0.65) * math.sin(rad)
        draw.ellipse([(hx - 1.5*SCALE, hy - 1.5*SCALE), (hx + 1.5*SCALE, hy + 1.5*SCALE)], fill=(50, 52, 60, 255))

    # 4. Brake Caliper (top-left of rotor)
    cal_rect = [(cx - rotor_r + 2*SCALE, cy - rotor_r * 0.8), (cx - 2*SCALE, cy - 2*SCALE)]
    draw.rounded_rectangle(cal_rect, radius=4*SCALE, fill=caliper_col + (255,), outline=(255, 255, 255, 160), width=1*SCALE)

    # 5. Spokes or Aero Disc
    if style == "sport":
        # 5 twin spokes in silver alloy
        for spoke_idx in range(5):
            angle = spoke_idx * (2 * math.pi / 5) - math.pi / 2
            # Twin spoke lines
            for offset in [-0.08, 0.08]:
                a = angle + offset
                sx = cx + (rim_r - 2*SCALE) * math.cos(a)
                sy = cy + (rim_r - 2*SCALE) * math.sin(a)
                draw.line([(cx, cy), (sx, sy)], fill=(210, 218, 230, 255), width=4*SCALE)
                draw.line([(cx, cy), (sx, sy)], fill=(245, 248, 255, 200), width=1*SCALE)
    elif style == "aero":
        # Turbofan aero disc with cooling slots
        draw.ellipse([(cx - rim_r + 3*SCALE, cy - rim_r + 3*SCALE),
                      (cx + rim_r - 3*SCALE, cy + rim_r - 3*SCALE)], fill=(25, 27, 34, 255), outline=(255, 181, 27, 255), width=2*SCALE)
        # Radial cooling fins
        for spoke_idx in range(12):
            a = spoke_idx * (2 * math.pi / 12)
            sx1 = cx + (rotor_r * 0.4) * math.cos(a)
            sy1 = cy + (rotor_r * 0.4) * math.sin(a)
            sx2 = cx + (rim_r - 4*SCALE) * math.cos(a)
            sy2 = cy + (rim_r - 4*SCALE) * math.sin(a)
            draw.line([(sx1, sy1), (sx2, sy2)], fill=(60, 65, 80, 255), width=2*SCALE)

    # 6. Center hub & lug nuts
    hub_r = 10 * SCALE
    draw.ellipse([(cx - hub_r, cy - hub_r), (cx + hub_r, cy + hub_r)], fill=(40, 42, 50, 255), outline=(255, 255, 255, 180), width=1*SCALE)
    # Center lock nut
    nut_col = (255, 181, 27, 255) if style == "aero" else (220, 40, 50, 255)
    draw.ellipse([(cx - 4*SCALE, cy - 4*SCALE), (cx + 4*SCALE, cy + 4*SCALE)], fill=nut_col)

def create_side_car(filename, car_type="starter"):
    print(f"Generating side-view {filename}...")
    im = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Ground Drop Shadow underneath car
    shadow = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    # Shadow ellipse
    s_draw.ellipse([(80 * SCALE, (WHEEL_Y + WHEEL_R - 12 * SCALE)), 
                    (740 * SCALE, (WHEEL_Y + WHEEL_R + 18 * SCALE))], fill=(5, 6, 10, 190))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8 * SCALE))
    im = Image.alpha_composite(im, shadow)
    draw = ImageDraw.Draw(im)

    # Base car silhouette coordinates (facing LEFT)
    # Front is at left (~100-120), Rear is at right (~710-730)
    # Roof peak is around x=380 to x=520, y=95-125
    
    if car_type == "starter":
        # Sleek GT coupe: White/Silver with Red Livery
        body_col = hex_to_rgb("#EEF2F7")
        body_shade = hex_to_rgb("#B8C2D1")
        stripe_col = hex_to_rgba("#C83B43", 255)
        accent_col = hex_to_rgba("#1C1E28", 255)
        spoiler_pts = [
            (685 * SCALE, 145 * SCALE), (725 * SCALE, 140 * SCALE),
            (730 * SCALE, 150 * SCALE), (680 * SCALE, 160 * SCALE)
        ]
        spoiler_stands = [(695 * SCALE, 158 * SCALE, 700 * SCALE, 185 * SCALE)]
        wing_type = "gt"
        wheel_style = "sport"
        caliper = (200, 30, 40)
    elif car_type == "apex":
        # Aggressive widebody: Golden-Yellow & Gloss Black
        body_col = hex_to_rgb("#FFB51B")
        body_shade = hex_to_rgb("#D68700")
        stripe_col = hex_to_rgba("#14151E", 255)
        accent_col = hex_to_rgba("#FF7B25", 255)
        spoiler_pts = [
            (675 * SCALE, 120 * SCALE), (735 * SCALE, 115 * SCALE),
            (738 * SCALE, 130 * SCALE), (670 * SCALE, 138 * SCALE)
        ]
        spoiler_stands = [(685 * SCALE, 135 * SCALE, 690 * SCALE, 180 * SCALE),
                          (720 * SCALE, 130 * SCALE, 725 * SCALE, 185 * SCALE)]
        wing_type = "high"
        wheel_style = "aero"
        caliper = (255, 181, 27)
    else: # phantom
        # Futuristic hypercar: Stealth Charcoal & Electric Crimson
        body_col = hex_to_rgb("#1C1D27")
        body_shade = hex_to_rgb("#101118")
        stripe_col = hex_to_rgba("#FF2E4C", 255)
        accent_col = hex_to_rgba("#FF2E4C", 255)
        spoiler_pts = [
            (660 * SCALE, 105 * SCALE), (740 * SCALE, 100 * SCALE),
            (745 * SCALE, 116 * SCALE), (655 * SCALE, 124 * SCALE)
        ]
        spoiler_stands = [(675 * SCALE, 120 * SCALE, 680 * SCALE, 180 * SCALE),
                          (725 * SCALE, 114 * SCALE, 730 * SCALE, 180 * SCALE)]
        wing_type = "hyper"
        wheel_style = "sport"
        caliper = (255, 46, 76)

    # 1. Wheel arch cutouts (fenders)
    # Define main body profile polygon
    nose_x = 105 * SCALE
    splitter_y = 238 * SCALE
    hood_y = 180 * SCALE
    roof_front_x = 340 * SCALE
    roof_front_y = 115 * SCALE
    roof_back_x = 510 * SCALE
    roof_back_y = 118 * SCALE
    tail_x = 725 * SCALE
    tail_top_y = 175 * SCALE
    diffuser_y = 238 * SCALE

    # Under-body and Wheel arches
    # Front arch: center (FRONT_WHEEL_X, WHEEL_Y), radius WHEEL_R + 10*SCALE
    # Rear arch: center (REAR_WHEEL_X, WHEEL_Y), radius WHEEL_R + 10*SCALE
    f_arch_r = WHEEL_R + 12 * SCALE
    r_arch_r = WHEEL_R + 12 * SCALE

    # Build main body contour points:
    body_pts = [
        # Front Splitter tip
        (nose_x, splitter_y),
        (nose_x - 5*SCALE, splitter_y - 12*SCALE),
        (nose_x + 12*SCALE, hood_y + 15*SCALE),
        # Headlight corner
        (nose_x + 30*SCALE, hood_y),
        # Hood line sweeping up
        (nose_x + 130*SCALE, hood_y - 15*SCALE),
        # A-pillar base
        (roof_front_x - 30*SCALE, hood_y - 20*SCALE),
        # Windshield
        (roof_front_x, roof_front_y),
        # Roof line
        (roof_front_x + 80*SCALE, roof_front_y - 5*SCALE),
        (roof_back_x, roof_back_y),
        # Rear window slope
        (roof_back_x + 100*SCALE, hood_y - 10*SCALE),
        # Trunk / Decklid
        (tail_x - 30*SCALE, tail_top_y),
        (tail_x, tail_top_y + 8*SCALE),
        # Rear bumper
        (tail_x + 5*SCALE, tail_top_y + 35*SCALE),
        (tail_x - 8*SCALE, diffuser_y),
        # Rear underside
        (REAR_WHEEL_X + r_arch_r, diffuser_y),
    ]

    # Rear wheel arch curve (semi-circle)
    for a_deg in range(0, 181, 15):
        rad = math.radians(a_deg)
        ax = REAR_WHEEL_X + r_arch_r * math.cos(rad)
        ay = WHEEL_Y - r_arch_r * math.sin(rad)
        body_pts.append((ax, ay))

    # Side skirt rocker
    body_pts.append((REAR_WHEEL_X - r_arch_r, diffuser_y))
    body_pts.append((FRONT_WHEEL_X + f_arch_r, diffuser_y))

    # Front wheel arch curve
    for a_deg in range(0, 181, 15):
        rad = math.radians(a_deg)
        ax = FRONT_WHEEL_X + f_arch_r * math.cos(rad)
        ay = WHEEL_Y - f_arch_r * math.sin(rad)
        body_pts.append((ax, ay))

    # Front underside to splitter
    body_pts.append((FRONT_WHEEL_X - f_arch_r, splitter_y))
    body_pts.append((nose_x, splitter_y))

    # Draw body base fill
    draw.polygon(body_pts, fill=body_col + (255,))

    # Body shading (linear gradient from top highlight to lower shadow)
    shade_img = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shade_img)
    sh_draw.polygon(body_pts, fill=(255, 255, 255, 255))
    
    gradient = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(gradient)
    for y in range(int(roof_front_y - 10*SCALE), int(diffuser_y + 5*SCALE)):
        t = (y - roof_front_y) / (diffuser_y - roof_front_y)
        c = lerp_color(body_col, body_shade, t)
        g_draw.line([(0, y), (SIDE_W, y)], fill=c + (255,))
    
    # Mask gradient with body silhouette
    body_shaded = Image.composite(gradient, Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0)), shade_img.split()[3])
    im = Image.alpha_composite(im, body_shaded)
    draw = ImageDraw.Draw(im)

    # 2. Livery racing stripes & accents
    if car_type == "starter":
        # Dynamic red sweeping racing stripes along door and waistline
        stripe_pts = [
            (nose_x + 50*SCALE, hood_y + 2*SCALE),
            (roof_front_x - 10*SCALE, hood_y - 10*SCALE),
            (roof_back_x + 130*SCALE, hood_y - 5*SCALE),
            (tail_x - 15*SCALE, tail_top_y + 12*SCALE),
            (tail_x - 15*SCALE, tail_top_y + 28*SCALE),
            (roof_back_x + 120*SCALE, hood_y + 12*SCALE),
            (roof_front_x - 10*SCALE, hood_y + 8*SCALE),
            (nose_x + 60*SCALE, hood_y + 18*SCALE),
        ]
        draw.polygon(stripe_pts, fill=stripe_col)
        # Thin charcoal secondary accent stripe
        sec_stripe = [
            (nose_x + 70*SCALE, hood_y + 24*SCALE),
            (tail_x - 20*SCALE, tail_top_y + 34*SCALE),
            (tail_x - 20*SCALE, tail_top_y + 39*SCALE),
            (nose_x + 80*SCALE, hood_y + 29*SCALE),
        ]
        draw.polygon(sec_stripe, fill=accent_col)
    elif car_type == "apex":
        # Bold black graphic livery
        black_stripe = [
            (nose_x + 40*SCALE, hood_y + 5*SCALE),
            (roof_front_x - 10*SCALE, hood_y - 8*SCALE),
            (roof_back_x + 120*SCALE, hood_y - 4*SCALE),
            (tail_x - 10*SCALE, tail_top_y + 14*SCALE),
            (tail_x - 10*SCALE, tail_top_y + 42*SCALE),
            (roof_back_x + 80*SCALE, hood_y + 26*SCALE),
            (roof_front_x - 20*SCALE, hood_y + 20*SCALE),
            (nose_x + 80*SCALE, hood_y + 25*SCALE),
        ]
        draw.polygon(black_stripe, fill=stripe_col)
        # Racing orange accent pin
        draw.line([(nose_x + 80*SCALE, hood_y + 26*SCALE), (tail_x - 10*SCALE, tail_top_y + 44*SCALE)], fill=accent_col, width=3*SCALE)
    else: # phantom
        # Glowing crimson aerodynamic accents
        draw.line([(nose_x, splitter_y), (FRONT_WHEEL_X - f_arch_r, splitter_y)], fill=accent_col, width=4*SCALE)
        draw.line([(FRONT_WHEEL_X + f_arch_r, diffuser_y), (REAR_WHEEL_X - r_arch_r, diffuser_y)], fill=accent_col, width=4*SCALE)
        draw.line([(REAR_WHEEL_X + r_arch_r, diffuser_y), (tail_x, diffuser_y)], fill=accent_col, width=4*SCALE)
        # Neon red side channel
        side_channel = [
            (nose_x + 90*SCALE, hood_y + 10*SCALE),
            (roof_front_x + 40*SCALE, hood_y),
            (roof_back_x + 60*SCALE, hood_y + 5*SCALE),
            (tail_x - 25*SCALE, tail_top_y + 20*SCALE)
        ]
        draw.line(side_channel, fill=accent_col, width=3*SCALE)

    # 3. Cockpit Glass / Windows (Dark tinted with gloss reflection)
    glass_pts = [
        # A-pillar
        (roof_front_x - 18*SCALE, hood_y - 16*SCALE),
        # Windshield top
        (roof_front_x + 5*SCALE, roof_front_y + 5*SCALE),
        # Roof edge
        (roof_back_x - 15*SCALE, roof_back_y + 5*SCALE),
        # Rear window
        (roof_back_x + 75*SCALE, hood_y - 12*SCALE),
        # Door glass bottom sill
        (roof_front_x - 8*SCALE, hood_y - 10*SCALE),
    ]
    draw.polygon(glass_pts, fill=(20, 22, 32, 255))
    # B-pillar divider
    b_x = (roof_front_x + roof_back_x) // 2 + 10*SCALE
    draw.line([(b_x, roof_front_y + 5*SCALE), (b_x - 5*SCALE, hood_y - 11*SCALE)], fill=(12, 13, 18, 255), width=6*SCALE)
    # Glass gloss glare reflection lines
    draw.line([(roof_front_x - 5*SCALE, hood_y - 12*SCALE), (roof_front_x + 45*SCALE, roof_front_y + 8*SCALE)], 
              fill=(160, 210, 255, 140), width=3*SCALE)
    draw.line([(b_x + 15*SCALE, hood_y - 12*SCALE), (roof_back_x + 20*SCALE, roof_back_y + 8*SCALE)], 
              fill=(160, 210, 255, 90), width=2*SCALE)

    # 4. Aerodynamic Front Splitter, Side Skirts, Rear Diffuser (Carbon fiber)
    carbon_col = (18, 20, 26, 255)
    # Splitter
    draw.polygon([
        (nose_x - 12*SCALE, splitter_y), (nose_x + 45*SCALE, splitter_y),
        (nose_x + 45*SCALE, splitter_y + 7*SCALE), (nose_x - 12*SCALE, splitter_y + 7*SCALE)
    ], fill=carbon_col)
    # Side skirt
    draw.rectangle([
        (FRONT_WHEEL_X + f_arch_r - 2*SCALE, diffuser_y - 2*SCALE),
        (REAR_WHEEL_X - r_arch_r + 2*SCALE, diffuser_y + 6*SCALE)
    ], fill=carbon_col)
    # Rear Diffuser fins
    draw.polygon([
        (tail_x - 35*SCALE, diffuser_y), (tail_x + 8*SCALE, diffuser_y),
        (tail_x + 12*SCALE, diffuser_y + 10*SCALE), (tail_x - 30*SCALE, diffuser_y + 10*SCALE)
    ], fill=carbon_col)

    # 5. Rear Wing / Spoiler
    for stand in spoiler_stands:
        draw.line([stand[:2], stand[2:]], fill=(30, 32, 40, 255), width=4*SCALE)
    draw.polygon(spoiler_pts, fill=carbon_col)
    # Spoiler highlight
    draw.line([spoiler_pts[0], spoiler_pts[1]], fill=(120, 130, 150, 200), width=2*SCALE)
    # Endplate
    ep_x = spoiler_pts[1][0]
    ep_y = spoiler_pts[1][1]
    draw.polygon([
        (ep_x - 5*SCALE, ep_y - 15*SCALE), (ep_x + 8*SCALE, ep_y - 15*SCALE),
        (ep_x + 8*SCALE, ep_y + 18*SCALE), (ep_x - 5*SCALE, ep_y + 18*SCALE)
    ], fill=(stripe_col if car_type != "phantom" else accent_col))

    # 6. Headlights & Taillights
    # Front Headlight (sleek LED cluster on left)
    hl_pts = [
        (nose_x + 8*SCALE, hood_y + 10*SCALE),
        (nose_x + 42*SCALE, hood_y + 2*SCALE),
        (nose_x + 36*SCALE, hood_y + 16*SCALE),
        (nose_x + 12*SCALE, hood_y + 18*SCALE)
    ]
    draw.polygon(hl_pts, fill=(240, 250, 255, 255))
    draw.polygon(hl_pts, outline=(80, 180, 255, 240), width=1*SCALE)
    # Headlight flare
    flare = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    f_draw = ImageDraw.Draw(flare)
    f_draw.ellipse([(nose_x - 15*SCALE, hood_y - 5*SCALE), (nose_x + 35*SCALE, hood_y + 30*SCALE)], fill=(120, 200, 255, 70))
    flare = flare.filter(ImageFilter.GaussianBlur(5*SCALE))
    im = Image.alpha_composite(im, flare)
    draw = ImageDraw.Draw(im)

    # Rear Taillight (modern LED strip on right)
    tl_pts = [
        (tail_x - 5*SCALE, tail_top_y + 12*SCALE),
        (tail_x + 4*SCALE, tail_top_y + 14*SCALE),
        (tail_x + 3*SCALE, tail_top_y + 26*SCALE),
        (tail_x - 8*SCALE, tail_top_y + 24*SCALE)
    ]
    draw.polygon(tl_pts, fill=(255, 30, 45, 255))
    draw.line([(tail_x - 25*SCALE, tail_top_y + 14*SCALE), (tail_x + 4*SCALE, tail_top_y + 14*SCALE)], fill=(255, 80, 95, 255), width=2*SCALE)

    # 7. Door cut-lines & handle
    draw.line([(roof_front_x + 20*SCALE, hood_y - 10*SCALE), (roof_front_x + 5*SCALE, diffuser_y - 4*SCALE)], fill=(60, 65, 80, 140), width=2*SCALE)
    draw.line([(roof_back_x - 10*SCALE, hood_y - 10*SCALE), (roof_back_x - 20*SCALE, diffuser_y - 4*SCALE)], fill=(60, 65, 80, 140), width=2*SCALE)
    # Flush door handle
    draw.rounded_rectangle([(roof_front_x + 80*SCALE, hood_y + 12*SCALE), (roof_front_x + 115*SCALE, hood_y + 18*SCALE)], radius=3*SCALE, fill=(40, 44, 56, 220))

    # 8. Render Wheels at FRONT_WHEEL_X and REAR_WHEEL_X
    draw_wheel(draw, FRONT_WHEEL_X, WHEEL_Y, WHEEL_R, style=wheel_style, caliper_col=caliper)
    draw_wheel(draw, REAR_WHEEL_X, WHEEL_Y, WHEEL_R, style=wheel_style, caliper_col=caliper)

    # Final downsample with Lanczos for smooth supersampled quality
    im_final = im.resize((SIDE_W // SCALE, SIDE_H // SCALE), Image.Resampling.LANCZOS)
    im_final.save(f"assets/art/cars/{filename}", "PNG")
    print(f"-> Saved assets/art/cars/{filename}")

def create_top_down_car(filename, car_type="starter"):
    print(f"Generating top-down {filename}...")
    W = 140 * SCALE
    H = 280 * SCALE
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx = W // 2
    # Front is at top (y=25*SCALE), rear is at bottom (y=255*SCALE)

    if car_type == "starter":
        body_col = hex_to_rgb("#EEF2F7")
        body_shade = hex_to_rgb("#B8C2D1")
        stripe_col = hex_to_rgba("#C83B43", 255)
        accent_col = hex_to_rgba("#1C1E28", 255)
    elif car_type == "apex":
        body_col = hex_to_rgb("#FFB51B")
        body_shade = hex_to_rgb("#D68700")
        stripe_col = hex_to_rgba("#14151E", 255)
        accent_col = hex_to_rgba("#FF7B25", 255)
    else: # phantom
        body_col = hex_to_rgb("#1C1D27")
        body_shade = hex_to_rgb("#101118")
        stripe_col = hex_to_rgba("#FF2E4C", 255)
        accent_col = hex_to_rgba("#FF2E4C", 255)

    # Drop shadow
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([(15*SCALE, 20*SCALE), (W - 15*SCALE, H - 15*SCALE)], fill=(5, 6, 10, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(6*SCALE))
    im = Image.alpha_composite(im, shadow)
    draw = ImageDraw.Draw(im)

    # 4 Corner Tires (black rubber)
    tw = 14 * SCALE
    th = 38 * SCALE
    tire_pts = [
        (10*SCALE, 60*SCALE),       # Front Left
        (W - 10*SCALE - tw, 60*SCALE), # Front Right
        (8*SCALE, 205*SCALE),      # Rear Left
        (W - 8*SCALE - tw, 205*SCALE),# Rear Right
    ]
    for tx, ty in tire_pts:
        draw.rounded_rectangle([(tx, ty), (tx + tw, ty + th)], radius=4*SCALE, fill=(20, 22, 28, 255))
        draw.rounded_rectangle([(tx + 2*SCALE, ty + 2*SCALE), (tx + tw - 2*SCALE, ty + th - 2*SCALE)], radius=3*SCALE, outline=(45, 50, 60, 255), width=1*SCALE)

    # Main Car Body Contour (Aerodynamic top view)
    body_pts = [
        # Front nose
        (cx - 24*SCALE, 24*SCALE),
        (cx + 24*SCALE, 24*SCALE),
        # Front bumper to front wheels
        (cx + 42*SCALE, 42*SCALE),
        (cx + 48*SCALE, 75*SCALE),
        # Side mirrors
        (cx + 56*SCALE, 105*SCALE),
        (cx + 46*SCALE, 112*SCALE),
        # Waist / Cabin
        (cx + 44*SCALE, 160*SCALE),
        # Rear widebody fender
        (cx + 52*SCALE, 210*SCALE),
        (cx + 48*SCALE, 245*SCALE),
        # Rear bumper
        (cx + 35*SCALE, 258*SCALE),
        (cx - 35*SCALE, 258*SCALE),
        # Left side symmetry
        (cx - 48*SCALE, 245*SCALE),
        (cx - 52*SCALE, 210*SCALE),
        (cx - 44*SCALE, 160*SCALE),
        (cx - 46*SCALE, 112*SCALE),
        (cx - 56*SCALE, 105*SCALE),
        (cx - 48*SCALE, 75*SCALE),
        (cx - 42*SCALE, 42*SCALE),
    ]
    draw.polygon(body_pts, fill=body_col + (255,))

    # Body shading
    for y in range(int(24*SCALE), int(258*SCALE)):
        t = (y - 24*SCALE) / (234*SCALE)
        col = lerp_color(body_col, body_shade, t * 0.5)
        # horizontal line clipped
    draw.polygon(body_pts, outline=(30, 32, 40, 220), width=2*SCALE)

    # Racing Center Stripes
    stripe_w = 12 * SCALE
    draw.rectangle([(cx - stripe_w, 24*SCALE), (cx + stripe_w, 258*SCALE)], fill=stripe_col)
    if car_type == "starter":
        # White center divider
        draw.line([(cx, 24*SCALE), (cx, 258*SCALE)], fill=hex_to_rgba("#FFFFFF", 255), width=2*SCALE)

    # Cockpit Glass (Windshield, Roof, Rear Window)
    # Windshield
    ws_pts = [
        (cx - 30*SCALE, 95*SCALE), (cx + 30*SCALE, 95*SCALE),
        (cx + 34*SCALE, 130*SCALE), (cx - 34*SCALE, 130*SCALE)
    ]
    draw.polygon(ws_pts, fill=(22, 25, 36, 255))
    draw.line([(cx - 18*SCALE, 98*SCALE), (cx - 8*SCALE, 126*SCALE)], fill=(160, 210, 255, 140), width=2*SCALE)

    # Roof
    draw.rectangle([(cx - 32*SCALE, 130*SCALE), (cx + 32*SCALE, 168*SCALE)], fill=(car_type == "apex" and (18, 20, 26, 255) or body_col + (255,)))
    if car_type == "apex":
        draw.rectangle([(cx - stripe_w, 130*SCALE), (cx + stripe_w, 168*SCALE)], fill=stripe_col)

    # Rear Window
    rw_pts = [
        (cx - 32*SCALE, 168*SCALE), (cx + 32*SCALE, 168*SCALE),
        (cx + 28*SCALE, 195*SCALE), (cx - 28*SCALE, 195*SCALE)
    ]
    draw.polygon(rw_pts, fill=(22, 25, 36, 255))

    # Rear Wing
    wing_w = 46 * SCALE
    draw.rectangle([(cx - wing_w, 242*SCALE), (cx + wing_w, 254*SCALE)], fill=(20, 22, 28, 255), outline=(60, 65, 80, 255), width=1*SCALE)
    # Wing endplates
    draw.rectangle([(cx - wing_w - 2*SCALE, 238*SCALE), (cx - wing_w + 3*SCALE, 258*SCALE)], fill=stripe_col)
    draw.rectangle([(cx + wing_w - 3*SCALE, 238*SCALE), (cx + wing_w + 2*SCALE, 258*SCALE)], fill=stripe_col)

    # Headlights & Taillights
    # Front Headlights
    draw.polygon([(cx - 38*SCALE, 35*SCALE), (cx - 25*SCALE, 28*SCALE), (cx - 22*SCALE, 42*SCALE)], fill=(240, 250, 255, 255))
    draw.polygon([(cx + 38*SCALE, 35*SCALE), (cx + 25*SCALE, 28*SCALE), (cx + 22*SCALE, 42*SCALE)], fill=(240, 250, 255, 255))

    # Rear Taillights
    draw.rectangle([(cx - 34*SCALE, 255*SCALE), (cx - 20*SCALE, 258*SCALE)], fill=(255, 30, 45, 255))
    draw.rectangle([(cx + 20*SCALE, 255*SCALE), (cx + 34*SCALE, 258*SCALE)], fill=(255, 30, 45, 255))

    im_final = im.resize((W // SCALE, H // SCALE), Image.Resampling.LANCZOS)
    im_final.save(f"assets/art/cars/{filename}", "PNG")
    print(f"-> Saved assets/art/cars/{filename}")

def create_decals():
    print("Generating customization decal overlays...")
    # 1. decal_stripes.png (Twin bold racing stripes & racing number #07)
    im1 = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    d1 = ImageDraw.Draw(im1)
    
    # Racing number roundel on door (x=420*SCALE, y=185*SCALE)
    rcx, rcy, rr = 410 * SCALE, 185 * SCALE, 32 * SCALE
    d1.ellipse([(rcx - rr, rcy - rr), (rcx + rr, rcy + rr)], fill=(255, 255, 255, 230), outline=(20, 22, 30, 255), width=3*SCALE)
    # Stencil text "07"
    # Simple crisp polygonal digits "0" and "7"
    d1.ellipse([(rcx - 18*SCALE, rcy - 18*SCALE), (rcx - 2*SCALE, rcy + 18*SCALE)], fill=(20, 22, 30, 255))
    d1.ellipse([(rcx - 13*SCALE, rcy - 12*SCALE), (rcx - 7*SCALE, rcy + 12*SCALE)], fill=(255, 255, 255, 255))
    # Digit 7
    d1.polygon([
        (rcx + 2*SCALE, rcy - 18*SCALE), (rcx + 20*SCALE, rcy - 18*SCALE),
        (rcx + 10*SCALE, rcy + 18*SCALE), (rcx + 4*SCALE, rcy + 18*SCALE),
        (rcx + 13*SCALE, rcy - 12*SCALE), (rcx + 2*SCALE, rcy - 12*SCALE)
    ], fill=(20, 22, 30, 255))

    # Bold speed stripes along side
    d1.polygon([
        (130*SCALE, 205*SCALE), (690*SCALE, 205*SCALE),
        (685*SCALE, 215*SCALE), (135*SCALE, 215*SCALE)
    ], fill=(255, 181, 27, 240))
    d1.polygon([
        (150*SCALE, 218*SCALE), (670*SCALE, 218*SCALE),
        (665*SCALE, 224*SCALE), (155*SCALE, 224*SCALE)
    ], fill=(243, 106, 61, 220))

    im1.resize((SIDE_W // SCALE, SIDE_H // SCALE), Image.Resampling.LANCZOS).save("assets/art/cars/decal_stripes.png", "PNG")
    print("-> Saved assets/art/cars/decal_stripes.png")

    # 2. decal_checkered.png (Dynamic checkered racing flag on rear quarter panel)
    im2 = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(im2)
    # Checkered grid tapering from rear wheel forward
    for row in range(5):
        for col in range(9):
            if (row + col) % 2 == 0:
                cx_box = (450 + col * 18) * SCALE
                cy_box = (150 + row * 14 - col * 2) * SCALE
                # Angled parallelogram
                pts = [
                    (cx_box, cy_box),
                    (cx_box + 16*SCALE, cy_box),
                    (cx_box + 22*SCALE, cy_box + 12*SCALE),
                    (cx_box + 6*SCALE, cy_box + 12*SCALE)
                ]
                d2.polygon(pts, fill=(245, 248, 255, 210))
    im2.resize((SIDE_W // SCALE, SIDE_H // SCALE), Image.Resampling.LANCZOS).save("assets/art/cars/decal_checkered.png", "PNG")
    print("-> Saved assets/art/cars/decal_checkered.png")

    # 3. decal_flame.png (Aerodynamic tribal speed flame)
    im3 = Image.new("RGBA", (SIDE_W, SIDE_H), (0, 0, 0, 0))
    d3 = ImageDraw.Draw(im3)
    flame_pts_outer = [
        (260*SCALE, 195*SCALE), (330*SCALE, 185*SCALE), (310*SCALE, 195*SCALE),
        (420*SCALE, 175*SCALE), (380*SCALE, 192*SCALE), (520*SCALE, 168*SCALE),
        (460*SCALE, 196*SCALE), (620*SCALE, 175*SCALE), (510*SCALE, 208*SCALE),
        (380*SCALE, 212*SCALE), (260*SCALE, 208*SCALE)
    ]
    d3.polygon(flame_pts_outer, fill=(243, 106, 61, 230))
    
    # Inner bright flame core
    flame_pts_inner = [
        (280*SCALE, 198*SCALE), (350*SCALE, 188*SCALE), (335*SCALE, 196*SCALE),
        (430*SCALE, 182*SCALE), (400*SCALE, 195*SCALE), (500*SCALE, 178*SCALE),
        (450*SCALE, 200*SCALE), (390*SCALE, 206*SCALE), (280*SCALE, 204*SCALE)
    ]
    d3.polygon(flame_pts_inner, fill=(255, 215, 60, 240))
    im3.resize((SIDE_W // SCALE, SIDE_H // SCALE), Image.Resampling.LANCZOS).save("assets/art/cars/decal_flame.png", "PNG")
    print("-> Saved assets/art/cars/decal_flame.png")

def create_standalone_wheels():
    print("Generating standalone wheel textures...")
    SIZE = 160 * SCALE
    for style, filename, caliper in [("sport", "wheel_sport.png", (200, 30, 40)),
                                     ("aero", "wheel_aero.png", (255, 181, 27))]:
        im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(im)
        draw_wheel(draw, SIZE // 2, SIZE // 2, (SIZE // 2) - 8*SCALE, style=style, caliper_col=caliper)
        im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS).save(f"assets/art/cars/{filename}", "PNG")
        print(f"-> Saved assets/art/cars/{filename}")

if __name__ == "__main__":
    create_side_car("car_starter_gt.png", "starter")
    create_side_car("car_apex_cruiser.png", "apex")
    create_side_car("car_phantom_turbo.png", "phantom")
    create_top_down_car("car_top_starter.png", "starter")
    create_top_down_car("car_top_apex.png", "apex")
    create_top_down_car("car_top_phantom.png", "phantom")
    create_decals()
    create_standalone_wheels()
    print("All car and customization assets generated successfully!")
