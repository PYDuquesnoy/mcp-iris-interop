/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Audit.SelectiveWizard Extends %ZEN.Dialog.standardDialog [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

///  Displayed name of this page.
Parameter PAGENAME = "Selective SQL Auditing Wizard";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.SelectiveWizard.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Configure System Events";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Audit.SystemEvents.cls";

Parameter EMSSERVICE = "Security";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Parameter APPLYBUTTON = 1;

Property ALREADYON As %String(ZENURL = "ALREADYON");

XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
	<label id="promptTop" value="Which SQL Statement Types and Sources Would You Like to Audit?" containerStyle="padding-top:8px; padding-bottom:4px;"/>
	<hgroup>
		<vgroup>
			<label label="" containerStyle="height:30px;"/>
			<label label="All" containerStyle="height:30px;"/>
			<label label="Query" containerStyle="height:30px;"/>
			<label label="DDL" containerStyle="height:30px;"/>
			<label label="DML" containerStyle="height:30px;"/>
			<label label="Utility" containerStyle="height:30px;"/>
		</vgroup>
		<vgroup>
			<label label="" containerStyle="height:30px;"/>
			<hgroup id="All" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all SQL statement types and sources." onclick="for (var idt of ['DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility','EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility','XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all SQL statement types and sources." onclick="for (var idt of ['DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility','EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility','XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<hgroup id="Query" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all query statements." onclick="for (var idt of ['DynamicStatementQuery','EmbeddedStatementQuery','XDBCStatementQuery']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all query statements." onclick="for (var idt of ['DynamicStatementQuery','EmbeddedStatementQuery','XDBCStatementQuery']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<hgroup id="DDL" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all DDL statements." onclick="for (var idt of ['DynamicStatementDDL','EmbeddedStatementDDL','XDBCStatementDDL']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all DDL statements." onclick="for (var idt of ['DynamicStatementDDL','EmbeddedStatementDDL','XDBCStatementDDL']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<hgroup id="DML" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all DML statements." onclick="for (var idt of ['DynamicStatementDML','EmbeddedStatementDML','XDBCStatementDML']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all DML statements." onclick="for (var idt of ['DynamicStatementDML','EmbeddedStatementDML','XDBCStatementDML']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<hgroup id="Utility" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all Utility statements." onclick="for (var idt of ['DynamicStatementUtility','EmbeddedStatementUtility','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all Utility statements." onclick="for (var idt of ['DynamicStatementUtility','EmbeddedStatementUtility','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<!-- <checkbox id="All" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;" onchange="for (var idt of ['Query','DDL','DML','Utility','Dynamic','DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility','Embedded','EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility','XDBC','XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('All').getValue()); }; "/> -->			
			<!-- <checkbox id="Query" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;" onchange="for (var idt of ['DynamicStatementQuery','EmbeddedStatementQuery','XDBCStatementQuery']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('Query').getValue()); };"/> -->
			<!-- <checkbox id="DDL" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;" onchange="for (var idt of ['DynamicStatementDDL','EmbeddedStatementDDL','XDBCStatementDDL']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('DDL').getValue()); };"/> -->
			<!-- <checkbox id="DML" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;" onchange="for (var idt of ['DynamicStatementDML','EmbeddedStatementDML','XDBCStatementDML']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('DML').getValue()); };"/> -->
			<!-- <checkbox id="Utility" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999;" onchange="for (var idt of ['DynamicStatementUtility','EmbeddedStatementUtility','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('Utility').getValue()); };"/> -->
		</vgroup>
		<vgroup>
			<label label="Dynamic" containerStyle="height:30px;"/>
			<hgroup id="Dynamic" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all Dynamic statements." onclick="for (var idt of ['DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all Dynamic statements." onclick="for (var idt of ['DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<!-- <checkbox id="Dynamic" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999; border-left:1px solid #999;" onchange="for (var idt of ['DynamicStatementQuery','DynamicStatementDDL','DynamicStatementDML','DynamicStatementUtility']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('Dynamic').getValue()); };"/> -->
			<checkbox id="DynamicStatementQuery" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="DynamicStatementDDL" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="DynamicStatementDML" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="DynamicStatementUtility" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
		</vgroup>
		<vgroup>
			<label label="Embedded" containerStyle="height:30px;"/>
			<hgroup id="Embedded" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all Embedded statements." onclick="for (var idt of ['EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all Embedded statements." onclick="for (var idt of ['EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<!-- <checkbox id="Embedded" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999; border-left:1px solid #999;" onchange="for (var idt of ['EmbeddedStatementQuery','EmbeddedStatementDDL','EmbeddedStatementDML','EmbeddedStatementUtility']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('Embedded').getValue()); };"/> -->
			<checkbox id="EmbeddedStatementQuery" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="EmbeddedStatementDDL" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="EmbeddedStatementDML" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
			<checkbox id="EmbeddedStatementUtility" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999;"/>
		</vgroup>
		<vgroup>
			<label label="XDBC" containerStyle="height:30px;"/>
			<hgroup id="XDBC" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999; border-right:1px solid #999;">
				<link href="#" caption="On" containerStyle="font-size:14px;" title="Turn on auditing for all XDBC statements." onclick="for (var idt of ['XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(1); }; return false;"/>
				<label label=" " containerStyle="font-size:20px;"></label>
				<label label="/" containerStyle="font-size:20px;"></label>
				<link href="#" caption="Off" containerStyle="font-size:14px;" title="Turn off auditing for all XDBC statements." onclick="for (var idt of ['XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(0); }; return false;"/>
			</hgroup>
			<!-- <checkbox id="XDBC" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-bottom:1px solid #999; border-left:1px solid #999; border-right:1px solid #999;" onchange="for (var idt of ['XDBCStatementQuery','XDBCStatementDDL','XDBCStatementDML','XDBCStatementUtility']) { zenPage.getComponentById(idt).setValue(zenPage.getComponentById('XDBC').getValue()); };"/> -->
			<checkbox id="XDBCStatementQuery" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999; border-right:1px solid #999;"/>
			<checkbox id="XDBCStatementDDL" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999; border-right:1px solid #999;"/>
			<checkbox id="XDBCStatementDML" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-bottom:1px solid #999; border-right:1px solid #999;"/>
			<checkbox id="XDBCStatementUtility" value="0" controlClass="normal" containerStyle="height:30px; width:80px; border-left:1px solid #999; border-right:1px solid #999; border-bottom:1px solid #999;"/>
		</vgroup>
	</hgroup>
</pane>
}

Method %OnGetTitle() As %String
{
  Quit $$$TextHTML("Selective SQL Auditing Wizard")
}

Method %OnGetSubtitle() As %String
{
  Quit $$$TextHTML("")
}

ClientMethod onloadHandler(load) [ Language = javascript ]
{
	if (this.ALREADYON !== "") {
		for (var key of this.ALREADYON.split(",")) {
			zenPage.getComponentById(key).setValue(1);
		}
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
  var results = {
	DynamicStatementQuery: this.getComponentById('DynamicStatementQuery').getValue(),
	DynamicStatementDDL: this.getComponentById('DynamicStatementDDL').getValue(),
	DynamicStatementDML: this.getComponentById('DynamicStatementDML').getValue(),
	DynamicStatementUtility: this.getComponentById('DynamicStatementUtility').getValue(),
	EmbeddedStatementQuery: this.getComponentById('EmbeddedStatementQuery').getValue(),
	EmbeddedStatementDDL: this.getComponentById('EmbeddedStatementDDL').getValue(),
	EmbeddedStatementDML: this.getComponentById('EmbeddedStatementDML').getValue(),
	EmbeddedStatementUtility: this.getComponentById('EmbeddedStatementUtility').getValue(),
	XDBCStatementQuery: this.getComponentById('XDBCStatementQuery').getValue(),
	XDBCStatementDDL: this.getComponentById('XDBCStatementDDL').getValue(),
	XDBCStatementDML: this.getComponentById('XDBCStatementDML').getValue(),
	XDBCStatementUtility: this.getComponentById('XDBCStatementUtility').getValue()
  };
  return results;
}

}
