/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.NLSImport Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Import Locale";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.NLSImport.zen";

Parameter HELPADDRESS = "Home,Configuration,Import Locale";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
a.radioSetCaption { vertical-align: text-bottom; }
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<radioSet id="Type" label="Import" displayList="Locales,Tables,Both" valueList="0,1,2" value="2"/>
<hgroup label="Import from file">
<text id="FileName" size="50" hint="Required. Valid file extensions are: 'xml' or 'goq' only."/>
<button id="FileNameBrowse" caption="Browse..." onclick="zenPage.doBrowse('FileName');" valign="top"/>
</hgroup>
<button id="btnRun" onclick="zenPage.doImport();" caption="Import" enclosingStyle="margin-top:5px;"/>
</group>
</form>
</pane>
}

/// Returning from file select OR qualifiers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen(popupName).setValue(value);		
	}
}

/// Launching a file selector window. 
ClientMethod doBrowse(fieldID) [ Language = javascript ]
{
	var Dir = zen(fieldID).getValue();
	var wildcard = "*.xml;*.goq";
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard);
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	try {
		var pass = true;
		if (!this.validateRequired(zen('FileName'),pass,"S")) pass = false;
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Save current item.
ClientMethod doImport() [ Language = javascript ]
{
	try {
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		
		this.showMsg($$$Text("Importing started. Please wait..."),false);
		zen('btnRun').setDisabled(true);
		
		var proxy = new zenProxy();
		proxy.FileName = zen('FileName').getValue();
		var type = zen('Type').getValue();
		proxy.ImportLocale = (type != 1);
		proxy.ImportTable = (type > 0);
		
		var result = this.SaveData(proxy);
		
		zen('btnRun').setDisabled(false);
		
		if (result.ok == 1) {
			var msg = $$$Text("Import completed.")+'&nbsp;&nbsp;';
			if (proxy.ImportLocale) {
				msg += $$$Text("Locales: %1");
				msg = msg.replace('%1',result.Locales);
			}
			if (proxy.ImportTable) {
				if (proxy.ImportLocale) msg += ", ";
				msg += $$$Text("Tables: %1");
				msg = msg.replace('%1',result.Tables);
				msg += ", ";
				msg += $$$Text("Subtables: %1");
				msg = msg.replace('%1',result.SubTables);
			}
			this.showMsg(msg,false);
		} else {
			this.showMsg(result.ErrorMessage,true);
		}
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
		Set FileName = pProxy.FileName
		Set ImportLocale = pProxy.ImportLocale
		Set ImportTable = pProxy.ImportTable

		Set ext = $ZCVT($P(FileName,".",$L(FileName,".")),"L")
		If (ext '= "xml") && (ext '= "goq") {
			Set tProxy.ErrorMessage = $$$TextHTML("Invalid file name. ")_$$$TextHTML("Please enter a file name with extention 'xml' or 'goq'.")
			Throw
		}
		
		Set SelBits = ImportLocale * 2 + ImportTable * 2 + ImportTable
		
		If ext = "xml" {
			Set tSC = ##class(Config.NLS.Locales).ImportAll(FileName,.NumImported,SelBits)
			If $$$ISERR(tSC) {
				Set tProxy.ErrorMessage = $$$TextHTML("Error occured during import. ")_..EvalResult(tSC)
				Throw
			}
		} Else {
			If $ZCVT($E(FileName,$L(FileName)-7,*),"L")="_obj.goq" {
				Set tProxy.ErrorMessage = $$$TextHTML("Object files not accepted. ")_$$$TextHTML("Please select a source file.")
				Throw
			}
			Set tSC = ##class(Config.NLS.Locales).ImportLegacy(FileName,.NumImported,SelBits)
			If $$$ISERR(tSC) {
				Set tProxy.ErrorMessage = $$$TextHTML("Error occured during import. ")_..EvalResult(tSC)
				Throw
			}
		}
		
		If (ImportLocale = 1) {
			Set tProxy.Locales = $G(NumImported("Locales"))
		}
		If (ImportTable = 1) {
			Set tProxy.Tables = $G(NumImported("Tables"))
			Set tProxy.SubTables = $G(NumImported("SubTables"))
		}

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If (tProxy.ErrorMessage = "") Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Import locale from a file:")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Import Locale")
}

}
