/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %UnitTest.Portal.standardPage Extends %ZEN.Portal.standardPage [ System = 4 ]
{

/// URL of home page (used in links).
Parameter HOMEPAGE = "%25CSP.Portal.Home.zen";

Parameter RESOURCE As STRING = "%Development";

Property IndexId As %ZEN.Datatype.integer(ZENURL = "Index");

XData Style
{
<style type="text/css">

/* tool ribbon */
.toolRibbon {
	height: 48px;
	background: white;
	border-bottom: 1px solid gray;
	vertical-align: middle;
}

.ribbonTitle {
	font-size: 18px;
	font-family: "Myriad Pro Regular", arial;
	color: #505050;
	background: #80F080;
	border-left: 1px solid white;
	text-align: center;
	text-shadow: #808080 1px 1px 2px;
}

.ribbonLabel {
	vertical-align: middle;
	color: #404040;
	font-weight: bold;
	font-size: 10pt;
}

.ribbonSortOption:hover,.ribbonSortOptionSelected:hover {
	color: darkred;
}

.ribbonSortOption {
	text-decoration: none;
	color: #5ba4dc;
	font-weight: normal;
}

.ribbonSortOptionSelected {
	text-decoration: none;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

.viewIconBar {
	vertical-align: bottom;
}

.viewIcon,.viewIconSelected,.viewIconDis,.viewIconHover {
	vertical-align: bottom;
	opacity: 0.7;
	border: 2px solid white;
}

.viewIconSelected {
	opacity: 1.0;
	border-radius: 2px;
	border: 2px solid darkred;
}

.viewIconHover {
	border: 2px solid #FFEEAA;
	border-radius: 4px;
	opacity: 1.0;
}

.titleTable, .titleTable TD, .titleTable TH {
	font-family:sans-serif;
 	font-size:18pt;
	font-weight:bold;
	color:white;
 	background-color:#BBBBBB;
 	width:100%;
}
.headerTable, .headerTable TD, .headerTable TH {
 	font-family:sans-serif;
 	font-size:11pt;
 	background-color:#DDDDDD;
}
.indexTable, .indexTable TD {
 	font-family:sans-serif;
 	font-size:11pt;
 	vertical-align:middle;
 	border-color:#CCCCCC;
}
.indexTable TH {
	font-family:sans-serif;
	font-size:11pt;
	color:white;
 	background-color:#ACBBD5;
 	padding:4px;
}
.bodyTable, .bodyTable TD {
 	font-family:sans-serif;
 	font-size:11pt;
 	vertical-align:top;
 	border-color:#CCCCCC;
}
.bodyTable TH {
 	font-family:sans-serif;
 	font-size:11pt;
 	color:white;
 	background-color:#ACBBD5;
 	width:100%;
}
</style>
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25UnitTest.Portal.Home.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	}
}

/// Name of this page.
Parameter PAGENAME = "UnitTest Report Page";

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	set tPageName = $$$Text("UnitTest")
	Set tCurrPageName = ..%OnGetPageName()
	Set tURL(1) = $ZCVT("%UnitTest.Portal.Home","O","URL")_".cls"
	Set tURL(2) = $ZCVT($className(),"O","URL")_".zen?Index="_$ZCVT(..IndexId,"O","URL")
	Set pLink(1) = $LB(tPageName,..Link(tURL(1)))
	Set pLink(2) = $LB(tCurrPageName,..Link(tURL(2)))

	Quit $$$OK
}

/// return value 0 = failed, 1 = passed, 2 = skipped
ClassMethod GetTestStatus(index, suite, case, method, action) As %Integer
{
	; status precedence order: failed, skipped, passed
	set sp(0)=3,sp(2)=2,sp(1)=1,sphighest=3
	If $d(action) {
		Quit $li(^UnitTest.Result(index,suite,case,method,action),1)
	}
	If $d(method) {
		Set status=$li(^UnitTest.Result(index,suite,case,method),1) Quit:status=sphighest status
		Set action="" For  Set action=$o(^UnitTest.Result(index,suite,case,method,action)) Quit:action=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(index,suite,case,method,action) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(case) {
		Set status=$li(^UnitTest.Result(index,suite,case),1) Quit:status=sphighest status
		Set method="" For  Set method=$o(^UnitTest.Result(index,suite,case,method)) Quit:method=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(index,suite,case,method) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(suite) {
		Set status=$li(^UnitTest.Result(index,suite),1) Quit:status=sphighest status
		Set case="" For  Set case=$o(^UnitTest.Result(index,suite,case)) Quit:case=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(index,suite,case) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(index) {
		Set status=1
		Set suite="" For  Set suite=$o(^UnitTest.Result(index,suite)) Quit:suite=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(index,suite) if sp(one)>sp(status) set status=one
		Quit status
	}
	Quit 0
}

ClassMethod GetTestState(level) As %String
{
	quit $s(level=1:"passed",level=2:"skipped",1:"failed")
}

ClassMethod GetTestColor(level) As %String
{
	quit $s(level=1:"green",level=2:"blue",1:"red")
}

ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	
	if %request.Get("NS")'="" {
		set appdir=$$getDefaultApp^%SYS.cspServer2(%request.Get("NS"))
	}
	set namespace=%request.Get("NS")
	set index=%request.Get("INDEX")
	set page="Indices"
	if %request.Get("SUITE")'="" {
		set index=index_"||"_%request.Get("SUITE")	
		set page="TestSuite"
		if %request.Get("CASE")'="" {
			set index=index_"||"_%request.Get("CASE")	
			set page="TestCase"
			if %request.Get("METHOD")'="" {
				set index=index_"||"_%request.Get("METHOD")
				set page="TestMethod"
			}
		}	
	} 
	
	if namespace'="" {
		set url=appdir_"/%25UnitTest.Portal."_page_".cls?Index="_..EscapeURL(index)
		set %response.Redirect=url
	}
	quit $$$OK
}

}
