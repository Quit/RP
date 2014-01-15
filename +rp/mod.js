/**
* RPMod implements a deferred object that can be used to create JS mods
* Simply extend this class and over-write the "work" function.
* Remember to call .resolve() (on success) or .reject() (on failure).
*/

RPMod = SimpleClass.extend({
	/// FUNCTIONS THAT SHOULD BE REDEFINED
	// The only function that should be over-written.
	work : function() {},
	
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