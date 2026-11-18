"""
RACEZONE - Track Texture Generator
Generates track and race surface textures for 2D race scenes:
- track_asphalt.png (seamless tarmac)
- track_kerb.png (racing kerbing / apex rumble strip)
- track_finish_line.png (checkered line)
- track_barrier.png (circuit safety barrier)
"""
import random
from PIL import Image, ImageDraw

def create_track_textures():
    print("Generating track textures...")

    # 1. track_asphalt.png (256x256 seamless tarmac)
    im_asphalt = Image.new("RGBA", (256, 256), (32, 34, 44, 255))
    draw_a = ImageDraw.Draw(im_asphalt)
    random.seed(999)
    # Add subtle aggregate noise
    for _ in range(12000):
        x = random.randint(0, 255)
        y = random.randint(0, 255)
        v = random.randint(22, 52)
        draw_a.point((x, y), fill=(v, v + 2, v + 6, 255))
    im_asphalt.save("assets/art/tracks/track_asphalt.png", "PNG")
    print("-> Saved assets/art/tracks/track_asphalt.png")

    # 2. track_kerb.png (256x64 red/white alternating curb)
    im_kerb = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    draw_k = ImageDraw.Draw(im_kerb)
    block_w = 32
    for i in range(0, 256, block_w):
        col = (200, 35, 45, 255) if (i // block_w) % 2 == 0 else (245, 248, 255, 255)
        draw_k.rectangle([(i, 0), (i + block_w, 64)], fill=col)
        # 3D bevel / ridge line
        draw_k.line([(i, 0), (i + block_w, 0)], fill=(255, 255, 255, 160), width=3)
        draw_k.line([(i, 63), (i + block_w, 63)], fill=(20, 22, 30, 180), width=3)
    im_kerb.save("assets/art/tracks/track_kerb.png", "PNG")
    print("-> Saved assets/art/tracks/track_kerb.png")

    # 3. track_finish_line.png (256x64 checkered start/finish strip)
    im_finish = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    draw_f = ImageDraw.Draw(im_finish)
    sq = 16
    for r in range(4):
        for c in range(16):
            col = (250, 252, 255, 255) if (r + c) % 2 == 0 else (20, 22, 30, 255)
            draw_f.rectangle([(c * sq, r * sq), ((c + 1) * sq, (r + 1) * sq)], fill=col)
    im_finish.save("assets/art/tracks/track_finish_line.png", "PNG")
    print("-> Saved assets/art/tracks/track_finish_line.png")

    # 4. track_barrier.png (256x64 circuit barrier with tire stack)
    im_barrier = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    draw_b = ImageDraw.Draw(im_barrier)
    draw_b.rectangle([(0, 16), (256, 48)], fill=(40, 42, 54, 255))
    draw_b.line([(0, 16), (256, 16)], fill=(80, 85, 105, 255), width=2)
    draw_b.line([(0, 48), (256, 48)], fill=(15, 16, 22, 255), width=2)
    # Red & white diagonal chevron hazard stripes
    for x in range(-32, 256, 32):
        draw_b.polygon([(x, 48), (x + 16, 16), (x + 32, 16), (x + 16, 48)], fill=(200, 35, 45, 255))
    im_barrier.save("assets/art/tracks/track_barrier.png", "PNG")
    print("-> Saved assets/art/tracks/track_barrier.png")

if __name__ == "__main__":
    create_track_textures()
