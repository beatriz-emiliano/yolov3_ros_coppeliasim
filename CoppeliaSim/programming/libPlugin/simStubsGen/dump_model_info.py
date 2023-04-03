import os
import os.path
import errno
import re
import sys

from parse import parse
import model

plugin = parse(sys.argv[1])

def dumpobj(o, indent=0, indentstr='  '):
    if isinstance(o, dict):
        d = o
    else:
        d = o.__dict__
    for k, v in d.items():
        if k.startswith('__'): continue
        if isinstance(v, (list, tuple)):
            print(f'{indentstr*indent}{k}: <{len(v)} items>')
            dumpobj({f'[{i}]': vi for i, vi in enumerate(v)}, indent=indent+1)
        elif isinstance(v, (type(None), int, str, bool, model.plugin.Plugin)):
            print(f'{indentstr*indent}{k}: {v}')
        else:
            print(f'{indentstr*indent}{k}: {v}')
            dumpobj(v, indent=indent+1)

dumpobj(plugin)
