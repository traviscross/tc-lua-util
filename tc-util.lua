-- Copyright (c) 2014 Travis Cross <tc@traviscross.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- strings

function string.ref(str,i)
  return string.sub(str,i,i)
end

function string.zref(str,i)
  return string.sub(str,i+1,i+1)
end

function string.esub(str,x,y)
  return string.sub(str,x,(y or #str)-1)
end

function string.zsub(str,x,y)
  return string.sub(str,x+1,y or #str)
end

function string.intersperse(str,fence)
  local acc
  for i=0,#str-1 do
    if not acc then acc=str:zref(i)
    else acc=acc..fence..str:zref(i) end
  end
  return acc
end

function string.split(str,sep)
  local acc={} i=0 last=0
  while i<#str do
    if sep==str:zsub(i,i+#sep) then
      table.insert(acc,str:zsub(last,i))
      i=i+#sep
      last=i
    else
      i=i+1
    end
  end
  table.insert(acc,str:zsub(last))
  return acc
end

-- tables

function table.join(table,sep)
  local acc=""
  for _,v in pairs(table) do
    if acc=="" then
      acc=v
    else
      acc=acc..sep..v
    end
  end
  return acc
end

function table.nmerge(xs,...)
  for _,ys in pairs({...}) do
    for k,v in pairs(ys) do
      xs[k]=v
    end
  end
  return xs
end

function table.merge(...)
  local xs={}
  return table.nmerge(xs,...)
end

function table.copy(xs)
  return table.merge(xs)
end

function table.nconc(xs,...)
  for _,ys in pairs({...}) do
    for _,z in pairs(ys) do
      table.insert(xs,z)
    end
  end
  return xs
end

function table.append(...)
  local xs={}
  return table.nconc(xs,...)
end

function table.copylist(xs)
  return table.append(xs)
end

function table.rem(xs,pos)
  local ys=table.copy(xs)
  local y=table.remove(ys,pos)
  return ys, y
end

function table.splice(xs,pos)
  local ys={} zs={} i=1
  for _,v in pairs(xs) do
    if i<pos then
      table.insert(ys,v)
    else
      table.insert(zs,v)
    end
    i=i+1
  end
  return ys, zs
end

function table.keys(xs)
  local ks={}
  if not xs then return ks end
  for k,_ in pairs(xs) do
    table.insert(ks,k)
  end
  return ks
end

function table.values(xs)
  return table.append(xs)
end

function table.size(xs)
  local i=0
  for _,_ in pairs(xs) do
    i=i+1
  end
  return i
end

-- trees

tree={}
local leaf="__leaf"
function tree.get(tr,k)
  if not tr or not k or #k < 1 then
    return nil
  elseif #k == 1 then
    local node=tr[k[1]]
    if not node then
      return nil,nil,tr
    end
    local rem=table.copy(node)
    rem[leaf]=nil
    return node[leaf],rem,tr
  else
    local _, ys = table.splice(k,2)
    return tree.get(tr[k[1]], ys)
  end
end

function tree.set(tr,k,v)
  if not tr then tr={} end
  if not k or #k < 1 then
    return nil
  elseif #k == 1 then
    tr[k[1]]=table.nmerge(tr[k[1]] or {},{[leaf]=v})
  else
    local _, ys = table.splice(k,2)
    tr[k[1]]=tree.set(tr[k[1]],ys,v)
  end
  return tr
end

function tree.merge_table(tr,xs)
  for k,v in pairs(xs) do
    tree.set(tr,k,v)
  end
  return tr
end
function tree.from_table(xs)
  return tree.merge_table({},xs)
end

-- printer

local lua_from_hash
local lua_from_list
function lua_from(x)
  local k=type(x)
  if k == "string" then return "\""..x.."\""
  elseif k == "table" then
    if table.size(x) == #x then
      return lua_from_list(x)
    else
      return lua_from_hash(x)
    end
  elseif k == "number" then
    return tostring(x)
  elseif k == "nil" then
    return "nil"
  else
    return tostring(x)
  end
end

local ulua_from_list
function ulua_from_list(l)
  if not l then return "" end
  local m
  for _,v in pairs(l) do
    if m then m=m..", " else m="" end
    m=m..lua_from(v)
  end
  return m or ""
end
function lua_from_list(l)
  return "{"..ulua_from_list(l).."}"
end

local ulua_from_hash
function ulua_from_hash(tab)
  if not tab then return "" end
  local m
  for k,v in pairs(tab) do
    if m then m=m..", " else m="" end
    local ks
    if type(k) == "string" then
      ks=k
      if k:match("[^a-zA-Z0-9_]") then
        ks="[\""..k.."\"]"
      end
    else
      ks="["..lua_from(k).."]"
    end
    m=m..ks.."="..lua_from(v)
  end
  return m or ""
end
function lua_from_hash(tab)
  return "{"..ulua_from_hash(tab).."}"
end
