/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized control for indicating the current drill level on a DeepSee pivot.
/// This is designed for use within DeepSee components and not as a stand-alone control.
Class %DeepSee.Component.drillIndicator Extends %ZEN.Component.component [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Localization domain
Parameter DOMAIN = "%DeepSee";

/// Id of pivot table.
Property pivotId As %ZEN.Datatype.string;

/// Ondrilldown event.
Property ondrilldown As %ZEN.Datatype.eventHandler;

/// Ondrillup event.
Property ondrillup As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
</style>
}

/// Draw the control.
ClientMethod renderContents() [ Internal, Language = javascript ]
{
	try {
		var encDiv = this.getEnclosingDiv();
		// test if we have not been rendered yet
		if (encDiv == null) return;
		var html = [];

		var msgUp = $$$Text('Drill up one level','%DeepSee');
		var msgDown = $$$Text('Drill down into the selected item','%DeepSee');

		html[html.length] = '<div style="white-space:nowrap;" nowrap="1">';
		var pivot = null;
		if (this.pivotId) {
			pivot = zen(this.pivotId);
		}
		if (pivot) {
			var level = pivot.getDrillLevel();
			if (pivot.getDrillLevel()>0) {
				// DTB020: disable drill controls if pivot is in listing mode
				if (pivot.isDrillThrough) {
					html[html.length] = '<image src="deepsee/ds2_arrow_north_44.png" style="opacity:0.5;"/>';
				}
				else {
					html[html.length] = '<image title="'+msgUp+'" src="deepsee/ds2_arrow_north_44.png" onclick="zenPage.getComponent('+this.index+').drillUpHandler();"/>';
				}
				// JMD1266: truncate list
				var start = (level>1) ? level-1 : 0;
				if (start>0) {
					html[html.length] = '...';
				}
				var drillText
				for (var n = start; n < level; n++) {
					drillText = pivot.drillLevels[n].text
					// DTB081 - escape angle brackets if there is a <> pair  
					if ( (drillText.indexOf('<') > -1) && (drillText.indexOf('>') > -1) ) {
						drillText = drillText.replace('<', "&lt;");
		         		drillText = drillText.replace('>', "&gt;");
					}
					html[html.length] = (n>start?'|':'')+drillText;
				}
			}
			if ((!pivot.selectedRange)||(pivot.isDrillThrough)) {
				html[html.length] = '<image src="deepsee/ds2_arrow_south_44.png" style="opacity:0.5;"/>';
			}
			else {
				html[html.length] = '<image title="'+msgDown+'" src="deepsee/ds2_arrow_south_44.png" onclick="zenPage.getComponent('+this.index+').drillDownHandler();"/>';
			}
		}
		html[html.length] = '</div>';
		encDiv.innerHTML = html.join('');
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in renderContents.');
	}
}

/// Action handler for drill down.
ClientMethod drillDownHandler() [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.ondrilldown,this,'ondrilldown');
}

/// Action handler for drill up.
ClientMethod drillUpHandler() [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.ondrillup,this,'ondrillup');
}

}
