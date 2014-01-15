App.RPLoadingScreenView = App.View.extend({
  templateName: 'stonehearthLoadingScreen',
	i18nNamespace: 'stonehearth',
	
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
	
	init: function() {
		this._super();
	},

  didInsertElement: function() {
		var self = this;
		
		this._progressbar = $("#progressbar")
		//~ rp.log(this._progressbar);
    this._progressbar.progressbar({
			value: 0
		});
			
    var numBackgrounds = 6;
    var imageUrl = '/stonehearth/ui/shell/loading_screen/images/bg' + Math.floor((Math.random()*numBackgrounds)) +'.jpg';
    $('#randomScreen').css('background-image', 'url(' + imageUrl + ')');
		$('#message').text('Loading mods...');
		
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
		
		// Just call @loadMod and see what it does.
		this.loadMod();
	},
	
	loadMod : function() {	
		rp.log('loadMod');
		// Setup
		var self = this;
		this._modProgress = 0;
	
		// @loadMod thinks @_onModsUpdate is stupid
		// _mods, modIndex and 3 others like this
		if (this.modIndex >= this.mods.length)
		{
			rp.log('Buffer overflow');
			
			// We can has current mod?
			// For some reason I believe this will always be false, because of the poll(ut)ing.
			if (this.currentlyLoading != null) // We can at least display a fancy message!
				$('#message').html('Loading ' + (this.currentlyLoading.info.name || this.currentlyLoading.name));
			
			if (this.luaDone)
				this._done();
			return;
		}
		
		rp.log('loadMod has work');
		
		var mod = this.mods[this.modIndex++];
		rp.log('Loading mod ', mod);
		
		rp.log('Loading mod #' + this.modIndex + '; ' + (mod.info.name || mod.name));
		
		// Set the message
		$('#message').html('Loading ' + mod.name);
		
		// Attempt to do the mod stuff
		try
		{
			var currentModObject = new (currentMod._class)();
			// Set the callbacks
			currentModObject.always(function() { self._onModLoaded(); }).progress(function(progress) { self._onProgress(progress); });
			// Start working
			currentModObject.work();
		}
		catch (err)
		{
			rp.log('Current mod exploded:' + err);
		}
	},
	
	_done : function()
	{
		var self = this;
		
		// Done?
		rp.log("All mods loaded.");
		// Give me something like flushScreen() or so. :(
		$('#loadingScreen').replaceWith('<div style="height:100%;width:100%;position:absolute;top:0;left:0;background:black;">');
		setTimeout(function() { App.gotoTitle(); self.destroy(); }, 0);
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
		
		// Update progress by however much taht mod took
		this._baseProgress += 100 / this.modCount;
		setTimeout(function() { self.loadMod(); }, 1000);
		//~ this.loadMod();
		this.updateProgress();
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
	}
});
