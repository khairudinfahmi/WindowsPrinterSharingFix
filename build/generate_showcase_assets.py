"""
Generate high-fidelity showcase assets for Windows Printer Sharing Fix.
Generates:
  1. assets/preview-main-menu.png  (Terminal window preview of Main Menu & Health HUD)
  2. assets/preview-scanner.png    (Terminal window preview of Submenu 7 Scanner & UNC Port Map)
  3. assets/social-banner.png      (1200x630 OpenGraph / Social Share preview card)
"""

import os
import sys
import math
from PIL import Image, ImageDraw, ImageFont

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

WINDIR = os.environ.get("WINDIR", r"C:\Windows")
FONTS_DIR = os.path.join(WINDIR, "Fonts")

def get_font(name, size):
    path = os.path.join(FONTS_DIR, name)
    if os.path.exists(path):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()

FONT_MONO = get_font("consola.ttf", 15)
FONT_MONO_BOLD = get_font("consolab.ttf", 15)
FONT_MONO_SMALL = get_font("consola.ttf", 13)
FONT_MONO_BANNER = get_font("consola.ttf", 11)
FONT_MONO_BANNER_BOLD = get_font("consolab.ttf", 11)

FONT_SANS = get_font("segoeui.ttf", 16)
FONT_SANS_BOLD = get_font("segoeuib.ttf", 28)
FONT_SANS_SUB = get_font("segoeui.ttf", 17)
FONT_SANS_SMALL = get_font("segoeui.ttf", 14)
FONT_SANS_TAG = get_font("segoeuib.ttf", 13)
FONT_SANS_BADGE = get_font("segoeuib.ttf", 11)

# Terminal color palette
BG_DARK = (15, 23, 42)          # Slate 900
HEADER_BG = (30, 41, 59)        # Slate 800
BORDER_COLOR = (51, 65, 85)     # Slate 700
TEXT_WHITE = (248, 250, 252)
TEXT_GRAY = (148, 163, 184)
TEXT_DARKGRAY = (100, 116, 139)
TEXT_CYAN = (56, 189, 248)      # Sky 400
TEXT_GREEN = (74, 222, 128)     # Green 400
TEXT_YELLOW = (250, 204, 21)    # Yellow 400
TEXT_RED = (248, 113, 113)      # Red 400
TEXT_MAGENTA = (232, 121, 249)

def draw_star(draw, cx, cy, size=7, fill=(250, 204, 21)):
    points = []
    for i in range(10):
        angle = i * math.pi / 5 - math.pi / 2
        r = size if i % 2 == 0 else size * 0.45
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=fill)

def draw_window_frame(draw, width, height, title="Windows Terminal - Windows Printer Sharing Fix"):
    draw.rounded_rectangle([(0, 0), (width, height)], radius=10, fill=BG_DARK, outline=BORDER_COLOR, width=2)
    draw.rounded_rectangle([(0, 0), (width, 38)], radius=10, fill=HEADER_BG)
    draw.rectangle([(0, 28), (width, 38)], fill=HEADER_BG)
    draw.line([(0, 38), (width, 38)], fill=BORDER_COLOR, width=1)
    
    # Red, Yellow, Green subtle dots
    draw.ellipse([(14, 13), (24, 23)], fill=(239, 68, 68))
    draw.ellipse([(32, 13), (42, 23)], fill=(234, 179, 8))
    draw.ellipse([(50, 13), (60, 23)], fill=(34, 197, 94))
    
    # Title
    draw.text((72, 11), title, font=FONT_SANS_SMALL, fill=TEXT_GRAY)

def generate_main_menu():
    w, h = 960, 620
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    json_path = os.path.join(ASSETS_DIR, "console-lines.json")
    version_str = "2.4.0"
    real_lines = []
    if os.path.exists(json_path):
        try:
            import json
            with open(json_path, "r", encoding="utf-8-sig") as jf:
                data = json.load(jf)
                version_str = data.get("version", "2.4.0")
                real_lines = data.get("lines", [])
        except Exception as e:
            print(f"[WARN] Failed to read {json_path}: {e}")

    draw_window_frame(draw, w, h, f"PowerShell (Admin) - Windows Printer Sharing Fix v{version_str}")
    
    x = 24
    y = 52
    line_h = 21

    if real_lines:
        color_map = {
            'Green': TEXT_GREEN,
            'Cyan': TEXT_CYAN,
            'Yellow': TEXT_YELLOW,
            'Red': TEXT_RED,
            'White': TEXT_WHITE,
            'Gray': TEXT_GRAY,
            'DarkGray': TEXT_DARKGRAY,
            'DarkCyan': (2, 132, 199)
        }
        for line_obj in real_lines:
            segs = line_obj.get("Segments", [])
            seg_x = x
            full_line = ""
            for seg in segs:
                stext = seg.get("Text", "")
                full_line += stext
                scolor = color_map.get(seg.get("Color"), TEXT_WHITE)
                font_to_use = FONT_MONO_BOLD if seg.get("Color") in ['Green', 'Yellow', 'Red'] and not stext.startswith("=") and not stext.startswith("-") else FONT_MONO
                draw.text((seg_x, y), stext, font=font_to_use, fill=scolor)
                seg_x += int(draw.textlength(stext, font=font_to_use))
            fl = full_line.strip().lower()
            if "select option" in fl or "pilih nomor" in fl:
                cursor_txt = "1\u2588" if full_line.endswith(" ") else " 1\u2588"
                draw.text((seg_x, y), cursor_txt, font=FONT_MONO_BOLD, fill=TEXT_WHITE)
            y += line_h
    else:
        line_bar = "=" * 86
        draw.text((x, y), line_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h
        draw.text((x, y), "   WINDOWS PRINTER SHARING FIX  |  Windows Network Printer Repair Tool", font=FONT_MONO_BOLD, fill=TEXT_GREEN); y += line_h
        draw.text((x, y), f"   Version: {version_str}  |  System: WINDOWS 11 PRO 26200 64-BIT", font=FONT_MONO, fill=TEXT_CYAN); y += line_h
        draw.text((x, y), "   Computer: DESKTOP-OFFICE01  |  User: Administrator", font=FONT_MONO, fill=TEXT_GRAY); y += line_h
        
        hud_y = y
        draw.text((x, hud_y), "   STATUS: ", font=FONT_MONO, fill=TEXT_GRAY)
        hx = x + 11 * 9
        draw.text((hx, hud_y), "Spooler [RUNNING] ", font=FONT_MONO_BOLD, fill=TEXT_GREEN); hx += 18 * 9
        draw.text((hx, hud_y), "| ", font=FONT_MONO, fill=TEXT_DARKGRAY); hx += 2 * 9
        draw.text((hx, hud_y), "Network [PRIVATE] ", font=FONT_MONO_BOLD, fill=TEXT_GREEN); hx += 18 * 9
        draw.text((hx, hud_y), "| ", font=FONT_MONO, fill=TEXT_DARKGRAY); hx += 2 * 9
        draw.text((hx, hud_y), "SMB Signing [OK] ", font=FONT_MONO_BOLD, fill=TEXT_GREEN); hx += 17 * 9
        draw.text((hx, hud_y), "| ", font=FONT_MONO, fill=TEXT_DARKGRAY); hx += 2 * 9
        draw.text((hx, hud_y), "Pass Sharing [OFF]", font=FONT_MONO_BOLD, fill=TEXT_GREEN)
        y += line_h
        
        draw.text((x, y), line_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h + 6
        draw.text((x, y), "  SELECT REPAIR CATEGORY:", font=FONT_MONO_BOLD, fill=TEXT_YELLOW); y += line_h + 4
        
        draw.text((x, y), "  [1] Quick & Automated Solutions (ALLFIX & Modern Win 11)", font=FONT_MONO_BOLD, fill=TEXT_GREEN)
        draw.text((x + 520, y), "<-- RECOMMENDED", font=FONT_MONO_BOLD, fill=TEXT_RED); y += line_h
        draw.text((x, y), "  [2] Fix Specific Error Codes (0x11b, 0x709, 0xbc4, 0x040, etc.)", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [3] Network, File & Printer Sharing (SMB) & Firewall", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [4] Print Spooler Service & Print Queue Maintenance", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [5] Driver Management & Ghost / USB Printer Cleanup", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [6] Credentials, Access Rights & Security (Vault, LSA, UAC)", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [7] Port Mapping & Manual Connections (UNC Port Map & TCP/IP)", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
        draw.text((x, y), "  [8] Backup, System Diagnostics & Recovery", font=FONT_MONO, fill=TEXT_WHITE); y += line_h + 6
        
        draw.text((x, y), "  [9] Help & Usage Guide", font=FONT_MONO, fill=TEXT_CYAN); y += line_h
        draw.text((x, y), "  [L] Switch Language / Ganti ke Bahasa Indonesia", font=FONT_MONO, fill=TEXT_YELLOW); y += line_h
        draw.text((x, y), "  [0] Exit Application", font=FONT_MONO, fill=TEXT_DARKGRAY); y += line_h + 6
        
        div_bar = "-" * 86
        draw.text((x, y), div_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h
        draw.text((x, y), "  [Shortcut Tips]: Enter menu (1-9), press [L] to switch language, or type classic", font=FONT_MONO_SMALL, fill=TEXT_GRAY); y += line_h - 2
        draw.text((x, y), "                   codes directly like 84 (AllFix), 83 (Extreme), 64 (Backup), 86 (UNC).", font=FONT_MONO_SMALL, fill=TEXT_GRAY); y += line_h - 2
        draw.text((x, y), div_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h + 4
        
        draw.text((x, y), "Select option: ", font=FONT_MONO_BOLD, fill=TEXT_YELLOW)
        draw.text((x + 15 * 9, y), "1█", font=FONT_MONO_BOLD, fill=TEXT_WHITE)
    
    out_path = os.path.join(ASSETS_DIR, "preview-main-menu.png")
    img.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

def generate_scanner_preview():
    w, h = 960, 560
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_window_frame(draw, w, h, "PowerShell (Admin) - Remote Printer Scanner & 1-Click UNC Port Mapping")
    
    x = 24
    y = 52
    line_h = 21

    draw.text((x, y), "SUBMENU 7: PORT MAPPING & MANUAL CONNECTIONS", font=FONT_MONO_BOLD, fill=TEXT_CYAN); y += line_h + 4
    draw.text((x, y), "  [*] Running Fast Multi-Tier LAN Printer Discovery...", font=FONT_MONO, fill=TEXT_YELLOW); y += line_h + 2
    draw.text((x, y), "  [+] Discovered 4 active shared printer(s) across LAN:", font=FONT_MONO, fill=TEXT_GREEN); y += line_h + 4
    
    div_bar = "=" * 86
    draw.text((x, y), div_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h
    draw.text((x, y), "   [#]  PRINTER NAME             SHARE NAME        UNC PATH                             STATUS", font=FONT_MONO_BOLD, fill=TEXT_YELLOW); y += line_h
    draw.text((x, y), "-" * 86, font=FONT_MONO, fill=TEXT_CYAN); y += line_h
    
    rows = [
        ("[1]  ", "EPSON L3210 Series      ", "EPSON_L3210      ", "\\\\SERVER-PC\\EPSON L3210 Series      ", "[ONLINE]"),
        ("[2]  ", "Canon G2010 series      ", "Canon_G2010      ", "\\\\SERVER-PC\\Canon G2010 series      ", "[ONLINE]"),
        ("[3]  ", "HP LaserJet Pro M404dn  ", "HP_M404dn        ", "\\\\ADMIN-KASIR\\HP LaserJet Pro M404  ", "[ONLINE]"),
        ("[4]  ", "Brother DCP-T720DW      ", "Brother_T720     ", "\\\\WORKSTATION-03\\Brother DCP-T720   ", "[ONLINE]"),
    ]
    for num, pname, sname, upath, st in rows:
        row_prefix = "   " + num + pname + sname + upath
        draw.text((x, y), row_prefix, font=FONT_MONO, fill=TEXT_WHITE)
        pw = int(draw.textlength(row_prefix, font=FONT_MONO))
        draw.text((x + pw, y), st, font=FONT_MONO_BOLD, fill=TEXT_GREEN)
        y += line_h
        
    draw.text((x, y), div_bar, font=FONT_MONO, fill=TEXT_CYAN); y += line_h + 6
    
    prompt_str = "  Select printer number [1-4], or 'B' to return: "
    draw.text((x, y), prompt_str, font=FONT_MONO_BOLD, fill=TEXT_YELLOW)
    prompt_w = int(draw.textlength(prompt_str, font=FONT_MONO_BOLD))
    draw.text((x + prompt_w, y), "1\u2588", font=FONT_MONO_BOLD, fill=TEXT_WHITE); y += line_h + 4
    draw.text((x, y), "  [+] UNC Target: \\\\SERVER-PC\\EPSON L3210 Series", font=FONT_MONO, fill=TEXT_CYAN); y += line_h
    draw.text((x, y), "  [+] Copied to Windows Clipboard! (Ready to paste Ctrl+V)", font=FONT_MONO_BOLD, fill=TEXT_GREEN); y += line_h
    draw.text((x, y), "  [+] Creating Local UNC Port Mapping (Bypasses 0x00000709)...", font=FONT_MONO, fill=TEXT_WHITE); y += line_h
    draw.text((x, y), "  [SUCCESS] Local Port 'LPT2:' mapped to '\\\\SERVER-PC\\EPSON L3210 Series'!", font=FONT_MONO_BOLD, fill=TEXT_GREEN); y += line_h
    draw.text((x, y), "  [SUCCESS] 0x00000709 completely resolved without modifying remote server!", font=FONT_MONO_BOLD, fill=TEXT_CYAN); y += line_h

    out_path = os.path.join(ASSETS_DIR, "preview-scanner.png")
    img.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

def generate_social_banner():
    # 1200 x 630 px (Optimal for OpenGraph, Twitter Card, GitHub Social Preview)
    w, h = 1200, 630
    img = Image.new("RGBA", (w, h), (10, 15, 29)) # Deep dark navy
    draw = ImageDraw.Draw(img)
    
    # Top-right cyan glow
    glow_cyan = Image.new("RGBA", (500, 500), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow_cyan)
    for r in range(250, 0, -5):
        alpha = int((1 - r / 250) * 40)
        g_draw.ellipse([(250 - r, 250 - r), (250 + r, 250 + r)], fill=(14, 165, 233, alpha))
    img.paste(glow_cyan, (750, -100), glow_cyan)
    
    # Bottom-left emerald glow
    glow_green = Image.new("RGBA", (400, 400), (0, 0, 0, 0))
    g_draw2 = ImageDraw.Draw(glow_green)
    for r in range(200, 0, -5):
        alpha = int((1 - r / 200) * 35)
        g_draw2.ellipse([(200 - r, 200 - r), (200 + r, 200 + r)], fill=(16, 185, 129, alpha))
    img.paste(glow_green, (-80, 350), glow_green)

    # Outer border
    draw.rounded_rectangle([(8, 8), (w - 8, h - 8)], radius=16, outline=(30, 41, 59), width=2)
    
    # Left Content Column (0 to 550)
    lx = 54
    ly = 48
    
    json_path = os.path.join(ASSETS_DIR, "console-lines.json")
    version_str = "2.4.0"
    real_lines = []
    if os.path.exists(json_path):
        try:
            import json
            with open(json_path, "r", encoding="utf-8-sig") as jf:
                data = json.load(jf)
                version_str = data.get("version", "2.4.0")
                real_lines = data.get("lines", [])
        except Exception as e:
            print(f"[WARN] Failed to read {json_path}: {e}")

    # Top Badge
    draw.rounded_rectangle([(lx, ly), (lx + 236, ly + 30)], radius=15, fill=(30, 58, 138), outline=(59, 130, 246), width=1)
    draw.text((lx + 16, ly + 6), f"OPEN SOURCE UTILITY  \u2022  v{version_str}", font=FONT_SANS_TAG, fill=(147, 197, 253))
    ly += 48
    
    # Main Title
    draw.text((lx, ly), "Windows Printer", font=FONT_SANS_BOLD, fill=(248, 250, 252))
    draw.text((lx, ly + 38), "Sharing Fix", font=FONT_SANS_BOLD, fill=(56, 189, 248))
    ly += 90
    
    # Subtitle
    draw.text((lx, ly), "Diagnose & resolve network printer sharing errors:", font=FONT_SANS_SUB, fill=(203, 213, 225))
    draw.text((lx, ly + 24), "0x0000011b, 0x00000709, 0x00000bc4, and Win 11 24H2/26H2.", font=FONT_SANS_SUB, fill=(148, 163, 184))
    ly += 65
    
    # Feature Badges (Pure typography badges - ZERO emoji tofu boxes)
    pills = [
        ("ALLFIX", "50-Step Automated Repair Routine", (22, 101, 52), (134, 239, 172), (34, 197, 94)),
        ("WIN 11", "24H2 & 26H2 SMB Signing Mitigations", (30, 58, 138), (147, 197, 253), (59, 130, 246)),
        ("SCANNER", "Remote Printer Discovery & 1-Click Port Map", (112, 26, 117), (240, 171, 252), (192, 38, 211)),
        ("BILINGUAL", "English & Bahasa Indonesia Toggle (Key [L])", (133, 77, 14), (253, 224, 71), (202, 138, 4)),
        ("PLATFORM", "x64, ARM64 & Windows Server 2012-2025", (51, 65, 85), (226, 232, 240), (100, 116, 139))
    ]
    
    py = ly
    pill_w = 460
    for tag, desc, bg_col, txt_col, tag_accent in pills:
        # Pill outer container
        draw.rounded_rectangle([(lx, py), (lx + pill_w, py + 34)], radius=8, fill=(15, 23, 42), outline=(51, 65, 85), width=1)
        # Left tag badge
        draw.rounded_rectangle([(lx + 4, py + 4), (lx + 88, py + 30)], radius=5, fill=bg_col, outline=tag_accent, width=1)
        # Center tag text
        bbox = draw.textbbox((0, 0), tag, font=FONT_SANS_BADGE)
        tw = bbox[2] - bbox[0]
        tx = lx + 4 + (84 - tw) // 2
        draw.text((tx, py + 8), tag, font=FONT_SANS_BADGE, fill=txt_col)
        # Description
        draw.text((lx + 98, py + 7), desc, font=FONT_SANS_SMALL, fill=(241, 245, 249))
        py += 44
    
    # Bottom GitHub Link with drawn vector star
    draw_star(draw, lx + 6, h - 48, size=7, fill=(250, 204, 21))
    draw.text((lx + 22, h - 56), "github.com/khairudinfahmi/WindowsPrinterSharingFix", font=FONT_SANS_SMALL, fill=(148, 163, 184))
    
    # Right Column: Terminal Window Preview Rendered Directly from .ps1 Source
    rx = 545
    ry = 45
    rw = 605
    rh = 540
    
    draw.rounded_rectangle([(rx, ry), (rx + rw, ry + rh)], radius=12, fill=(12, 16, 23), outline=(48, 54, 61), width=2)
    draw.rounded_rectangle([(rx, ry), (rx + rw, ry + 34)], radius=12, fill=(22, 27, 34))
    draw.rectangle([(rx, ry + 22), (rx + rw, ry + 34)], fill=(22, 27, 34))
    draw.line([(rx, ry + 34), (rx + rw, ry + 34)], fill=(48, 54, 61), width=1)
    
    draw.ellipse([(rx + 18, ry + 12), (rx + 28, ry + 22)], fill=(255, 95, 86))
    draw.ellipse([(rx + 33, ry + 12), (rx + 43, ry + 22)], fill=(255, 189, 46))
    draw.ellipse([(rx + 48, ry + 12), (rx + 58, ry + 22)], fill=(39, 201, 63))
    draw.text((rx + 66, ry + 10), f"PowerShell (Admin) - Windows Printer Sharing Fix v{version_str}", font=FONT_SANS_SMALL, fill=TEXT_GRAY)
    
    tx = rx + 14
    ty = ry + 44
    tl_h = 18
    
    color_map = {
        'Green': TEXT_GREEN,
        'Cyan': TEXT_CYAN,
        'Yellow': TEXT_YELLOW,
        'Red': TEXT_RED,
        'White': TEXT_WHITE,
        'Gray': TEXT_GRAY,
        'DarkGray': TEXT_DARKGRAY,
        'DarkCyan': (2, 132, 199)
    }

    if real_lines:
        for line_obj in real_lines:
            segs = line_obj.get("Segments", [])
            seg_x = tx
            full_line = ""
            for seg in segs:
                stext = seg.get("Text", "")
                full_line += stext
                scolor = color_map.get(seg.get("Color"), TEXT_WHITE)
                font_to_use = FONT_MONO_BANNER_BOLD if seg.get("Color") in ['Green', 'Yellow', 'Red'] and not stext.startswith("=") and not stext.startswith("-") else FONT_MONO_BANNER
                draw.text((seg_x, ty), stext, font=font_to_use, fill=scolor)
                seg_x += int(draw.textlength(stext, font=font_to_use))
            fl = full_line.strip().lower()
            if "select option" in fl or "pilih nomor" in fl:
                cursor_txt = "\u2588" if full_line.endswith(" ") else " \u2588"
                draw.text((seg_x, ty), cursor_txt, font=FONT_MONO_BANNER_BOLD, fill=TEXT_YELLOW)
            ty += tl_h
            if ty > ry + rh - 16:
                break
    else:
        draw.text((tx, ty), "=" * 70, font=FONT_MONO_BANNER, fill=TEXT_CYAN); ty += tl_h
        draw.text((tx, ty), "  WINDOWS PRINTER SHARING FIX", font=FONT_MONO_BANNER_BOLD, fill=TEXT_GREEN); ty += tl_h
        draw.text((tx, ty), "  STATUS: Spooler [RUNNING] | Network [PRIVATE]", font=FONT_MONO_BANNER, fill=TEXT_CYAN); ty += tl_h
        draw.text((tx, ty), "=" * 70, font=FONT_MONO_BANNER, fill=TEXT_CYAN); ty += tl_h + 4
        draw.text((tx, ty), "Select option: \u2588", font=FONT_MONO_BANNER_BOLD, fill=TEXT_YELLOW); ty += tl_h
    
    out_path = os.path.join(ASSETS_DIR, "social-banner.png")
    img.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

if __name__ == "__main__":
    generate_main_menu()
    generate_scanner_preview()
    generate_social_banner()
    print("\nAll showcase assets generated successfully in assets/ directory!")
