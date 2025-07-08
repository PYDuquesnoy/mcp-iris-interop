/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal Routine Compare
Class %CSP.UI.Portal.RoutineCompare Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Compare Routines";

Parameter RESOURCE = "%Development:USE";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.RoutineCompare.zen";

Parameter HELPADDRESS = "Home,Routines,Compare";

Parameter PARENTPAGE = "/csp/sys/exp/%CSP.UI.Portal.RoutineList.zen";

Parameter RECENT = 0;

Property Namespace1 As %String(ZENURL = "$NAMESPACE");

Property Namespace2 As %String(ZENURL = "$NAMESPACE");

Property Routine1 As %String(ZENURL = "Routine1");

Property Routine2 As %String(ZENURL = "Routine2");

XData Style
{
<style type="text/css">
TABLE.DetailTable	{ 
	font-size: 11px;
	margin-right: 10px;
	border: 1px #cbcbcb solid;
}
TABLE.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: center;
}
TABLE.DetailTable TR.OddRow { background: white; }

TABLE.DetailTable TR.EvenRow { background: #F1F0E7; }

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<form name="cmpForm" id="cmpForm" width="100%" layout="vertical">
<hgroup cellVAlign="top">
<vgroup labelPosition="left">
<combobox name="Namespace1" id="Namespace1" label="Namespace 1:"/>
<combobox name="Namespace2" id="Namespace2" label="Namespace 2:"/>
</vgroup>
<spacer width="4"/>
<vgroup labelPosition="left">
<text name="txtRoutine1" id="txtRoutine1" label="Routine 1:" size="40"/>
<text name="txtRoutine2" id="txtRoutine2" label="Routine 2:" size="40"/>
<button name="btnOK" id="btnOK" caption="Compare" onclick="zenPage.doCompare();"/>
</vgroup>
<spacer width="4"/>
<vgroup>
<button name="btnBrowse1" id="btnBrowse1" caption="Browse..." onclick="zenPage.browseSelect(1);"/>
<button name="btnBrowse2" id="btnBrowse2" caption="Browse..." onclick="zenPage.browseSelect(2);"/>
<text hidden="true" name="browseselect" id="browseselect"/>
</vgroup>
</hgroup>
<html><hr width="100%" color="#7eabff"/></html>
<html id="idResult" OnDrawContent="DrawHTML"/>

</form>
</pane>
}

ClientMethod doCompare() [ Language = javascript ]
{
	this.Namespace1 = zen("Namespace1").getValue();
	this.Namespace2 = zen("Namespace2").getValue();
	this.Routine1 = zen("txtRoutine1").getValue();
	this.Routine2 = zen("txtRoutine2").getValue();
	var html = zen("idResult");
	html.seed = 1;
	html.refreshContents();
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Routine Compare")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Routine Compare")
}

/// When page is loaded, put focus on Routine 1
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zenPage.getComponentById("txtRoutine1").focus();
}

/// User clicked one of the Browse buttons.
/// Save the flag so that when you return you know which text box to update.
ClientMethod browseSelect(flag) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(flag);
	var Namespace = zenPage.getComponentById("Namespace"+flag).getValue();
	var Mask = zenPage.getComponentById("txtRoutine"+flag).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.routineSelect.cls?NAMESPACE='+encodeURIComponent(Namespace)+'&MASK='+encodeURIComponent(Mask),'RoutineSelect','resizable,width=600,height=700');
}

/// Load page specific data
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; Load namespace
	Set Namespace = $G(%request.Data("$NAMESPACE",1))
	If Namespace = "" Set Namespace = $namespace

	#; Populate Namespace drop-downs
	Set Namespace1 = ..%GetComponentById("Namespace1")
	Set Namespace2 = ..%GetComponentById("Namespace2")
	
	Set tCNT = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.NMS)
	Set tCN = $O(NMS(""))
	While tCN '= "" {
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do Namespace1.options.Insert(tOption)
			Do Namespace2.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tName = NMS(tCN)
			Set tOption.text = tName
			Set tOption.value = tName
		Set tCN = $O(NMS(tCN))
	}
	Set (tNamespace1,tNamespace2) = Namespace
	Set Namespace1.value = tNamespace1
	Set Namespace2.value = tNamespace2
	Set ..%GetComponentById("txtRoutine1").value = ..Routine1
	Set ..%GetComponentById("txtRoutine2").value = ..Routine2
	Quit 1
}

/// Draw HTML for Compare Results
Method DrawHTML(p As %String) As %Status
{
	If p = "" Quit 1
	Set Namespace1 = %page.Namespace1
	Set Namespace2 = %page.Namespace2
	
	Set Routine1 = %page.Routine1
	Set Routine2 = %page.Routine2

	If Routine1 = ""!(Routine2 = "") &html<<p>#($$$TextHTML("Routine name(s) empty!"))#</p>> Quit 1
	Set msgTitle = $$$TextHTML("Differences between these two routines:")
	Set lblLine = $$$TextHTML("Line")
	&html<<p class="ltcaption">#(msgTitle)#</p>>
	&html<<table class="DetailTable" border="0" cellpadding="2" cellspacing="2" bgcolor="#c4d6d6">>
	&html<<th>#(lblLine)#</th><th>#($ZCVT(Routine1,"O","HTML"))#</th><th>#(lblLine)#</th><th>#($ZCVT(Routine2,"O","HTML"))#</th>>
	Set tTotalRows = 0
	Set lastcolor = "OddRow"
	If Routine1 '= "",Routine2 '= "" {
		Set EventDesc = "Compare Routines"
		Set EventData = "Namespace 1: "_Namespace1_" Routine 1:"_Routine1_$$$CRLF_"Namespace 2: " _Namespace2_" Routine 2:"_Routine2
		$$$SMPAuditView
		Set tRS = ##class(%ResultSet).%New("%Routine:Compare")
		Do tRS.Execute(Namespace1,Routine1,Namespace2,Routine2)
		While tRS.Next() {
			Set tTotalRows = tTotalRows + 1
			Set line1 = tRS.GetData(1)
			Set line2 = tRS.GetData(3)
			Set thiscolor = $S(tTotalRows#2:"OddRow",1:"EvenRow")
			If line1=""!(line2="") Set thiscolor = lastcolor
			&html<<tr class="#(thiscolor)#">>
			&html<<td nowrap>#(line1)#</td><td nowrap>#($ZCVT(tRS.GetData(2),"O","HTML"))#</td><td nowrap>#(line2)#</td><td nowrap>#($ZCVT(tRS.GetData(4),"O","HTML"))#</td>>
			&html<</tr>>
			Set lastcolor = thiscolor
		}
	}  
	&html<<tr><td colspan="4">#($ZCVT($$$FormatText($$$Text("Completed at %1"),$ZDT($h,3)),"O","HTML"))#</td></tr>>
	&html<</table>>
	Quit 1
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		var flag = zenPage.getComponentById("browseselect").getValue();
		var name = "txtRoutine" + flag;
		zenPage.getComponentById(name).setValue(value);
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Routines","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

}
