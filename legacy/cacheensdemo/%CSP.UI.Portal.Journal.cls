/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Journal Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Journal Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Journal.zen";

Parameter HELPADDRESS = "Home,Journal Settings";

Parameter EMSSERVICE = "Config";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage,%Admin_Journal";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup label="Primary journal directory">
<text id="CurrentDirectory" size="50" hint="Required." onchange="zenPage.doModified();"/>
<button id="JournalPrimaryBrowse" caption="Browse..." onclick="zenPage.doBrowse('CurrentDirectory');" valign="top"/>
</hgroup>
<hgroup label="Secondary journal directory">
<text id="AlternateDirectory" size="50" onchange="zenPage.doModified();"/>
<button id="JournalAlternateBrowse" caption="Browse..." onclick="zenPage.doBrowse('AlternateDirectory');"/>
</hgroup>
<text id="FileSizeLimit" label="Start new journal file every (MB)" size="6" hint="Required." onchange="zenPage.doModified();"/>
<text id="JournalFilePrefix" label="Journal file prefix" size="20" onchange="zenPage.doModified();"/>
<vgroup label="Archive journal files" cellStyle="padding:4px;" labelPosition="left" cellVAlign="top">
<hgroup label="To Archive Target">
<dataCombo id="ArchiveName"
queryClass="Config.Archives"
queryName="List"
displayColumns="1,2,3" 
choiceColumn="1"
containerStyle="padding-left:2px;"
onchange="zenPage.changeArchiveName(zenThis.getValue());"
/>
<button caption="Create New Archive Target..." containerStyle="padding-left:2px;" onclick="zenPage.doNewArchive();" valign="top"/>
</hgroup>
</vgroup>
<vgroup label="When to purge journal files (that are not needed by the system)" cellStyle="padding:4px;" hint="If both numbers are defined as nonzero, purging occurs when either condition is met. Purging will never occur if the files are needed by the system (for crash recovery, mirroring, etc.)." hintClass="normal" hintStyle="font-style:italic;" labelPosition="left">
<checkbox id="PurgeArchived" label="As soon as they are copied to archive" hint="If enabled, the two numbers below are ignored." onchange="zenPage.changePurgeArchived(zenThis.getValue());"/>
<text id="DaysBeforePurge" label="After this many days" size="3" title="'0' means not to purge." hint="Required. (0 - 100)" onchange="zenPage.doModified();"/>
<text id="BackupsBeforePurge" label="After this many successive backups" size="3" title="'0' means not to purge." hint="Required. (0 - 10)" onchange="zenPage.doModified();"/>
</vgroup>
<checkbox id="FreezeOnError" label="Freeze on error" onchange="zenPage.doModified();"/>
<checkbox id="JournalcspSession" label="Journal Web session" onchange="zenPage.doModified();"/>
<checkbox id="CompressFiles" label="Compress journal files" onchange="zenPage.doModified();"/>
<hgroup label="Write image journal directory" hint="Activating a WIJ directory change on cluster members requires restart." hintClass="normal" hintStyle="font-style:italic;">
<text id="wijdir" size="50" onchange="zenPage.doModified();"/>
<button id="wijdirBrowse" caption="Browse..." onclick="zenPage.doBrowse('wijdir');"/>
</hgroup>
<text id="targwijsz" label="Target size for the wij (MB) (0=not set)" size="6" hint="Required." onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod doNewArchive() [ Language = javascript ]
{
        var url = zenLink('%CSP.UI.Portal.Dialog.ArchiveWizard.zen');
        var popupName = 'ArchiveWizard';
        zenLaunchPopupWindow(url,popupName,'status,scrollbars,resizable=yes,width=900,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
        if (action != 'ok') return false;
        try {
		    if (popupName == 'ArchiveWizard') {
                zen("ArchiveName").refreshContents(true);
                zen("ArchiveName").setValue(value.toUpperCase());
                this.changeArchiveName(zen("ArchiveName").getValue());
            } else {
                zen(popupName).setValue(value);	
            }
        } catch (ex) {
            alert("Error: " + ex);
        }

        return true;
}

ClientMethod changeArchiveName(newvalue) [ Language = javascript ]
{
        this.doModified();
	if (newvalue) {
        	zen('PurgeArchived').setHidden(false);
	        zen('PurgeArchived').setDisabled(false);
	} else {
        	zen('PurgeArchived').setHidden(true);
	        zen('PurgeArchived').setDisabled(true);
	        zen('PurgeArchived').setValue(0);
		this.changePurgeArchived();
	}
}

ClientMethod changePurgeArchived(newvalue) [ Language = javascript ]
{
        this.doModified();
	zen('DaysBeforePurge').setDisabled(newvalue);
	//zen('DaysBeforePurge').setHidden(newvalue);
	zen('BackupsBeforePurge').setDisabled(newvalue);
	//zen('BackupsBeforePurge').setHidden(newvalue);
}

/// Launching a file selector window. 
ClientMethod doBrowse(fieldID) [ Language = javascript ]
{
	var Dir = zen(fieldID).getValue();
	var wildcard = "*";
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=1");
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	try {
		var pass = true;
		if (!this.validateRequired(zen('CurrentDirectory'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('FileSizeLimit'),pass,"N")) pass = false;
		if (!this.validateRequired(zen('DaysBeforePurge'),pass,"N",true,0,100)) pass = false;
		if (!this.validateRequired(zen('BackupsBeforePurge'),pass,"N",true,0,10)) pass = false;
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.pageModified) {
			this.doCancel();
			return;
		}
		
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		
		var proxy = new zenProxy();
		proxy.CurrentDirectory = zen('CurrentDirectory').getValue();
		proxy.AlternateDirectory = zen('AlternateDirectory').getValue();
		proxy.FileSizeLimit = zen('FileSizeLimit').getValue();
		proxy.JournalFilePrefix = zen('JournalFilePrefix').getValue();
		proxy.DaysBeforePurge = zen('DaysBeforePurge').getValue();
		proxy.BackupsBeforePurge = zen('BackupsBeforePurge').getValue();
                proxy.PurgeArchived = zen('PurgeArchived').getValue();
                proxy.ArchiveName = zen('ArchiveName').getValue();
		proxy.FreezeOnError = zen('FreezeOnError').getValue();
		proxy.CompressFiles = zen('CompressFiles').getValue();
		proxy.JournalcspSession = zen('JournalcspSession').getValue();
		proxy.wijdir = zen('wijdir').getValue();
	        proxy.targwijsz = zen('targwijsz').getValue();
	    		
		var ok = this.SaveData(proxy);
		this.afterSave(ok);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("CurrentDirectory") = pProxy.CurrentDirectory
		Set Properties("AlternateDirectory") = pProxy.AlternateDirectory
		Set Properties("FileSizeLimit") = pProxy.FileSizeLimit
		Set Properties("JournalFilePrefix") = pProxy.JournalFilePrefix
                Set Properties("ArchiveName") = pProxy.ArchiveName
		If Properties("ArchiveName")="" {
                	Set Properties("PurgeArchived") = 0
		} else {
                	Set Properties("PurgeArchived") = pProxy.PurgeArchived
		}
		If Properties("PurgeArchived") {
			Set Properties("DaysBeforePurge") = 0
			Set Properties("BackupsBeforePurge") = 0
		} else {
			Set Properties("DaysBeforePurge") = pProxy.DaysBeforePurge
			Set Properties("BackupsBeforePurge") = pProxy.BackupsBeforePurge
		}
		Set Properties("FreezeOnError") = pProxy.FreezeOnError
		Set Properties("CompressFiles") = pProxy.CompressFiles
		Set Properties("JournalcspSession") = pProxy.JournalcspSession
		Set tSC = ##Class(Config.Journal).Modify(.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Kill Properties
		Set tSC = ##Class(Config.config).Get(.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		If Properties("wijdir") '= pProxy.wijdir {
			Set Properties("wijdir") = pProxy.wijdir
			Set tSC = ##Class(Config.config).Modify(.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		If Properties("targwijsz") '= pProxy.targwijsz {
			s Properties("targwijsz") = pProxy.targwijsz
			Set tSC = ##Class(Config.config).Modify(.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	Set ..lblTitle = $$$Text("Use the form below to configure journal settings:")
	
	Kill Properties
	Set tSC = ##class(Config.Journal).Get(.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	If ..%GetComponentById("ArchiveName").value = "" {
		Set ..%GetComponentById("PurgeArchived").disabled = 1
		Set ..%GetComponentById("PurgeArchived").hidden = 1
		Set ..%GetComponentById("PurgeArchived").value = 0
	} else {
		Set ..%GetComponentById("PurgeArchived").disabled = 0
		Set ..%GetComponentById("PurgeArchived").hidden = 0
		If ..%GetComponentById("PurgeArchived").value {
			Set ..%GetComponentById("DaysBeforePurge").disabled = 1
			//Set ..%GetComponentById("DaysBeforePurge").hidden = 1
			Set ..%GetComponentById("BackupsBeforePurge").disabled = 1
			//Set ..%GetComponentById("BackupsBeforePurge").hidden = 1
		}
	}
	
	Kill Properties
	Set tSC = ##class(Config.config).Get(.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	Set ..%GetComponentById("wijdir").value = Properties("wijdir")
	Set ..%GetComponentById("targwijsz").value = Properties("targwijsz")
	If ..IsEMSReadOnly {
		Set ..%GetComponentById("wijdir").disabled = 1
		Set ..%GetComponentById("targwijsz").disabled = 1
		Set ..%GetComponentById("JournalPrimaryBrowse").hidden = 1
		Set ..%GetComponentById("JournalAlternateBrowse").hidden = 1
		Set ..%GetComponentById("wijdirBrowse").hidden = 1
	}
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Journal Settings")
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean
{
	if '($system.Security.Check("%Admin_Manage","U") && $system.Security.Check("%Admin_Journal","U")) {
		set %zenPageError=$$$ERROR($$$AccessDenied)
	}
	quit 1
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
