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

local constants = radiant.resources.load_json("/stonehearth/services/calendar/calendar_constants.json")

--[[ Generic helper functions ]]--
-- Parses a string à "4d12h" into hours, minutes and seconds.
-- Accepts days (d), hours (h), minutes (m) and seconds (s) as modifiers.
function rp.parse_time(str)
	local hours, minutes, seconds = 0, 0, 0
	
	for time, unit in str:gmatch('(%d+)([dhms])') do
		time = tonumber(time)
		if unit == 'd' then
			hours = hours + time * constants.hours_per_day
		elseif unit == 'h' then
			hours = hours + time
		elseif unit == 'm' then
			minutes = minutes + time
		elseif unit == 's' then
			seconds = seconds + time
		end
	end
	
	local whole
	
	minutes, seconds = minutes + math.floor(seconds / constants.seconds_per_minute), seconds % constants.seconds_per_minute
	hours, minutes = hours + math.floor(minutes / constants.minutes_per_hour), minutes % constants.minutes_per_hour
	
	return hours, minutes, seconds
end

-- Converts a time into an amount of game ticks
function rp.time_to_ticks(hours, minutes, seconds)
	return constants.ticks_per_second * ((hours * constants.minutes_per_hour + minutes) * constants.seconds_per_minute + seconds)
end

--[[ Timer related stuff ]]--
local timers = {}

local last_now = 0

local function on_gameloop(_, event)
	last_now = event.now
	
	local t = {}
	
	for id, timer in pairs(timers) do
		printf('timer %s: %d <=> %d', tostring(id), timer._next_run, last_now)
		if timer._next_run <= last_now then
			-- If we have ran out of repetitions...
			if not timer:run() then
				-- Remove us after the loop
				table.insert(t, id)
			end
		end
	end
	
	for i = 1, #t do
		if timers[t[i]]:is_stopped() then
			timers[t[i]] = nil
		end
	end
end
radiant.events.listen(radiant.events, 'stonehearth:gameloop', rp, on_gameloop)

--[[ Timer class ]]--
local Timer = class()

function Timer:__init(id, interval, repetition, func, ...)
	printf('new timer %s %d', tostring(id), interval)
	self.id, self.interval, self.repetition, self.func, self.args = id, interval, repetition, func, { ... }
	
	-- When we'll run the timer the next time
	self._next_run = last_now + interval
end

-- Executes the timer function
function Timer:run()
	self.repetition = self.repetition - 1
	
	if self.repetition < 0 then
		return false
	end
	
	self.func(unpack(self.args))
	
	if self.repetition >= 1 then
		self:reset()
		return true
	end
	
	return false
end

-- Resets the timer's next execution time frame thingy
function Timer:reset()
	self._next_run = last_now + self.interval
end

-- Stops the timer and destroys it ASAP
function Timer:stop()
	self.repetitions = -1
	self._next_run = math.huge
end

function Timer:is_stopped()
	return self.repetitions < 0
end

--[[ rp functions ]]--
-- Creates a timer with a certain id that runs at `interval' ticks and has `repetition` repetitions while calling `func`
function rp.add_timer(id, interval, repetition, func, ...)
	-- If a time string has been passed
	if type(interval) == 'string' then
		interval = rp.time_to_ticks(rp.parse_time(interval))
	end
	
	local timer = Timer(id, interval, repetition, func, ...)
	timers[id] = timer
	
	return timer
end

rp.create_timer = rp.add_timer

function rp.remove_timer(id)
	timers[id] = nil
end

-- Creates a fire-and-forget timer
function rp.simple_timer(interval, func, ...)
	return rp.add_timer({}, interval, 1, func, ...)
end

-- Returns timer with id `id`
function rp.get_timer(id)
	return timers[id]
end