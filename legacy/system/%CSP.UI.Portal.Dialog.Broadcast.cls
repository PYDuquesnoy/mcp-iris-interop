/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Broadcast message to principal devices of processes.
Class %CSP.UI.Portal.Dialog.Broadcast Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.Broadcast.zen";

Parameter RESOURCE = "%Admin_Operate:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Broadcast Message";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnFinish" controlClass="commandButton" caption="Broadcast" onclick="zenPage.doBroadcast();"/>
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding: 4px;">
<spacer height="2"/>
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<text id="txtMsg" label="Enter a message you want to send:" size="80"/>
<tablePane id="table" label="Select devices that can receive broadcast:"
queryClass="SYS.Process"
queryName="CONTROLPANEL"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="false"
valueColumn="Pid"
useSnapshot="true"
>
<column colName="Job#" hidden="true"/>
<column colName="Pid" hidden="true"/>
<column colName="DisplayPID" header="Process ID"/>
<column colName="Username" header="User" title="User name."/>
<column colName="Device" header="Device" title="Name of device currently in use by this process."/>
<column colName="Nspace" header="Namespace" title="Current namespace used by this process."/>
<column colName="Routine" header="Routine" hidden="true"/>
<column colName="Commands" header="Commands" hidden="true"/>
<column colName="Globals" header="Globals" hidden="true"/>
<column colName="State" header="State" hidden="true"/>
<column colName="Client Name" header="Client Name" hidden="true"/>
<column colName="EXE Name" header="Client EXE" hidden="true"/>
<column colName="IP Address" header="Client IP" hidden="true"/>
<column colName="Can Be Examined" hidden="true"/>
<column colName="Can Be Suspended" hidden="true"/>
<column colName="Can Be Terminated" hidden="true"/>
<column colName="Can Receive Broadcast" header="Can Receive Broadcast" style="text-align:center;"/>
<column colName="PrvGblBlkCnt" hidden="true"/>
<condition colName="Can Be Examined" predicate="EQ" value="0" rowStyle="background: #c4d6d6;" cellStyle="disabled" targetCol="DisplayPID"/> 
<condition colName="Can Receive Broadcast" predicate="EQ" value="0" targetCol="checkbox" cellStyle="disabled"/> 
</tablePane>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Broadcast Message")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("txtMsg").focus();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; Use the same sort column and sort order as the processes page so it's easier for user to compare the two
	Set TableState = $G($$$IRISTempMgt($Username,"Operation Processes","TableState"))
	If TableState'="" {
		Set ..%GetComponentById("table").currColumn = $lg(TableState,1)
		Set ..%GetComponentById("table").sortOrder = $lg(TableState,2)
	}	
	Quit $$$OK
}

/// Send message
ClassMethod BroadcastMsg(Msg As %String, selectedRows As %String) As %String [ ZenMethod ]
{
	Set tmsg = 1
	Set TotalSelected = 0
	Set tTotal = $L(selectedRows,",")
	For tItem = 1:1:tTotal {
		Set Pid = $P(selectedRows,",",tItem)
		If Pid '= "" {
			Job PID^BROADCAS(Pid,Msg)
			Set TotalSelected = TotalSelected + 1	
		}
	}
	If TotalSelected = 0 Quit $$$Text("Please select one or more processes")
	Quit tmsg
}

ClientMethod doBroadcast() [ Language = javascript ]
{
	try {
		var msg = zen("txtMsg").getValue();
		msg = zenTrim(msg);
		if (msg == "") {
			alert($$$Text("Message is empty!"));
			return false;	
		}
		var table = zen("table");
		var selectedRows = table.getProperty("selectedRows");
		var ok = this.BroadcastMsg(msg,selectedRows);
		if (ok != 1) {
			alert(ok);
			return;	
		} else {
			zen('btnCancel').setProperty('caption',$$$Text("Done"));
			zen('btnFinish').setProperty('disabled',true);
			zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$TextHTML("Send a message to the principal devices.")_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit 1
}

}
