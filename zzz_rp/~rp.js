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

// Patch StonehearthShellView to... be something completely different.
App.StonehearthShellView = App.ContainerView.extend({
	init: function() {
		this._super();
		
    var self = this;
		
		this.addView(App.RPLoadingScreenView);
		App.gotoTitle = function() { self.gotoTitle(); }
	},
	 
	 
	 // Whatever was past "this._super" in the old view
	 _rp_oldInit : function() {
		var self = this;
		 
		var json = {
			views : [
				"StonehearthTitleScreenView"
			]
		};

		var views = json.views || [];
		$.each(views, function(i, name) {
			console.log(name);
			var ctor = App[name]
			if (ctor) {
				self.addView(ctor);
			}
		});
	},
	
	gotoTitle : function() {
		this._rp_oldInit();
		App.gotoTitle = null; // we don't want anyone to get crazy ideas
		App.gotoShell();
	}
});

/// Patch App.RootView
// didInsertElement does *nothing*
App.RootView = App.RootView.extend({
	didInsertElement : null
});