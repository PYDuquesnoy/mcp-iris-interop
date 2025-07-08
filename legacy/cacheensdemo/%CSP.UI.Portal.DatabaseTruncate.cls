/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Databases Truncate
Class %CSP.UI.Portal.DatabaseTruncate Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Cleanup";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.DatabaseTruncate.zen";

Parameter HELPADDRESS = "Home,Databases,Database Info,Truncate";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.DatabaseDetails.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// ID for edit. DBName for this page.
Property DBName As %String(ZENURL = "DBName");

/// DBDirectory passed in.
Property Directory As %String(ZENURL = "Directory");

/// Current size.
Property Size As %String;

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form>
 <label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;" labelPosition="left" hidden="false">
 <label id="DatabaseName" label="Database Name:" value="#(%page.DBName)#" enclosingClass="normal"/>
 <label id="Directory" label="Directory:" value="#(%page.Directory)#" enclosingClass="normal"/>
 <label id="Size" label="Size: " value="" enclosingClass="normal"/>
 <text id="txtTarget" label="" size="10" value="0" hint="" hintClass="helpText"/> 
 <html><hr size="1"/></html>
<hgroup cellAlign="right">
<hgroup cellStyle="padding:2px;">
 <button id="btnOK" caption=" OK " controlClass="commandButton" onclick="zenPage.doFinish();"/>
 <button id="btnCancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.doCancel();"/>
 <button id="btnDone" caption="Done" controlClass="commandButtonDisabled" onclick="zenPage.doCancel();" disabled="true"/>
 </hgroup>
 </hgroup>
 </group>
 </form>
  <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>
  <button id="btnExit" caption="Cancel" onclick="zenPage.doCancel();" hidden="true"/>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set %page.lblTitle = $$$Text("To truncate unused space in the selected directory, fill out the following form and press [ OK ]:")

	Set msg = ..GetSize(%page.Directory,.Size)
	If (msg '= 1) {
		Set ErrorComp = ..%GetComponentById("idError")
		If (msg = "Not Mounted") || (msg = "ReadOnly") {
			Set ErrorComp.seed = 1
		} Else {
			Set ErrorComp.seed = msg
		}
		Set ErrorComp.hidden = 0
		Set ..%GetComponentById("form").hidden = 1
		Set ..%GetComponentById("btnExit").hidden = 0
	} Else {
		Set %page.Size = Size
		Set ..%GetComponentById("Size").value = %page.Size_" MB"
		Set txtTarget = ..%GetComponentById("txtTarget")
		Set txtTarget.label = $$$TextHTML("Target file size (MB):")
		Set txtTarget.hint = $$$TextHTML("Specify the target size for the file, or 0 to remove all unused space.")
	}

	Quit $$$OK
}

/// Return current size since the size may have changed since the table was drawn
ClassMethod GetSize(Directory As %String, Output Size As %Integer) As %String
{
	Try {
		Set tObj = ##Class(SYS.Database).%OpenId(Directory,,.tSC)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		If (tObj.Mounted '= 1) {
			Set msg = "Not Mounted"
		} ElseIf $$$NotAllowDBCompTrunDefrag(tObj) {
			Set msg = "ReadOnly"
		} Else {
			Set Size = tObj.Size
			Set msg = $$$OK
		}
	} Catch Error {
		Set msg = $$$Text("Error occurred in GetSize:")_" "_..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
	}
	Quit msg
}

/// User clicked "OK" to cleanup. Call server method to job off in the background.
ClientMethod doFinish(isFinish) [ Language = javascript ]
{
	var DatabaseName = this.DBName;
	var Directory = this.Directory;
	var Size = this.Size;
	var Target = zenPage.getComponentById("txtTarget").getValue();
	if (!this.validate(Size,Target)) return;
	var proxy = this.StartCleanup(DatabaseName,Directory,Target);
	if (proxy.error != '') {
		this.showMsg(proxy.error, 1);	
	} else {
		this.showMsg(proxy.message, 0);
		zen("btnOK").setProperty("disabled",true);
		zen("btnOK").setProperty("controlClass","commandButtonDisabled");
		zen("btnCancel").setProperty("disabled",true);
		zen("btnCancel").setProperty("controlClass","commandButtonDisabled");
		zen("btnDone").setProperty("disabled",false);
		zen("btnDone").setProperty("controlClass","commandButton");
		}
}

/// Make sure that the Target size is smaller than that of the current size.
ClientMethod validate(size, target) As %Boolean [ Language = javascript ]
{
	var ok = true;
	if ((target != "") && (target == 0)) {
		return ok;
	} else {
		if (target == "") ok = false;
	    else if (!(target.match(/\d/))) ok = false;
		else if (parseInt(target) >= parseInt(size)) ok = false;
	}
	if (!ok) {
		alert($$$Text('Please enter a number that is less than the current size. To remove all unused space, enter 0.'));
		zenPage.getComponentById("txtTarget").focus();
	}
	return ok
}

/// Start background job to cleanup a selected directory
ClassMethod StartCleanup(DBName, Directory, Target) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = ##class(SYS.Database).ReturnUnusedSpace(
				$G(Directory),
				$G(Target),
				.newsize)
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)	
	} Else {
		Set tProxy.message = $$$FormatTextHTML("Database new size is %1 MB",newsize)
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartCleanup: "_$ZE
	Quit tProxy
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Databases")
	Set tURL = ..Link($ZCVT("%CSP.UI.Portal.OpDatabases","O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL")))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)


	Set tPageName = $$$Text("Database Details")
	Set tURL = ..Link(..ParentURL_"?DBName="_$ZCVT($G(%request.Data("DBName",1)),"O","URL")_"&$ID1="_$ZCVT($G(%request.Data("Directory",1)),"O","URL"))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($classname(),"O","URL")_".zen?DBName="_$ZCVT($G(%request.Data("DBName",1)),"O","URL")_"&Directory="_$ZCVT($G(%request.Data("Directory",1)),"O","URL")))
	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If ..DBName'="" Quit $$$FormatText($$$Text("Truncate: %1"),$ZCVT(..DBName,"O","HTML"))
	Quit ..LocatorHeader
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Truncate")
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed = 1 {
		Set text = $$$TextHTML("Unable to continue. Database is not mounted or is read-only.")
	} Else {
		Set text = $zconvert(seed,"O","HTML")
	}
	&html<<div class="ErrorBox">#(text)#</div>>
	Quit $$$OK
}

/// This method resets the modified indicator and return user to the parent page. 
ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	self.document.location = this.ParentURL + '?DBName=' + encodeURIComponent(this.DBName) + '&$ID1=' + encodeURIComponent(this.Directory);
}

}
