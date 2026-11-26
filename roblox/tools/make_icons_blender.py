# Renders one consistent set of glossy 3D app icons (transparent PNG, 256 px) for "Lose a Brain Cell".
# Same lighting, camera, material style and size for every icon, so the phone looks like one set.
import bpy, math, os
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else OUT_DIR, "png")
os.makedirs(OUT, exist_ok=True)

def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.curves):
        for b in list(block):
            if b.users == 0:
                block.remove(b)
    MATS.clear()
    global W, DARK
    W = mat("white", C("f4f6fb"))
    DARK = mat("dark", C("2a2f45"))

MATS = {}
def mat(name, rgb, rough=0.28, metal=0.0, emit=0.0):
    key = (name, rgb, rough, metal, emit)
    if key in MATS:
        return MATS[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    for k in ("Coat Weight", "Clearcoat"):
        if k in b.inputs:
            b.inputs[k].default_value = 0.6
    if emit > 0:
        for k in ("Emission Color", "Emission"):
            if k in b.inputs:
                b.inputs[k].default_value = (*rgb, 1)
        if "Emission Strength" in b.inputs:
            b.inputs["Emission Strength"].default_value = emit
    MATS[key] = m
    return m

def C(h):  # hex -> linear-ish rgb tuple
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))

def finish(o, m, bevel=0.06, smooth=True):
    o.data.materials.append(m)
    if bevel:
        mod = o.modifiers.new("b", "BEVEL")
        mod.width = bevel
        mod.segments = 4
    if smooth and o.type == "MESH":
        for p in o.data.polygons:
            p.use_smooth = True
    return o

def box(size, loc, m, rot=(0, 0, 0), bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.object
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return finish(o, m, bevel)

def cyl(r, depth, loc, m, rot=(0, 0, 0), verts=48, bevel=0.04):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    return finish(bpy.context.object, m, bevel)

def ball(r, loc, m, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=48, ring_count=24)
    o = bpy.context.object
    o.scale = scale
    return finish(o, m, 0)

def cone(r1, r2, depth, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot, vertices=48)
    return finish(bpy.context.object, m, 0.02)

def torus(R, r, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot, major_segments=48, minor_segments=16)
    return finish(bpy.context.object, m, 0)

def text(t, size, loc, m, rot=(math.radians(90), 0, 0), extrude=0.12):
    bpy.ops.object.text_add(location=loc, rotation=rot)
    o = bpy.context.object
    o.data.body = t
    o.data.size = size
    o.data.extrude = extrude
    o.data.bevel_depth = 0.02
    o.data.align_x = "CENTER"
    o.data.align_y = "CENTER"
    o.data.materials.append(m)
    return o

def poly(points, depth, loc, m, rot=(math.radians(90), 0, 0)):
    # an extruded 2D outline (x, y) in the icon plane
    me = bpy.data.meshes.new("poly")
    n = len(points)
    vs = [(x, y, -depth / 2) for x, y in points] + [(x, y, depth / 2) for x, y in points]
    fs = [list(range(n))[::-1], list(range(n, 2 * n))] + [[i, (i + 1) % n, n + (i + 1) % n, n + i] for i in range(n)]
    me.from_pydata(vs, [], fs)
    o = bpy.data.objects.new("poly", me)
    bpy.context.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = rot
    return finish(o, m, 0.03, smooth=False)

def star_points(r1, r2, k=5):
    pts = []
    for i in range(k * 2):
        a = math.pi / 2 + i * math.pi / k
        r = r1 if i % 2 == 0 else r2
        pts.append((math.cos(a) * r, math.sin(a) * r))
    return pts

# ---------------------------------------------------------------- the icons (front = -Y, up = +Z)
W = mat("white", C("f4f6fb"))
DARK = mat("dark", C("2a2f45"))
def I_settings():
    g = mat("gear", C("8fa3c8"), metal=0.6, rough=0.25)
    cyl(0.62, 0.3, (0, 0, 0), g, rot=(math.radians(90), 0, 0))
    for i in range(8):
        a = i * math.pi / 4
        box((0.3, 0.3, 0.34), (math.cos(a) * 0.72, 0, math.sin(a) * 0.72), g, rot=(0, -a, 0), bevel=0.05)
    cyl(0.24, 0.36, (0, 0, 0), DARK, rot=(math.radians(90), 0, 0))
def I_library():
    for i, (c, w) in enumerate([("e8534a", 1.5), ("3f8cff", 1.35), ("39c27a", 1.45)]):
        box((w, 0.9, 0.34), (0.04 * (i % 2), 0, -0.45 + i * 0.36), mat("b" + c, C(c)), bevel=0.05)
        box((w - 0.08, 0.82, 0.24), (0.04 * (i % 2) + 0.05, -0.05, -0.45 + i * 0.36), W, bevel=0.02)
def I_braintalks():
    k = mat("cap", C("2b2d42"))
    box((1.5, 1.5, 0.14), (0, 0, 0.25), k, rot=(0, 0, math.radians(45)), bevel=0.03)
    cyl(0.48, 0.5, (0, 0, -0.05), k)
    t = mat("tassel", C("ffcf3d"))
    cyl(0.03, 0.6, (0.62, 0, -0.08), t)
    ball(0.1, (0.62, 0, -0.4), t)
def I_clickbait():
    box((1.4, 0.1, 1.7), (0, 0, 0), W, bevel=0.03)
    box((1.2, 0.14, 0.3), (0, -0.02, 0.58), mat("red", C("ff3b3b")), bevel=0.02)
    for i in range(4):
        box((1.1 - (i % 2) * 0.3, 0.14, 0.08), (-(i % 2) * 0.15, -0.02, 0.18 - i * 0.22), DARK, bevel=0.01)
def I_comments():
    b = mat("bub", C("38b6ff"))
    cyl(0.78, 0.3, (0, 0, 0.1), b, rot=(math.radians(90), 0, 0))
    cone(0.25, 0.0, 0.5, (-0.4, 0, -0.62), b, rot=(0, math.radians(200), 0))
    for x in (-0.3, 0, 0.3):
        ball(0.1, (x, -0.17, 0.1), W)
def I_items():
    b = mat("bag", C("8a5cf5"))
    box((1.2, 0.7, 1.4), (0, 0, -0.1), b, bevel=0.22)
    box((0.8, 0.2, 0.5), (0, -0.4, -0.35), mat("pocket", C("b48bff")), bevel=0.1)
    torus(0.3, 0.07, (0, 0, 0.68), mat("strap", C("5b3cb8")), rot=(math.radians(90), 0, 0))
def I_jobs():
    b = mat("case", C("b8763b"))
    box((1.6, 0.6, 1.1), (0, 0, -0.15), b, bevel=0.12)
    torus(0.28, 0.07, (0, 0, 0.48), mat("handle", C("6b4220")), rot=(math.radians(90), 0, 0))
    box((0.3, 0.1, 0.2), (0, -0.33, 0.1), mat("clasp", C("ffd34d"), metal=0.8), bevel=0.03)
def I_lab():
    m1 = mat("scope", C("dfe6f2"), metal=0.3)
    box((1.3, 0.8, 0.18), (0, 0, -0.7), DARK, bevel=0.05)
    cyl(0.12, 1.2, (-0.25, 0, -0.1), m1)
    cyl(0.2, 0.9, (0.05, 0, 0.35), mat("tube", C("38b6ff")), rot=(0, math.radians(-35), 0))
    box((0.6, 0.4, 0.06), (0.15, 0, -0.35), m1, bevel=0.02)
def I_map():
    cols = ["7bd389", "f5d76e", "7bd389"]
    for i, c in enumerate(cols):
        box((0.52, 0.06, 1.5), (-0.52 + i * 0.52, 0, 0), mat("m" + c, C(c)), rot=(0, 0, math.radians(18 if i % 2 == 0 else -18)), bevel=0.02)
    r = mat("pin", C("ff3b3b"))
    ball(0.22, (0.1, -0.3, 0.35), r)
    cone(0.16, 0.0, 0.35, (0.1, -0.3, 0.08), r, rot=(math.radians(180), 0, 0))
def I_phone():
    box((0.95, 0.18, 1.7), (0, 0, 0), mat("ph", C("7c4dff")), bevel=0.14)
    box((0.8, 0.06, 1.35), (0, -0.09, 0.05), mat("scr", C("49c6ff"), emit=0.6), bevel=0.06)
def I_shop():
    c = mat("cart", C("ff6fb1"))
    box((1.4, 0.9, 0.8), (0, 0, 0.1), c, bevel=0.08)
    for x in (-0.45, 0.45):
        cyl(0.16, 0.12, (x, -0.35, -0.48), DARK, rot=(math.radians(90), 0, 0))
    box((0.1, 0.1, 0.6), (-0.75, 0, 0.45), c, rot=(0, math.radians(20), 0), bevel=0.03)
def I_space():
    w = mat("rocket", C("f4f6fb"))
    cyl(0.3, 1.1, (0, 0, -0.05), w)
    cone(0.3, 0.0, 0.5, (0, 0, 0.75), mat("nose", C("ff3b3b")))
    for a in (0, 120, 240):
        r = math.radians(a)
        box((0.08, 0.35, 0.4), (math.sin(r) * 0.33, -math.cos(r) * 0.33, -0.5), mat("fin", C("ff3b3b")), rot=(0, 0, r), bevel=0.02)
    ball(0.12, (0, -0.28, 0.15), mat("win", C("49c6ff"), emit=0.4))
    cone(0.2, 0.05, 0.4, (0, 0, -0.85), mat("fire", C("ffb030"), emit=2), rot=(math.radians(180), 0, 0))
def I_steal():
    p = mat("pad", C("3b3f5c"))
    box((1.7, 0.4, 0.8), (0, 0, 0), p, bevel=0.3)
    for (x, z, c) in [(0.45, 0.12, "ff4d6d"), (0.65, -0.08, "39c27a"), (0.25, -0.08, "3f8cff"), (0.45, -0.28, "ffcf3d")]:
        ball(0.09, (x, -0.22, z), mat("btn" + c, C(c)))
    box((0.36, 0.1, 0.1), (-0.45, -0.22, -0.08), W, bevel=0.02)
    box((0.1, 0.1, 0.36), (-0.45, -0.22, -0.08), W, bevel=0.02)
def I_theater():
    box((1.5, 0.2, 1.0), (0, 0, -0.25), DARK, bevel=0.05)
    top = box((1.5, 0.2, 0.28), (0, 0, 0.45), W, rot=(0, math.radians(-12), 0), bevel=0.03)
    for i in range(4):
        box((0.16, 0.24, 0.3), (-0.55 + i * 0.36, 0, 0.45 - i * 0.075), DARK, rot=(0, math.radians(-12 + 30), 0), bevel=0.01)
def I_together():
    ball(0.55, (-0.3, 0, 0.15), mat("happy", C("ffcf3d")), scale=(1, 0.45, 1.1))
    ball(0.55, (0.35, 0.15, -0.1), mat("sad", C("38b6ff")), scale=(1, 0.45, 1.1))
    for (x, z) in [(-0.48, 0.3), (-0.12, 0.3), (0.2, 0.05), (0.52, 0.05)]:
        ball(0.08, (x, -0.28 if x < 0 else -0.12, z), DARK)
def I_work():
    s = mat("steel", C("b8c2d6"), metal=0.8, rough=0.2)
    a = math.radians(35)
    box((0.22, 0.22, 1.5), (-0.1, 0, -0.2), mat("grip", C("ff8a3d")), rot=(0, a, 0), bevel=0.08)
    box((1.0, 0.4, 0.38), (0.36, 0, 0.5), s, rot=(0, a, 0), bevel=0.08)
def I_badges():
    cyl(0.5, 0.16, (0, 0, -0.15), mat("gold", C("ffc93c"), metal=0.7), rot=(math.radians(90), 0, 0))
    poly(star_points(0.32, 0.14), 0.12, (0, -0.1, -0.15), mat("goldstar", C("fff1a8"), metal=0.5))
    box((0.3, 0.08, 0.6), (-0.15, 0.05, 0.55), mat("rib1", C("3f8cff")), rot=(0, math.radians(15), 0), bevel=0.02)
    box((0.3, 0.08, 0.6), (0.15, 0.05, 0.55), mat("rib2", C("ff4d6d")), rot=(0, math.radians(-15), 0), bevel=0.02)
def I_help():
    text("?", 2.6, (0, 0, -0.1), mat("q", C("8a5cf5")), extrude=0.25)
def I_gate():
    y = mat("y", C("ffcf3d"))
    for x in (-0.65, 0.65):
        box((0.14, 0.14, 1.3), (x, 0, -0.2), DARK, bevel=0.03)
    box((1.6, 0.16, 0.3), (0, -0.05, 0.25), y, bevel=0.04)
    for i in range(4):
        box((0.2, 0.18, 0.3), (-0.6 + i * 0.4, -0.06, 0.25), mat("r", C("ff3b3b")), rot=(0, math.radians(35), 0), bevel=0.0)
def I_coffee():
    c = mat("cup", C("f4f6fb"))
    cyl(0.5, 0.9, (0, 0, -0.1), c)
    torus(0.25, 0.07, (0.55, 0, -0.05), c, rot=(math.radians(90), 0, 0))
    cyl(0.44, 0.05, (0, 0, 0.33), mat("cof", C("6b3e1f")))
    box((1.5, 1.0, 0.08), (0, 0, -0.58), mat("plate", C("c7d0e3")), bevel=0.04)
def I_nap():
    moon = ball(0.7, (-0.1, 0, -0.05), mat("moon", C("ffd84d"), emit=0.3), scale=(1, 0.5, 1))
    cut = ball(0.6, (0.3, 0, 0.2), mat("cut", C("ffffff")), scale=(1, 1.5, 1))
    mod = moon.modifiers.new("cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cut
    cut.hide_render = True
    zz = mat("zz", C("8fb7ff"))
    text("Z", 0.55, (0.45, -0.2, 0.45), zz)
    text("z", 0.35, (0.75, -0.2, 0.8), zz)
def I_pigeons():
    g = mat("pig", C("a9b2c6"))
    ball(0.5, (0, 0, -0.1), g, scale=(1.2, 0.9, 0.9))
    ball(0.3, (0.5, 0, 0.35), g)
    cone(0.08, 0.0, 0.22, (0.82, 0, 0.33), mat("beak", C("ffb030")), rot=(0, math.radians(90), 0))
    ball(0.06, (0.6, -0.26, 0.42), DARK)
def I_events():
    e = mat("env", C("ff6fb1"))
    box((1.5, 0.12, 1.0), (0, 0, 0), e, bevel=0.05)
    poly([(-0.75, 0.5), (0.75, 0.5), (0, -0.05)], 0.06, (0, -0.08, 0), mat("flap", C("ff9ccb")))
    ball(0.15, (0, -0.14, 0.0), mat("heart", C("ff3b3b")))
def I_genius():
    poly(star_points(0.85, 0.38), 0.3, (0, 0, 0), mat("star", C("ffcf3d"), emit=0.3))
def I_home():
    box((1.2, 1.0, 0.9), (0, 0, -0.35), mat("wall", C("f4e3c7")), bevel=0.05)
    poly([(-0.85, 0.0), (0.85, 0.0), (0, 0.7)], 1.1, (0, 0, 0.1), mat("roof", C("e8534a")))
    box((0.3, 0.1, 0.5), (0, -0.5, -0.55), mat("door", C("8a5530")), bevel=0.03)
def I_town():
    for (x, h, c) in [(-0.55, 1.2, "3f8cff"), (0, 1.7, "8a5cf5"), (0.55, 1.0, "39c27a")]:
        box((0.48, 0.5, h), (x, 0, -0.8 + h / 2), mat("t" + c, C(c)), bevel=0.04)
        for k in range(int(h / 0.35)):
            box((0.28, 0.06, 0.12), (x, -0.25, -0.62 + k * 0.32), mat("win", C("fff1a8"), emit=0.5), bevel=0.0)
def I_jokejobs():
    ball(0.7, (0, 0, 0), mat("face", C("fff0e0")))
    ball(0.2, (0, -0.66, -0.02), mat("nose", C("ff2d2d")))
    for x in (-0.25, 0.25):
        ball(0.09, (x, -0.6, 0.22), DARK)
    ball(0.32, (-0.6, 0.05, 0.45), mat("hair1", C("39c27a")))
    ball(0.32, (0.6, 0.05, 0.45), mat("hair2", C("3f8cff")))
def I_camera():
    box((1.5, 0.6, 1.0), (0, 0, -0.1), DARK, bevel=0.12)
    cyl(0.36, 0.3, (0, -0.35, -0.1), mat("lens", C("8fa3c8"), metal=0.8), rot=(math.radians(90), 0, 0))
    cyl(0.22, 0.32, (0, -0.37, -0.1), mat("glass", C("49c6ff"), emit=0.3), rot=(math.radians(90), 0, 0))
    box((0.35, 0.3, 0.18), (-0.45, 0, 0.45), mat("flash", C("ffcf3d")), bevel=0.04)
def I_hoppr():
    y = mat("taxi", C("ffcf3d"))
    box((1.7, 0.8, 0.5), (0, 0, -0.2), y, bevel=0.15)
    box((0.9, 0.7, 0.45), (-0.05, 0, 0.22), y, bevel=0.12)
    box((0.7, 0.72, 0.3), (-0.05, 0, 0.22), mat("glass2", C("49c6ff")), bevel=0.06)
    for x in (-0.55, 0.55):
        cyl(0.2, 0.86, (x, 0, -0.45), DARK, rot=(math.radians(90), 0, 0))
def I_bank():
    g = mat("coin", C("ffc93c"), metal=0.7)
    for i in range(4):
        cyl(0.5, 0.18, (-0.3 + (i % 2) * 0.05, 0, -0.55 + i * 0.2), g)
    cyl(0.5, 0.16, (0.45, -0.2, 0.15), g, rot=(math.radians(90), 0, 0))
    text("$", 0.55, (0.45, -0.3, 0.12), mat("dollar", C("b07a10")))
def I_shifts():
    cyl(0.75, 0.25, (0, 0, 0), mat("clock", C("ff6b5b")), rot=(math.radians(90), 0, 0))
    cyl(0.62, 0.27, (0, 0, 0), W, rot=(math.radians(90), 0, 0))
    box((0.08, 0.1, 0.45), (0, -0.16, 0.18), DARK, bevel=0.0)
    box((0.35, 0.1, 0.08), (0.15, -0.16, 0), DARK, bevel=0.0)
def I_quickplay():
    poly([(0.15, 0.9), (-0.5, -0.05), (-0.05, -0.05), (-0.2, -0.9), (0.55, 0.15), (0.08, 0.15)], 0.3, (0, 0, 0), mat("bolt", C("ffcf3d"), emit=0.4))

def I_daily():
    b = mat("gift", C("ff4d6d"))
    box((1.3, 1.0, 0.95), (0, 0, -0.3), b, bevel=0.06)
    box((1.45, 1.1, 0.3), (0, 0, 0.25), b, bevel=0.06)
    r = mat("ribbon", C("ffcf3d"))
    box((0.22, 1.14, 1.3), (0, 0, -0.08), r, bevel=0.02)
    box((1.49, 0.22, 1.3), (0, 0, -0.08), r, bevel=0.02)
    torus(0.2, 0.07, (-0.2, 0, 0.55), r, rot=(0, math.radians(30), 0))
    torus(0.2, 0.07, (0.2, 0, 0.55), r, rot=(0, math.radians(-30), 0))
def I_friends():
    for (x, c, s) in [(-0.38, "3f8cff", 0.9), (0.38, "39c27a", 1.0)]:
        m = mat("f" + c, C(c))
        ball(0.28 * s, (x, 0, 0.3 * s), mat("skin", C("ffd7b0")))
        ball(0.45 * s, (x, 0, -0.45), m, scale=(1, 0.8, 1))
def I_unstuck():
    torus(0.55, 0.2, (0, 0, 0), mat("ring", C("ff4d4d")), rot=(math.radians(90), 0, 0))
    for a in (45, 135, 225, 315):
        r = math.radians(a)
        box((0.22, 0.44, 0.44), (math.cos(r) * 0.55, -0.02, math.sin(r) * 0.55), W, rot=(0, -r, 0), bevel=0.0)

ICONS = {k[2:]: v for k, v in globals().items() if k.startswith("I_")}

def setup_scene():
    scn = bpy.context.scene
    try:
        scn.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        try:
            scn.render.engine = "BLENDER_EEVEE"
        except TypeError:
            pass
    scn.render.film_transparent = True
    try:
        scn.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    scn.view_settings.look = "None"
    scn.render.resolution_x = 256
    scn.render.resolution_y = 256
    scn.render.image_settings.file_format = "PNG"
    scn.render.image_settings.color_mode = "RGBA"
    w = scn.world or bpy.data.worlds.new("w")
    scn.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.9, 0.92, 1.0, 1)
    bg.inputs["Strength"].default_value = 0.6

def lights_and_camera():
    bpy.ops.object.light_add(type="AREA", location=(-2.5, -3, 3.5))
    k = bpy.context.object
    k.data.energy = 600
    k.data.size = 3
    k.rotation_euler = (math.radians(50), 0, math.radians(-35))
    bpy.ops.object.light_add(type="AREA", location=(3, -2, 1))
    f = bpy.context.object
    f.data.energy = 250
    f.data.size = 3
    f.rotation_euler = (math.radians(70), 0, math.radians(55))
    bpy.ops.object.light_add(type="AREA", location=(0, 3, 2.5))
    r = bpy.context.object
    r.data.energy = 300
    r.rotation_euler = (math.radians(-60), 0, 0)
    bpy.ops.object.camera_add(location=(1.6, -4.2, 1.5))
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 2.6
    direction = Vector((0, 0, 0)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam

def render_all(only=None):
    done = []
    for key, fn in ICONS.items():
        if only and key not in only:
            continue
        clear()
        setup_scene()
        lights_and_camera()
        fn()
        bpy.context.scene.render.filepath = os.path.join(OUT, key + ".png")
        bpy.ops.render.render(write_still=True)
        done.append(key)
    return done
