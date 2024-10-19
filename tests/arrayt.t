C = terralib.includecstring [[
	#include <stdio.h>
	#include <stdlib.h>
]]
local arraytypes = {}
function Array(T)
	local struct ArrayImpl {
		data : &T;
		N : int;
	}
	function ArrayImpl.metamethods.__typename(self)
	    return "Array("..tostring(T)..")"
	end
	arraytypes[ArrayImpl] = true
	terra ArrayImpl:init(N : int)
		self.data = [&T](C.malloc(N*sizeof(T)))
		self.N = N
	end
	terra ArrayImpl:free()
		C.printf("freeing array of %d elements\n", self.N)
		C.free(self.data)
	end
	ArrayImpl.metamethods.__apply = macro(function(self,idx)
		print("accesing ", idx)
		return `self.data[idx]  --`
	end)
	ArrayImpl.metamethods.__methodmissing = macro(function(methodname,selfexp,...)
		local args = terralib.newlist {...}
		local i = symbol(int)
		local promotedargs = args:map(function(a)
			if arraytypes[a:gettype()] then
				return `a(i)  --`
			else
				return a
			end
		end)
		return quote
			var self = selfexp
			var r : ArrayImpl
			r:init(self.N)
			for [i] = 0,r.N do
				r.data[i] = self.data[i]:[methodname](promotedargs)
			end
		in
			r
		end
	end)
	return ArrayImpl
end

struct Complex {
	real : float;
	imag : float;
}

terra Complex:add(c : Complex) 
	return Complex { self.real + c.real, self.imag + c.imag }
end

ComplexArray = Array(Complex)
terra testit()
	var ca : ComplexArray
	ca:init(10)
	for i = 0,ca.N do
		ca(i) = Complex { i, i + 1 }
	end
	var ra = ca:add(ca)
	return ra
end
local r = testit()
assert(r.N == 10)
for i = 0,r.N-1 do
	assert(r.data[i].real == 2*i)
	assert(r.data[i].imag == 2*(i+1))
end
assert(tostring(Array(int)) == "Array(int32)")
terra cleanup(a1 : ComplexArray)
	a1:free()
end
cleanup(r)