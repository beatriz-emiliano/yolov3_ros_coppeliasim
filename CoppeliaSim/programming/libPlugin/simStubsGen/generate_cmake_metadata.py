import argparse
import sys
from parse import parse

parser = argparse.ArgumentParser(description='Generate CMake metadata.')
parser.add_argument('xml_file', type=str, default=None, help='the (merged) XML file')
parser.add_argument('out_file', type=str, default=None, help='the output CMake file')
args = parser.parse_args()

if args is False:
    SystemExit

plugin = parse(args.xml_file)

def output_cmake_var(f, cmake_name, value, cache=False, cmake_type='STRING', docstring=''):
    if cmake_type == 'STRING' and not isinstance(value, (int, float)):
        value = f'"{value}"'
    sc = f' CACHE {cmake_type} "{docstring}" FORCE' if cache else ''
    f.write(f'set({cmake_name} {value}{sc})\n')

with open(args.out_file, 'wt') as f:
    output_cmake_var(f, 'PLUGIN_NAME', plugin.name, True)
    output_cmake_var(f, 'PLUGIN_VERSION', plugin.version, True)
