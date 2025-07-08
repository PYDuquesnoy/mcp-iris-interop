/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Delete Namespace Popup Dialog for Management Portal
Class %CSP.UI.Portal.Dialog.NamespaceDelete Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.NamespaceDelete.zen";

/// Displayed name of this page.
Parameter PAGENAME = "NamespaceDelete";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter EMSSERVICE = "Namespace";

/// When deleting a namespace this is passed in as the namespace name.
Property NamespaceName As %ZEN.Datatype.string(ZENURL = "ID");

Property NamespaceOK As %Boolean;

Property CSPCount As %Integer;

Property CSPList As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.dialogFinish();;"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed=""/>

<group layout="none" containerStyle="position:relative; top:0px; left:0px">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<spacer height="4px"/>
<vgroup id="idDelete" label="Are you sure you want to do this?" labelStyle="padding-left:10px;display:block;" cellStyle="padding:10px;">
<group id="cspContainer" layout="none" hidden="true">
<label label="Web applications associated with this namespace will also be deleted."/>
<spacer height="10px"/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.Applications"
queryName="NamespaceList"
dataSource="columns"
maxRows="1000"
multiSelect="true"
showZebra="true"
useSnapshot="true"
valueColumn="Path"
label="Additionally, you may select web applications below to delete their Web pages from the physical paths:"
>
<parameter value="#(%page.NamespaceName)#"/>
<column colName="Name" header="Web Application"/>
<column colName="Path" header="Physical Path"/>
 </tablePane>
 </group>
</vgroup>
</group>

</pane>
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	if (!this.NamespaceOK) {
		var msg = $$$Text("Invalid Namespace name.");
		this.showMsg(msg,1);
		zen("btnFinish").setDisabled(true);
		zen("btnFinish").setProperty("controlClass","commandButtonDisabled");
		zen("idDelete").setHidden(true);
		return;
	}
	zen('btnCancel').focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();

	var proxy = new zenProxy();
	proxy.NamespaceName = zenPage.NamespaceName;
	proxy.CSPCount = zenPage.CSPCount;
	proxy.CSPList = zenPage.CSPList;
	proxy.CSPSelected = zen('table').selectedRows;
		
	var result = this.SaveData(proxy);
	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage,1);
		return false;
	}
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Delete Namespace")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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

	Set ..NamespaceOK = (##Class(Config.Namespaces).Exists(..NamespaceName) && (..NamespaceName '= "%SYS"))

	Set count = 0
	Set list = ""
	Set tRS = ##class(%Library.ResultSet).%New("Security.Applications:NamespaceList")
	Do tRS.Execute(..NamespaceName)
	While tRS.Next() {
		Set count = count + 1
		if (count > 1) Set list = list_","
		Set list = list_tRS.Get("Name")
	}
	
	If (count > 0) {
		Set ..%GetComponentById("cspContainer").hidden = 0
	}
	
	Set ..CSPCount = count
	Set ..CSPList = list

	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Delete Namespace %1"),..EscapeHTML(%page.NamespaceName))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""

 	Try {
		Set tSC = ##class(Config.Namespaces).Delete(pProxy.NamespaceName)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.Message = ..EscapeHTML($$$FormatText($$$Text("%1 deleted."),pProxy.NamespaceName))
		
		#; Remove the following so locator bar will stop carrying $NAMESPACE with the deleted namespace.
		If $G(%session.Data("$NAMESPACE")) = pProxy.NamespaceName Kill %session.Data("$NAMESPACE")
		#; clear application 
		If pProxy.CSPCount > 0 {
			For n = 1:1:pProxy.CSPCount {
				Set cspName = $PIECE(pProxy.CSPList,",",n)
				Set cspPath = $PIECE(pProxy.CSPSelected,",",n)
				#; delete csp application from security
				Set tSC = ##Class(Security.Applications).Delete(cspName)
				#; delete csp pages and physical path
				If (cspPath '= "") {
					#; delete csp pages in this directory
					Set tRS = ##class(%ResultSet).%New("%File:FileSet")
					Do tRS.Execute(cspPath,"*.csp")
					While tRS.Next() {
						Do ##class(%File).Delete(tRS.Get("Name"))
					}
					#; delete this directory - If there are no files left and no subdirectory, then it's deleted.
					Do ##class(%File).RemoveDirectory(cspPath)
				}
			}
		}
		
		#; remove Ensemble namespace
	 	If ((##class(%Library.EnsembleMgr).IsEnsembleInstalled() || ##class(%Library.EnsembleMgr).IsHealthShareInstalled())) {
	 		Set tSC = ##class(%Library.EnsembleMgr).DisableNamespace(pProxy.NamespaceName)
	 		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	 	}
	 	
		#; remove the session data so System link (from locator bar) will not have the old namespace built into URL.
		Kill %session.Data("$NAMESPACE")
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

}
