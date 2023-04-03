import argparse
import re
import sys
import xml.etree.ElementTree as ET
from parse import parse

parser = argparse.ArgumentParser(description='Generate xml from lua functions annotated with doc-strings.')
parser.add_argument('xml_file', type=str, default=None, help='the callbacks.xml file')
parser.add_argument('lua_file', type=str, default=None, help='the input lua file')
parser.add_argument('out_xml', type=str, default=None, help='the output lua.xml file')
parser.add_argument("--verbose", help='print verbose messages', action='store_true')
parser.add_argument("--dry-run", help='don\'t write any output file', action='store_true')
args = parser.parse_args()

if args is False:
    SystemExit

plugin = parse(args.xml_file)

fun = None
ins, outs = [], []
cats = []

def output():
    if fun:
        if args.verbose:
            print('.')
        f, fdesc = fun
        cmd = ET.SubElement(root, 'command')
        cmd.attrib['name'] = f
        if fdesc:
            d = ET.SubElement(cmd, 'description')
            d.text = fdesc
        if cats:
            cs = ET.SubElement(cmd, 'categories')
            for cat in cats:
                c = ET.SubElement(cs, 'category', name=cat)
        pars = ET.SubElement(cmd, 'params')
        rets = ET.SubElement(cmd, 'return')
        for (src, parent) in ((ins, pars), (outs, rets)):
            for (typeSpec, name, description) in src:
                p = ET.SubElement(parent, 'param')
                p.attrib['name'] = name
                p.attrib['type'] = typeSpec['type']
                if 'item_type' in typeSpec:
                    p.attrib['item-type'] = typeSpec['item_type']
                if 'size' in typeSpec:
                    p.attrib['size'] = str(typeSpec["size"])
                if 'nullable' in typeSpec:
                    p.attrib['nullable'] = str(typeSpec["nullable"]).lower()
                if 'default' in typeSpec:
                    p.attrib['default'] = typeSpec["default"]
                if description:
                    d = ET.SubElement(p, 'description')
                    d.text = description

def error(msg):
    global args, lineno
    print(f'{args.lua_file}:{lineno}: {msg}')
    sys.exit(2)


root = ET.Element('plugin')
root.attrib['name'] = plugin.name
if plugin.version:
    root.attrib['version'] = str(plugin.version)

with open(args.lua_file, 'r') as f:
    for lineno, line in enumerate(f):
        lineno += 1
        if m := re.match(r'\s*--\s*@(\w+)\b\s*(.*?)\s*$', line):
            tag, line = m.groups()
            if tag in ('func', 'fun'):
                if m := re.match(r'(\w+)\s*(.*?)\s*$', line):
                    name, description = m.groups()
                    fun = (name, description)
                    if args.verbose:
                        print(f'fun={name}, {description}')
                else:
                    error('bad arguments: must be: @func <funcName> [description]')
            elif tag in ('arg', 'ret'):
                if m := re.match(r'(\w+)\s+(\w+)\s*(.*?)$', line):
                    dtype, name, description = m.groups()
                    typeSpec = {'type': dtype}
                elif m := re.match(r'table\.(\w+)\s+(\w+)\s*(.*?)$', line):
                    itype, name, description = m.groups()
                    typeSpec = {'type': 'table', 'item_type': itype}
                elif m := re.match(r'\{([^\s]*)\}\s+(\w+)\s*(.*?)$', line):
                    spec, name, description = m.groups()
                    typeSpec = {}
                    for s in spec.split(','):
                        s = s.strip()
                        k, v = s.split('=')
                        if k in ('type', 'item_type', 'default', 'size'):
                            typeSpec[k] = v
                        elif k in ('nullable',):
                            try:
                                typeSpec[k] = {'true': True, 'false': False}[v]
                            except KeyError:
                                error(f'bad value for {k}: must be true or false')
                        else:
                            error(f'bad key in typeSpec: {k}')
                else:
                    error(f'bad arguments: must be: @{tag} <typeSpec> <name> [description]')
                if tag == 'arg':
                    ins.append((typeSpec, name, description))
                    if args.verbose:
                        print(f'arg={typeSpec}, {name}, {description}')
                elif tag == 'ret':
                    outs.append((typeSpec, name, description))
                    if args.verbose:
                        print(f'ret={typeSpec}, {name}, {description}')
            elif tag == 'cats':
                cats = [x.strip() for x in line.split(',')]
                if args.verbose:
                    print(f'cats={cats}')
            else:
                error(f'unknown tag: @{tag}')
        else:
            output()
            fun = None
            ins, outs = [], []
            cats = []
    output()

tree = ET.ElementTree(root)
if not args.dry_run:
    tree.write(args.out_xml, encoding='utf-8', xml_declaration=True)
if args.dry_run:
    from xml.dom.minidom import parseString
    print(parseString(ET.tostring(root,'utf-8')).toprettyxml(indent="  "))
