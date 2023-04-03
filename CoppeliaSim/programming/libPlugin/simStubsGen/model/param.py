import re

class Param(object):
    mapping = {}

    def __init__(self, node):
        if node.tag != 'param':
            raise ValueError('expected <param>, got <%s>' % node.tag)
        self.name = node.attrib['name']
        if self.name == '':
            raise ValueError('attribute "name" of <param> cannot be empty')
        if self.name.startswith('_'):
            raise ValueError('attribute "name" of <param> cannot start with underscore')

        try:
            descnode = node.find('description')
            self.description = '' if descnode is None else '' if descnode.text is None else descnode.text
        except AttributeError:
            self.description = ''
        self.description = self.description.split('\n')[0]
        self.description = re.sub(' +', ' ', self.description)

        if 'type' not in node.attrib:
            raise ValueError('attribute "type" is missing in <param>')
        self.dtype = node.attrib['type']

        self.ctype_base = self.dtype
        self.default = node.attrib.get('default', None)
        self.skip = node.attrib.get('skip', 'false').lower() in ('true', 'yes', '1')
        self.nullable = node.attrib.get('nullable', 'false').lower() in ('true', 'yes', '1')
        self.write_in = True
        self.write_out = True

    def mandatory(self):
        return self.default is None

    def optional(self):
        return self.default is not None

    def ctype(self):
        if self.nullable: return 'boost::optional< %s >' % self.ctype_base
        else: return self.ctype_base

    def htype(self):
        return self.dtype

    def cdefault(self):
        if self.nullable and self.default == 'nil': return 'boost::none'
        return self.default

    def hdefault(self):
        return self.default

    @staticmethod
    def register_type(dtype, clazz):
        Param.mapping[dtype] = clazz

    @staticmethod
    def factory(node):
        if 'type' not in node.attrib:
            raise ValueError('attribute "type" is missing in <param>')
        dtype = node.attrib['type']
        if dtype not in Param.mapping:
            print('ERROR: type "{}" not found in mapping; valid types are: {}'.format(dtype, ', '.join('"%s"' % k for k in Param.mapping.keys())))
        return Param.mapping[dtype](node)

    def declaration(self):
        return '{} {}'.format(self.ctype(), self.name)

    def declaration_with_default(self):
        return self.declaration() + (' = {}'.format(self.cdefault()) if self.cdefault() else '')

class ParamInt(Param):
    def __init__(self, node):
        super(ParamInt, self).__init__(node)

    def htype(self):
        return 'int'

class ParamLong(Param):
    def __init__(self, node):
        super(ParamLong, self).__init__(node)

    def htype(self):
        return 'int'

class ParamFloat(Param):
    def __init__(self, node):
        super(ParamFloat, self).__init__(node)

    def htype(self):
        return 'float'

class ParamDouble(Param):
    def __init__(self, node):
        super(ParamDouble, self).__init__(node)

    def htype(self):
        return 'float'

class ParamString(Param):
    def __init__(self, node):
        super(ParamString, self).__init__(node)
        self.ctype_base = 'std::string'

class ParamBool(Param):
    def __init__(self, node):
        super(ParamBool, self).__init__(node)

class ParamTable(Param):
    def __init__(self, node):
        super(ParamTable, self).__init__(node)
        self.itype = node.attrib.get('item-type', None)
        if self.itype is not None:
            self.ctype_base = 'std::vector< %s >' % self.item_dummy().ctype()
        else:
            self.ctype_base = 'void *'

        self.minsize = 0
        self.maxsize = -1
        self.size = node.attrib.get('size', '')
        if self.size:
            sizecomp = self.size.split('..')
            if len(sizecomp) == 2:
                self.minsize = int(sizecomp[0])
                self.maxsize = -1 if sizecomp[1] == '*' else int(sizecomp[1])
            elif len(sizecomp) == 1 and sizecomp[0] != '*':
                self.minsize = self.maxsize = int(sizecomp[0])
        if self.minsize < 0:
            raise ValueError('Invalid min-size: cannot be negative')

        if self.itype is None:
            self.write_in = False
            self.write_out = False

    def item_dummy(self):
        n = type('dummyNode', (object,), dict(tag='param', attrib={'name': 'dummy', 'type': self.itype}))
        return Param.factory(n)

    def htype(self):
        if self.itype:
            return f'{self.item_dummy().htype()}[{self.size}]'
        elif self.size:
            return f'any[{self.size}]'
        else:
            return 'map'

class ParamStruct(Param):
    def __init__(self, node, name):
        super(ParamStruct, self).__init__(node)
        self.structname = name

    def htype(self):
        return 'map'

class ParamGrid(Param):
    def __init__(self, node):
        super(ParamGrid, self).__init__(node)
        self.size = node.attrib.get('size', '')
        self.itype = node.attrib.get('item-type', None)
        valid_itypes = ('int', 'float', 'double', 'long')
        if self.itype is None or self.itype not in valid_itypes:
            raise ValueError(f'Attribute "item-type" must be one of: {", ".join(valid_itypes)}')
        self.ctype_base = 'Grid< %s >' % self.itype

Param.register_type('any', Param)
Param.register_type('int', ParamInt)
Param.register_type('long', ParamLong)
Param.register_type('float', ParamFloat)
Param.register_type('double', ParamDouble)
Param.register_type('string', ParamString)
Param.register_type('bool', ParamBool)
Param.register_type('table', ParamTable)
Param.register_type('grid', ParamGrid)
