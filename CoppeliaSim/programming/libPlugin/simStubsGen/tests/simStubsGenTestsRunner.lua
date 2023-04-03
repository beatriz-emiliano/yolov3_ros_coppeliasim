function main()
    local struct1={i=10,f=6.6,d=4.444444,s='xx',b=false}

    numPassed,numFailed=0,0

    assertOk('basic.valid.1', function()
        -- valid args
        a,b,c,d,e,f,g=simStubsGenTests.basic(5,3.3,4.444444,'x',true,{1,2},struct1)
        -- output args are copied from input args
        assertEq('i',a,5)
        assertEq('f',b,3.3)
        assertEq('d',c,4.444444)
        assertEq('s',d,'x')
        assertEq('b',e,true)
        assertEq('ti',f,{1,2})
        assertEq('z',g,struct1)
    end)

    assertOk('basic.valid.2', function()
        -- more valid args
        simStubsGenTests.basic(0,0,0,'',false,{1},struct1)
    end)

    assertFail('basic.toofew', function()
        simStubsGenTests.basic(0,0,0,'',false,{1})
    end)

    assertFail('basic.toomany', function()
        simStubsGenTests.basic(0,0,0,'',false,{1},struct1,8)
    end)

    assertFail('basic.toomany.2', function()
        simStubsGenTests.basic(0,0,0,'',false,{1},struct1,nil)
    end)

    assertFail('basic.1.badnil', function()
        -- pass nil to first (is not nullable)
        simStubsGenTests.basic(nil,3.3,6,'x',true,{1},struct1)
    end)

    assertFail('basic.1.badtype', function()
        -- pass incorrect type to first (requires int)
        simStubsGenTests.basic('z',3.3,6,'x',true,{1},struct1)
    end)

    assertFail('basic.2.badtype', function()
        -- pass incorrect type to second (requires float)
        simStubsGenTests.basic(0,true,6,'x',true,{1},struct1)
    end)

    assertFail('basic.2.badnil', function()
        -- pass nil to second (is not nullable)
        simStubsGenTests.basic(1,nil,6,'x',true,{1},struct1)
    end)

    assertFail('basic.3.badnil', function()
        -- pass nil to third (is not nullable)
        simStubsGenTests.basic(2,3.7,nil,'x',true,{1},struct1)
    end)

    assertFail('basic.4.badtype', function()
        -- pass incorrect type to fourth (requires string)
        simStubsGenTests.basic(9,3.3,6,false,true,{1},struct1)
    end)

    assertFail('basic.5.badtype', function()
        -- pass incorrect type to fifth (requires bool)
        simStubsGenTests.basic(9,3.3,6,'x',0,{1},struct1)
    end)

    assertFail('basic.5.badnil', function()
        -- pass nil to fifth (is not nullable)
        simStubsGenTests.basic(9,3.3,6,'x',nil,{1},struct1)
    end)

    assertFail('basic.6.badsize.1', function()
        -- pass incorrect table size to sixth (requires 1<=sz<=2)
        simStubsGenTests.basic(9,3.3,6,'x',false,{},struct1)
    end)

    assertFail('basic.6.badsize.2', function()
        -- pass incorrect table size to sixth (requires 1<=sz<=2)
        simStubsGenTests.basic(9,3.3,6,'x',false,{1,2,3},struct1)
    end)

    assertFail('basic.6.badtype', function()
        -- pass incorrect item type to sixth (requires int)
        simStubsGenTests.basic(9,3.3,6,'x',false,{'a','b'},struct1)
    end)

    assertFail('basic.7.badnil', function()
        -- pass nil to seventh (is not nullable, requires struct)
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},nil)
    end)

    assertFail('basic.7.badnil', function()
        -- pass nil to seventh (is not nullable, requires struct)
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},nil)
    end)

    assertFail('basic.7.badnil', function()
        -- pass nil to seventh (is not nullable, requires struct)
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},nil)
    end)

    assertFail('basic.7.badtype', function()
        -- pass incorrect type to seventh (requires struct)
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},'')
    end)

    assertFail('basic.struct.badtype.1', function()
        -- pass bad struct (z.i requires int) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i='',f=6.6,d=4.444444,s='xx',b=false})
    end)

    assertFail('basic.struct.badtype.2', function()
        -- pass bad struct (z.f requires float) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=false,d=4.444444,s='xx',b=false})
    end)

    assertFail('basic.struct.badtype.3', function()
        -- pass bad struct (z.d requires double) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d={},s='xx',b=false})
    end)

    assertFail('basic.struct.badtype.4', function()
        -- pass bad struct (z.s requires string) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d=4.444444,s=true,b=false})
    end)

    assertFail('basic.struct.badtype.5', function()
        -- pass bad struct (z.b requires bool) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d=4.444444,s='xx',b={}})
    end)

    assertFail('basic.struct.missing.1', function()
        -- pass bad struct (z.i is not nullable) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{f=6.6,d=4.444444,s='xx',b=false})
    end)

    assertFail('basic.struct.missing.2', function()
        -- pass bad struct (z.f is not nullable) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,d=4.444444,s='xx',b=false})
    end)

    assertFail('basic.struct.missing.3', function()
        -- pass bad struct (z.d is not nullable) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,s='xx',b=false})
    end)

    assertFail('basic.struct.missing.4', function()
        -- pass bad struct (z.s is not nullable) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d=4.444444,b=false})
    end)

    assertFail('basic.struct.missing.5', function()
        -- pass bad struct (z.b is not nullable) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d=4.444444,s='xx'})
    end)

    assertFail('basic.struct.extra', function()
        -- pass bad struct (z.z is not a valid field) to seventh
        simStubsGenTests.basic(9,3.3,6,'x',true,{1},{i=6,f=6.6,d=4.444444,s='xx',b=false,z=9})
    end)

    assertOk('nullable.valid.1', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,nil,nil,nil,nil,nil)
        assertEq('i',i,nil)
        assertEq('f',f,nil)
        assertEq('d',d,nil)
        assertEq('s',s,nil)
        assertEq('b',b,nil)
        assertEq('ti',ti,nil)
        assertEq('z',z,nil)
    end)

    assertFail('nullable.toofew', function()
        simStubsGenTests.nullable(nil,nil,nil,nil,nil)
    end)

    assertFail('nullable.toomany', function()
        simStubsGenTests.nullable(nil,nil,nil,nil,nil,nil,nil,nil,nil)
    end)

    assertOk('nullable.valid.1', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(56,nil,nil,nil,nil,nil,nil)
        assertEq('i',i,56)
    end)

    assertOk('nullable.valid.2', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,1.23,nil,nil,nil,nil,nil)
        assertEq('f',f,1.23)
    end)

    assertOk('nullable.valid.3', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,1.2345,nil,nil,nil,nil)
        assertEq('d',d,1.2345)
    end)

    assertOk('nullable.valid.4', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,nil,'fg',nil,nil,nil)
        assertEq('s',s,'fg')
    end)

    assertOk('nullable.valid.5', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,nil,nil,true,nil,nil)
        assertEq('b',b,true)
    end)

    assertOk('nullable.valid.6', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,nil,nil,nil,{7,8},nil)
        assertEq('ti',ti,{7,8})
    end)

    assertOk('nullable.valid.7', function()
        i,f,d,s,b,ti,z=simStubsGenTests.nullable(nil,nil,nil,nil,nil,nil,struct1)
        assertEq('z',z,struct1)
    end)

    assertOk('struct_table.valid.1', function()
        i,f,d,s,b=simStubsGenTests.struct_table(0,'i',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('i',i,1)
        assertEq('f',f,nil)
        assertEq('d',d,nil)
        assertEq('s',s,nil)
        assertEq('b',b,nil)
    end)

    assertOk('struct_table.valid.2', function()
        i,f,d,s,b=simStubsGenTests.struct_table(0,'f',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('i',i,nil)
        assertEq('f',f,4.4)
        assertEq('d',d,nil)
        assertEq('s',s,nil)
        assertEq('b',b,nil)
    end)

    assertOk('struct_table.valid.3', function()
        i,f,d,s,b=simStubsGenTests.struct_table(0,'d',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('d',d,6.6)
    end)

    assertOk('struct_table.valid.4', function()
        i,f,d,s,b=simStubsGenTests.struct_table(0,'s',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('s',s,'a')
    end)

    assertOk('struct_table.valid.5', function()
        i,f,d,s,b=simStubsGenTests.struct_table(0,'b',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('b',b,false)
    end)

    assertOk('struct_table.valid.6', function()
        i,f,d,s,b=simStubsGenTests.struct_table(1,'i',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('i',i,2)
    end)

    assertOk('struct_table.valid.7', function()
        i,f,d,s,b=simStubsGenTests.struct_table(1,'f',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('f',f,4.5)
    end)

    assertOk('struct_table.valid.8', function()
        i,f,d,s,b=simStubsGenTests.struct_table(1,'d',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('d',d,6.7)
    end)

    assertOk('struct_table.valid.9', function()
        i,f,d,s,b=simStubsGenTests.struct_table(1,'s',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('s',s,'b')
    end)

    assertOk('struct_table.valid.10', function()
        i,f,d,s,b=simStubsGenTests.struct_table(1,'b',{{i=1,f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
        assertEq('b',b,true)
    end)

    assertFail('struct_table.item.missing.field', function()
        -- field 'i' missing in first item
        simStubsGenTests.struct_table(1,'b',{{f=4.4,d=6.6,s='a',b=false},{i=2,f=4.5,d=6.7,s='b',b=true}})
    end)

    assertOk('test_struct2.i.provided', function()
        i,in_,id,idn=simStubsGenTests.test_struct2{i=1}
        assertEq('i',i,1)
        assertEq('id',id,42) -- default val
        assertEq('idn',idn,43) -- default val
    end)

    assertFail('test_struct2.i.missing', function()
        i,in_,id,idn=simStubsGenTests.test_struct2{}
    end)

    assertOk('test_struct2.id.override', function()
        i,in_,id,idn=simStubsGenTests.test_struct2{i=10,id=5}
        assertEq('id',id,5)
    end)

    assertOk('test_struct2.idn.reset', function()
        i,in_,id,idn=simStubsGenTests.test_struct2{i=-1} -- i<0 will cause idn to be set to nil
        assertEq('idn',idn,nil)
    end)

    assertOk('struct_default.1', function()
        z=simStubsGenTests.struct_default()
        assertEq('z',z,{i=10,["in"]=20,id=30,idn=40})
    end)

    --[[
    assertOk('lua.nullable.nil', function()
        simStubsGenTests.testLuaNullable(nil,'x')
    end)

    assertOk('lua.nullable.typeOk', function()
        simStubsGenTests.testLuaNullable(123,'x')
    end)

    assertFail('lua.nullable.typeFail', function()
        simStubsGenTests.testLuaNullable('bad','x')
    end)

    assertFail('lua.default.badtype', function()
        simStubsGenTests.testLuaDefault(123,456)
    end)

    assertFail('lua.default.nil', function()
        simStubsGenTests.testLuaDefault(123,nil) -- b is not nullable
    end)

    assertOk('lua.default.def', function()
        assertEq('ret',simStubsGenTests.testLuaDefault(123),'x')
    end)

    assertOk('lua.default.typeok', function()
        assertEq('ret',simStubsGenTests.testLuaDefault(123,'y'),'y')
    end)
    ]]

    assertOk('grid.1', function()
        local a=simStubsGenTests.test_grid({dims={2,3},data={11,12,13,21,22,23}})
        assertEq('a',{dims={2,3},data={22,24,26,42,44,46}},a)
    end)

    assertFail('grid.2', function()
        simStubsGenTests.test_grid({dims={2,3},data={11,12,13,21,22}})
    end)

    assertFail('grid.3', function()
        simStubsGenTests.test_grid({dims={},data={}})
    end)

    assertOk('grid.2.1', function()
        simStubsGenTests.test_grid2(
            {dims={2,3},data={11,12,13,21,22,23}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={4,2,1},data={1,0,0,0,1,0,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.2', function()
        simStubsGenTests.test_grid2(
            {dims={6},data={11,12,13,21,22,23}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={4,2,1},data={1,0,0,0,1,0,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.3', function()
        simStubsGenTests.test_grid2(
            {dims={2,2,4},data={4,4,4,4,5,5,5,5,4,4,4,4,8,8,8,8}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={4,2,1},data={1,0,0,0,1,0,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.4', function()
        simStubsGenTests.test_grid2(
            {dims={2,3},data={11,12,13,21,22,23}},
            {dims={3,2},data={1,1,1,2,2,2}},
            {dims={4,2,1},data={1,0,0,0,1,0,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.5', function()
        simStubsGenTests.test_grid2(
            {dims={2,3},data={11,12,13,21,22,23}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={4,2},data={1,0,0,0,1,0,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.6', function()
        simStubsGenTests.test_grid2(
            {dims={2,3},data={11,12,13,21,22,23}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={3,2,1},data={1,0,0,1,0,0}},
            {dims={2,3},data={11,12,13,21,22,23}}
        )
    end)

    assertFail('grid.2.7', function()
        simStubsGenTests.test_grid2(
            {dims={2,3},data={11,12,13,21,22,23}},
            {dims={3,3},data={1,0,0,0,1,0,0,0,1}},
            {dims={4,2,1},data={1,0,0,0,1,0,0,0}},
            {dims={2,1},data={11,12}}
        )
    end)

    local totalTests=numPassed+numFailed
    logInfo('%d/%d tests passed successfully',numPassed,totalTests)

    if numPassed<totalTests then
        sim.setInt32Parameter(sim.intparam_exitcode,1)
    end
end

function level2string(level)
    if level==sim.verbosity_errors then return 'error' end
    if level==sim.verbosity_warnings then return 'warning' end
    if level==sim.verbosity_infos then return 'info' end
    if level==sim.verbosity_debug then return 'debug' end
    return '???'
end

function log(level,fmt,...)
    --sim.addLog(level,string.format('StubsGenTests: '..fmt,...))
    printToConsole(level2string(level),string.format('StubsGenTests: '..fmt,...))
end

function logError(fmt,...)
    log(sim.verbosity_errors,fmt,...)
end

function logWarn(fmt,...)
    log(sim.verbosity_warnings,fmt,...)
end

function logInfo(fmt,...)
    log(sim.verbosity_infos,fmt,...)
end

function logDebug(fmt,...)
    log(sim.verbosity_debug,fmt,...)
end

logInfo('simStubsGenTests.lua loaded')

function table.pack(...)
    return {n=select("#",...),...}
end

function table.tostring(t)
    local vals={}
    local maxIntKey=nil
    for i,v in ipairs(t) do
        if type(v)=='table' then v=table.tostring(v) end
        table.insert(vals,tostring(v))
        maxIntKey=i
    end
    for k,v in pairs(t) do
        if (type(k)=='number' and (not maxIntKey or k<1 or k>maxIntKey)) or type(k)~='number' then
            if type(v)=='table' then v=table.tostring(v) end
            table.insert(vals,k..'='..tostring(v))
        end
    end
    local s,sep='{',''
    for _,v in ipairs(vals) do
        s=s..sep..v
        sep=','
    end
    return s..'}'
end

function argsStr(...)
    local s,sep='',''
    local args=table.pack(...)
    for i=1,args.n do
        local v=args[i]
        local sv=type(v)=='table' and table.tostring(v) or tostring(v)
        s=s..sep..sv
        sep=','
    end
    return s
end

function assertEq(a,b)
    if type(a)=='number' and type('b')=='number' then
        return math.abs(a-b)<1e-9
    end
    return a==b
end

function assertOk(n,f)
    logDebug('test "%s"...',n)
    if runTest and runTest[n]==nil then
        logInfo('test "%s": SKIPPED',n)
        return
    end
    local r,e=pcall(f)
    if not r then
        logDebug('test "%s": error: %s',n,e)
        logError('test "%s": FAILED',n)
        numFailed=numFailed+1
    else
        logInfo('test "%s": OK',n)
        numPassed=numPassed+1
    end
end

function assertFail(n,f)
    logDebug('test "%s"...',n)
    if runTest and runTest[n]==nil then
        logInfo('test "%s": SKIPPED',n)
        return
    end
    local r,e=pcall(f)
    if r then
        logDebug('test "%s": succeeded, but should have failed',n)
        logError('test "%s": FAILED',n)
        numFailed=numFailed+1
    else
        logDebug('test "%s": error: %s',n,e)
        logInfo('test "%s": OK',n)
        numPassed=numPassed+1
    end
end

function assertEq(n,a,b)
    assert(type(a)==type(b),'field "'..n..'": type mismatch ('..type(a)..'~='..type(b)..')')
    if type(a)=='number' then
        assert(math.abs(a-b)<1e-6,'field "'..n..'": not equal: '..a..'~='..b)
    elseif type(a)=='table' then
        for k,v in pairs(a) do
            assertEq(n..'.'..k,a[k],b[k])
        end
        for k,v in pairs(b) do
            assertEq(n..'.'..k,a[k],b[k])
        end
    else
        assert(a==b,'field "'..n..'": not equal: '..tostring(a)..'~='..tostring(b))
    end
end

function loadModule()
    local p=sim.getStringNamedParam('simStubsGenTests.module')
    local h=sim.loadModule(p,'StubsGenTests')
    if h==-1 then
        error('the module could not initialize (-1)')
    elseif h==-2 then
        error('the module is missing entrypoints (-2)')
    elseif h==-3 then
        error('the module could not be loaded (-3)')
    end
    logInfo('loaded module %s with handle %d',p,h)
    local funcs={}
    for k,v in pairs(simStubsGenTests) do if type(v)=='function' then table.insert(funcs,k) end end
    logInfo('module functions: %s',table.concat(funcs,', '))
end

function callFunc(fname,...)
    logInfo('calling %s(%s)',fname,argsStr(...))
    local f=simStubsGenTests[fname]
    return f(...)
end

function sysCall_init()
    local v=sim.getStringNamedParam('simStubsGenTests.verbosity')
    if v then sim.setInt32Parameter(sim.intparam_verbosity,sim['verbosity_'..v]) end

    local tests=sim.getStringNamedParam('simStubsGenTests.tests')
    if tests then
        runTest={}
        for test in string.gmatch(tests,'([^,]+)') do runTest[test]=1 end
    end

    logInfo('add-on initialized')
    local r,e=pcall(loadModule)
    if r then
        runMain=true
    else
        logError('aborted: %s',e)
        sim.setInt32Parameter(sim.intparam_exitcode,2)
        sim.quitSimulator()
    end
end

function sysCall_nonSimulation()
    if not runMain then return end
    local r,e=pcall(main)
    runMain=false
    if not r then
        logError('aborted: %s',e)
        sim.setInt32Parameter(sim.intparam_exitcode,3)
        sim.quitSimulator()
    end
    sim.quitSimulator()
end

function sysCall_cleanup()
    sim.setInt32Parameter(sim.intparam_verbosity,sim.verbosity_warnings)
end
