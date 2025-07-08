/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component displays a small area in which a component 
/// help message can be displayed.
/// DEPRECATED!
Class %ZEN.Component.helpBox Extends component [ Deprecated, System = 3 ]
{

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
div.helpBoxOn {
	border: 1px solid black;
	background: #AAAAFF;
}

div.helpBoxOff {
	display: none;
}

div.helpBoxTitle {
	font-weight: bold;
	color: darkblue;
}

div.helpBoxMsg {
	font-size: 0.8em;
	color: darkblue;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="helpBoxOff" id="#(..%MakeId("helpBoxDiv"))#">&nbsp;</div>>
}

/// Display help: if flag is true, show help
ClientMethod showHelp(flag, title, msg) [ Language = javascript ]
{
	var div = this.findElement('helpBoxDiv');
	zenASSERT(ctrl,"Unable to find div element.",arguments);
	
	if (flag) {
		div.className = 'helpBoxOn';
		title = (!title || ''==title) ? 'Help' : title;
		msg = (!msg || ''==msg) ? '&nbsp;' : msg;
		div.innerHTML = '<div class="helpBoxTitle">'+title+'</div><div class="helpBoxMsg">'+msg+'</div>';
	}
	else {
		div.className = 'helpBoxOff';
		div.innerHTML = '&nbsp;';
	}
}

}
