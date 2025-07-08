/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.RecordStatus Extends %WebStress.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// 
/// Set this to the appropriate application class.
Parameter APPLICATION = "%ZEN.Portal.Application";

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

<timer id="timer1" timeout="0" ontimeout="zenPage.checkTimer()"/>

<hgroup>

<vgroup>

<label id="refreshLabel" value="Refresh Time (secs):" hidden="true" />

<label value="Script:" />

<label value="Port:" />

<label value="Status:" />

<link href="javascript:self.document.location.reload()" caption="Refresh" />

</vgroup>

<vgroup>

<label id="refresh" value="0" hidden="true" />

<label id="scriptlabel" value="" />

<label id="portlabel" value=""/>

<label id="status" value="" />

<button id="button1" controlClass="commandButton" caption="Stop Recording" onclick="zenPage.StopRecord()" />

</vgroup>

</hgroup>

<html id="lines" />

</pane>
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

	set label=%page.%GetComponentById("scriptlabel")

	set label.value=$get(^WebStress.Record("Script"))
	
	set label=%page.%GetComponentById("portlabel")

	set label.value=$get(^WebStress.Record("BrowserPort"))

	set label=%page.%GetComponentById("status")
	set status=+$get(^WebStress.Record("Shutdown"))
	set label.value=$select(status=0:"Running",status=1:"Stopping",status=2:"Stopped",1:"Unknown")
	
	If ..enableAutoRefresh {
		Set tRefreshTimeout = 5
		Set ..%GetComponentById("timer1").timeout = (tRefreshTimeout * 1000)
		Set ..%GetComponentById("refreshLabel").hidden = 0
		Set tRefreshValue = ..%GetComponentById("refresh")
		Set tRefreshValue.hidden = 0
		Set tRefreshValue.value = tRefreshTimeout
	}

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

ClientMethod renderGrid() [ Language = javascript ]
{

	var holder=zenPage.GetStatus();

	var place=zen("lines").getEnclosingDiv();

	var statuslabel=zen("status");

	statuslabel.setValue(holder.Status);

	var html=new Array();

	html[html.length]=holder.Recorded;

	place.innerHTML=html.join('');
}

ClassMethod GetStatus() As %ZEN.proxyObject [ ZenMethod ]
{
	set holder=##class(%ZEN.proxyObject).%New()
	set holder.Status=..Status()
	set holder.Recorded=..Recorded()
	quit holder
}

ClassMethod Status() As %String
{
	set status=+$get(^WebStress.Record("Shutdown"))
	quit $select(status=0:"Running",status=1:"Stopping",status=2:"Stopped",1:"Unknown")
}

ClassMethod Recorded(max As %Integer = 20) As %String
{
	set max=$get(max,0)
	set key=" ",count=0,str=""
	for  {
		set key=$order(^WebStress.Record(key),-1)
		if key="" quit
		set count=count+1
		if (max>0)&&(count>max) quit
		set info=$get(^WebStress.Record(key,"read",1))
		if info'="" {
			set str=str_key_"&nbsp;"_$piece(info," ",1)_"&nbsp;"_$piece(info," ",2)_"<br/>"
		}
	}
	quit str
}

ClassMethod StopRecord() [ ZenMethod ]
{

	set ^WebStress.Record("Shutdown")=1

	set status=##class(%WebStress.Control).SetAppEncrypt(1,0)

	quit
}

ClientMethod checkTimer() [ Language = javascript ]
{

  	zenPage.renderGrid();

  	if (zenPage.enableAutoRefresh) {
	  	// restart the timer
	  	var timer=zen("timer1");
	  	timer.startTimer();
  	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.renderGrid();
}

}
