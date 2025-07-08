/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// SQL Performance Tool - Trouble shooting report generator for Management Portal.
Class %CSP.UI.Portal.Dialog.SQLReportGenerator Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLReportGenerator.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "SQL Trouble Shooting Report Generator";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// WRC Number
Property WRCNUM As %ZEN.Datatype.string(ZENURL = "WRCNUM");

/// Selected IDs
Property SelectedIDs As %ZEN.Datatype.string(ZENURL = "SelectedIDs");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property HasMultiple As %ZEN.Datatype.boolean;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<hgroup label="" labelClass="normal" cellVAlign="bottom" >
<text id="FileName" label="Enter the path and name of the XML file to store the report" size="70"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<spacer height="4"/>
<vgroup>
<label id="lblNote" label="File saved. You may email this file to your InterSystem's support adviser now." labelClass="caption" hidden="true"/>
<link id="emaillink" href="" caption="Mail to" hidden="true"/>
</vgroup>
</pane>
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// Check if file is empty.
ClientMethod validateFile(fileName) [ Language = javascript ]
{
	if (fileName == "") {
		alert($$$Text("File name is empty. Please enter a file name."));
		zen("FileName").focus();
		return false;	
	}
	return true;
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("FileName").setValue(value);
		zenPage.updateState();	
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Generate Report")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit "WRC: "_$zconvert(%page.WRCNUM,"O","HTML")
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
	Set (WRC,defaultName) = %page.WRCNUM
	Set SelectedIDs = %page.SelectedIDs
	Set WRCList = ""
	Set tCnt = 1
	Set tID = $P(SelectedIDs,",",tCnt)
	While tID '= "" {
		Set tObj = ##class(%SQL.Manager.QButtons.Base).%OpenId(tID)
		If $IsObject(tObj) {
			Set WRC = tObj.WRCNumber
			Set WRCList = $S(WRCList'="": WRCList_",",1:"")_WRC
		}
		Set tCnt = tCnt + 1
		Set tID = $P(SelectedIDs,",",tCnt)	
	}
	Set %page.HasMultiple = ($L(WRCList,",") > 1)
	If %page.HasMultiple {
		Set defaultName = "Multiple"
		Set %page.WRCNUM = WRCList	
	} 
	Set ..%GetComponentById("btnHelp").hidden = 1
	Set filename = ##class(%File).NormalizeFilename("WRC"_defaultName_".xml",$G(^%SYS("TempDir")))
	Set ..%GetComponentById("FileName").value = filename
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Generate SQL trouble shooting report in namespace %1 for WRC number %2."),..EscapeHTML(%page.NAMESPACE),..EscapeHTML(%page.WRCNUM))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

/// Check to see if file exists
ClassMethod FileExists(filename) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(filename) Quit -1
	If ##class(%File).Exists(filename) Quit 1
	Quit 0
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var filename = zen("FileName").getValue();
	if (this.validateFile(filename) == false) return false;
	var exists = this.FileExists(filename);
	if (exists == -1) {
		alert($$$Text("You have entered a directory without a file name."));
		zen("FileName").focus();
		return false;	
	}
	if (exists == 1) {
		if (!confirm($$$Text("File already exists. Overwrite the existing file?"))) {
			return false;
		}
	}
	var ok = this.WriteToFile(this.WRCNUM,filename);
	if (ok) {
		zen('btnCancel').setProperty('caption',$$$Text("Done"));
		zen('btnFinish').setProperty('disabled',true);
		zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		zen('lblNote').setHidden(false);
		var maillink = "mailto:support@intersystems.com?subject=SQL Troubleshooting Report for WRC"+encodeURIComponent(this.WRCNUM)+"&body=See attachment&attachment="+encodeURIComponent(filename);
		var html = zen('emaillink');
		html.setProperty("href",maillink);
		html.setHidden(false);
	}
	return false;
}

ClassMethod WriteToFile(WRCNUM, filename) As %String [ ZenMethod ]
{
	Set sc = ##class(%SQL.Manager.QButtons.Base).WriteAllToFile(WRCNUM,.filename)
	If $$$ISERR(sc) Quit $$$HTMLErrorMsg(sc)
	//Set src = "_XML.Utils.SchemaServer.cls?FILE=" _ ..Encrypt($zcvt(filename,"O","UTF8"))	
	//Quit src
	Quit sc
}

}
