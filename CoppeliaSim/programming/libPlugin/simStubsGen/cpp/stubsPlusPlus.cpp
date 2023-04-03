#py from parse import parse
#py import model
#py plugin = parse(pycpp.params['xml_file'])

// include this file after calling the SIM_PLUGIN(...) macro

#py for cmd in plugin.commands:
void `cmd.c_name`(SScriptCallBack *p, const char *cmd, `cmd.c_in_name` *in, `cmd.c_out_name` *out)
{
    sim::plugin->`cmd.c_name`(in, out);
}
#py endfor

