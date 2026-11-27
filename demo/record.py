#!/usr/bin/env python3
"""record demo.gif: drives `nvim --embed` over the ui protocol and renders
each flushed screen with pillow.

    pip install msgpack pillow
    python3 demo/record.py
"""

import os
import shutil
import tempfile
import subprocess
import threading
import time

import msgpack
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COLS, ROWS = 124, 34
FONT_SIZE = 15
PAD = 18
BAR = 34

FONT_DIR = "/usr/share/fonts/truetype"
FONTS = {
    (False, False): f"{FONT_DIR}/jetbrains-mono/JetBrainsMono-Regular.ttf",
    (True, False): f"{FONT_DIR}/jetbrains-mono/JetBrainsMono-Bold.ttf",
    (False, True): f"{FONT_DIR}/jetbrains-mono/JetBrainsMono-Italic.ttf",
    (True, True): f"{FONT_DIR}/jetbrains-mono/JetBrainsMono-BoldItalic.ttf",
}
FALLBACK = f"{FONT_DIR}/dejavu/DejaVuSansMono.ttf"
FALLBACK_CHARS = set("☐☑")

BG = "#15171c"
FG = "#c9ced6"
FRAME_BG = "#0d0e11"
class Nvim:
    """minimal msgpack-rpc ui client for `nvim --embed`"""

    def __init__(self, argv, cwd):
        self.proc = subprocess.Popen(argv, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        self.lock = threading.Lock()
        self.grid = [[[" ", 0] for _ in range(COLS)] for _ in range(ROWS)]
        self.attrs = {0: {}}
        self.default_fg, self.default_bg = FG, BG
        self.cursor = (0, 0)
        self.mode = "normal"
        self.snap = None
        self.msgid = 0
        threading.Thread(target=self._read, daemon=True).start()
        self._request("nvim_ui_attach", [COLS, ROWS, {"ext_linegrid": True, "rgb": True}])

    def _request(self, method, args):
        self.msgid += 1
        self.proc.stdin.write(msgpack.packb([0, self.msgid, method, args]))
        self.proc.stdin.flush()

    def send(self, keys):
        self._request("nvim_input", [keys])

    def _read(self):
        unpacker = msgpack.Unpacker(raw=False)
        while True:
            data = self.proc.stdout.read1(65536)
            if not data:
                return
            unpacker.feed(data)
            for msg in unpacker:
                if msg[0] == 2 and msg[1] == "redraw":
                    for batch in msg[2]:
                        name, calls = batch[0], batch[1:]
                        for args in calls:
                            self._event(name, args)

    @staticmethod
    def _hex(v, default):
        return default if v is None or v < 0 else "#%06x" % v

    def _event(self, name, a):
        if name == "default_colors_set":
            self.default_fg = self._hex(a[0], FG)
            self.default_bg = self._hex(a[1], BG)
        elif name == "hl_attr_define":
            self.attrs[a[0]] = a[1]
        elif name == "grid_line":
            _, row, col, cells = a[:4]
            hl = 0
            for cell in cells:
                text = cell[0]
                if len(cell) > 1:
                    hl = cell[1]
                rep = cell[2] if len(cell) > 2 else 1
                for _ in range(rep):
                    if col < COLS:
                        self.grid[row][col] = [text, hl]
                    col += 1
        elif name == "grid_clear":
            for row in self.grid:
                for c in row:
                    c[0], c[1] = " ", 0
        elif name == "grid_scroll":
            _, top, bot, left, right, rows = a[:6]
            rng = range(top, bot - rows) if rows > 0 else range(bot - 1, top - rows - 1, -1)
            for r in rng:
                self.grid[r][left:right] = [list(c) for c in self.grid[r + rows][left:right]]
        elif name == "grid_cursor_goto":
            self.cursor = (a[2], a[1])
        elif name == "mode_change":
            self.mode = "insert" if a[0] in ("insert", "cmdline_normal") else "normal"
        elif name == "flush":
            rows = []
            for row in self.grid:
                out = []
                for text, hl in row:
                    at = self.attrs.get(hl, {})
                    fg = self._hex(at.get("foreground"), self.default_fg)
                    bg = self._hex(at.get("background"), self.default_bg)
                    if at.get("reverse"):
                        fg, bg = bg, fg
                    out.append((text, fg, bg, bool(at.get("bold")), bool(at.get("italic")),
                                bool(at.get("underline")), bool(at.get("strikethrough"))))
                rows.append(tuple(out))
            with self.lock:
                self.snap = (tuple(rows), self.cursor, self.mode)

    def snapshot(self):
        with self.lock:
            return self.snap


class Recorder:
    def __init__(self, term):
        self.term = term
        self.frames = []  # (snapshot, t)
        self.running = True
        self.t0 = time.monotonic()
        threading.Thread(target=self._sample, daemon=True).start()

    def _sample(self):
        last = None
        while self.running:
            snap = self.term.snapshot()
            if snap is not None and snap != last:
                self.frames.append((snap, time.monotonic() - self.t0))
                last = snap
            time.sleep(0.02)

    def wait(self, ms):
        time.sleep(ms / 1000)

    def keys(self, keys, after=0):
        self.term.send(keys)
        self.wait(after)

    def type(self, text, per=75, after=0):
        for ch in text:
            self.term.send(ch)
            self.wait(per)
        self.wait(after)


def script(r):
    r.wait(1200)
    r.type(":Glance", per=90, after=150)
    r.keys("<CR>", 1400)
    for _ in range(22):
        r.keys("j", 120)
    r.wait(400)
    for _ in range(3):
        r.keys("}", 450)
    for _ in range(10):
        r.keys("j", 110)
    r.wait(500)
    r.keys("G", 700)
    r.keys("o", 250)
    r.type("- [x] **pure lua**, no binary", per=70, after=900)
    r.keys("<Esc>", 900)
    r.keys("gg", 1600)
    r.type(" gp", per=120, after=1000)
    r.type(" gp", per=120, after=1600)


def load_fonts():
    fonts = {k: ImageFont.truetype(v, FONT_SIZE) for k, v in FONTS.items()}
    fallback = ImageFont.truetype(FALLBACK, FONT_SIZE)
    return fonts, fallback


def render(snap, fonts, fallback, cell_w, cell_h, ascent):
    rows, cur, mode = snap
    w = COLS * cell_w + PAD * 2
    h = ROWS * cell_h + PAD * 2 + BAR
    img = Image.new("RGB", (w, h), FRAME_BG)
    d = ImageDraw.Draw(img)

    # window chrome
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=12, fill=BG, outline="#262a32")
    d.rectangle((1, BAR - 1, w - 2, BAR - 1), fill="#262a32")
    for i, dot in enumerate(("#e8707b", "#e8c47c", "#9ccc7e")):
        x = 20 + i * 20
        d.ellipse((x - 6, BAR // 2 - 6, x + 6, BAR // 2 + 6), fill=dot)
    title = "nvim demo.md"
    tw = d.textlength(title, font=fonts[(False, False)])
    d.text(((w - tw) / 2, BAR // 2 - FONT_SIZE // 2 - 2), title, fill="#5d6470", font=fonts[(False, False)])

    ox, oy = PAD, BAR + PAD // 2
    for y, row in enumerate(rows):
        for x, (ch, fgc, bgc, bold, italic, under, strike) in enumerate(row):
            px, py = ox + x * cell_w, oy + y * cell_h
            if bgc != BG:
                d.rectangle((px, py, px + cell_w - 1, py + cell_h - 1), fill=bgc)
            if ch.strip():
                font = fallback if ch in FALLBACK_CHARS else fonts[(bool(bold), bool(italic))]
                if ch in "─━│┌┐└┘├┤┬┴┼▎":
                    draw_box(d, ch, px, py, cell_w, cell_h, fgc)
                else:
                    d.text((px, py + ascent), ch, fill=fgc, font=font, anchor="ls")
            if under:
                d.line((px, py + cell_h - 3, px + cell_w, py + cell_h - 3), fill=fgc)
            if strike:
                d.line((px, py + cell_h // 2, px + cell_w, py + cell_h // 2), fill=fgc)

    if cur:
        cx, cy = cur
        px, py = ox + cx * cell_w, oy + cy * cell_h
        if mode == "insert":
            d.rectangle((px, py + 1, px + 1, py + cell_h - 2), fill=FG)
        else:
            cell = rows[cy][cx] if cy < ROWS and cx < COLS else (" ", FG, BG)
            d.rectangle((px, py, px + cell_w - 1, py + cell_h - 1), fill=cell[1])
            if cell[0].strip():
                d.text((px, py + ascent), cell[0], fill=cell[2], font=fonts[(False, False)], anchor="ls")
    return img


def draw_box(d, ch, px, py, cw, chh, fill):
    """draw box glyphs as lines so they connect across cells"""
    mx, my = px + cw // 2, py + chh // 2
    heavy = ch == "━"
    t = 2 if heavy else 1
    left = ch in "─━┐┘┤┬┴┼"
    right = ch in "─━┌└├┬┴┼"
    up = ch in "│└┘├┤┴┼"
    down = ch in "│┌┐├┤┬┼"
    if ch == "▎":
        d.rectangle((px + 1, py, px + 2, py + chh - 1), fill=fill)
        return
    if left:
        d.rectangle((px, my, mx, my + t - 1), fill=fill)
    if right:
        d.rectangle((mx, my, px + cw - 1, my + t - 1), fill=fill)
    if up:
        d.rectangle((mx, py, mx, my), fill=fill)
    if down:
        d.rectangle((mx, my, mx, py + chh - 1), fill=fill)


def main():
    work = tempfile.mkdtemp()
    shutil.copy(os.path.join(ROOT, "demo.md"), os.path.join(work, "demo.md"))
    term = Nvim(["nvim", "--embed", "-u", os.path.join(ROOT, "demo", "init.lua"), "-n", "demo.md"], work)
    rec = Recorder(term)
    script(rec)
    rec.running = False
    term.send("<Esc>:qa!<CR>")
    time.sleep(0.2)
    term.proc.kill()

    fonts, fallback = load_fonts()
    base = fonts[(False, False)]
    cell_w = round(base.getlength("M"))
    asc, desc = base.getmetrics()
    cell_h = asc + desc + 3
    ascent = asc + 1

    # drop the startup frames before the first full draw
    frames = [f for f in rec.frames if any(c[0].strip() for c in f[0][0][0])]
    images, durations = [], []
    cache = {}
    for i, (snap, t) in enumerate(frames):
        end = frames[i + 1][1] if i + 1 < len(frames) else t + 2.0
        ms = max(20, round((end - t) * 1000 / 10) * 10)
        key = snap
        if key not in cache:
            cache[key] = render(snap, fonts, fallback, cell_w, cell_h, ascent)
        if images and cache[key] is images[-1]:
            durations[-1] += ms
        else:
            images.append(cache[key])
            durations.append(ms)

    # one shared palette keeps colors stable between frames
    picks = images[:: max(1, len(images) // 8)]
    sheet = Image.new("RGB", (picks[0].width, picks[0].height * len(picks)))
    for i, im in enumerate(picks):
        sheet.paste(im, (0, i * im.height))
    palette_src = sheet.quantize(colors=160, method=Image.Quantize.MAXCOVERAGE)
    paletted = [im.quantize(palette=palette_src, dither=Image.Dither.NONE) for im in images]
    out = os.path.join(ROOT, "demo.gif")
    paletted[0].save(out, save_all=True, append_images=paletted[1:], duration=durations,
                     loop=0, optimize=False, disposal=1)
    print(f"{len(images)} frames, {sum(durations) / 1000:.1f}s, {os.path.getsize(out) / 1024:.0f} KB -> {out}")


if __name__ == "__main__":
    main()
