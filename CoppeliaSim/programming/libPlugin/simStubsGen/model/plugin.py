from .command import Command
from .script_function import ScriptFunction
from .enum import Enum
from .struct import Struct

class Plugin(object):
    def __init__(self, node):
        if node.tag != 'plugin':
            raise ValueError('expected <plugin>, got <%s>' % node.tag)
        self.name = node.attrib['name']
        self.version = int(node.attrib.get('version', 0))
        self.enums = [Enum(self, n) for n in node.findall('enum')]
        self.structs = [Struct(self, n) for n in node.findall('struct')]
        self.commands = [Command(self, n) for n in node.findall('command')]
        self.script_functions = [ScriptFunction(self, n) for n in node.findall('script-function')]

