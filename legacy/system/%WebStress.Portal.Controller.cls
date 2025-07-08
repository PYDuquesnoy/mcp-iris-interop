/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Controller Extends %WebStress.Portal.standardPage [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// Name of this page.
Parameter PAGENAME = "Webstress Controller Detail Page";

XData Style
{
<style type="text/css">

</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<timer id="timer1" timeout="0" ontimeout="zenPage.controlTimer()"/>
<html id="controlgrid" />
<jsonProvider id="control" OnGetArray="GetControlArray"/>
</pane>
}

Method GetControlArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK,desc="",sys=##class(%WebStress.Control).SystemID()
	Set pMetaData = $LB("test","type","node")
	set sub="",count=0
	for  {
		set sub=$O(^WebStress.ControlD(sub))
		quit:sub=""
		set sub1=""
		for  {
			set sub1=$O(^WebStress.ControlD(sub,sys,sub1))
			quit:sub1=""
			set sub2=""
			for  {
				set sub2=$O(^WebStress.ControlD(sub,sys,sub1,sub2))
				quit:sub2=""
				set count=count+1
				set pData(count)=$LB(sub,sub1,$G(^WebStress.ControlD(sub,sys,sub1,sub2)))
			}
		}
	}
	merge ^bill=pData
	quit tSC
}

ClientMethod renderControl() [ Language = javascript ]
{
	var griddiv=zen('controlgrid').getEnclosingDiv();
	var json=zen('control')
	var model=json.getContentObject();
	var html=new Array();
	html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>Test</th><th>Type</th></tr>';
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			var row = '<tr class=tpRow>';
			row=row+'<td>'+item.test+'</td>';
			row=row+'<td>'+item.type+'</td>';
			row=row+'<td>'+item.node+'</td>';
			html[html.length]=row+'</tr>';
		}
	}
	html[html.length]='</tbody></table>';
	griddiv.innerHTML=html.join('');
}

ClientMethod controlTimer() [ Language = javascript ]
{
	var runs=zen("control");
	runs.reloadContents();
	zenPage.renderControl();
	if (zenPage.enableAutoRefresh) {
		var timer=zen("timer1");
  		timer.startTimer();
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	// default: make *this* page the complete list
	Set tPageName = $$$ZENVAL(..title)
	Set tPageName = $P(tPageName," ",$L(tPageName," "))
	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))
	Quit $$$OK
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) {
		Quit tSC
	}
	
	If ..enableAutoRefresh {
		Set ..%GetComponentById("timer1").timeout = 10000
	}

	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.renderControl();
}

}
