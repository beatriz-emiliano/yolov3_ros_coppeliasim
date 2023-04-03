local simStubsGenTests={}

--@fun testLuaNullable
--@arg {type=int,nullable=true} a
--@arg {type=string} b
function simStubsGenTests.testLuaNullable(a,b)
    if a==nil then
        print('a is nil')
    elseif type(a)=='number' then
        print('a is '..tostring(a))
    else
        error('a is '..type(a))
    end
end

--@fun testLuaDefault
--@arg {type=int} a
--@arg {type=string,default="x"} b
--@ret string r
function simStubsGenTests.testLuaDefault(a,b)
    return b
end

return simStubsGenTests
