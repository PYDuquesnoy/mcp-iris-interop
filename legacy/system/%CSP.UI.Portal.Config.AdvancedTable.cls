/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template for System Management Portal - Configure a large group of settings that are defined in one class, 
/// such as Config.Miscellaneous, Config.Startup and Config.config (for advanced memory) 
Class %CSP.UI.Portal.Config.AdvancedTable Extends %CSP.UI.Portal.Template [ Abstract, System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.AdvancedTable.zen";

Parameter EMSSERVICE = "Config";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Name of the current configuration class
Property ConfigClass As %ZEN.Datatype.string;

Property HelpLink As %String;

/// Subject name for the setting page. 
Property Subject As %String;

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<html id="table" OnDrawContent="DrawTable" seed="#(%page.Subject)#"/>
<label id="idRestart" hidden="true" label="Note: Changes to some of these settings may require a InterSystems IRIS restart" labelClass="brownnote"/>
</pane>
}

/// User clicked Edit. Go to Edit page.
ClientMethod editItem(tRow) [ Language = javascript ]
{
	try {
		var PID = document.getElementById('id_' + tRow).innerHTML;
		var url = "%25CSP.UI.Portal.Config.ValueEditor.zen?Subject="+this.Subject+"Edit&PID="+encodeURIComponent(PID)+"&ClassName="+encodeURIComponent(this.ConfigClass);
		this.gotoPage(url);
	 } catch (ex) {
		alert("Error: " + ex);
	 }
}

/// User clicked Help. Build the help link and open popup.
ClientMethod helpItem(tRow) [ Language = javascript ]
{
	try {
		var PID = document.getElementById('id_' + tRow).innerHTML;
		var HelpLink = this.HelpLink + PID;
		zenLaunchPopupWindow(HelpLink,this.Subject,'status,scrollbars,resizable,modal',zenThis);
	 } catch (ex) {
		alert("Error: " + ex);
	 }
}

/// Draw HTML for the table. pSeed = "Memory" or "Miscellaneous" or "Startup"
Method DrawTable(pSeed As %String) As %Status
{
	Set Status = $classmethod(..ConfigClass,"Get",.Properties)
	If $$$ISERR(Status) Quit Status

	&html<<table class="tpTable" border="1" cellpadding="0" cellspacing="2" style="table-layout:auto;">>
	&html<<tr><th>#($$$TextHTML("Setting"))#</th><th>#($$$TextHTML("Value"))#</th><th>&nbsp;</th><th>&nbsp;</th></tr>>
	
	#; Whatever properties you do not want to include in the table, add it to the string and kill it from the array:
	Set tExcludes = "EnableLongStrings,OsType,Platform,DefaultPort,PageSizeAlt,ZaMode"
	Set tExcludes = tExcludes_",bbsiz,globals2kb,globals4kb,globals8kb,globals16kb,globals32kb,globals64kb,pijdir,routines,wijdir"
	
	#; Show EnsembleAutoStart only if we are on Ensemble system
	If ..Subject = "Startup",##class(%Library.EnsembleMgr).IsEnsembleInstalled() = 0 Set tExcludes = tExcludes_",EnsembleAutoStart"
	
	For i = 1:1:$L(tExcludes,",") Kill Properties($P(tExcludes,",",i))
	
	Set editTitle = $$$Text("Edit this setting")
	Set helpTitle = $$$Text("View documentation on this setting")
	
	Set tRow = 0
	#;YSD2369 - remove Comments from array
	Set (tProperty,tp) = ""
	For  Set tp=$O(Properties(tp)) q:tp=""  Kill Properties(tp,"Comment"),Properties(tp,"Comments")
	Set tProperty = $O(Properties(tProperty))
	While tProperty '= "" {
		Set tRow = tRow + 1
		Set trowclass = $S(tRow#2:"tpOdd",1:"tpEven")
		Set tValue = $S(Properties(tProperty)'="":$ZCVT(Properties(tProperty),"O","HTML"),1:"&nbsp;")
		Set tType = $$$comMemberKeyGet(..ConfigClass,$$$cCLASSproperty,tProperty,$$$cPROPruntimetype)
		If tType [ "Boolean" Set tValue = $S(tValue=1:$$$TextHTML("true"),1:$$$TextHTML("false"))
		&html<<tr class=#(trowclass)#>
		<td id="id_#(tRow)#" class="tpStr" nowrap>#($ZCVT(tProperty,"O","HTML"))#</td>
		<td nowrap>#(tValue)#</td>>
		If '..IsEMSReadOnly {
			&html<<td nowrap><a href="#" onclick="zenPage.editItem('#(tRow)#');return false;" title="#(editTitle)#" class="link">#($$$TextHTML("Edit"))#</a></td>>
		}
		&html<<td nowrap><a href="#" onclick="zenPage.helpItem('#(tRow)#');return false;" title="#(helpTitle)#" class="link">#($$$TextHTML("Help"))#</a></td>
		</tr>
		>
		Set tProperty = $O(Properties(tProperty))
	}
	&html<</table>>
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..Subject = "Miscellaneous" {
		Set ..lblTitle = $$$Text("The following is a list of compatibility settings:")
		Set ..ConfigClass = "Config.Miscellaneous"
	} ElseIf ..Subject = "Startup" {
		Set ..lblTitle = $$$Text("The following is a list of system startup settings:")
		Set ..ConfigClass = "Config.Startup"
	} Else {
		Set ..lblTitle = $$$Text("The following is a list of advanced system memory settings:")
		Set ..ConfigClass = "Config.config"
		Set ..%GetComponentById("idRestart").hidden = 0
	}

	Set ..HelpLink = ..Link("/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_")

	Quit $$$OK
}

}
