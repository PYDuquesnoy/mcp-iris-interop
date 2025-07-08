/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %UnitTest.Portal.TestMethod Extends %UnitTest.Portal.standardPage [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

Property RealSuite As %String [ Calculated ];

Property RealTestCase As %String [ Calculated ];

Property RealTestMethod As %String [ Calculated ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup width="100%" groupClass="headerTable">
<vgroup width="20%" >
<label id="machinelabel" align="right" value="Machine: "/>
<label id="configlabel" align="right" value="Configuration: "/>
<label id="namespacelabel" align="right" value="Namespace: "/>
<label id="versionlabel" align="right" value="Version: "/>
<label id="tslabel" align="right" value="Time: "/>
</vgroup>
<vgroup width="5%" />
<vgroup width="75%">
<label align="left" id="machine"/>
<label align="left" id="config"/>
<label align="left" id="namespace"/>
<label align="left" id="version"/>
<label align="left" id="ts"/>
</vgroup>
</hgroup>
<hgroup>
<spacer height="3px"  width="100%"/>
</hgroup>
<hgroup  groupClass="headerTable" width="100%">
<vgroup width="20%">
<label id="indexid" align="right" value="LogIndex:" />
<label id="testsuite" align="right" value="TestSuite:" />
<label id="testcase" align="right" value="TestCase:" />
<label id="testmethod" align="right" value="TestMethod:" />
</vgroup>
<vgroup width="5%" />
<vgroup width="75%">
<link align="left" id="myindex" />
<link align="left" id="testsuiteid" />
<link align="left" id="testcaseid" />
<link align="left" id="testmethodid" />
</vgroup>
</hgroup>
<hgroup>
<spacer width="100%"/>
</hgroup>
<hgroup>
<tableNavigatorBar tablePaneId="indices" showPageSize="true" />
</hgroup>
<hgroup>
<tablePane showZebra="true" id="indices" useSnapshot="true" pageSize="100" maxRows="0" sql="Select ID,Counter,Action,Status,Description,Location from %UnitTest_Result.TestAssert where TestMethod=?">
	<parameter id="param1"/>
	<condition colName="Status" predicate="EQ" value="passed" cellStyle="color:green;"/>
    <condition colName="Status" predicate="EQ" value="skipped" cellStyle="color:blue;"/>
    <condition colName="Status" predicate="EQ" value="failed" cellStyle="color:red;"/>          
	<condition colName="ErrorDescription" predicate="CONTAINS" value="skipped" cellStyle="color:blue;"/>
	<column colName="ID" hidden="true"/>
	<column colName="Counter" />
	<column colName="Action" />
	<column colName="Status" style="text-align:left;"/>
	<column colName="Description" style="text-align:left;" />
	<column colName="Location" style="text-align:left;" />
</tablePane>
</hgroup>
</pane>
}

Method BuildTestInstance() As %Status
{
	set id=$P(..IndexId,"||",1)
	set suite=..RealSuite
	set case=..RealTestCase
	set method=..RealTestMethod
	set comp=%page.%GetComponentById("testsuiteid")
	set comp.caption=suite
	set comp.href="%25UnitTest.Portal.TestSuite.cls?Index="_id_"||"_..RealSuite
	set comp=%page.%GetComponentById("testcaseid")
	set comp.caption=case
	set comp.href="%25UnitTest.Portal.TestCase.cls?Index="_id_"||"_..RealSuite_"||"_..RealTestCase
	set comp=%page.%GetComponentById("testmethodid")
	set comp.caption=method
	set comp.href="%25UnitTest.Portal.TestMethod.cls?Index="_..IndexId
	set unit=##class(%UnitTest.Result.TestInstance).%OpenId(id)
	if $IsObject(unit) {
		set comp=%page.%GetComponentById("myindex")
		set comp.caption=id
		set comp.href="%25UnitTest.Portal.Indices.cls?Index="_id
		set comp=%page.%GetComponentById("machine")
		set comp.value=unit.MachineName
		set comp=%page.%GetComponentById("config")
		set comp.value=unit.ConfigurationName
		set comp=%page.%GetComponentById("version")
		set comp.value=unit.Version
		set comp=%page.%GetComponentById("namespace")
		set comp.value=unit.Namespace
		set comp=%page.%GetComponentById("ts")
		set comp.value=unit.DateTime
		
	}
	quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("UnitTest TestMethod")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("UnitTest TestMethod")
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	set %page.%GetComponentById("param1").value=..IndexId
	#; register visit
	Set tSC = ..%Register()
	If $$$ISERR(tSC) Quit tSC
	
	#; The BuildMenu may be called from subclasses, if %OnAfterCreatePage is overriden.
	Set tSC = ..BuildMenu()
	set tSC = ..BuildTestInstance()
	Quit tSC
}

Method RealSuiteGet() As %Status
{
	quit $P(..IndexId,"||",2)
}

Method RealTestCaseGet() As %Status
{
	quit $P(..IndexId,"||",3)
}

Method RealTestMethodGet() As %Status
{
	quit $P(..IndexId,"||",4)
}

}
