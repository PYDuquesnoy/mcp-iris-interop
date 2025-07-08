/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component displays a locator bar; a set of links 
/// displayed along the top of a page to indicate where the page
/// is located within the application.
Class %ZEN.Component.locatorBar Extends component [ Deprecated, System = 3 ]
{

/// List of link objects.<br>
/// Each object specifies a link displayed in the locator bar.
Property links As list Of %ZEN.Auxiliary.locatorLink(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

/// Optional.
/// Name of Server-side callback method that returns an array
/// of quick links. The array is of the form:<br>
/// pLink("caption")=url<br>
/// If provided, these are displayed in a dropdown list at the edge
/// of the locator bar.<br>
/// This must be the name of a server-only method in the page
/// class that contains this view component.
Property OnGetQuickLinks As %ZEN.Datatype.delegator(FORMALSPEC = "*links:%ZEN.Datatype.string", RETURNTYPE = "%Status");

/// Optional.
/// User-defined seed value. This is an optional parameter that
/// is passed on to the <method>OnDrawBar</method> callback
/// method.<br>
Property seed As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// Name of Server-side callback method that will inject additional
/// content into the center of the locator bar.<br>
/// If defined, this callback is invoked on the server when this 
/// component is drawn. It provides HTML content by using &html or
/// by using the WRITE command.<br>
/// This must be the name of a server-only method in the page
/// class that contains this component.
Property OnDrawBar As %ZEN.Datatype.delegator(FORMALSPEC = "seed:%ZEN.Datatype.string", RETURNTYPE = "%Status");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Table used for locator bar." */
.locatorBarTable {
	font-size: 10pt;
	width: 100%;
}

/* @doc="Cell within locator bar." */
.locatorBarTable td {
	background: #A0B088;
	background-image: url(images/locatorgradient.png);
	background-repeat: repeat-x;
	border-bottom: 1px darkblue solid;
	padding-bottom: 1px;
}

/* @doc="Div around locator links." */
.locatorBarLinks {
	font-size: 0.8em;
	font-weight: bold;
	color: darkblue;
	text-decoration: none;
	text-align: left;
}

/* @doc="Links in locator bar." */
.locatorBarLinks a {
	color: darkblue;
	text-decoration: none;
	padding-right: 1px;
	padding-left: 1px;
}

.locatorBarLinks a:visited {
	color: darkblue;
}

.locatorBarLinks a:hover {
	color: red;
	background: #FFFAE7;
}

/* @doc="Dropdown of jump links in locator bar." */
.locatorBarSelect {
	color: darkblue;
	font-size: 0.8em;
}
</style>
}

/// Static HTML display method
Method %DrawHTML()
{
	#; get set of links to show
	Set tCount = ..links.Count()
			
	&html<<table class="locatorBarTable" border="0" cellpadding="0" cellspacing="0">>

	&html<<tr><td colspan="2" valign="center" nowrap="1">
		<div class="locatorBarLinks">&nbsp;>

	#; draw links
	If (tCount > 0) {
		For i = 1:1:tCount {
			If (i > 1) { &html<&gt;> }	
			Set tLink = ..links.GetAt(i)
			Set tTarget = tLink.target
			Set tCaption = tLink.caption
			#; if URL is "", default to *this* page.
			Set tURL = $S(tLink.href="":%request.URL,1:tLink.href)
			Set tURL = %page.%Link(tURL)
			Set tTitle = tLink.title
			&html<[<a target="#($ZCVT(tTarget,"O","HTML"))#" href="#(tURL)#" title="#($ZCVT(tTitle,"O","HTML"))#">#($ZCVT(tCaption,"O","HTML"))#</a>]>
		} 
	}
	&html<</div></td>>
	
	#; show potential multiple drop-downs right justified
	&html<<td nowrap="1" align="right" valign="middle" colspan="2">>
	
	#; invoke user callback, if present
	If (..OnDrawBar '= "") {
		Set tSC = ..%DrawContent()
		If $$$ISERR(tSC) {
			Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
			Quit
		}
	}

	#; draw QuickJump list, if present
	Set tSC = ..%GetQuickLinks(.tLinks)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}

	If ($D(tLinks)) {
		Set msgJumpTask = $$$TextHTML("Go directly to the selected task","%ZEN")
		Set cmdJumpTask = $$$TextHTML("Go to","%ZEN")
		&html<&nbsp;<span title="#(msgJumpTask)#">#(cmdJumpTask)#:&nbsp;</span>>

		//YSD2252 &html<<td title="#($ZCVT(msgJumpTask,"O","HTML"))#" nowrap="1" align="right" valign="center" colspan="2">#($ZCVT(cmdJumpTask,"O","HTML"))#:&nbsp;>
		&html<<select class="locatorBarSelect" onchange="zenPage.gotoPage(this.options[this.selectedIndex].value);">>
		&html<<option >   </option>>  // initial blank to force onchange event
		Set j = $O(tLinks(""))
		While (j '= "") {
			Set tJumpLink = tLinks(j)
			&html<<option value="#(tJumpLink)#">#($ZCVT(j,"O","HTML"))#</option>>
			Set j = $O(tLinks(j))
		}
		&html<</select>>
		&html<</td><td colspan="2">&nbsp;</td>>
	}

	&html<</tr></table>>
}

/// Invoke user method to get the list of quick links, if any.
Method %GetQuickLinks(Output pLinks) As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	#; if user callback is defined, call it
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetQuickLinks '= "")) {
		Set tSC = $zobjmethod(tHost,..OnGetQuickLinks,.pLinks)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Invoke user method to inject HTML contents into the 
/// bar.
Method %DrawContent() As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	#; if user callback is defined, use that
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnDrawBar '= "")) {
		Set tSeed = $$$ZENVAL(..seed)
		Set tSC = $zobjmethod(tHost,..OnDrawBar,tSeed)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This client method, if present, is fired when the object is updated from the server.
ClientMethod onupdateHandler() [ Language = javascript ]
{
	this.refreshContents();
}

}
