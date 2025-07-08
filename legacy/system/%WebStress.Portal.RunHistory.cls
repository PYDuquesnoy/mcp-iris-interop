/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.RunHistory Extends %WebStress.Portal.standardPage [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// Name of this page.
Parameter PAGENAME = "Webstress Run History";

XData Style
{
<style type="text/css">
.tpNum {
    text-align: left;
}
</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tableNavigator tablePaneId="runs" />
<tablePane id="runs" align="center" useSnapshot="true" pageSize="50" maxRows="1000" tableName="%WebStress_Results.Iterations">
   <column colName="Name"
   colExpression="TestID->Name" 
   filterType="query" 
   filterOp="=" 
   filterQuery="Select TestID->Name from %WebStress_Results.Iterations" />
   <column colName="Script" 
    filterType="query" 
   filterOp="=" 
   filterQuery="Select Distinct(Script) from %WebStress_Results.Iterations" />
   <column colName="RunID" 
    filterType="query" 
   filterOp="=" 
   filterQuery="Select Distinct(RunID) from %WebStress_Results.Iterations" />
    <column colName="RunDescription" 
    filterType="query" 
   filterOp="=" 
   filterQuery="Select Distinct(RunDescription) from %WebStress_Results.Iterations" />
   <column colName="Generator" />
    <column colName="Minutes" />
   <column colName="Processes" />
   <column colName="Sessions" />
   <column colName="Iterations" />
   <column colName="Target" />
   <column colName="RatePerMinute" OnDrawCell="Color" />
</tablePane>
</pane>
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

	Quit tSC
}

Method Color(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set rate=0,good=" background: green;"
	set target=%query("Target")
	set goodlow=(target*.95)
	set goodhi=(target*1.05)
	set rate=%query("RatePerMinute")
	if (rate<goodlow)||(rate>goodhi) {
		set good=" background: yellow;"
	}
	set goodlow=(target*.9)
	set goodhi=(target*1.1)
	if (rate<goodlow)||(rate>goodhi) {
		set good=" background: red;"
	}
	&html<<div style='#(good)#'>#(%query("RatePerMinute"))#</div>>
	quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

}
