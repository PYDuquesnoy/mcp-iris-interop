/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %UnitTest.Portal.Home Extends %UnitTest.Portal.standardPage [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

Method %OnGetTitle() As %String
{
	Quit $$$Text("UnitTest Report Home")
}

/// Contents of this page:
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<tableNavigator tablePaneId="indices" />
	<tablePane id="indices" useSnapshot="true" pageSize="50" maxRows="0" sql="Select ID,ID as Status,ID as DeleteSuite,DateTime,Duration,MachineName,ConfigurationName,Namespace,Version from %UnitTest_Result.TestInstance Order By ID Desc">
	<column colName="ID" link="%25UnitTest.Portal.Indices.cls?Index=#(%query.ID)#" />
	<column colName="Status" OnDrawCell="calcStatus" />
	<column	colName="DeleteSuite" OnDrawCell="delCell" />
	<column colName="DateTime" />
	<column colName="Duration" />
	<column colName="MachineName" />
	<column colName="ConfigurationName" />
	<column colName="Namespace" />
	<column colName="Version" />
	</tablePane>
	</pane>
}

Method calcStatus(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set notPassed=0
	set ind=##class(%UnitTest.Result.TestInstance).%OpenId(%query(pName))
	if $IsObject(ind) {
		for i=1:1:ind.TestSuites.Count() {
			set suitestatus=..GetTestStatus(%query(pName),ind.TestSuites.GetAt(i).Name)
			set suite(suitestatus)=$G(suite(suitestatus))+1
			if suitestatus'=1 {
				set notPassed=1
			}
		}
	}
	if notPassed=0 {
		&html<<font color="green">#($$$Text("All Suites Passed"))#</font>>
	}
	else {
		set sub=""
		for  {
			set sub=$O(suite(sub))
			quit:sub=""
			set str=$$$Text("Test Suite")
			if suite(sub)>1 {
				set str=$$$Text("Test Suites")	
			}	
			if sub=0 {
				set color="red",status=$$$Text("failed")
			}
			if sub=2 {
				set color="blue",status=$$$Text("skipped")
			}
			if sub=1 {
				set color="green",status=$$$Text("passed")
			}
			&html<<font color="#(color)#">#(..EscapeHTML(str))# #(..EscapeHTML(status))#</font>>
		}
	}
	quit $$$OK
}

Method delCell(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	&html<<input type="button" value="Delete" onclick="zenPage.deleteInstance('#($zconvert(%query(pName),"O","JS"))#')">>
	quit $$$OK
}

ClientMethod deleteInstance(id) [ Language = javascript ]
{
	if (confirm('Deleting Index '+id))
	{
		var go=zenPage.DelInst(id);
		self.document.location.reload();
	}
}

ClassMethod DelInst(id As %Integer) As %Status [ ZenMethod ]
{
	quit ##class(%UnitTest.Result.TestInstance).%DeleteId(id)
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("UnitTest Portal Home")
}

}
