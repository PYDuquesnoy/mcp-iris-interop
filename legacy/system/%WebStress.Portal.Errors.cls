/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Errors Extends %WebStress.Portal.standardPage [ DependsOn = %ZEN.Component.tableNavigator, LegacyInstanceContext, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// Name of this page.
Parameter PAGENAME = "Webstress Errors Page";

XData Style
{
<style type="text/css">

</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tableNavigator tablePaneId="errors" />
<tablePane id="errors" useSnapshot="true" pageSize="25" maxRows="1000" queryClass="%WebStress.Errors" queryName="ShowAll" >
   <column colName="ID" />
   <column colName="ErrorStatus" />
   <column colName="ErrorText" />
   <column colName="ErrorTS" />
   <column colName="Process" />
   <column colName="RunID" />
   <column colName="ScriptID" />
   <column colName="SystemIdentifier" />
   <column colName="TestID" />
   <column colName="URLNumber" />
   <column colName="URLPath" />
   <column colName="URLVerb" />
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

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

}
