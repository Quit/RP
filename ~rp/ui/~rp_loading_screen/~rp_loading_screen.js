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

App.RPLoadingScreenView = App.View.extend({
  templateName: 'rpLoadingScreen',
	
	// Current index that we pursue
	modIndex : 0,
	
	// The mods - which will be taken straight from the update data.
	mods : [],
	
	// The mod count, taken from the mod data too.
	modCount : 0,
	
	// Mod that lua currently loads
	currentlyLoading : null,
	
	// IS LUA DONE YET?
	// Not now, honey.
	luaDone : false,
	
	// Progress.
	_progress : 0,
	_baseProgress : 0,
	
	_toad : null,
	
	init: function() {
		var self = this;
		this._super();
		$.get('/~rp/toad.json').done(function(data) { self._toad = data.tips; self.showNextTip(); });
	},

  didInsertElement: function() {
		var self = this;
		
		this._progressbar = $("#progressbar")
		this._progressbar.progressbar({
			value: 0
		});
			
    var numBackgrounds = 6;
    var imageUrl = '/stonehearth/ui/shell/loading_screen/images/bg' + Math.floor((Math.random()*numBackgrounds)) +'.jpg';
    $('#randomScreen').css('background-image', 'url(' + imageUrl + ')');

		// Get the thing started
		radiant.call('rp:get_lm_data_store').done(function(o) { 
			// Install the tracer
			self._modsTracer = radiant.trace(o.data)
					.progress(function(modsUpdate) { self._onModsUpdate(modsUpdate); })
					.fail(function(o) { throw "Mods tracing failed: " + dump(o); });
			// INITIATE MOD LOADING SEQUENCE
			radiant.call('rp:_load_mods');
		});
	},

	updateProgress: function() {
		var self = this;
		self._updateMessage();
    this._progressbar.progressbar( "option", "value", this._progress);
	},

  _updateMessage : function() {
		var self = this;
    var max = 29;
    var min = 1;
    var random =  Math.floor(Math.random() * (max - min + 1)) + min;
	},
	
	_onModsUpdate : function(o)
	{
		this.luaDone = o.done;
		this.mods = o.processed;
		this.currentlyLoading = o.current_mod;
		this.modCount = o.count;
		
		// Just call @loadMod and see what it does.
		this.loadMod();
	},
	
	loadMod : function() {	
		// Setup
		var self = this;
		
		self.showNextTip();
		
		for (; this.modIndex <= this.mods.length; ++this.modIndex)
		{
			// Set our progress already to zero
			this._modProgress = 0;
		
			// @loadMod thinks @_onModsUpdate is stupid
			// _mods, modIndex and 3 others like this
			if (this.modIndex >= this.mods.length)
			{
				// We can has current mod?
				// For some reason I believe this will always be false, because of the poll(ut)ing.
				if (this.currentlyLoading != null) // We can at least display a fancy message!
					$('#message').html('Loading ' + (this.currentlyLoading.info.name || this.currentlyLoading.name));
				
				// If our lua already tell us that we're done, well, we're done.
				if (this.luaDone)
					this._done();
				
				// Either way, this function ends here.
				return;
			}
			
			// Load said mod
			var mod = this.mods[this.modIndex];
			// Do we have an entry for it?
			var _class = rp._mods[mod.name];
			
			// No class => continue
			if (!_class)
			{
				rp.log(mod.name, 'has no class; skip');
				this._baseProgress += 100 / this.modCount;
				this._progress = this._baseProgress;
				this.updateProgress();
				continue;
			}
			
			// Alright, the class exists I guess.
			rp.log('Loading mod #' + this.modIndex + '; ' + (mod.info.name || mod.name));
			
			// Set the message
			$('#message').html('Loading ' + (mod.info.name || mod.name));
			//~ $('#tipOfTheDay').fadeOut(function() { $('#tipOfTheDay').text(mod.info.description || 'No text available').fadeIn(); });
			
			// Attempt to do the mod stuff
			try
			{
				var currentModObject = new _class();
				// Set the callbacks
				currentModObject.always(function() { self._onModLoaded(); }).progress(function(progress) { self._onProgress(progress); });
				// Start working
				currentModObject.work();
			}
			catch (err)
			{
				rp.log('Current mod exploded:' + err);
			}
			
			// Either way, done!
			return;
		}
	},
	
	_done : function()
	{
		var self = this;
		
		// Done?
		rp.log("All mods loaded.");
		// Give me something like flushScreen() or so. :(
		$('#loadingScreen').replaceWith('<div style="height:100%;width:100%;position:absolute;top:0;left:0;background:black;">');
		setTimeout(function() { App.gotoTitle(); self.destroy(); }, 100); // 100 seems like a safe guess
	},
	
	_onModLoadingSuccessful: function()
	{
		rp.log('Mod successfully loaded.');
		this._onModLoaded();
	},
	
	_onModLoadingFailure : function(data)
	{
		rp.log('Mod loading failed.');
		if (data)
		{
			rp.log('Reason:');
			rp.log(dump(data));
		}
		
		this._onModLoaded();
	},
	
	_onModLoaded : function()
	{
		var self = this;

		++this.modIndex;
		rp.log('Mod loaded.');
		
		// Update progress by however much that mod took
		this._baseProgress += 100 / this.modCount;
		this.updateProgress();
		// Load the next mod. In theory, I hope this avoids stack overflows.
		setTimeout(function() { self.loadMod(); }, 0);
	},
	 
	_onProgress : function(progress) {
		if (typeof(progress) != 'number')
		{
			rp.log('Mod reported non-number progress (of type ' + typeof(progress) + ')');
			return;
		}
		
		// Validate input. sigh.
		if (progress < 0)
			progress  = 0;
		else if (progress > 100)
			progress = 100;
		
		this._modProgress = progress;
		this._progress = this._baseProgress + (this._modProgress / this.modCount);
		this.updateProgress();
	},
	
	_nextTip : 0,
	
	showNextTip : function() {
		var self = this;
		var now = new Date().getTime();
		if (now < self._nextTip)
			return;
		
		var tip = self._toad[_.random(0, self._toad.length - 1)];
		self._nextTip = now + tip.length * 100;
		
		$('#tipOfTheDay').fadeOut(function() { $('#tipOfTheDay').text('Did you know? ' + tip).fadeIn(); });
	}
});
