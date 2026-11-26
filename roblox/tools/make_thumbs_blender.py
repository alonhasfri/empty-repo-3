# Builds 1920x1080 thumbnails: an in-game screenshot as the background + big glossy 3D art and 3D titles on top.
# Run inside Blender after exec'ing ../icons/make_icons.py (for mat/box/ball/cyl/cone/torus/poly/C/clear helpers).
import bpy, math, os
from mathutils import Vector

TD = THUMB_DIR  # noqa: F821 (set by the caller)
BG = os.path.join(TD, "bg")
OUTD = os.path.join(TD, "out")
os.makedirs(OUTD, exist_ok=True)
FONT_PATH = r"C:\Windows\Fonts\ariblk.ttf"
CW, CH = 16.0, 9.0  # camera view in world units


def font():
    for f in bpy.data.fonts:
        if f.filepath == FONT_PATH:
            return f
    return bpy.data.fonts.load(FONT_PATH)


def setup():
    clear()  # noqa: F821
    scn = bpy.context.scene
    try:
        scn.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        try:
            scn.render.engine = "BLENDER_EEVEE"
        except TypeError:
            pass
    scn.render.film_transparent = False
    scn.render.resolution_x = 1920
    scn.render.resolution_y = 1080
    scn.render.resolution_percentage = 100
    scn.render.image_settings.file_format = "PNG"
    scn.render.image_settings.color_mode = "RGB"
    try:
        scn.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    scn.view_settings.look = "None"
    w = scn.world or bpy.data.worlds.new("w")
    scn.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.9, 0.92, 1.0, 1)
    bg.inputs["Strength"].default_value = 0.5
    bpy.ops.object.camera_add(location=(0, -30, 0), rotation=(math.radians(90), 0, 0))
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = CW
    scn.camera = cam
    for loc, rot, e in [((-6, -12, 7), (55, 0, -30), 2500), ((7, -10, 2), (75, 0, 40), 1200), ((0, 6, 6), (-60, 0, 0), 1500)]:
        bpy.ops.object.light_add(type="AREA", location=loc)
        l = bpy.context.object
        l.data.energy = e
        l.data.size = 6
        l.rotation_euler = tuple(math.radians(a) for a in rot)


def background(name, x_shift=0.0, darken=1.0, blur_side=None, crop=None):
    """An emission plane far behind everything, showing an in-game screenshot. crop = (u0, u1) part of the width."""
    img = bpy.data.images.load(os.path.join(BG, name + ".jpg"), check_existing=True)
    aspect = img.size[0] / img.size[1]
    u0, u1 = crop or (0, 1)
    w = CH * aspect * (u1 - u0)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(x_shift, 10, 0), rotation=(math.radians(90), 0, 0))
    p = bpy.context.object
    p.scale = (w, CH, 1)
    # crop UVs
    for loop in p.data.uv_layers.active.data:
        u, v = loop.uv
        loop.uv = (u0 + u * (u1 - u0), v)
    m = bpy.data.materials.new("bg_" + name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Strength"].default_value = darken
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(tex.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    p.data.materials.append(m)
    return p


def shade(x0, x1, y0, y1, rgb, alpha):
    """A see-through colour panel over the background (for text readability or a split tint)."""
    bpy.ops.mesh.primitive_plane_add(size=1, location=((x0 + x1) / 2, 9, (y0 + y1) / 2), rotation=(math.radians(90), 0, 0))
    p = bpy.context.object
    p.scale = (x1 - x0, y1 - y0, 1)
    m = bpy.data.materials.new("shade")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*rgb, 1)
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = alpha
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(tr.outputs[0], mix.inputs[1])
    nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    try:
        m.surface_render_method = "BLENDED"
    except Exception:
        pass
    try:
        m.blend_method = "BLEND"
    except Exception:
        pass
    p.data.materials.append(m)
    return p


def title(t, size, x, z, rgb, outline=(0.01, 0.008, 0.03), rot=0.0, align="CENTER", y=-2):
    """Big chunky 3D text with a fat dark outline behind it."""
    objs = []
    for layer, (col, off, dy, ex) in enumerate([(outline, 0.07 * size, 0.25, 0.05), (rgb, 0.0, 0.0, 0.18)]):
        bpy.ops.object.text_add(location=(x, y + dy, z), rotation=(math.radians(90), math.radians(rot), 0))
        o = bpy.context.object
        o.data.body = t
        o.data.font = font()
        o.data.size = size
        o.data.extrude = ex
        o.data.offset = off
        o.data.bevel_depth = 0.02 if layer == 1 else 0
        o.data.align_x = align
        o.data.align_y = "CENTER"
        if layer == 1:
            o.data.materials.append(mat("t" + str(rgb), C_rgb(rgb), rough=0.3, emit=0.35))  # noqa: F821
        else:
            m = bpy.data.materials.new("outline")
            m.use_nodes = True
            b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            b.inputs["Base Color"].default_value = (*outline, 1)
            b.inputs["Roughness"].default_value = 0.9
            o.data.materials.append(m)
        objs.append(o)
    return objs


def brain(loc, r, rgb=(1.0, 0.55, 0.65), metal=0.0, rough=0.35, emit=0.0, rot=(0, 0, 0)):
    """A lumpy cartoon brain: a squashed sphere with Voronoi folds and a middle groove."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=96, ring_count=64, rotation=rot)
    o = bpy.context.object
    o.scale = (1.25, 0.9, 0.95)
    o.modifiers.new("pre", "SUBSURF").levels = 1
    tex = bpy.data.textures.new("folds", type="MARBLE")
    tex.marble_type = "SHARPER"
    tex.noise_basis_2 = "SIN"
    tex.noise_scale = 0.18 * r
    tex.turbulence = 9.0
    tex.noise_depth = 2
    d = o.modifiers.new("folds", "DISPLACE")
    d.texture = tex
    d.strength = 0.10 * r
    d.mid_level = 0.6
    d.texture_coords = "LOCAL"
    o.modifiers.new("smooth", "SUBSURF").levels = 1
    for p in o.data.polygons:
        p.use_smooth = True
    m = mat("brain" + str(rgb) + str(metal), C_rgb(rgb), rough=rough, metal=metal, emit=emit)  # noqa: F821
    o.data.materials.append(m)
    return o
    # (no stem: it looked like a lollipop)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.22 * r, depth=0.8 * r, location=(loc[0] + 0.25 * r, loc[1] + 0.1, loc[2] - 0.85 * r), rotation=(0, math.radians(-20), 0))
    s = bpy.context.object
    s.data.materials.append(m)
    for p in s.data.polygons:
        p.use_smooth = True
    return o


def C_rgb(rgb):
    return tuple(c ** 2.2 for c in rgb)


def render(name):
    bpy.context.scene.render.filepath = os.path.join(OUTD, name + ".png")
    bpy.ops.render.render(write_still=True)
    return name


# ------------------------------------------------------------------ extra props
def sparkle(loc, s, rgb=(1, 0.95, 0.6)):
    o = poly(star_points(s, s * 0.22, 4), 0.05, loc, mat("spark", C_rgb(rgb), emit=4.0))  # noqa: F821
    return o


def dog(loc, s=1.0):
    x, y, z = loc
    fur = mat("fur", C_rgb((0.62, 0.40, 0.22)), rough=0.6)  # noqa: F821
    light = mat("fur2", C_rgb((0.93, 0.82, 0.66)), rough=0.6)  # noqa: F821
    dark = mat("dogdark", C_rgb((0.12, 0.1, 0.1)), rough=0.3)  # noqa: F821
    box((2.6 * s, 1.3 * s, 1.3 * s), (x, y, z), fur, bevel=0.12 * s)  # noqa: F821
    for dx in (-0.9, 0.9):
        for dy in (-0.4, 0.4):
            box((0.42 * s, 0.42 * s, 1.1 * s), (x + dx * s, y + dy * s, z - 1.1 * s), fur, bevel=0.08 * s)  # noqa: F821
    hx, hz = x - 1.5 * s, z + 0.9 * s
    box((1.4 * s, 1.3 * s, 1.25 * s), (hx, y, hz), fur, bevel=0.15 * s)  # noqa: F821
    box((0.7 * s, 0.8 * s, 0.6 * s), (hx - 0.85 * s, y, hz - 0.25 * s), light, bevel=0.1 * s)  # noqa: F821
    ball(0.17 * s, (hx - 1.2 * s, y - 0.1 * s, hz - 0.05 * s), dark)  # noqa: F821
    for dy in (-0.3, 0.3):
        ball(0.13 * s, (hx - 0.55 * s, y + dy * s - 0.45 * s, hz + 0.25 * s), dark)  # noqa: F821
        box((0.35 * s, 0.2 * s, 0.8 * s), (hx + 0.2 * s, y + dy * 1.6 * s, hz + 0.55 * s), mat("ear", C_rgb((0.35, 0.22, 0.12))), rot=(0, math.radians(25), 0), bevel=0.06 * s)  # noqa: F821
    box((0.25 * s, 0.25 * s, 1.0 * s), (x + 1.45 * s, y, z + 0.6 * s), fur, rot=(0, math.radians(-35), 0), bevel=0.06 * s)  # noqa: F821
    # tongue
    box((0.25 * s, 0.1 * s, 0.4 * s), (hx - 1.0 * s, y - 0.42 * s, hz - 0.65 * s), mat("tongue", C_rgb((1, 0.4, 0.5))), bevel=0.05 * s)  # noqa: F821


def cap(loc, s=1.0):
    k = mat("capk", C_rgb((0.13, 0.14, 0.2)), rough=0.4)  # noqa: F821
    x, y, z = loc
    box((2.6 * s, 2.6 * s, 0.18 * s), (x, y, z + 0.45 * s), k, rot=(math.radians(8), 0, math.radians(45)), bevel=0.04 * s)  # noqa: F821
    cyl(0.9 * s, 0.7 * s, (x, y, z), k)  # noqa: F821
    t = mat("tassel", C_rgb((1, 0.8, 0.2)), metal=0.5)  # noqa: F821
    cyl(0.05 * s, 1.0 * s, (x + 1.1 * s, y - 0.3 * s, z), t)  # noqa: F821
    ball(0.14 * s, (x + 1.1 * s, y - 0.3 * s, z - 0.55 * s), t)  # noqa: F821


def glasses(loc, s=1.0):
    k = mat("glass_k", C_rgb((0.08, 0.08, 0.1)), rough=0.3)  # noqa: F821
    x, y, z = loc
    for dx in (-0.55, 0.55):
        torus(0.42 * s, 0.07 * s, (x + dx * s, y, z), k, rot=(math.radians(90), 0, 0))  # noqa: F821
    box((0.4 * s, 0.1 * s, 0.1 * s), (x, y, z + 0.05 * s), k, bevel=0.02)  # noqa: F821


# ------------------------------------------------------------------ the five thumbnails
def t1_split():
    setup()
    background("dumb", x_shift=-4, crop=(0.147, 0.5))
    background("smart", x_shift=4, crop=(0.5, 0.853))
    shade(-8, 0, -4.5, 4.5, (0.55, 0.1, 0.45), 0.22)
    shade(0, 8, -4.5, 4.5, (0.1, 0.3, 0.7), 0.18)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 8, 0), rotation=(math.radians(90), 0, 0))
    bar = bpy.context.object
    bar.scale = (0.12, 9, 1)
    bar.data.materials.append(mat("bar", (1, 1, 1), emit=3))  # noqa: F821
    brain((0, -3, -0.6), 2.0)
    title("LOSE", 1.9, -4.6, 3.0, (1.0, 0.35, 0.7), rot=-4)
    title("GAIN", 1.9, 4.6, 3.0, (0.35, 0.7, 1.0), rot=4)
    title("A BRAIN CELL", 0.9, -4.6, 1.6, (1, 1, 1), rot=-4)
    title("A BRAIN CELL", 0.9, 4.6, 1.6, (1, 1, 1), rot=4)
    title("WHICH WAY WILL YOU GO?", 0.75, 0, -3.7, (1, 0.85, 0.2))
    return render("thumb1_lose_or_gain")


def t2_countdown():
    setup()
    background("toon", crop=(0.1, 0.9))
    shade(-8, 8, -4.5, 4.5, (0.2, 0.05, 0.3), 0.25)
    for i, (x, r) in enumerate([(-4.6, 1.9), (-0.6, 1.3), (2.6, 0.85), (5.0, 0.45)]):
        g = 1 - i * 0.22
        brain((x, -3, -1.0 + (1.9 - r) * 0.6), r, rgb=(1.0 * g + 0.4 * (1 - g), 0.55 * g + 0.5 * (1 - g), 0.65 * g + 0.5 * (1 - g)))
    box((0.6, 0.6, 0.55), (6.6, -3, -1.6), mat("rock", C_rgb((0.5, 0.5, 0.52)), rough=0.9), bevel=0.15)  # noqa: F821
    title("86,000,000,000", 1.25, 0, 3.15, (1, 1, 1))
    title("BRAIN CELLS", 0.8, 0, 1.85, (1, 0.55, 0.8))
    title("CAN YOU GET TO 0?", 0.85, 0, -3.75, (1, 0.85, 0.2))
    return render("thumb2_86_billion_to_zero")


def t3_dog():
    setup()
    background("toon", crop=(0.14, 0.92), x_shift=-0.3)
    shade(-8, 8, -4.5, 4.5, (0.3, 0.1, 0.4), 0.2)
    dog((1.6, -3, -1.6), 1.25)
    brain((-4.6, -3, -1.6), 0.6, rgb=(0.9, 0.7, 0.75))
    for p in [(-4.0, -2.5, -0.8), (-5.2, -2.5, -0.9), (-4.6, -2.5, -0.5)]:
        sparkle(p, 0.25, (0.7, 0.9, 1))
    title("TOO DUMB?", 1.2, -3.6, 3.1, (1, 1, 1), rot=-3)
    title("YOU BECOME", 0.85, 3.6, 3.3, (1, 0.85, 0.2), rot=3)
    title("A DOG!", 1.6, 3.6, 1.9, (1, 0.55, 0.25), rot=3)
    title("WORM  FLY  BEE  MOUSE  DOG", 0.55, 0, -3.85, (1, 1, 1))
    return render("thumb3_become_a_dog")


def t4_golden():
    setup()
    background("plaza", crop=(0.14, 0.86), darken=0.75)
    shade(-8, 8, -4.5, 4.5, (0.15, 0.08, 0.0), 0.3)
    brain((0, -3, -0.4), 2.4, rgb=(1.0, 0.78, 0.2), metal=0.9, rough=0.2, emit=0.15)
    bpy.ops.object.light_add(type="POINT", location=(0, -6, 0))
    bpy.context.object.data.energy = 900
    bpy.context.object.data.color = (1, 0.8, 0.4)
    for p, s in [((-4.2, -4, 1.6), 0.6), ((3.9, -4, 1.9), 0.45), ((4.6, -4, -1.2), 0.7), ((-3.6, -4, -1.9), 0.4), ((-1.8, -4, 2.6), 0.3), ((2.2, -4, -2.6), 0.35)]:
        sparkle(p, s)
    title("GOLDEN BRAIN", 1.35, 0, 3.4, (1, 0.82, 0.2))
    title("GRAB IT FIRST!", 0.95, 0, -3.7, (1, 1, 1))
    return render("thumb4_golden_brain")


def t5_genius():
    setup()
    background("smart", crop=(0.12, 0.88))
    shade(-8, 8, -4.5, 4.5, (0.05, 0.15, 0.35), 0.25)
    brain((3.6, -3, -0.9), 2.0)
    cap((3.6, -3.4, 1.35), 1.0)
    glasses((3.0, -5.6, -0.6), 0.9)
    title("IQ 200", 2.0, -3.4, 1.6, (1, 0.85, 0.2), rot=-3)
    title("BECOME A", 0.8, -3.4, 3.4, (1, 1, 1), rot=-3)
    title("GENIUS", 1.1, -3.4, -0.2, (0.45, 0.8, 1.0), rot=-3)
    title("JOBS  INVENTIONS  ROCKETS", 0.55, 0, -3.85, (1, 1, 1))
    return render("thumb5_become_a_genius")


# ------------------------------------------------------------------ v2 (user, Nov 26): real brain model + white backgrounds
# "Brain" by Poly by Google, https://poly.pizza/m/5mPRPZkI3qt, CC-BY 3.0 (credited in marketing/CREDITS.md)
BRAIN_FILE = os.path.join(TD, "brain_model.blend")
WHITE = False


def brain(loc, r, rgb=None, metal=0.0, rough=0.35, emit=0.0, rot=(0, 0, 0)):  # noqa: F811
    with bpy.data.libraries.load(BRAIN_FILE) as (src, dst):
        dst.objects = ["BRAIN"]
    o = dst.objects[0]
    bpy.context.collection.objects.link(o)
    o.data = o.data.copy()
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.6)
    bm.to_mesh(o.data)
    bm.free()
    # model: 214 x 172 x 180 units, origin at the bottom; centre it on loc and size it so its width is ~2.5 r
    s = (2.5 * r) / 214.0
    o.scale = (s, s, s)
    o.rotation_euler = (math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2]))
    bpy.context.view_layer.update()
    corners = [o.matrix_world @ Vector(c) for c in o.bound_box]
    centre = sum(corners, Vector()) / 8
    o.location += Vector(loc) - centre
    rgb = rgb or (1.0, 0.56, 0.68)
    if True:
        m = mat("brainmodel" + str(rgb), C_rgb(rgb), rough=rough, metal=metal, emit=emit)  # noqa: F821
        o.data.materials.clear()
        o.data.materials.append(m)
    for p in o.data.polygons:
        p.use_smooth = True
    sub = o.modifiers.new("round", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    return o


_bg_v1, _shade_v1, _title_v1 = background, shade, title


def background(*a, **k):  # noqa: F811
    return None if WHITE else _bg_v1(*a, **k)


def shade(*a, **k):  # noqa: F811
    return None if WHITE else _shade_v1(*a, **k)


def title(t, size, x, z, rgb, **k):  # noqa: F811
    if WHITE and rgb == (1, 1, 1):
        rgb = (0.3, 0.6, 1.0)  # white text would vanish on white
    return _title_v1(t, size, x, z, rgb, **k)


def white_world():
    # pure white where the camera looks at the sky, but only soft grey light on the objects (no wash-out)
    w = bpy.context.scene.world
    nt = w.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    lp = nt.nodes.new("ShaderNodeLightPath")
    white = nt.nodes.new("ShaderNodeBackground")
    white.inputs["Color"].default_value = (1, 1, 1, 1)
    white.inputs["Strength"].default_value = 1.0
    soft = nt.nodes.new("ShaderNodeBackground")
    soft.inputs["Color"].default_value = (0.9, 0.92, 1.0, 1)
    soft.inputs["Strength"].default_value = 0.45
    mix = nt.nodes.new("ShaderNodeMixShader")
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs["Fac"])
    nt.links.new(soft.outputs[0], mix.inputs[1])
    nt.links.new(white.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])


def render_white(fn, name):
    global WHITE
    WHITE = True
    try:
        _render = globals()["render"]
        globals()["render"] = lambda n: (white_world(), _render(name))[1]
        return fn()
    finally:
        globals()["render"] = _render
        WHITE = False


_sparkle_v1 = sparkle


def sparkle(loc, s, rgb=(1, 0.95, 0.6)):  # noqa: F811
    if WHITE:
        o = poly(star_points(s, s * 0.22, 4), 0.05, loc, mat("spark_w", C_rgb((1.0, 0.72, 0.1)), emit=0.6))  # noqa: F821
        return o
    return _sparkle_v1(loc, s, rgb)
