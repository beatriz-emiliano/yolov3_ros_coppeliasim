import argparse
from parse import parse, escape

parser = argparse.ArgumentParser(description='Generate calltips for Lua functions.')
parser.add_argument('xml_file', type=str, default=None, help='the lua.xml file')
parser.add_argument('out_file', type=str, default=None, help='the output .cpp file')
args = parser.parse_args()

if args is False:
    SystemExit

plugin = parse(args.xml_file)

ver_suffix = f'_{plugin.version}' if plugin.version > 0 else ''

with open(args.out_file, 'w') as fout:
    for cmd in plugin.commands:
        fout.write(f'sim::registerScriptCallbackFunction("sim{plugin.name}{ver_suffix}.{cmd.name}@{plugin.name}", "{escape(cmd.calltip)}{escape(cmd.documentation)}", NULL);\n')
