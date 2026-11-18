#!/usr/bin/env python3
"""Packs src/ into one Roblox place file (.rbxlx) that opens in Roblox Studio.

Folder layout -> Roblox:
  src/ReplicatedStorage/...           -> ReplicatedStorage
  src/ServerScriptService/...         -> ServerScriptService
  src/StarterPlayer/StarterPlayerScripts/... -> StarterPlayer > StarterPlayerScripts
  *.server.lua -> Script, *.client.lua -> LocalScript, other *.lua -> ModuleScript
  sub-folders -> Folder
"""
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

SERVICES = {"ReplicatedStorage", "ServerScriptService", "StarterPlayer", "Workspace"}
CONTAINERS = {"StarterPlayerScripts", "StarterCharacterScripts"}

counter = [0]


def ref():
    counter[0] += 1
    return "RBX%032X" % counter[0]


def script_item(path, filename):
    if filename.endswith(".server.lua"):
        cls, name = "Script", filename[: -len(".server.lua")]
    elif filename.endswith(".client.lua"):
        cls, name = "LocalScript", filename[: -len(".client.lua")]
    else:
        cls, name = "ModuleScript", filename[: -len(".lua")]
    with open(path, encoding="utf-8") as f:
        source = f.read()
    if "]]>" in source:
        raise SystemExit("Source contains ]]> which breaks CDATA: " + path)
    return (
        '<Item class="%s" referent="%s"><Properties>'
        '<string name="Name">%s</string>'
        '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>'
        "</Properties></Item>" % (cls, ref(), escape(name), source)
    )


def folder_item(path, name, cls=None):
    if cls is None:
        if name in SERVICES:
            cls = name
        elif name in CONTAINERS:
            cls = name
        else:
            cls = "Folder"
    children = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            children.append(folder_item(full, entry))
        elif entry.endswith(".lua"):
            children.append(script_item(full, entry))
    return (
        '<Item class="%s" referent="%s"><Properties><string name="Name">%s</string></Properties>%s</Item>'
        % (cls, ref(), escape(name), "".join(children))
    )


def main(out_path):
    items = []
    for entry in sorted(os.listdir(SRC)):
        full = os.path.join(SRC, entry)
        if os.path.isdir(full):
            items.append(folder_item(full, entry))
    if not os.path.isdir(os.path.join(SRC, "Workspace")):
        items.insert(0, '<Item class="Workspace" referent="%s"><Properties><string name="Name">Workspace</string></Properties></Item>' % ref())
    xml = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        + "".join(items)
        + "</roblox>"
    )
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Wrote", out_path, "(%d items)" % counter[0])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "LoseABrainCell_v1.0.rbxlx"))
