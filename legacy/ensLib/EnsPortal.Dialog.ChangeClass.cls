/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Add a new component to a production
Class EnsPortal.Dialog.ChangeClass Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to access this page.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

Parameter PAGENAME = "Change Class";

Parameter APPLYBUTTON = 0;

Property HostName As %ZEN.Datatype.string(ZENURL = "HOSTNAME");

Property HostId As %ZEN.Datatype.string(ZENURL = "HOSTID");

Property OldClassName As %ZEN.Datatype.string(ZENURL = "OLDCLASS");

Property HostType As %ZEN.Datatype.string(ZENURL = "HOSTTYPE");

/// Contents of this dialog
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<spacer width="20" />
<vgroup labelPosition="left" >
<spacer height="20" />
<text id="HostItemName" label="Production Item" size="53" 
       readOnly="true" enclosingStyle="padding-bottom: 6px;" />
<text id="OldClassName" label="Old Class" size="53" 
       readOnly="true" enclosingStyle="padding-bottom: 6px;"/>
<!-- a title and context are selected in OnAfterCreatePage -->
<selector id="HostClassName" size="50" label="New Class"  
       required="true" multiSelect="false" enclosingStyle="padding-after: 6px;"/>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Change Class","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Change a production item to use a different underlying class")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zenPage.HostId + ":" + zen("HostClassName").getValue();
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Do ..%SetValueById("HostItemName", ..HostName)
	Do ..%SetValueById("OldClassName", ..OldClassName)
	Set sel = ..%GetComponentById("HostClassName")
	Set tType = ..HostType
	If tType="service" {
		Set sel.title = "Choose a base class for this Business Service. Only valid Business Service class names appear in the list. If there are no such items available, the list is empty."
	    Set sel.context="Ens.ContextSearch/BusinessServices" 
	}
	ElseIf tType="process" {
		Set sel.title = "Choose a base class for this Business Process. Only valid Business Process class names appear in the list. If there are no such items available, the list is empty."
	    Set sel.context="Ens.ContextSearch/BusinessProcesses" 
	}
	ElseIf tType="operation" {
		Set sel.title = "Choose a base class for this Business Operation. Only valid Business Operation class names appear in the list. If there are no such items available, the list is empty."
	    Set sel.context="Ens.ContextSearch/BusinessOperations" 
	}
	Else {
		// tType is "unrecognized:x" because the class is missing or uncompiled, all host types should be shown
		Set sel.title = "Choose a base class for this item. The list contains all Business Services, Business Processes and Business Operations."
	    Set sel.context="Ens.ContextSearch/AllBusinessHosts" 
	}

	Quit $$$OK
}

}
