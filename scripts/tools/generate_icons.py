"""
RACEZONE - UI Icon Generator
Generates high-resolution 2D UI icons (128x128):
- icon_coin.png
- icon_diamond.png
- icon_trophy.png
- icon_gear.png
- icon_mail.png
- icon_gift.png
- icon_car.png
- icon_cart.png
- icon_leaderboard.png
- icon_news.png
- icon_customize.png
- icon_quit.png
- icon_play.png
- icon_plus.png
- icon_check.png
- icon_lock.png
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SCALE = 2 # Supersampling factor
SIZE = 128 * SCALE

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    return hex_to_rgb(h) + (a,)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def save_icon(im, filename):
    im_final = im.resize((SIZE // SCALE, SIZE // SCALE), Image.Resampling.LANCZOS)
    im_final.save(f"assets/art/icons/{filename}", "PNG")
    print(f"-> Saved assets/art/icons/{filename}")

def draw_drop_shadow(im, pts_or_bbox, is_ellipse=False):
    s = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(s)
    if is_ellipse:
        sd.ellipse(pts_or_bbox, fill=(5, 6, 12, 140))
    else:
        sd.polygon(pts_or_bbox, fill=(5, 6, 12, 140))
    s = s.filter(ImageFilter.GaussianBlur(4 * SCALE))
    return Image.alpha_composite(im, s)

# 1. icon_coin.png
def create_coin():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    r = 50 * SCALE

    # Drop shadow
    im = draw_drop_shadow(im, [(cx - r, cy - r + 6*SCALE), (cx + r, cy + r + 6*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Outer coin rim (Golden amber gradient)
    for i in range(int(r), 0, -1):
        t = i / r
        col = lerp_color(hex_to_rgb("#FFAE19"), hex_to_rgb("#B87700"), 1.0 - t)
        draw.ellipse([(cx - i, cy - i), (cx + i, cy + i)], fill=col + (255,))

    # Inner recessed face
    in_r = r - 8 * SCALE
    for i in range(int(in_r), 0, -1):
        t = i / in_r
        col = lerp_color(hex_to_rgb("#FFD452"), hex_to_rgb("#E09400"), 1.0 - t)
        draw.ellipse([(cx - i, cy - i), (cx + i, cy + i)], fill=col + (255,))

    # Embossed "R" Racing Monogram
    rw = 18 * SCALE
    rh = 28 * SCALE
    # R vertical stem
    draw.rounded_rectangle([(cx - 16*SCALE, cy - rh), (cx - 6*SCALE, cy + rh)], radius=2*SCALE, fill=(255, 255, 255, 240))
    # R loop
    draw.arc([(cx - 14*SCALE, cy - rh), (cx + 14*SCALE, cy + 2*SCALE)], start=270, end=90, fill=(255, 255, 255, 240), width=8*SCALE)
    # R diagonal leg
    draw.line([(cx - 6*SCALE, cy + 2*SCALE), (cx + 16*SCALE, cy + rh)], fill=(255, 255, 255, 240), width=8*SCALE)

    # Specular Glint crescent
    draw.arc([(cx - in_r + 4*SCALE, cy - in_r + 4*SCALE), (cx + in_r - 4*SCALE, cy + in_r - 4*SCALE)], start=200, end=300, fill=(255, 255, 255, 210), width=4*SCALE)

    save_icon(im, "icon_coin.png")

# 2. icon_diamond.png
def create_diamond():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Faceted diamond vertices
    t_y = cy - 42 * SCALE
    m_y = cy - 8 * SCALE
    b_y = cy + 46 * SCALE
    l_x = cx - 48 * SCALE
    r_x = cx + 48 * SCALE
    tl_x = cx - 26 * SCALE
    tr_x = cx + 26 * SCALE

    # Drop shadow
    shadow_pts = [(tl_x, t_y + 8*SCALE), (tr_x, t_y + 8*SCALE), (r_x, m_y + 8*SCALE),
                  (cx, b_y + 8*SCALE), (l_x, m_y + 8*SCALE)]
    im = draw_drop_shadow(im, shadow_pts)
    draw = ImageDraw.Draw(im)

    # Top facets
    draw.polygon([(tl_x, t_y), (tr_x, t_y), (cx, m_y)], fill=(0, 230, 240, 255))
    draw.polygon([(tl_x, t_y), (cx, m_y), (l_x, m_y)], fill=(0, 180, 220, 255))
    draw.polygon([(tr_x, t_y), (r_x, m_y), (cx, m_y)], fill=(0, 210, 235, 255))

    # Bottom facets
    draw.polygon([(l_x, m_y), (cx, m_y), (cx, b_y)], fill=(0, 150, 200, 255))
    draw.polygon([(cx, m_y), (r_x, m_y), (cx, b_y)], fill=(0, 190, 225, 255))

    # Facet edges & sparkles
    draw.line([(tl_x, t_y), (tr_x, t_y), (r_x, m_y), (cx, b_y), (l_x, m_y), (tl_x, t_y)], fill=(255, 255, 255, 240), width=2*SCALE)
    draw.line([(tl_x, t_y), (cx, m_y), (cx, b_y)], fill=(255, 255, 255, 180), width=2*SCALE)
    draw.line([(tr_x, t_y), (cx, m_y)], fill=(255, 255, 255, 180), width=2*SCALE)

    # Star glint on top-left
    glint_x, glint_y = tl_x + 5*SCALE, t_y + 5*SCALE
    draw.line([(glint_x - 10*SCALE, glint_y), (glint_x + 10*SCALE, glint_y)], fill=(255, 255, 255, 255), width=2*SCALE)
    draw.line([(glint_x, glint_y - 10*SCALE), (glint_x, glint_y + 10*SCALE)], fill=(255, 255, 255, 255), width=2*SCALE)

    save_icon(im, "icon_diamond.png")

# 3. icon_trophy.png
def create_trophy():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Drop shadow
    im = draw_drop_shadow(im, [(cx - 45*SCALE, cy - 35*SCALE), (cx + 45*SCALE, cy + 50*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Base Pedestal (Dark marble / titanium with gold plate)
    draw.polygon([
        (cx - 32*SCALE, cy + 46*SCALE), (cx + 32*SCALE, cy + 46*SCALE),
        (cx + 38*SCALE, cy + 54*SCALE), (cx - 38*SCALE, cy + 54*SCALE)
    ], fill=(35, 38, 50, 255))
    draw.rectangle([(cx - 24*SCALE, cy + 34*SCALE), (cx + 24*SCALE, cy + 46*SCALE)], fill=(45, 48, 62, 255))
    # Golden plaque
    draw.rectangle([(cx - 16*SCALE, cy + 37*SCALE), (cx + 16*SCALE, cy + 43*SCALE)], fill=(255, 185, 30, 255))

    # Trophy Stem
    draw.polygon([(cx - 8*SCALE, cy + 18*SCALE), (cx + 8*SCALE, cy + 18*SCALE),
                  (cx + 14*SCALE, cy + 34*SCALE), (cx - 14*SCALE, cy + 34*SCALE)], fill=(225, 160, 20, 255))

    # Dual Wing Handles
    draw.arc([(cx - 52*SCALE, cy - 32*SCALE), (cx - 18*SCALE, cy + 14*SCALE)], start=90, end=270, fill=(245, 175, 25, 255), width=6*SCALE)
    draw.arc([(cx + 18*SCALE, cy - 32*SCALE), (cx + 52*SCALE, cy + 14*SCALE)], start=270, end=90, fill=(245, 175, 25, 255), width=6*SCALE)

    # Golden Trophy Cup
    cup_pts = [
        (cx - 32*SCALE, cy - 36*SCALE),
        (cx + 32*SCALE, cy - 36*SCALE),
        (cx + 28*SCALE, cy - 4*SCALE),
        (cx + 12*SCALE, cy + 18*SCALE),
        (cx - 12*SCALE, cy + 18*SCALE),
        (cx - 28*SCALE, cy - 4*SCALE),
    ]
    draw.polygon(cup_pts, fill=(255, 195, 35, 255))
    # Cup rim
    draw.ellipse([(cx - 34*SCALE, cy - 42*SCALE), (cx + 34*SCALE, cy - 30*SCALE)], fill=(255, 215, 65, 255), outline=(225, 160, 20, 255), width=2*SCALE)

    # Shading and specular highlight
    draw.line([(cx - 18*SCALE, cy - 32*SCALE), (cx - 8*SCALE, cy + 12*SCALE)], fill=(255, 255, 255, 190), width=4*SCALE)

    # Star emblem on cup
    draw.polygon([(cx, cy - 18*SCALE), (cx + 4*SCALE, cy - 8*SCALE), (cx + 14*SCALE, cy - 8*SCALE),
                  (cx + 6*SCALE, cy - 2*SCALE), (cx + 10*SCALE, cy + 8*SCALE), (cx, cy + 2*SCALE),
                  (cx - 10*SCALE, cy + 8*SCALE), (cx - 6*SCALE, cy - 2*SCALE), (cx - 14*SCALE, cy - 8*SCALE),
                  (cx - 4*SCALE, cy - 8*SCALE)], fill=(255, 255, 255, 240))

    save_icon(im, "icon_trophy.png")

# 4. icon_gear.png
def create_gear():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    draw = ImageDraw.Draw(im)

    r_outer = 48 * SCALE
    r_inner = 38 * SCALE
    r_hole = 16 * SCALE
    num_teeth = 6

    # Draw teeth
    gear_pts = []
    for i in range(num_teeth):
        a_mid = i * (2 * math.pi / num_teeth)
        a1 = a_mid - 0.22
        a2 = a_mid - 0.14
        a3 = a_mid + 0.14
        a4 = a_mid + 0.22
        gear_pts.append((cx + r_inner * math.cos(a1), cy + r_inner * math.sin(a1)))
        gear_pts.append((cx + r_outer * math.cos(a2), cy + r_outer * math.sin(a2)))
        gear_pts.append((cx + r_outer * math.cos(a3), cy + r_outer * math.sin(a3)))
        gear_pts.append((cx + r_inner * math.cos(a4), cy + r_inner * math.sin(a4)))

    im = draw_drop_shadow(im, [(cx - r_outer, cy - r_outer + 5*SCALE), (cx + r_outer, cy + r_outer + 5*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Fill Gear body (Sleek Titanium Silver with gold accent)
    draw.polygon(gear_pts, fill=(195, 202, 215, 255), outline=(240, 245, 255, 255), width=2*SCALE)
    draw.ellipse([(cx - r_inner, cy - r_inner), (cx + r_inner, cy + r_inner)], fill=(195, 202, 215, 255))
    
    # Golden inner ring
    draw.ellipse([(cx - r_hole - 8*SCALE, cy - r_hole - 8*SCALE), (cx + r_hole + 8*SCALE, cy + r_hole + 8*SCALE)],
                 fill=(255, 185, 30, 255), outline=(220, 150, 15, 255), width=2*SCALE)

    # Center axle cutout
    draw.ellipse([(cx - r_hole, cy - r_hole), (cx + r_hole, cy + r_hole)], fill=(22, 24, 34, 255), outline=(50, 54, 70, 255), width=2*SCALE)

    save_icon(im, "icon_gear.png")

# 5. icon_mail.png
def create_mail():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    w = 46 * SCALE
    h = 32 * SCALE
    box = [(cx - w, cy - h + 4*SCALE), (cx + w, cy + h + 4*SCALE)]
    im = draw_drop_shadow(im, [(cx - w, cy - h + 8*SCALE), (cx + w, cy + h + 8*SCALE)])
    draw = ImageDraw.Draw(im)

    # Envelope base (White / Silver metallic)
    draw.rounded_rectangle([(cx - w, cy - h), (cx + w, cy + h)], radius=6*SCALE, fill=(235, 238, 246, 255), outline=(180, 185, 200, 255), width=2*SCALE)

    # Flap folds
    draw.polygon([(cx - w, cy - h), (cx + w, cy - h), (cx, cy + 4*SCALE)], fill=(245, 248, 255, 255), outline=(190, 195, 210, 255), width=2*SCALE)
    draw.line([(cx - w, cy + h), (cx - 10*SCALE, cy - 2*SCALE)], fill=(190, 195, 210, 255), width=2*SCALE)
    draw.line([(cx + w, cy + h), (cx + 10*SCALE, cy - 2*SCALE)], fill=(190, 195, 210, 255), width=2*SCALE)

    # Red notification badge / seal in top-right
    badge_x, badge_y = cx + w - 4*SCALE, cy - h + 4*SCALE
    draw.ellipse([(badge_x - 12*SCALE, badge_y - 12*SCALE), (badge_x + 12*SCALE, badge_y + 12*SCALE)], fill=(220, 45, 55, 255), outline=(255, 255, 255, 255), width=2*SCALE)

    save_icon(im, "icon_mail.png")

# 6. icon_gift.png
def create_gift():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    im = draw_drop_shadow(im, [(cx - 40*SCALE, cy - 25*SCALE), (cx + 40*SCALE, cy + 48*SCALE)])
    draw = ImageDraw.Draw(im)

    # Gift Box Bottom (Crimson Red)
    draw.rounded_rectangle([(cx - 36*SCALE, cy - 10*SCALE), (cx + 36*SCALE, cy + 44*SCALE)], radius=5*SCALE, fill=(215, 45, 60, 255))
    # Gift Box Lid
    draw.rounded_rectangle([(cx - 42*SCALE, cy - 24*SCALE), (cx + 42*SCALE, cy - 8*SCALE)], radius=4*SCALE, fill=(235, 60, 75, 255))

    # Golden Ribbon (Vertical & Horizontal)
    rw = 8 * SCALE
    draw.rectangle([(cx - rw, cy - 24*SCALE), (cx + rw, cy + 44*SCALE)], fill=(255, 185, 30, 255))
    draw.rectangle([(cx - 42*SCALE, cy - 18*SCALE), (cx + 42*SCALE, cy - 14*SCALE)], fill=(255, 185, 30, 255))

    # Ribbon Bow on Top
    bow_y = cy - 32 * SCALE
    draw.arc([(cx - 24*SCALE, bow_y - 12*SCALE), (cx, bow_y + 10*SCALE)], start=90, end=330, fill=(255, 185, 30, 255), width=5*SCALE)
    draw.arc([(cx, bow_y - 12*SCALE), (cx + 24*SCALE, bow_y + 10*SCALE)], start=210, end=90, fill=(255, 185, 30, 255), width=5*SCALE)
    draw.ellipse([(cx - 6*SCALE, bow_y - 4*SCALE), (cx + 6*SCALE, bow_y + 6*SCALE)], fill=(255, 215, 60, 255))

    save_icon(im, "icon_gift.png")

# 7. icon_car.png
def create_car_icon():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    im = draw_drop_shadow(im, [(cx - 48*SCALE, cy + 18*SCALE), (cx + 48*SCALE, cy + 32*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Sleek side profile sports car
    body = [
        (cx - 45*SCALE, cy + 14*SCALE),
        (cx - 42*SCALE, cy + 2*SCALE),
        (cx - 25*SCALE, cy - 6*SCALE),
        (cx - 10*SCALE, cy - 18*SCALE),
        (cx + 15*SCALE, cy - 18*SCALE),
        (cx + 34*SCALE, cy - 2*SCALE),
        (cx + 46*SCALE, cy + 2*SCALE),
        (cx + 46*SCALE, cy + 14*SCALE),
    ]
    draw.polygon(body, fill=(245, 248, 255, 255), outline=(200, 35, 45, 255), width=2*SCALE)

    # Cabin window
    cabin = [
        (cx - 22*SCALE, cy - 4*SCALE),
        (cx - 8*SCALE, cy - 15*SCALE),
        (cx + 12*SCALE, cy - 15*SCALE),
        (cx + 28*SCALE, cy - 4*SCALE),
    ]
    draw.polygon(cabin, fill=(22, 25, 36, 255))

    # Racing side stripe
    draw.line([(cx - 40*SCALE, cy + 4*SCALE), (cx + 42*SCALE, cy + 4*SCALE)], fill=(200, 35, 45, 255), width=3*SCALE)

    # Wheels
    for wx in [cx - 28*SCALE, cx + 28*SCALE]:
        draw.ellipse([(wx - 10*SCALE, cy + 8*SCALE), (wx + 10*SCALE, cy + 28*SCALE)], fill=(20, 22, 28, 255))
        draw.ellipse([(wx - 5*SCALE, cy + 13*SCALE), (wx + 5*SCALE, cy + 23*SCALE)], fill=(200, 205, 215, 255))

    save_icon(im, "icon_car.png")

# 8. icon_cart.png
def create_cart():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    draw = ImageDraw.Draw(im)
    # Shopping basket frame (Racing Yellow)
    col = (255, 181, 27, 255)
    # Basket outline
    pts = [
        (cx - 36*SCALE, cy - 26*SCALE), # handle
        (cx - 26*SCALE, cy - 26*SCALE),
        (cx - 16*SCALE, cy + 14*SCALE),
        (cx + 28*SCALE, cy + 14*SCALE),
        (cx + 38*SCALE, cy - 18*SCALE),
        (cx - 22*SCALE, cy - 18*SCALE),
    ]
    draw.line([(pts[0]), (pts[1]), (pts[2]), (pts[3]), (pts[4]), (pts[5])], fill=col, width=5*SCALE)

    # Basket grid lines
    draw.line([(cx - 10*SCALE, cy - 18*SCALE), (cx - 6*SCALE, cy + 12*SCALE)], fill=(255, 205, 80, 255), width=3*SCALE)
    draw.line([(cx + 6*SCALE, cy - 18*SCALE), (cx + 8*SCALE, cy + 12*SCALE)], fill=(255, 205, 80, 255), width=3*SCALE)
    draw.line([(cx + 22*SCALE, cy - 18*SCALE), (cx + 20*SCALE, cy + 12*SCALE)], fill=(255, 205, 80, 255), width=3*SCALE)

    # Wheels
    for wx in [cx - 12*SCALE, cx + 24*SCALE]:
        wy = cy + 26*SCALE
        draw.ellipse([(wx - 7*SCALE, wy - 7*SCALE), (wx + 7*SCALE, wy + 7*SCALE)], fill=(235, 240, 250, 255), outline=(30, 32, 42, 255), width=2*SCALE)

    save_icon(im, "icon_cart.png")

# 9. icon_leaderboard.png
def create_leaderboard():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    im = draw_drop_shadow(im, [(cx - 45*SCALE, cy - 15*SCALE), (cx + 45*SCALE, cy + 45*SCALE)])
    draw = ImageDraw.Draw(im)

    # 3-step podium
    # 2nd Place (Left)
    draw.rounded_rectangle([(cx - 44*SCALE, cy - 5*SCALE), (cx - 16*SCALE, cy + 38*SCALE)], radius=3*SCALE, fill=(185, 195, 210, 255))
    # 1st Place (Center - Tallest)
    draw.rounded_rectangle([(cx - 14*SCALE, cy - 22*SCALE), (cx + 14*SCALE, cy + 38*SCALE)], radius=3*SCALE, fill=(255, 185, 30, 255))
    # 3rd Place (Right)
    draw.rounded_rectangle([(cx + 16*SCALE, cy + 8*SCALE), (cx + 44*SCALE, cy + 38*SCALE)], radius=3*SCALE, fill=(205, 125, 75, 255))

    # Numbers 1, 2, 3
    draw.text((cx - 5*SCALE, cy - 15*SCALE), "1", fill=(20, 22, 30, 255))
    draw.text((cx - 35*SCALE, cy + 5*SCALE), "2", fill=(20, 22, 30, 255))
    draw.text((cx + 25*SCALE, cy + 15*SCALE), "3", fill=(20, 22, 30, 255))

    # Star above 1st place
    star_y = cy - 36 * SCALE
    draw.polygon([(cx, star_y - 8*SCALE), (cx + 3*SCALE, star_y - 2*SCALE), (cx + 9*SCALE, star_y - 2*SCALE),
                  (cx + 4*SCALE, star_y + 2*SCALE), (cx + 6*SCALE, star_y + 8*SCALE), (cx, star_y + 4*SCALE),
                  (cx - 6*SCALE, star_y + 8*SCALE), (cx - 4*SCALE, star_y + 2*SCALE), (cx - 9*SCALE, star_y - 2*SCALE),
                  (cx - 3*SCALE, star_y - 2*SCALE)], fill=(255, 220, 60, 255))

    save_icon(im, "icon_leaderboard.png")

# 10. icon_news.png
def create_news():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    w, h = 38 * SCALE, 44 * SCALE
    im = draw_drop_shadow(im, [(cx - w, cy - h + 6*SCALE), (cx + w, cy + h + 6*SCALE)])
    draw = ImageDraw.Draw(im)

    # Folded Newspaper
    draw.rounded_rectangle([(cx - w, cy - h), (cx + w, cy + h)], radius=4*SCALE, fill=(245, 245, 250, 255), outline=(190, 195, 205, 255), width=2*SCALE)

    # Red Header Banner
    draw.rectangle([(cx - w + 2*SCALE, cy - h + 4*SCALE), (cx + w - 2*SCALE, cy - h + 18*SCALE)], fill=(200, 35, 45, 255))
    # Header checkered accent
    for i in range(0, int(w*2 - 8*SCALE), 8*SCALE):
        draw.rectangle([(cx - w + 4*SCALE + i, cy - h + 6*SCALE), (cx - w + 8*SCALE + i, cy - h + 10*SCALE)], fill=(255, 255, 255, 230))

    # Photo Box
    draw.rectangle([(cx - w + 6*SCALE, cy - h + 24*SCALE), (cx - 2*SCALE, cy + 6*SCALE)], fill=(30, 35, 50, 255))
    # Car silhouette inside photo
    draw.ellipse([(cx - 22*SCALE, cy - 4*SCALE), (cx - 8*SCALE, cy + 2*SCALE)], fill=(255, 181, 27, 255))

    # Text Lines
    for ly in [cy - h + 26*SCALE, cy - h + 32*SCALE, cy - h + 38*SCALE, cy + 14*SCALE, cy + 22*SCALE, cy + 30*SCALE]:
        draw.line([(cx + 4*SCALE, ly), (cx + w - 6*SCALE, ly)], fill=(120, 125, 140, 255), width=2*SCALE)
    # Bottom full width lines
    draw.line([(cx - w + 6*SCALE, cy + 16*SCALE), (cx + w - 6*SCALE, cy + 16*SCALE)], fill=(120, 125, 140, 255), width=2*SCALE)
    draw.line([(cx - w + 6*SCALE, cy + 26*SCALE), (cx + w - 6*SCALE, cy + 26*SCALE)], fill=(120, 125, 140, 255), width=2*SCALE)
    draw.line([(cx - w + 6*SCALE, cy + 36*SCALE), (cx + 10*SCALE, cy + 36*SCALE)], fill=(120, 125, 140, 255), width=2*SCALE)

    save_icon(im, "icon_news.png")

# 11. icon_customize.png
def create_customize():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    draw = ImageDraw.Draw(im)

    # Crossed Wrench and Paint Spray / Palette
    # 1. Chrome Wrench (diagonal /)
    wr_col = (200, 208, 222, 255)
    draw.line([(cx - 36*SCALE, cy + 36*SCALE), (cx + 36*SCALE, cy - 36*SCALE)], fill=wr_col, width=10*SCALE)
    # Wrench open end
    draw.ellipse([(cx + 25*SCALE, cy - 45*SCALE), (cx + 45*SCALE, cy - 25*SCALE)], outline=wr_col, width=6*SCALE)

    # 2. Paint Spray Can / Gun (diagonal \)
    sp_col = (255, 181, 27, 255)
    draw.line([(cx + 32*SCALE, cy + 32*SCALE), (cx - 15*SCALE, cy - 15*SCALE)], fill=(40, 44, 56, 255), width=12*SCALE)
    draw.line([(cx - 15*SCALE, cy - 15*SCALE), (cx - 30*SCALE, cy - 30*SCALE)], fill=sp_col, width=14*SCALE)

    # Paint droplets
    draw.ellipse([(cx - 38*SCALE, cy - 42*SCALE), (cx - 32*SCALE, cy - 36*SCALE)], fill=(255, 94, 54, 255))
    draw.ellipse([(cx - 44*SCALE, cy - 26*SCALE), (cx - 38*SCALE, cy - 20*SCALE)], fill=(0, 210, 211, 255))
    draw.ellipse([(cx - 24*SCALE, cy - 46*SCALE), (cx - 18*SCALE, cy - 40*SCALE)], fill=(255, 181, 27, 255))

    save_icon(im, "icon_customize.png")

# 12. icon_quit.png
def create_quit():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    r = 44 * SCALE

    im = draw_drop_shadow(im, [(cx - r, cy - r + 5*SCALE), (cx + r, cy + r + 5*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Emergency Power / Exit Ring (Crimson Red)
    draw.arc([(cx - r, cy - r), (cx + r, cy + r)], start=300, end=240, fill=(215, 45, 60, 255), width=8*SCALE)
    # Center Power Line
    draw.line([(cx, cy - r), (cx, cy - 6*SCALE)], fill=(215, 45, 60, 255), width=8*SCALE)

    # Bevel highlight
    draw.arc([(cx - r, cy - r), (cx + r, cy + r)], start=310, end=230, fill=(255, 120, 130, 180), width=3*SCALE)
    draw.line([(cx, cy - r + 2*SCALE), (cx, cy - 6*SCALE)], fill=(255, 200, 205, 200), width=3*SCALE)

    save_icon(im, "icon_quit.png")

# 13. icon_play.png
def create_play():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Bold Play Triangle with chamfer & speed streaks
    pts = [
        (cx - 30*SCALE, cy - 44*SCALE),
        (cx + 42*SCALE, cy),
        (cx - 30*SCALE, cy + 44*SCALE),
    ]
    im = draw_drop_shadow(im, [(p[0], p[1] + 6*SCALE) for p in pts])
    draw = ImageDraw.Draw(im)

    # Golden Racing Gradient Fill
    draw.polygon(pts, fill=(255, 181, 27, 255))
    # Bevel top edge
    draw.line([pts[0], pts[1]], fill=(255, 240, 140, 255), width=4*SCALE)
    # Bevel bottom edge
    draw.line([pts[1], pts[2]], fill=(200, 120, 10, 255), width=4*SCALE)

    # Speed trailing lines on the left
    draw.line([(cx - 44*SCALE, cy - 24*SCALE), (cx - 36*SCALE, cy - 24*SCALE)], fill=(255, 181, 27, 200), width=4*SCALE)
    draw.line([(cx - 50*SCALE, cy), (cx - 36*SCALE, cy)], fill=(255, 181, 27, 200), width=4*SCALE)
    draw.line([(cx - 44*SCALE, cy + 24*SCALE), (cx - 36*SCALE, cy + 24*SCALE)], fill=(255, 181, 27, 200), width=4*SCALE)

    save_icon(im, "icon_play.png")

# 14. icon_plus.png
def create_plus():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    r = 46 * SCALE

    im = draw_drop_shadow(im, [(cx - r, cy - r + 5*SCALE), (cx + r, cy + r + 5*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Circular Gold / Green Base
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], fill=(255, 181, 27, 255), outline=(225, 145, 15, 255), width=3*SCALE)

    # White Plus Sign
    pw = 9 * SCALE
    ph = 26 * SCALE
    draw.rounded_rectangle([(cx - pw, cy - ph), (cx + pw, cy + ph)], radius=3*SCALE, fill=(255, 255, 255, 255))
    draw.rounded_rectangle([(cx - ph, cy - pw), (cx + ph, cy + pw)], radius=3*SCALE, fill=(255, 255, 255, 255))

    save_icon(im, "icon_plus.png")

# 15. icon_check.png
def create_check():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    r = 46 * SCALE

    im = draw_drop_shadow(im, [(cx - r, cy - r + 5*SCALE), (cx + r, cy + r + 5*SCALE)], is_ellipse=True)
    draw = ImageDraw.Draw(im)

    # Emerald Green Circular Badge
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], fill=(46, 213, 115, 255), outline=(35, 180, 95, 255), width=3*SCALE)

    # Crisp White Checkmark
    chk_pts = [
        (cx - 24*SCALE, cy),
        (cx - 8*SCALE, cy + 18*SCALE),
        (cx + 26*SCALE, cy - 20*SCALE)
    ]
    draw.line(chk_pts, fill=(255, 255, 255, 255), width=10*SCALE, joint="curve")

    save_icon(im, "icon_check.png")

# 16. icon_lock.png
def create_lock():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    im = draw_drop_shadow(im, [(cx - 36*SCALE, cy - 35*SCALE), (cx + 36*SCALE, cy + 45*SCALE)])
    draw = ImageDraw.Draw(im)

    # Silver Steel Shackle (Arch)
    draw.arc([(cx - 24*SCALE, cy - 42*SCALE), (cx + 24*SCALE, cy + 10*SCALE)], start=180, end=0, fill=(195, 202, 215, 255), width=9*SCALE)

    # Brass / Gold Lock Body
    draw.rounded_rectangle([(cx - 34*SCALE, cy - 8*SCALE), (cx + 34*SCALE, cy + 44*SCALE)], radius=6*SCALE, fill=(245, 175, 25, 255), outline=(215, 140, 15, 255), width=3*SCALE)

    # Keyhole
    draw.ellipse([(cx - 7*SCALE, cy + 8*SCALE), (cx + 7*SCALE, cy + 22*SCALE)], fill=(20, 22, 30, 255))
    draw.polygon([(cx - 5*SCALE, cy + 16*SCALE), (cx + 5*SCALE, cy + 16*SCALE),
                  (cx + 8*SCALE, cy + 32*SCALE), (cx - 8*SCALE, cy + 32*SCALE)], fill=(20, 22, 30, 255))

    save_icon(im, "icon_lock.png")

if __name__ == "__main__":
    create_coin()
    create_diamond()
    create_trophy()
    create_gear()
    create_mail()
    create_gift()
    create_car_icon()
    create_cart()
    create_leaderboard()
    create_news()
    create_customize()
    create_quit()
    create_play()
    create_plus()
    create_check()
    create_lock()
    print("All UI icons generated successfully!")
