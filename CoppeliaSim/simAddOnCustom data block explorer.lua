function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool will display the custom data blocks attached to the selected object, or the custom data blocks attached to the scene, if no object is selected. Custom data blocks can be written and read with simWriteCustomDataBlock and simReadCustomDataBlock.")
    object=-1
    selectedDecoder=1
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

decoders={
    {
        name='auto',
        f=function(tag,data)
            local t=getTagType(tag)
            if t then
                local d=getDecoderForType(t)
                if d then
                    return d.f(tag,data)
                else
                    error('unknown type: '..t)
                end
            end
            return '<font color=#b75501>For automatic selection of decoder, there must be an \'__info__\' block with type information, e.g.: {myTagName={type=\'table\'}}</font>'
        end,
    },
    {
        name='binary',
        f=function(tag,data)
            return '<tt>'..data:gsub('(.)',function(y)
                return string.format('%02X ',string.byte(y))
            end)..'</tt>'
        end,
    },
    {
        name='string',
        f=function(tag,data)
            return data
        end,
    },
    {
        name='table',
        f=function(tag,data)
            local status,data=pcall(function() return sim.unpackTable(data) end)
            if status then
                return getAsString(data):gsub('[\n ]',{['\n']='<br/>',[' ']='&nbsp;'})
            end
        end,
    },
    {
        name='float[]',
        f=function(tag,data)
            return getAsString(sim.unpackFloatTable(data))
        end,
    },
    {
        name='double[]',
        f=function(tag,data)
            return getAsString(sim.unpackDoubleTable(data))
        end,
    },
    {
        name='int32[]',
        f=function(tag,data)
            return getAsString(sim.unpackInt32Table(data))
        end,
    },
    {
        name='uint8[]',
        f=function(tag,data)
            return getAsString(sim.unpackUInt8Table(data))
        end,
    },
    {
        name='uint16[]',
        f=function(tag,data)
            return getAsString(sim.unpackUInt16Table(data))
        end,
    },
    {
        name='uint32[]',
        f=function(tag,data)
            return getAsString(sim.unpackUInt32Table(data))
        end,
    },
}

function getTagType(tag)
    -- standard tags that have known types:
    if tag=='__info__' or tag=='__config__' or tag=='__schema__' then
        return 'table'
    elseif tag=='__type__' then
        return 'string'
    end

    if info and info.blocks and info.blocks[tag] then
        return info.blocks[tag]['type']
    end
end

function getDecoderForType(t)
    for i,decoder in ipairs(decoders) do
        if decoder.name~='auto' and decoder.name==t then
            return decoder
        end
    end
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function onDecoderChanged()
    local index=simUI.getComboboxSelectedIndex(ui,700)
    selectedDecoder=index+1
    if selectedDecoder>0 then
        local decoder=decoders[selectedDecoder]
        if selectedTag then
            local html=decoder.f(selectedTag,content[selectedTag])
            if html then
                simUI.setText(ui,800,html)
            else
                simUI.setText(ui,800,string.format('<font color=red>Not %s data</font>',decoder.name))
            end
        end
    else
        simUI.setText(ui,800,'')
    end
end

function onSelectionChange(ui,id,row,column)
    if row==-1 then
        selectedTag=nil
    else
        selectedTag=simUI.getItem(ui,id,row,0)
    end
    local e=selectedTag and true or false
    simUI.setEnabled(ui,20,e)
    simUI.setEnabled(ui,700,e)
    onDecoderChanged()
end

function onClearClicked(ui,id)
    if selectedTag then
        sim.writeCustomDataBlock(object,selectedTag,'')
        hideDlg()
    end
end

function onCloseClicked()
    leaveNow=true
end

function showDlg()
    if not ui then
        local pos='position="-30,160" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local title="Custom data blocks in scene:"
        if object~=sim.handle_scene then
            title="Custom data blocks in object '<b>"..sim.getObjectAlias(object,0).."</b>':"
        end
        if not ui then
            xml='<ui title="Custom Data Block Explorer" activate="false" closeable="true" on-close="onCloseClicked" resizable="false" '..pos..'>'
            xml=xml..'<group flat="true"><label text="'..title..'" /></group>'
            xml=xml..'<table id="600" selection-mode="row" editable="false" on-selection-change="onSelectionChange">'
            xml=xml..'<header><item>Tag name</item><item>Size (bytes)</item><item>Type</item></header>'
            local selectedIndex,i=-1,0
            for tag,data in pairs(content) do
                if tag==selectedTag then selectedIndex=i end
                xml=xml..'<row>'
                xml=xml..'<item>'..tag..'</item>'
                xml=xml..'<item>'..#data..'</item>'
                local t=getTagType(tag)
                if t then xml=xml..'<item>'..t..'</item>' end
                xml=xml..'</row>'
                i=i+1
            end
            xml=xml..'</table>'
            xml=xml..'<group flat="true" layout="grid">'
            xml=xml..'<label text="Decode as:" />'
            xml=xml..'<combobox id="700" on-change="onDecoderChanged">'
            for i,decoder in ipairs(decoders) do
                xml=xml..'<item>'..decoder.name..'</item>'
            end
            xml=xml..'</combobox>'
            xml=xml..'</group>'
            xml=xml..'<text-browser id="800" read-only="true" />'
            xml=xml..'<button id="20" enabled="false" text="Clear selected tag" on-click="onClearClicked" />'
            xml=xml..'</ui>'
            ui=simUI.create(xml)
            if selectedIndex~=-1 then
                simUI.setTableSelection(ui,600,selectedIndex,0,false)
            end
            simUI.setComboboxSelectedIndex(ui,700,selectedDecoder-1)
        end
    end
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local previousObject,previousContent=object,content
    content=nil
    object=-1
    info=nil
    local tags=nil
    if s then
        if #s>=1 then
            if s[#s]>=0 then
                object=s[#s]
            end
        end
    else
        object=sim.handle_scene
    end
    if object~=-1 then
        tags=sim.readCustomDataBlockTags(object)
        info=sim.readCustomDataBlock(object,'__info__')
        if info then info=sim.unpackTable(info) end
    end
    if previousObject~=object then
        hideDlg()
    end
    if tags then
        content={}
        for i,tag in ipairs(tags) do
            content[tag]=sim.readCustomDataBlock(object,tag)
        end
        local _=function(x) return x~=nil and sim.packTable(x) or nil end
        if _(content)~=_(previousContent) then
            hideDlg()
        end
        showDlg()
    else
        hideDlg()
    end
end
