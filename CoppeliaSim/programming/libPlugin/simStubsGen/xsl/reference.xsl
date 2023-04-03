<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" encoding="utf-8" indent="yes"/>

    <!-- special tags that can be used in the xml: -->

    <xsl:template match="command-ref">
        <xsl:call-template name="renderCmdRef">
            <xsl:with-param name="name" select="@name"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="enum-ref">
        <xsl:call-template name="renderEnumRef">
            <xsl:with-param name="name" select="@name"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="struct-ref">
        <xsl:call-template name="renderStructRef">
            <xsl:with-param name="name" select="@name"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="script-function-ref">
        <xsl:call-template name="renderScriptFunctionRef">
            <xsl:with-param name="name" select="@name"/>
        </xsl:call-template>
    </xsl:template>

    <!-- allow basic formatting HTML tags too: -->

    <xsl:template match="sub">
        <sub><xsl:apply-templates select="node()"/></sub>
    </xsl:template>

    <xsl:template match="sup">
        <sup><xsl:apply-templates select="node()"/></sup>
    </xsl:template>

    <xsl:template match="em">
        <em><xsl:apply-templates select="node()"/></em>
    </xsl:template>

    <xsl:template match="strong">
        <strong><xsl:apply-templates select="node()"/></strong>
    </xsl:template>

    <xsl:template match="ul">
        <ul><xsl:apply-templates select="node()"/></ul>
    </xsl:template>

    <xsl:template match="ol">
        <ol><xsl:apply-templates select="node()"/></ol>
    </xsl:template>

    <xsl:template match="li">
        <li><xsl:apply-templates select="node()"/></li>
    </xsl:template>

    <xsl:template match="br">
        <br />
    </xsl:template>

    <xsl:template match="a">
        <xsl:element name="a">
            <xsl:if test="@href">
                <xsl:attribute name="href">
                    <xsl:value-of select="@href" />
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()" />
        </xsl:element>
    </xsl:template>

    <xsl:preserve-space elements="code" />
    <xsl:template match="code">
        <xsl:element name="code">
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@display = 'inline'">code-inline</xsl:when>
                    <xsl:otherwise>code-block</xsl:otherwise>
                </xsl:choose>
                <xsl:text> hljs </xsl:text>
                <xsl:choose>
                    <xsl:when test="@language"><xsl:value-of select="@language"/></xsl:when>
                    <xsl:otherwise>lua</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="node()" />
        </xsl:element>
    </xsl:template>

    <!-- template routines: -->

    <xsl:template name="symbolPrefix">
        <xsl:text>sim</xsl:text>
        <xsl:value-of select="/plugin/@name"/>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <xsl:template name="renderCmdName">
        <xsl:param name="name"/>
        <xsl:call-template name="symbolPrefix"/>
        <xsl:value-of select="$name"/>
    </xsl:template>

    <xsl:template name="renderCmdRef">
        <xsl:param name="name"/>
        <a href="#{$name}"><xsl:call-template name="renderCmdName"><xsl:with-param name="name" select="$name"/></xsl:call-template></a>
    </xsl:template>

    <xsl:template name="renderLuaParamType">
        <xsl:choose>
            <xsl:when test="@type = 'table' and @item-type">
                <xsl:value-of select="@item-type"/>
                <xsl:text>[</xsl:text>
                <xsl:value-of select="@size"/>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="renderLuaParamsSynopsis">
        <xsl:param name="cmd"/>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="$cmd/params/param">
            <xsl:call-template name="renderLuaParamType" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="@default">=<xsl:value-of select="@default"/></xsl:if>
            <xsl:if test="not(position() = last())">, </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <xsl:template name="renderLuaReturnsSynopsis">
        <xsl:param name="cmd"/>
        <xsl:for-each select="$cmd/return/param">
            <xsl:call-template name="renderLuaParamType" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="not(position() = last())">, </xsl:if>
        </xsl:for-each>
        <xsl:if test="$cmd/return/param">=</xsl:if>
    </xsl:template>

    <xsl:template name="renderLuaCmdSynopsis">
        <xsl:param name="cmd"/>
        <xsl:param name="nameTemplate"/>
        <xsl:call-template name="renderLuaReturnsSynopsis">
            <xsl:with-param name="cmd" select="$cmd"/>
        </xsl:call-template>
        <xsl:call-template name="renderCmdName">
            <xsl:with-param name="name" select="$cmd/@name"/>
        </xsl:call-template>
        <xsl:call-template name="renderLuaParamsSynopsis">
            <xsl:with-param name="cmd" select="$cmd"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="renderPythonParamType">
        <xsl:choose>
            <xsl:when test="@type = 'table'">list</xsl:when>
            <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="renderPythonParamsSynopsis">
        <xsl:param name="cmd"/>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="$cmd/params/param">
            <xsl:call-template name="renderPythonParamType" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="@default">=<xsl:value-of select="@default"/></xsl:if>
            <xsl:if test="not(position() = last())">, </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <xsl:template name="renderPythonReturnsSynopsis">
        <xsl:param name="cmd"/>
        <xsl:for-each select="$cmd/return/param">
            <xsl:call-template name="renderPythonParamType" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="not(position() = last())">, </xsl:if>
        </xsl:for-each>
        <xsl:if test="$cmd/return/param">=</xsl:if>
    </xsl:template>

    <xsl:template name="renderPythonCmdSynopsis">
        <xsl:param name="cmd"/>
        <xsl:param name="nameTemplate"/>
        <xsl:call-template name="renderPythonReturnsSynopsis">
            <xsl:with-param name="cmd" select="$cmd"/>
        </xsl:call-template>
        <xsl:call-template name="renderCmdName">
            <xsl:with-param name="name" select="$cmd/@name"/>
        </xsl:call-template>
        <xsl:call-template name="renderPythonParamsSynopsis">
            <xsl:with-param name="cmd" select="$cmd"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="renderEnumName">
        <xsl:param name="name"/>
        <xsl:call-template name="symbolPrefix"/>
        <xsl:value-of select="$name"/>
    </xsl:template>

    <xsl:template name="renderEnumRef">
        <xsl:param name="name"/>
        <a href="#enum:{$name}"><xsl:call-template name="renderEnumName"><xsl:with-param name="name" select="$name"/></xsl:call-template></a>
    </xsl:template>

    <xsl:template name="renderStructName">
        <xsl:param name="name"/>
        <xsl:value-of select="$name"/>
    </xsl:template>

    <xsl:template name="renderStructRef">
        <xsl:param name="name"/>
        <a href="#struct:{$name}"><xsl:call-template name="renderStructName"><xsl:with-param name="name" select="$name"/></xsl:call-template></a>
    </xsl:template>

    <xsl:template name="renderScriptFunctionName">
        <xsl:param name="name"/>
        <xsl:value-of select="$name"/>
    </xsl:template>

    <xsl:template name="renderScriptFunctionRef">
        <xsl:param name="name"/>
        <a href="#scriptfun:{$name}"><xsl:call-template name="renderScriptFunctionName"><xsl:with-param name="name" select="$name"/></xsl:call-template></a>
    </xsl:template>

    <xsl:template name="renderParamsBlock">
        <xsl:param name="showDefault"/>
        <xsl:choose>
            <xsl:when test="param">
                <xsl:for-each select="param">
                    <div>
                        <strong><xsl:value-of select="@name"/></strong>
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="@type"/>
                        <xsl:if test="@type='table'">
                            <xsl:if test="@item-type">
                                <xsl:text> of </xsl:text>
                                <xsl:value-of select="@item-type"/>
                            </xsl:if>
                            <xsl:if test="@size and not(@size = '') and not(@size = '*')">
                                <xsl:text>, size </xsl:text>
                                <xsl:value-of select="@size"/>
                            </xsl:if>
                        </xsl:if>
                        <xsl:if test="@default and $showDefault='true'">
                            <xsl:text>, default: </xsl:text>
                            <xsl:value-of select="@default"/>
                        </xsl:if>
                        <xsl:text>): </xsl:text>
                        <xsl:apply-templates select="description/node()"/>
                    </div>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="renderRelated">
        <xsl:variable name="sname" select="@name"/>
        <!-- manual cross references (within tag <see-also>): -->
        <xsl:for-each select="see-also/*[name()='command-ref' or name()='enum-ref' or name()='struct-ref' or name()='script-function-ref']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="."/>
        </xsl:for-each>
        <!-- autogenerated cross references from command in the same category -->
        <xsl:for-each select="categories/category">
            <xsl:variable name="cat" select="@name"/>
            <xsl:for-each select="/plugin/command">
                <xsl:sort select="@name"/>
                <xsl:variable name="cmd" select="@name"/>
                <xsl:if test="not($cmd = $sname)">
                    <xsl:for-each select="categories/category">
                        <xsl:if test="not(@indirect = 'true')">
                            <xsl:if test="$cat=@name">
                                <xsl:text> </xsl:text>
                                <xsl:call-template name="renderCmdRef">
                                    <xsl:with-param name="name" select="$cmd"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- root template: -->

    <xsl:template match="/">
        <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Strict//EN"&gt;</xsl:text>
        <html>
            <head>
                <meta http-equiv="Content-Language" content="en-us"/>
                <title><xsl:value-of select="/plugin/@name"/> Plugin API reference</title>
                <link rel="stylesheet" type="text/css" href="../../helpFiles/style.css"/>
                <script type="text/javascript">
//<![CDATA[
function getParameterByName(name, url = window.location.href)
{
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if(!results) return null;
    if(!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}
//]]>
                </script>
                <style type="text/css">
td.section { margin: 0; padding: 0; }
                </style>
            </head>
            <body>
                <div align="center">
                    <table class="allEncompassingTable">
                        <tr>
                            <td id="title" class="section">
                                <h1><xsl:value-of select="/plugin/@name"/> Plugin API reference</h1>
                            </td>
                        </tr>
                        <tr>
                            <td id="info" class="section">
                                <!-- Short info -->
                                <xsl:if test="/plugin/description and (/plugin/description != '')">
                                    <p class="infoBox">
                                        <xsl:apply-templates select="/plugin/description/node()"/>
                                    </p>
                                </xsl:if>
                            </td>
                        </tr>
                        <tr>
                            <td id="alphabetical" class="section">
                                <!-- Alphabetical list -->
                                <pre class="lightGreyBox">
                                    <xsl:for-each select="plugin/command">
                                        <xsl:sort select="@name"/>
                                        <a href="?#{@name}"><xsl:call-template name="renderCmdName"><xsl:with-param name="name" select="@name"/></xsl:call-template></a><xsl:text>&#10;</xsl:text>
                                    </xsl:for-each>
                                </pre>
                            </td>
                        </tr>
                        <tr>
                            <td id="commands" class="section">
                                <!-- Commands reference list -->
                                <xsl:for-each select="plugin/command">
                                    <xsl:sort select="@name"/>
                                    <h3 class="subsectionBar"><a name="{@name}" id="{@name}"></a><xsl:call-template name="renderCmdName"><xsl:with-param name="name" select="@name"/></xsl:call-template></h3>
                                    <table class="apiTable">
                                        <xsl:if test="description != ''">
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftDescr">
                                                    Description
                                                </td>
                                                <td class="apiTableRightDescr">
                                                    <xsl:apply-templates select="description/node()"/>
                                                </td>
                                            </tr>
                                        </xsl:if>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftLSyn">Lua synopsis</td>
                                            <td class="apiTableRightLSyn">
                                                <xsl:call-template name="renderLuaCmdSynopsis">
                                                    <xsl:with-param name="cmd" select="."/>
                                                    <xsl:with-param name="nameTemplate" select="renderCmdName"/>
                                                </xsl:call-template>
                                                <br/>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftLParam">Lua parameters</td>
                                            <td class="apiTableRightLParam">
                                                <xsl:for-each select="params">
                                                    <xsl:call-template name="renderParamsBlock">
                                                        <xsl:with-param name="showDefault" select="'true'"/>
                                                    </xsl:call-template>
                                                </xsl:for-each>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftLRet">Lua return values</td>
                                            <td class="apiTableRightLRet">
                                                <xsl:for-each select="return">
                                                    <xsl:call-template name="renderParamsBlock">
                                                        <xsl:with-param name="showDefault" select="'false'"/>
                                                    </xsl:call-template>
                                                </xsl:for-each>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftPSyn">Python synopsis</td>
                                            <td class="apiTableRightPSyn">
                                                <xsl:call-template name="renderPythonCmdSynopsis">
                                                    <xsl:with-param name="cmd" select="."/>
                                                    <xsl:with-param name="nameTemplate" select="renderCmdName"/>
                                                </xsl:call-template>
                                                <br/>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftDescr">
                                                See also
                                            </td>
                                            <td class="apiTableRightDescr">
                                                <xsl:call-template name="renderRelated"/>
                                            </td>
                                        </tr>
                                    </table>
                                    <br/>
                                </xsl:for-each>
                            </td>
                        </tr>
                        <tr>
                            <td id="enums" class="section">
                                <!-- Enums reference list -->
                                <xsl:if test="plugin/enum/*">
                                    <br/>
                                    <br/>
                                    <h1>Constants</h1>
                                    <p>Constants used in the various functions. Refer to each constant using <i>enumName.constantName</i>, i.e. <b>simUI.curve_type.xy</b> for <b>xy</b> constant in <b>simUI.curve_type</b> enum.</p>
                                    <xsl:for-each select="plugin/enum">
                                        <h3 class="subsectionBar"><a name="enum:{@name}" id="enum:{@name}"></a><xsl:call-template name="renderEnumName"><xsl:with-param name="name" select="@name"/></xsl:call-template></h3>
                                    <table class="apiConstantsTable">
                                        <tbody>
                                            <tr>
                                                <td>
                                                    <xsl:for-each select="item">
                                                        <div>
                                                            <strong>
                                                                <xsl:value-of select="@name"/>
                                                            </strong>
                                                            <xsl:if test="description">
                                                                <xsl:text>: </xsl:text>
                                                                <xsl:apply-templates select="description/node()"/>
                                                            </xsl:if>
                                                        </div>
                                                    </xsl:for-each>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                    </xsl:for-each>
                                </xsl:if>
                            </td>
                        </tr>
                        <tr>
                            <td id="structs" class="section">
                                <!-- Data structures reference list -->
                                <xsl:if test="plugin/struct/*">
                                    <br/>
                                    <br/>
                                    <h1>Data structures</h1>
                                    <p>Data structures are used to pass complex data around. Create data structures in Lua in the form of a map, e.g.: <code>{line_size=3, add_to_legend=false, selectable=true}</code></p>
                                    <xsl:for-each select="plugin/struct">
                                    <h3 class="subsectionBar"><a name="struct:{@name}" id="struct:{@name}"></a><xsl:call-template name="renderStructName"><xsl:with-param name="name" select="@name"/></xsl:call-template></h3>
                                    <table class="apiTable">
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftDescr">
                                                Description
                                            </td>
                                            <td class="apiTableRightDescr">
                                                <xsl:apply-templates select="description/node()"/>
                                                <br/>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftLParam">Fields</td>
                                            <td class="apiTableRightLParam">
                                                <xsl:call-template name="renderParamsBlock">
                                                    <xsl:with-param name="showDefault" select="'true'"/>
                                                </xsl:call-template>
                                            </td>
                                        </tr>
                                        <tr class="apiTableTr">
                                            <td class="apiTableLeftDescr">
                                                See also
                                            </td>
                                            <td class="apiTableRightDescr">
                                                <xsl:call-template name="renderRelated"/>
                                            </td>
                                        </tr>
                                    </table>
                                    <br/>
                                    </xsl:for-each>
                                </xsl:if>
                            </td>
                        </tr>
                        <tr>
                            <td id="scriptFunctions" class="section">
                                <!-- Script functions reference list -->
                                <xsl:if test="plugin/script-function/*">
                                    <br/>
                                    <br/>
                                    <h1>Script functions</h1>
                                    <p>Script functions are used to call some lua code from the plugin side (tipically used for event handlers).</p>
                                    <xsl:for-each select="plugin/script-function">
                                    <h3 class="subsectionBar"><a name="scriptfun:{@name}" id="scriptfun:{@name}"></a><xsl:call-template name="renderScriptFunctionName"><xsl:with-param name="name" select="@name"/></xsl:call-template></h3>
                                        <table class="apiTable">
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftDescr">
                                                    Description
                                                </td>
                                                <td class="apiTableRightDescr">
                                                    <xsl:apply-templates select="description/node()"/>
                                                </td>
                                            </tr>
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftLSyn">Lua synopsis</td>
                                                <td class="apiTableRightLSyn">
                                                    <xsl:call-template name="renderLuaCmdSynopsis">
                                                        <xsl:with-param name="cmd" select="."/>
                                                        <xsl:with-param name="nameTemplate" select="renderScriptFunctionName"/>
                                                    </xsl:call-template>
                                                    <br/>
                                                </td>
                                            </tr>
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftLParam">Lua parameters</td>
                                                <td class="apiTableRightLParam">
                                                    <xsl:for-each select="params">
                                                        <xsl:call-template name="renderParamsBlock">
                                                            <xsl:with-param name="showDefault" select="'true'"/>
                                                        </xsl:call-template>
                                                    </xsl:for-each>
                                                </td>
                                            </tr>
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftLRet">Lua return values</td>
                                                <td class="apiTableRightLRet">
                                                    <xsl:for-each select="return">
                                                        <xsl:call-template name="renderParamsBlock">
                                                            <xsl:with-param name="showDefault" select="'false'"/>
                                                        </xsl:call-template>
                                                    </xsl:for-each>
                                                </td>
                                            </tr>
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftPSyn">Python synopsis</td>
                                                <td class="apiTableRightPSyn">
                                                    <xsl:call-template name="renderPythonCmdSynopsis">
                                                        <xsl:with-param name="cmd" select="."/>
                                                        <xsl:with-param name="nameTemplate" select="renderScriptFunctionName"/>
                                                    </xsl:call-template>
                                                    <br/>
                                                </td>
                                            </tr>
                                            <tr class="apiTableTr">
                                                <td class="apiTableLeftDescr">
                                                    See also
                                                </td>
                                                <td class="apiTableRightDescr">
                                                    <xsl:call-template name="renderRelated"/>
                                                </td>
                                            </tr>
                                        </table>
                                    <br/>
                                    </xsl:for-each>
                                </xsl:if>
                            </td>
                        </tr>
                    </table>
                </div>
                <script type="text/javascript">
//<![CDATA[
view = getParameterByName('view')
document.getElementById('alphabetical').style.display = view == 'alphabetical' ? 'table-cell' : 'none'
document.getElementById('commands').style.display = view == null ? 'table-cell' : 'none'
document.getElementById('enums').style.display = view == null ? 'table-cell' : 'none'
document.getElementById('structs').style.display = view == null ? 'table-cell' : 'none'
document.getElementById('scriptFunctions').style.display = view == null ? 'table-cell' : 'none'
//]]>
                </script>
                <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.6.0/styles/default.min.css" />
                <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.6.0/highlight.min.js"></script>
                <script type="text/javascript">
//<![CDATA[
document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('code.hljs').forEach((block) => {
        hljs.highlightBlock(block);
    });
});
//]]>
                </script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
