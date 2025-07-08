/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Record Extends %WebStress.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// 
/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// 
/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// 
/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

XData Style
{
<style type="text/css">



</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>

<hgroup>

<vgroup width="60%">

<label value="Script Name"/>

<label value="Port Number"/>

<label value="Set No-Encrypt Flag?" />

<label value="Routine Name" />

</vgroup>

<vgroup width="40%">

<text id="scriptname"/>

<text id="proxy" />

<checkbox id="encrypt" align="left"/>

<text id="rouname" value="Random.Script" />

</vgroup>

</hgroup>

<hgroup>

<button controlClass="commandButton" caption="Start the Recording" onclick="zenPage.recordStart();"/>

</hgroup>
<link href="%25WebStress.Portal.RecordStatus.cls" id="recstat" hidden="true"/>	

</pane>
}

ClientMethod recordStart() [ Language = javascript ]
{

	var scriptname=zen("scriptname").value;

	var proxy=zen("proxy").value;

	var flag=zen("encrypt").value;

	if (scriptname == '') {

		alert('Please enter a script name');

		return;

	}

	if (proxy == '') {

		alert('Please enter a port number');

		return;

	}

	if (flag == true) {

		var enccheck=zenPage.SetAppEncrypt();

	}

	var rtnname=zen("rouname").value;

	var run=zenPage.RecordLaunch(scriptname,proxy,rtnname);

	alert('Now start another browser and set the proxy settings accordingly\nYou may wish to clear the cache of temporary internet files');

	self.document.location = zen("recstat").href;
}

ClassMethod RecordLaunch(script As %String, port As %String, rtnName) As %String [ ZenMethod ]
{

	job ##class(%WebStress.Record).Run(script,port,rtnName)

	quit $$$OK
}

ClassMethod SetAppEncrypt(flag As %Boolean) As %String [ ZenMethod ]
{

	set status=##class(%WebStress.Control).SetAppEncrypt(1,1)

	quit status
}

/// 
/// Return the array of links to show in the locator bar.<br/>
/// 
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{

	// default: make *this* page the complete list

	Set tPageName = $$$ZENVAL(..title)

	Set tPageName = $P(tPageName," ",$L(tPageName," "))

	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))

	Quit $$$OK
}

/// 
/// This class method callback is called just before the server-side page 
/// 
/// object is created.
Method %OnAfterCreatePage() As %Status
{

	Set tSC = ##super()



	Quit tSC
}

/// 
/// Get the (localized) title string for the page.
/// 
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

/// 
/// Zen page notification of an HTTP request. This method can be overwritten
/// 
/// by subclasses.<br/>
/// 
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{

	lock +^WebStress.Record:0 set running='$test

	lock -^WebStress.Record

	if running set %response.ServerSideRedirect="%WebStress.Portal.RecordStatus.cls"

	quit 1
}

}
