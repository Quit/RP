/*********************************************************************************
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
*********************************************************************************/

// Stack of elements. I'm not sure if we could deal with a simple element instead of
// this overly ridiculous stack approach, but better safe than sorry.
// I still don't trust JS.
var stack = [];

// Whether or not or current input is (to be) disabled
var inputDisabled = false;

// On focus, disable our input
var onFocus = function(element)
{
	rp.setInputDisabled(true);
	stack.push(element.target);
}

// On blur, re-enable our focus again (if the stack's empty)
var onBlur = function(element)
{
	if (stack[stack.length - 1] != element.target)
		return;
	
	stack.pop();
	
	if (stack.length > 0)
		return;
	
	rp.setInputDisabled(false);
}

// Patches an element to listen to focus/blur events to disable input properly
var patchInput = function(type)
{
	$(document).on('focus', type, onFocus);
	$(document).on('blur', type, onBlur);
}

// So far, we have only text/number inputs and textareas to worry about
patchInput('input[type=text]');
patchInput('input[type=number]');
patchInput('textarea');

// Avoid that keyup/keydown events are sent when our input is dead
$(top).bindFirst('keyup', function(event)
{
	if (inputDisabled)
		event.stopImmediatePropagation();
});

$(top).bindFirst('keydown', function(event)
{
	if (inputDisabled)
		event.stopImmediatePropagation();
});

rp.setInputDisabled = function(status)
{
	if (inputDisabled == status)
		return;
	
	radiant.call('rp:set_input_disabled', status);
	$(top).trigger('rp:input_disabled', status);
	inputDisabled = status;
}
