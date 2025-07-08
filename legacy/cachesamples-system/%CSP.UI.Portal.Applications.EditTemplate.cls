/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit Application Template
Class %CSP.UI.Portal.Applications.EditTemplate Extends %CSP.UI.Portal.Template [ Abstract, System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property ApplicationType As %Integer;

Property EditHeader As %String;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsNewSave As %Integer(ZENURL = "new");

Property NumTabs As %Integer [ InitialExpression = 3 ];

Property RolesHeader As %String;

XData SVGStyle
{
<style type="text/css">
.tabBarBackground {
	fill:white;
	stroke:white;
}
</style>
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
		// find size of window
		var winWidth = zenGetWindowWidth();	
		// set the svg and tabs the right size
		zen("svgTabArea").setProperty("width",winWidth-50);
		zen("tabBar").setProperty("width",winWidth-50);
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	zen('newLink').setHidden(true);
	for (var i=0;i<this.NumTabs;i++) {
		var option = i + 1;
		if (i == index) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
	if (index == 0) {
		if (!this.IsEMSReadOnly) {
			this.enableCommandButton("btnSave");
		}
		zen('Text1').setValue(this.EditHeader);
	} else {
		this.disableCommandButton("btnSave");
		zen('Text1').setValue(this.RolesHeader);
	}
	document.location.hash = index;
}

/// Returning from file select and setting the value into the appropriate field.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if ((action == "ok") && (popupName != "NewName")) {
		zen(popupName).setValue(value);		
		zenPage.doModified();
	}
}

ClientMethod doBrowse(fieldID, wildcard, onlyDir) [ Language = javascript ]
{
	var Dir = zen(fieldID).getValue();
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=" + onlyDir);
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
}

}
