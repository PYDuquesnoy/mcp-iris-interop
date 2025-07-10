/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.VisualTrace Extends EnsPortal.VisualTrace [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageTrace:USE";

/// Name of this page.
Parameter PAGENAME = "Enterprise Visual Trace";

Parameter SVGTraceClass = "Ens.Enterprise.Portal.SVG.VisualTrace";

Property headerClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Enterprise.MsgBank.MessageHeader" ];

Property eventLogClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Enterprise.MsgBank.Log" ];

XData Style
{
<style type="text/css">
#resendTab {
	background-color: white;
}
#sessionLinkSection {
	padding: 5px;
	font-size: 0.9em;
	border-spacing: 2px;
}
#sessionLinkSection td {
	padding: 2px;
	vertical-align: top;
}
.sessionLink {
}
.sessionTitle {
	font-weight: bold;
}
.sessionList {
	list-style-type: none; 
	margin: 0;
	padding: 0;
}
.sessionList li {
	padding-top: 2px;
	padding-bottom: 2px;
}
.sessionList li a {
	padding-left: 5px;
	padding-right: 5px;
	
}
</style>
}

XData svgTracePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<svgFrame id="SVGTrace" svgPage="Ens.Enterprise.Portal.SVG.VisualTrace" width="300" height="200" svgAutoSize="true">
<parameter id="svgPAGE" paramName="PAGE" value="1" />
<parameter id="svgSESSIONID" paramName="SESSIONID" value="#(%page.sessionId)#"/>
<parameter id="printable" paramName="PRINTABLE" value="#(%page.printable)#" />
<parameter id="svgMsgPerPage" paramName="MSGPERPAGE" />
<parameter id="svgShowInternalItems" paramName="SHOWINTERNAL" />
<parameter id="svgShowEvents" paramName="INCLUDEEVENTS" />
</svgFrame>
</pane>
}

XData allTabs [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tabGroup id="contentTabs" showTabBar="true" remember="true" onshowTab="zenPage.updateTabs(true);">
<tab id="headerDetails" caption="Details" title="Item Details">
<html id="detailsContent" OnDrawContent="DrawDetailsContent" />
</tab>
<tab id="bodyDetails" caption="Body" title="Body Details">
<html id="bodyInfo" OnDrawContent="DrawBodyInfo" />
</tab>
<tab id="bodyContents" caption="Contents" title="Item Contents">
<html id="fullContent" containerStyle="padding-top: 5px; padding-bottom: 5px;" OnDrawContent="DrawFullContentLinks" />
<iframe id="contentFrame" frameBorder="false" width="100%"/>
</tab>
<tab id="resendTab" caption="Resends" title="Resend Data">
<html id="resendData" OnDrawContent="DrawResendData" />
</tab>
</tabGroup>
</pane>
}

/// Helper method to obtain the session id given the SESSIONID URL parameter which may be a session id or a message id
ClassMethod GetActualSessionId(pId As %String = "") As %String
{
	&sql(SELECT ClientSessionId	INTO :session FROM Ens_Enterprise_MsgBank.MessageHeader WHERE %ID = :pId)
	Quit $G(session,pId)
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
		Quit $$$Text("Message Bank Trace")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Bank Trace")
}

ClassMethod SetItemsPerPage(items As %Integer) As %String [ ZenMethod ]
{
	Set items = $get(items, $parameter(..#SVGTraceClass,"MSGPERPAGE"))
	Set ^EnsPortal.Settings($username,"MsgBankTrace","ItemsPerPage") = items
	Quit 1
}

ClassMethod GetItemsPerPage() As %Integer [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"MsgBankTrace","ItemsPerPage"), $parameter(..#SVGTraceClass,"MSGPERPAGE"))
}

ClassMethod SetShowInternalItems(flag As %Boolean = 0) As %String [ ZenMethod ]
{
	Set show = $get(flag, $parameter(..#SVGTraceClass,"SHOWINTERNALITEMS"))
	Set ^EnsPortal.Settings($username,"MsgBankTrace","ShowInternalItems") = show
	Quit 1
}

ClassMethod GetShowInternalItems() As %Boolean [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"MsgBankTrace","ShowInternalItems"), $parameter(..#SVGTraceClass,"SHOWINTERNALITEMS"))
}

ClassMethod SetShowEvents(flag As %Boolean = 0) As %String [ ZenMethod ]
{
	Set show = $get(flag, $parameter(..#SVGTraceClass,"INCLUDEEVENTS"))
	Set ^EnsPortal.Settings($username,"MsgBankTrace","ShowEvents") = show
	Quit 1
}

ClassMethod GetShowEvents() As %Boolean [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"MsgBankTrace","ShowEvents"), $parameter(..#SVGTraceClass,"INCLUDEEVENTS"))
}

Method CheckViewContents() As %Boolean [ CodeMode = expression ]
{
$system.Security.Check("%Ens_MsgBank_MessageContent","USE")
}

ClassMethod GetShowContents() As %Boolean [ CodeMode = expression ]
{
$select($IsObject($get(%session)): $get(%session.Data("EnsPortal","MsgBankTrace","ShowContents"),1), 1: 1)
}

ClassMethod SetShowContents(pValue As %Boolean = 1) As %String [ ZenMethod ]
{
	If $IsObject($get(%session)) {
		Set %session.Data("EnsPortal","MsgBankTrace","ShowContents") = pValue
	}
	Quit ""
}

/// Get next session Id; pDirection should be 1 or -1
ClassMethod NextSession(pSessionId = "", pDirection As %Integer = 1) As %Integer [ CodeMode = expression, Internal, Private ]
{
+$O(^Ens.EntMsgBank.MessageHeaderI("SessionId",pSessionId),pDirection)
}

/// Show the legend as a popup.
ClientMethod showLegend() [ Language = javascript ]
{
	zenPage.launchPopupWindow(zenLink('Ens.Enterprise.Portal.VisualTraceLegend.zen'),'','status=no,scrollbars=no,resizable=no,width=718,height=630,left=400');
}

/// Show the trace in full as a popup.
ClientMethod showPrintableVersion() [ Language = javascript ]
{
	var currentPage = (zenPage.currPage >0 ? zenPage.currPage : 1);
	zenPage.launchPopupWindow(zenLink('Ens.Enterprise.Portal.VisualTrace.zen?SESSIONID=' + zenPage.sessionId + '&PRINTABLE=1&PAGE='+currentPage),'','status=no,scrollbars=auto,resizable=yes,width=1280,height=800,left=150,top=150');
}

/// Go to the Trace page for the previous or next session.
ClientMethod goToSession(id) [ Language = javascript ]
{
	this.gotoPage('Ens.Enterprise.Portal.VisualTrace.zen?SESSIONID=' + id);
}

Method DrawResendData(pSeed As %String) As %Status
{
	If (..sessionId = "") {
		Quit $$$OK
	}
	
	&html<<table id="sessionLinkSection">
	<tr>
		<td class="sessionTitle">#($$$TextHTML("Client node"))#:</td>
		<td class="sessionLink">#(##class(Ens.Enterprise.MonitorClient).getNodeClient($extract(..sessionId,1,3)))#</td>
	</tr>
	<tr>
		<td class="sessionTitle">#($$$TextHTML("Sent from"))#:</td>>
	If $d(^Ens.MsgBank.Sessions("parent",..sessionId)) { ; This is a resent session
		&html<<td><ul class="sessionList">>
		Set tParentId = ""
		For {
			Set tParentId = $order(^Ens.MsgBank.Sessions("parent",..sessionId,tParentId))
			Quit:(tParentId = "")
			&html<	<li>
						<a href="#(##class(%CSP.Page).Link($classname($this)_".zen?SESSIONID="_tParentId))#">#(tParentId)#&nbsp;[#(##class(Ens.Enterprise.MonitorClient).getNodeClient($E(tParentId,1,3)))#]</a>
					</li>>
		}
		&html<</ul></td>>
	}
	Else {
		&html<<td>&nbsp;</td>>
	}
	&html<</tr><tr>
	<td class="sessionTitle">#($$$TextHTML("Resent to"))#:</td>>
	If $d(^Ens.MsgBank.Sessions("child",..sessionId)) { ; Messages were resent based on this session
		&html<<td><ul class="sessionList">>
		Set tChildId = ""
		For {
			Set tChildId = $order(^Ens.MsgBank.Sessions("child",..sessionId,tChildId))
			Quit:(tChildId = "")
			&html<<li>>
			If tChildId<0 {
				Set tClientName=$g(^Ens.MsgBank.Sessions("child",..sessionId,tChildId),"???")
				&html<#($e(tChildId,4,*))#&nbsp;[#(tClientName)#]>
			}
			Else {
				&html<<a href="#(##class(%CSP.Page).Link($classname($this)_".zen?SESSIONID="_tChildId))#">#(tChildId)#&nbsp;[#(##class(Ens.Enterprise.MonitorClient).getNodeClient($E(tChildId,1,3)))#]</a>>
			}
			&html<</li>>
			Set tFirst = 0
		}
		&html<</ul></td>>
	}
	Else {
		&html<<td>&nbsp;</td>>
	}
	&html<</tr></table>>
	Quit $$$OK
}

}
