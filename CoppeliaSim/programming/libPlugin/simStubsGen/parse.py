import os
import sys
import xml.etree.ElementTree as ET

import model

def parse(xml_file):
    try:
        import xmlschema
        schema = xmlschema.XMLSchema11(os.path.dirname(os.path.realpath(__file__)) + '/xsd/callbacks.xsd')
        schema.validate(xml_file)
    except ModuleNotFoundError:
        print(f'warning: missing python package "xmlschema"; input file {os.path.basename(xml_file)} will not be validated.', file=sys.stderr)
    tree = ET.parse(xml_file)
    root = tree.getroot()
    return model.Plugin(root)

def escape(s, method='C'):
    if isinstance(s, str) and method == 'C':
        return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    else:
        return s
