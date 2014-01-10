--[=============================================================================[
The MIT License (MIT)

Copyright (c) 2014 RepeatPan
excluding parts that were written by Radiant Entertainment.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]=============================================================================]

-- Initialize math.random()
math.randomseed(os.time())

do -- Overwrites `io.output' to our log file(s)
	io.output('stonehearth_mod' .. (radiant.is_server and '_server' or '') .. '.log')
	function print(...)
		local t = { ... }
		
		local argc = #t
		for i = 1, argc do
			io.write(tostring(t[i]))
			if i < argc then
				io.write("\t")
			end
		end
		
		io.write("\n")
		io.flush()
	end
	
	function printf(str, ...)
		print(string.format(str, ...))
	end
end

-- Curse you, Garry and my laziness
function PrintTable(tbl)
	print(table.show(tbl))
end

print_table = PrintTable
	
--[[ 3rd party functions ]]
do -- table.show
	--[[
		 Author: Julio Manuel Fernandez-Diaz
		 Date:   January 12, 2007
		 (For Lua 5.1)
		 
		 Modified slightly by RiciLake to avoid the unnecessary table traversal in tablecount()

		 Formats tables with cycles recursively to any depth.
		 The output is returned as a string.
		 References to other tables are shown as values.
		 Self references are indicated.

		 The string returned is "Lua code", which can be procesed
		 (in the case in which indent is composed by spaces or "--").
		 Userdata and function keys and values are shown as strings,
		 which logically are exactly not equivalent to the original code.

		 This routine can serve for pretty formating tables with
		 proper indentations, apart from printing them:

				print(table.show(t, "t"))   -- a typical use
		 
		 Heavily based on "Saving tables with cycles", PIL2, p. 113.

		 Arguments:
				t is the table.
				name is the name of the table (optional)
				indent is a first indentation (optional).
	--]]
	function table.show(t, name, indent)
		 local cart     -- a container
		 local autoref  -- for self references

		 --[[ counts the number of elements in a table
		 local function tablecount(t)
				local n = 0
				for _, _ in pairs(t) do n = n+1 end
				return n
		 end
		 ]]
		 -- (RiciLake) returns true if the table is empty
		 local function isemptytable(t) return next(t) == nil end

		 local function basicSerialize (o)
				local so = tostring(o)
				if type(o) == "function" then
					 local info = debug.getinfo(o, "S")
					 -- info.name is nil because o is not a calling level
					 if info.what == "C" then
							return string.format("%q", so .. ", C function")
					 else 
							-- the information is defined through lines
							return string.format("%q", so .. ", defined in (" ..
									info.linedefined .. "-" .. info.lastlinedefined ..
									")" .. info.source)
					 end
				elseif type(o) == "number" or type(o) == "boolean" then
					 return so
				else
					 return string.format("%q", so)
				end
		 end

		 local function addtocart (value, name, indent, saved, field)
				indent = indent or ""
				saved = saved or {}
				field = field or name

				cart = cart .. indent .. field

				if type(value) ~= "table" then
					 cart = cart .. " = " .. basicSerialize(value) .. ";\n"
				else
					 if saved[value] then
							cart = cart .. " = {}; -- " .. saved[value] 
													.. " (self reference)\n"
							autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
					 else
							saved[value] = name
							--if tablecount(value) == 0 then
							if isemptytable(value) then
								 cart = cart .. " = {};\n"
							else
								 cart = cart .. " = {\n"
								 for k, v in pairs(value) do
										k = basicSerialize(k)
										local fname = string.format("%s[%s]", name, k)
										field = string.format("[%s]", k)
										-- three spaces between levels
										addtocart(v, fname, indent .. "   ", saved, field)
								 end
								 cart = cart .. indent .. "};\n"
							end
					 end
				end
		 end

		 name = name or "__unnamed__"
		 if type(t) ~= "table" then
				return name .. " = " .. basicSerialize(t)
		 end
		 cart, autoref = "", ""
		 addtocart(t, name, indent)
		 return cart .. autoref
	end
end