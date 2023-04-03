#@name External file inclusion
include myExternalFile

# myExternalFile is the pythonScript name or path (absolute or relative), without quotes nor the ending '.py'
# searched paths include:
# <CoppeliaSim executable path>/ 
# <CoppeliaSim executable path>/python 
# <current scene path>/ 
# <additional path>/ (see system/usrset.txt and value 'additionalPythonPath')
# additional include paths passed via #luaExec additionalIncludePaths={'c:/Python38'}
