import argparse
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description='Merge two xml documents.')
parser.add_argument('xml_1', type=str, default=None, help='the first XML file')
parser.add_argument('xml_2', type=str, default=None, help='the second XML file')
parser.add_argument('out_xml', type=str, default=None, help='the output XML file')
args = parser.parse_args()

if args is False:
    SystemExit

with open(args.xml_1, 'rb') as f1, open(args.xml_2, 'rb') as f2, open(args.out_xml, 'wb') as f3:
    tree = list(map(ET.parse, (f1, f2)))
    root = list(map(lambda tree: tree.getroot(), tree))
    for e in root[1]:
        root[0].append(e)
    tree[0].write(f3, encoding='utf-8', xml_declaration=True)

