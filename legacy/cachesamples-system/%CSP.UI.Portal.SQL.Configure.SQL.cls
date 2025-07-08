/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// General SQL Settings
Class %CSP.UI.Portal.SQL.Configure.SQL Extends %CSP.UI.Portal.Template [ System = 4 ]
{

Parameter AUTONS = 0;

/// Displayed name of this page.
Parameter PAGENAME = "General SQL Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.SQL.Configure.SQL.zen";

Parameter HELPADDRESS = "System,Configuration,General SQL Settings";

Parameter EMSSERVICE = "Config";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.sectionCaption {
	color: #546075;
	font-size: 0.9em;
	font-weight: bold;
}
.shellNote {
	color: #666666;
}

</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground { fill:white; stroke:white; }	
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white; stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":SQL:SQL Shell"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<vgroup id="page_1" hidden="false" cellStyle="padding:2px 0px 6px 2px" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<checkbox id="Comment" label="Retains SQL statement as comments in .INT code" onchange="zenPage.doModified();" hidden="true"/>
<checkbox id="SaveMAC" label="Retain cached query source" onchange="zenPage.doModified();"/>
<select id="TimePrecision" label="Default time precision for GETDATE(), CURRENT_TIME, and CURRENT_TIMESTAMP" 
valueList="0,1,2,3,4,5,6,7,8,9" showEmpty="false"
onchange="zenPage.doModified();"/>
<text id="LockThreshold" label="Lock escalation threshold" size="8" onchange="zenPage.doModified();"/>
<text id="TODATEDefaultFormat" label="TO_DATE default format" size="20" onchange="zenPage.doModified();" title="Define the default format for the SQL TO_DATE() function. The default for this setting is 'DD MON YYYY'."/>

<spacer height="10"/>

<label label="Settings that will trigger all cached queries to be purged in all namespaces:" 
labelClass="sectionCaption" 
containerStyle="padding-top:5px;padding-bottom:5px;"
/>
<text id="ODBCVarcharMaxlen" label="Default length for VARCHAR" size="6" onchange="zenPage.doModified();" title="Define the default length to use for VARCHAR values that do not specify a length.  The default for this setting is 4096."/>
<text id="DefaultSchema" label="Default schema" size="30" onchange="zenPage.doModified();"/>
<checkbox id="AutoParallel" label="Execute queries in a single process" onchange="zenPage.doModified();"
title="If enabled, queries will not attempt to automatically divide their workload among multiple worker processes"/>

<!-- from the DDL tab -->
<checkbox id="IdKey" label="Define primary key as ID key for tables created via DDL" onchange="zenPage.doModified();"/>
<checkbox id="IgnoreRedundant" label="Ignore redundant DDL statements" onchange="zenPage.doModified();"
 title="If enabled, DDL statements attempting to create structures that already exist or remove structures that do not exist will report success."
/>

<!-- from the Optimization tab -->
<checkbox id="FastDistinct" label="GROUP BY and DISTINCT queries must produce original values" onchange="zenPage.doModified();"
title="If enabled, reduces the efficiency of some index-satisfiable DISTINCT and GROUP BY queries in order to retrieve actual field values to represent the groups."/>

<checkbox id="AdaptiveMode" label="Turn off Adaptive Mode to disable run time plan choice, automatic tuning, and Frozen/Upgrade query plans" onchange="zenPage.doModified();"
title="If Adaptive Mode is enabled, query plans will be optimized for runtime parameters, untuned tables will be tuned when queried, Query Plan will not be marked as Frozen/Upgrade in order to take advantage of optimizer improvements, etc."/>

<checkbox id="ParameterSampling" label="Turn on parameter sampling to sample the parameter value for query execution" onchange="zenPage.doModified();"
title="If Parameter Sampling is enabled, a random sample of actual parameter values used for query execution will be saved to the Statement Index."/>

<spacer height="10"/>

<label label="Settings that will take effect only on new processes after changes are saved:"
labelClass="sectionCaption" 
containerStyle="padding-top:5px;padding-bottom:5px;"
/>
<text id="LockTimeout" label="Lock timeout (seconds)" size="8" onchange="zenPage.doModified();"/>
<text id="TCPKeepAlive" label="TCP keepalive for client connections (seconds)" size="8" onchange="zenPage.doModified();"/>
<text id="ClientMaxIdleTime" label="Client maximum idle time (seconds)" size="8" onchange="zenPage.doModified();"/>
</vgroup>

<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:30px;padding-top:20px;" labelPosition="left">
<vgroup showLabel="false">
<label label="Default settings for entering SQL Shell. Once in the SQL Shell, you may change settings for the session, or save the user/namespace specific settings using the 'set save' command."
 labelClass="shellNote" containerStyle="padding:10px 0px 20px 0px;"
 />

<vgroup id="sqlshell" label="Changes to the following settings will be applied to the SQL Shell system-wide:"
 labelClass="sectionCaption" cellStyle="padding:2px 0px 6px 2px" enclosingStyle="padding:10px;" labelPosition="left">
<select id="SelectMode" label="Select mode" valueList="Logical,Display,ODBC" showEmpty="false" onchange="zenPage.doModified();"
title="The default is 'Logical'."/>
<select id="Dialect" label="SQL dialect" valueList="IRIS,MSSQL,Sybase" showEmpty="false" onchange="zenPage.doModified();"
title="The default is IRIS.  The dialect setting determines which dialect mode is used when preparing a statement."/>
<text id="Path" label="Schema search path" size="60" onchange="zenPage.doModified();" 
title="Used by the Prepare of the statement, you may enter a comma list of schema name that defines the current schema search path.  The default schema will be used if this field is left empty."/>
<select id="ColAlign" label="Result column alignment" valueList="Delimiter,Header,Data" showEmpty="false" onchange="zenPage.doModified();zenPage.setColAlign();"
hint=""
/>
<text id="CommandPrefix" label="Command prefix" size="20" onchange="zenPage.doModified();" 
title="Shell commands are entered in the first column and do not often conflict with executable statements.  In some cases, such as 'set', a command and an SQL statement can be ambiguous. This occurs most often in complex multiline statements such as 'CREATE PROCEDURE'. To eliminate confusion, the SQL Shell supports a command prefix that can be set to any value. The command prefix allows the user to specify that all commands begin with a special character or character sequence."/>
<select id="DisplayMode" label="Result output display mode" valueList="CURRENTDEVICE,XML,HTML,PDF,TXT,CSV" displayList="Current Device,XML,HTML,PDF,TXT,CSV" showEmpty="false" onchange="zenPage.doModified();zenPage.setDisplayOptions();"
title="Set the display mode.  The default is current device.  When Display mode is set to 'Current Device', statement results are displayed on the current device.  When XML, HTML, PDF, TXT, or CSV are specified, the statement results are written to a file using a ZEN Report that is generated from the statement metadata."/>

<vgroup id="DisplayModeOptions" enclosingStyle="padding:10px;"
labelPosition="left">
<text id="DisplayFile" label="Display file" size="40" onchange="zenPage.doModified();" 
hint="File name to write the output to. If left empty then a random file name will be generated for each statement execution."
title="Set the name of the file to be used for displaying the results of executing SQL statements when Display Mode is not 'Current Device'.  A messages file may be produced. The name of the file containing messages is either the display file concatenated with 'Messages', or it is a random file name if this field is left empty."/>
<text id="DisplayPath" label="Display path" size="80" onchange="zenPage.doModified();" 
hint="Directory path for the location of the display file. If left empty, the display file will be placed in the IRIS system temporary directory."
title="Set the directory path where files used to save statement results will be placed. "/>
<text id="DisplayTranslateTable" label="Display file translate table" size="40" onchange="zenPage.doModified();" 
hint="The translate table to use when sending output to file."
title="Set the translate table used for Display File when writing output in CSV and TXT formats.  For example, 'UTF8'.  Values are case sensitive."/>
</vgroup>
<select id="ExecuteMode" label="Execute mode" valueList="Immediate,Deferred" showEmpty="false" onchange="zenPage.doModified();zenPage.setExecuteMode();"
hint=""
/>
<select id="EchoMode" label="Echo mode" valueList="On,Off" displayList="ON,OFF" showEmpty="false" onchange="zenPage.doModified();"
title="The default is 'ON'.  If 'ON', statements and results are echoed to the current device. This setting does not impact logging."/>
<select id="MessagesMode" label="Messages mode" valueList="On,Off" displayList="ON,OFF" showEmpty="false" onchange="zenPage.doModified();"
title="The default is 'ON'.  If 'OFF' then results are displayed without any additional information and prepare and execute times are not displayed."/>
<text id="EscapeCondition" label="IF condition to allow execution of ObjectScript commands" size="50" onchange="zenPage.doModified();" 
hint="This argument to an IF condition must evaluate to TRUE in order for ObjectScript commands to be executed from within the SQL shell.  The default is '1'."
title="The process running the SQL Shell must also be in programmer mode, not application mode.  If the argument to the IF condition encounters an error, ObjectScript commands will not be allowed to be executed."/>
</vgroup>
</vgroup>
</vgroup>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	this.setDisplayOptions();
	this.setExecuteMode();
	this.setColAlign();
}

ClientMethod setDisplayOptions() [ Language = javascript ]
{
	var value = zen("DisplayMode").getValue();
	var text = '';
	var displayMode = zen('DisplayMode').getValue();
	var isCurrent = (displayMode == 'CURRENTDEVICE') ? true : false;
	zen('DisplayModeOptions').setProperty('disabled',isCurrent);
	if (!isCurrent) {
		zen('DisplayPath').setProperty('disabled',isCurrent);
		zen('DisplayFile').setProperty('disabled',isCurrent);
		if ((displayMode == 'CSV') || (displayMode == 'TXT')) {
			zen('DisplayTranslateTable').setProperty('disabled',false);
		} else {
			zen('DisplayTranslateTable').setProperty('disabled',true);	
		}
	}
}

ClientMethod setExecuteMode() [ Language = javascript ]
{
	var value = zen("ExecuteMode").getValue();
	var text = '';
	switch (value) {
		case 'Immediate':
			text = $$$Text("SQL statements are executed immediately.");
			break;
		case 'Deferred':
			text = $$$Text("The current statement is executed after entering a 'go' command.");
			break;
	}
	zen("ExecuteMode").setProperty('hint',text);
}

ClientMethod setColAlign() [ Language = javascript ]
{
	var value = zen("ColAlign").getValue();
	var text = '';
	switch (value) {
		case 'Delimiter':
			text = $$$Text("The SQL Resultset header/data columns will be aligned based on the standard delimiter (tab).");
			break;
		case 'Header':
			text = $$$Text("The SQL Resultset header/data columns will be aligned based on the length of the column header and the standard delimiter (tab).");
			break;
		case 'Data':
			text = $$$Text("The SQL Resultset header/data columns will be aligned based on the precision/length of the column data property and the standard delimiter (tab).");
			break;
	}
	zen("ColAlign").setProperty('hint',text);
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	var option;
	for ( var i=0; i<2; i++ ) {
		option = i + 1;
		if ( i == index ) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
}

/// User clicked Save. Save and return to parent page.
ClientMethod doSave() [ Language = javascript ]
{
	// if user has not changed anything, just quit.
	if (!this.pageModified) {
		this.showMsg($$$Text("Nothing changed."),0);
		return;	
	}
	var proxy = new zenProxy();
	proxy.IdKey = zen("IdKey").getValue() ? 1 : 0;
	proxy.IgnoreRedundant = zen("IgnoreRedundant").getValue() ? 1 : 0;
	proxy.LockTimeout = zen("LockTimeout").getValue();
	proxy.LockThreshold = zen("LockThreshold").getValue();
	proxy.TODATEDefaultFormat = zen("TODATEDefaultFormat").getValue();
	proxy.ODBCVarcharMaxlen = zen("ODBCVarcharMaxlen").getValue();
	proxy.Comment = zen("Comment").getValue();
	proxy.FastDistinct = zen("FastDistinct").getValue() ? 1 : 0;
	proxy.AdaptiveMode = zen("AdaptiveMode").getValue() ? 1 : 0;
	proxy.ParameterSampling = zen("ParameterSampling").getValue() ? 1 : 0;
	proxy.ClientMaxIdleTime = zen("ClientMaxIdleTime").getValue();
	proxy.SaveMAC = zen("SaveMAC").getValue() ? 1 : 0;
	proxy.DefaultSchema = zen("DefaultSchema").getValue();
	proxy.AutoParallel = zen("AutoParallel").getValue() ? 1 : 0;
	proxy.TimePrecision = zen("TimePrecision").getValue();
	proxy.TCPKeepAlive = zen("TCPKeepAlive").getValue();
	proxy.IsEMSReadOnly = this.IsEMSReadOnly;
	proxy.SelectMode = zen("SelectMode").getValue();
	proxy.Dialect = zen("Dialect").getValue();
	proxy.Path = zen("Path").getValue();
	proxy.ColAlign = zen("ColAlign").getValue();
	proxy.CommandPrefix = zen("CommandPrefix").getValue();
	proxy.DisplayMode = zen("DisplayMode").getValue();
	proxy.DisplayPath = zen("DisplayPath").getValue();
	proxy.DisplayFile = zen("DisplayFile").getValue();
	proxy.DisplayTranslateTable = zen("DisplayTranslateTable").getValue();
	proxy.EchoMode = zen("EchoMode").getValue();
	proxy.ExecuteMode = zen("ExecuteMode").getValue();
	proxy.MessagesMode = zen("MessagesMode").getValue();
	proxy.EscapeCondition = zen("EscapeCondition").getValue();
	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
		// find size of window
		var winWidth = zenGetWindowWidth();	
		// set the svg and tabs the right size
		zen("svgTabArea").setProperty("width",winWidth-50);
		zen("tabBar").setProperty("width",winWidth-50);
	
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Save file into global.
ClassMethod SaveData(proxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Quit ##class(%CSP.UI.Portal.SQL.Utils).SaveConfigSQLProperties(proxy)
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..lblTitle = "" //$$$Text("Use the form below to view or edit system-wide settings for SQL, DDL, and xDBC connectivity:")
	
	Set tSC = ##class(%CSP.UI.Portal.SQL.Utils).GetConfigSQLProperties(.Properties)
	If $$$ISERR(tSC) Quit tSC
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	For Number = "30","201","307","315","324","333","311" {
		If Properties("DDLNo"_Number) = 1 {
			Set ..%GetComponentById("IgnoreRedundant").value = 1 
			Quit
		}
	}
	Quit 1
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
