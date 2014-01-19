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

/**
* RPMod implements a deferred object that can be used to create JS mods
* Simply extend this class and over-write the "work" function.
* Remember to call .resolve() (on success) or .reject() (on failure).
*/

RPMod = SimpleClass.extend({
	/// FUNCTIONS THAT SHOULD BE REDEFINED
	// The only function that should be over-written.
	// If your mod is not very asynchronous, calling this._super() or this.resolve() at the end
	// is enough.
	work : function() {
		this.resolve();
	},
	
	/// FUNCTIONS THAT CAN BE CALLED
	// Reports the work as "done"
	resolve : function(args) {
		this._deferred.resolve(args);
	},
	
	// Reports the work as "failed"
	reject : function(args) {
		this._deferred.reject(args);
	},
	
	/// FUNCTIONS THAT SHOULD NOT BE TOUCHED
	/// unless you have a PhD in rocket science (or similar)
	
	// Proxy /all/ the things!
	init : function()
	{
		this._deferred = $.Deferred();
	},
	
	done : function(cb) {
		this._deferred.done(cb);
		return this;
	},
	
	fail : function(cb) {
		this._deferred.fail(cb);
		return this;
	},
	
	always : function(cb) {
		this._deferred.always(cb);
		return this;
	},
	
	notify : function(progress) {
		this._deferred.notify(progress);
		return this;
	},
	
	progress : function(cb) {
		this._deferred.progress(cb);
		return this;
	}
});