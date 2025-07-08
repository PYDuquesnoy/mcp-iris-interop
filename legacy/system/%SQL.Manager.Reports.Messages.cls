/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Manager.Reports.Messages Extends %ZEN.Report.reportPage [ Not ProcedureBlock, System = 4 ]
{

Parameter SQLCACHE As STRING = 0;

Parameter RESOURCE = "%Development:USE";

Property ResultSet As %SQL.IResultSet;

Method GetResult(ByRef pSc As %Status = {$$$OK}, ByRef pParameters) As %SQL.IResultSet [ CodeMode = expression ]
{
..ResultSet
}

XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition" name="resultset" OnCreateResultSet="GetResult">
<group name="ResultGroup">
<attribute field="Message" name="Message"/>
</group>
</report>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" title="Messages" name="resultset">
<document>
<class name="table.dynamic">
<att name="border" value ="1px solid gray"/>
</class>
<class name="td.dynamic">
<att name="border" value="none"/>
<att name="text-align" value="left"/>
<att name="padding-left" value="15px"/>
<att name="font-weight" value="normal"/>
<att name="font-size" value="10pt"/>
<att name="vertical-align" value="top"/>
<att name="line-height" value="175%"/>
</class>
</document>
<body>
<table orient="col" group="ResultGroup" class="dynamic">
<item field="@Message" insert-zero-width-spaces="true">
</item>
</table>
</body>
</report>
}

}
