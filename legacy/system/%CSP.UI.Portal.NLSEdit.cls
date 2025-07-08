/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// Zen page for System Management Portal - NLS Local Properties
Class %CSP.UI.Portal.NLSEdit Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "NLS Edit";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.NLSEdit.zen";

Parameter HELPADDRESS = "Home,Configuration,Locale Definitions";

Parameter EMSSERVICE = "Config";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.NLS.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Property msgIOTableName As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a table name.")} ];

Property msgIOTableOutput As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a value for Output.")} ];

Property msgIOTableInput As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a value for Input.")} ];

Property msgConfirmIOTable As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to remove this table from this locale?")} ];

Property msgPatternTables As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select at least one Pattern match table.")} ];

Property msgIdenTables As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select at least one Identifier table.")} ];

Property msgCollationTables As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select at least one Collation table.")} ];

Property msgXYTables As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select at least one $X/$Y action table.")} ];

Property msgSaved As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Change has been saved.")} ];

Property CharacterSet As %ZEN.Datatype.string;

Property cmbLocale As %ZEN.Datatype.string(ZENURL = "cmbLocale");

XData Style
{
<style type="text/css">
.caption {
	padding-right:5px;
}
.tc {
	font-weight: bold;
}
.brownnote {
	font-size: 0.8em;
	color: #000000;
}
.fieldSet {
	background: white;
	padding: 4px;
}
.fieldSetLabel {
	color: #333695;
	font-weight:bold;
	padding-bottom:5px;
}
.fieldStyle {
	border-bottom: 1px #333695 solid;
	color: #333695;
	font-weight:bold;
	margin-bottom:1em;
	margin-top:1em;
	padding:2px;
	width: 30em;
}
table.PropTable	{ 
	font-size: 0.8em;
	margin-left: 20px; margin-right: 20px;
}

TABLE.DetailTable	{ 
	font-size: 0.8em;
	margin-left: 20px; margin-right: 20px;
	border: 1px solid black;
	background: white;
}
TABLE.DetailTable TH { 
	font-weight: bold;		
	background:#333695; color: white;
	text-align: center;
	padding:4px;
}
TABLE.DetailTable TR.OddRow { background: white; }
TABLE.DetailTable TR.EvenRow { background: #eeeeee; }
a.link {
	color: #333695;
}
a.link:visited {
	color: #333695;
}	
a.link:hover {
	color: #00A09A;
}
a.link:active {
	color: #00A09A;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding-top:1px">
<hgroup valign="top">
<link id="idSelectLocal" href="#(%page.ParentURL)#" caption="Select a Different Locale" title="Click to select a different locale" containerStyle="padding:1em;" valign="top"/>

<form id="fld" layout="vertical" valign="top" containerStyle="padding:1em;">
<html id="lblLocale" OnDrawContent="DrawLocale"/>
<button id="btnReturn" caption="Return" onclick="zenPage.selectMenu(0);" hidden="true"/> 
<label id="lblSuccess" label="Changes have been saved." labelClass="brownnote" hidden="true"/>
<spacer height="2"/>
<html id="htmlDisplay" OnDrawContent="DrawProperties"/>

<fieldSet id="menu1" labelPosition="left" label="Basic Properties" labelClass="fieldSetLabel" cellStyle="padding-bottom:2px;" hidden="true">
<text id="Description" label="Description" size="80"/>
<label id="DescriptionHelp" labelClass="helpText"/>
<spacer height="1"/>
<text id="Currency" label="Currency sign" size="10"/>
<label id="CurrencyHelp" label="The currency sign used in this geographical locale. Examples: $, R$" labelClass="helpText"/>
<html><hr/></html>
<button caption="Save" onclick="zenPage.save(1);"/>
</fieldSet>

<fieldSet id="menu2" labelPosition="left" label="Date, Time and Number Formats" labelClass="fieldSetLabel" hidden="true">
<combobox id="DateFormat" label="$ZDate format">
<option value="0" text="DD Mmm [YY]YY"/>
<option value="1" text="MM/DD/[YY]"/>
<option value="2" text="DD Mmm [YY]YY"/>
<option value="3" text="YYYY-MM-DD"/>
<option value="4" text="DD/MM/[YY]YY"/>
<option value="5" text="Mmm D, YYYY"/>
<option value="6" text="Mmm D YYYY"/>
<option value="7" text="Mmm DD [YY]YY"/>
<option value="8" text="YYYYMMDD"/>
<option value="9" text="Mmmmmm D, YYYY"/>
<option value="10" text="W"/>
<option value="11" text="Www"/>
<option value="12" text="Wwwwww"/>
<option value="13" text="[D]D/[M]M/YYYY"/>
<option value="14" text="nnn"/>
</combobox>
<text id="DateSeparator" label="Date separator" size="2"/>
<spacer height="1"/>
<combobox id="TimeFormat" label="Time format">
<option value="1" text="hh:mm:ss"/>
<option value="2" text="hh:mm"/>
<option value="3" text="hh:mm:ss[AM/PM]"/>
<option value="4" text="hh:mm[AM/PM]"/>
</combobox>
<text id="TimeSeparator" label="Time separator" size="2"/>
<text id="TimePrecision" label="Time precision" size="2"/>
<spacer height="1"/>
<text id="MinusSign" label="Minus sign" size="2"/>
<text id="PlusSign" label="Plus sign" size="2"/>
<text id="DecimalSeparator" label="Decimal separator" size="2"/>
<text id="NumericGroupSeparator" label="Numeric group separator" size="2"/>
<text id="NumericGroupSize" label="Numeric group size" size="2"/>

<html><hr/></html>
<button caption="Save" onclick="zenPage.save(2);"/>

</fieldSet>
<fieldSet id="menu3" labelPosition="top" label="Loadable Internal Tables" labelClass="fieldSetLabel" hidden="true">
<label label="* indicates required field" labelStyle="font-size:10px;" labelClass="lblNormal" align="center"/>
<button caption="Save" align="center" onclick="zenPage.save(3);"/>
<hgroup id="g1" label="Pattern match tables *" labelClass="tc" cellVAlign="middle">
<listBox name="lst1" id="lst1" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst1','lstselect1');" listWidth="220px" listHeight="80px" hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL1" caption="&lt;" onclick="zenPage.arrowClick('lstselect1','lst1');"/>
<button id="btnR1" caption="&gt;" onclick="zenPage.arrowClick('lst1','lstselect1');"/>
<spacer width="4"/>
<listBox name="lstselect1" id="lstselect1" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect1','lst1');" listWidth="220px" listHeight="80px" hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g2" label="Identifier tables *" labelClass="tc" cellVAlign="middle">
<listBox name="lst2" id="lst2" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst2','lstselect2');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL2" caption="&lt;" onclick="zenPage.arrowClick('lstselect2','lst2');"/>
<button id="btnR2" caption="&gt;" onclick="zenPage.arrowClick('lst2','lstselect2');"/>
<spacer width="4"/>
<listBox name="lstselect2" id="lstselect2" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect2','lst2');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g3" label="Uppercase tables" labelClass="tc" cellVAlign="middle">
<listBox name="lst3" id="lst3" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst3','lstselect3');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL3" caption="&lt;" onclick="zenPage.arrowClick('lstselect3','lst3');"/>
<button id="btnR3" caption="&gt;" onclick="zenPage.arrowClick('lst3','lstselect3');"/>
<spacer width="4"/>
<listBox name="lstselect3" id="lstselect3" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect3','lst3');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g4" label="Lowercase tables" labelClass="tc" cellVAlign="middle">
<listBox name="lst4" id="lst4" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst4','lstselect4');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL4" caption="&lt;" onclick="zenPage.arrowClick('lstselect4','lst4');"/>
<button id="btnR4" caption="&gt;" onclick="zenPage.arrowClick('lst4','lstselect4');"/>
<spacer width="4"/>
<listBox name="lstselect4" id="lstselect4" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect4','lst4');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g5" label="Titlecase tables" labelClass="tc" cellVAlign="middle">
<listBox name="lst5" id="lst5" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst5','lstselect5');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL5" caption="&lt;" onclick="zenPage.arrowClick('lstselect5','lst5');"/>
<button id="btnR5" caption="&gt;" onclick="zenPage.arrowClick('lst5','lstselect5');"/>
<spacer width="4"/>
<listBox name="lstselect5" id="lstselect5" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect5','lst5');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<hgroup id="g6" label="Accent tables" labelClass="tc" cellVAlign="middle">
<listBox name="lst6" id="lst6" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst6','lstselect6');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL6" caption="&lt;" onclick="zenPage.arrowClick('lstselect6','lst6');"/>
<button id="btnR6" caption="&gt;" onclick="zenPage.arrowClick('lst6','lstselect6');"/>
<spacer width="4"/>
<listBox name="lstselect6" id="lstselect6" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect6','lst6');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g7" label="Collation tables *" labelClass="tc" cellVAlign="middle">
<listBox name="lst7" id="lst7" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst7','lstselect7');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL7" caption="&lt;" onclick="zenPage.arrowClick('lstselect7','lst7');"/>
<button id="btnR7" caption="&gt;" onclick="zenPage.arrowClick('lst7','lstselect7');"/>
<spacer width="4"/>
<listBox name="lstselect7" id="lstselect7" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect7','lst7');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>
<spacer height="1"/>
<hgroup id="g8" label="$X/$Y action tables *" labelClass="tc" cellVAlign="middle">
<listBox name="lst8" id="lst8" label="Available Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst8','lstselect8');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL8" caption="&lt;" onclick="zenPage.arrowClick('lstselect8','lst8');"/>
<button id="btnR8" caption="&gt;" onclick="zenPage.arrowClick('lst8','lstselect8');"/>
<spacer width="4"/>
<listBox name="lstselect8" id="lstselect8" label="Selected Tables" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect8','lst8');" listWidth="220px" listHeight="80px"  hzScroll="false">
</listBox>
</hgroup>

<spacer height="1"/>
<html><hr/></html>
<label label="* indicates required field" labelStyle="font-size:10px;" labelClass="lblNormal" align="center"/>
<button caption="Save" align="center" onclick="zenPage.save(3);"/>

</fieldSet>

<fieldSet id="menu4" labelPosition="top" label="Loadable Input/Output Tables" labelClass="fieldSetLabel" hidden="true">
<listBox id="cmbIOTables" name="cmbIOTables" label="Select a table to edit:" onchange="zenPage.selectIOTables(zenThis);" />
<spacer height="2"/>
<button caption="Add" onclick="zenPage.newIOTable();"/>
<spacer height="2"/>
<form name="frmIOTables" id="frmIOTables" hidden="true" containerStyle="border: black solid 1px; padding:5px;background:#E7E7E7;">
<vgroup labelPosition="left">
<text id="txtIOTable" label="Table:"/>
</vgroup>
<spacer height="1"/>
<hgroup id="idEditIOTable" disabled="false">
<vgroup labelPosition="left">
<label id="lblOutputFrom" label="Output from:"/>
<dataCombo id="cmbOutputTo" label="to:"
 dropdownWidth="400"
 multiColumn="true" 
 displayColumns="3,4"
 choiceColumn="3"
 valueColumn="3"
 searchKeyLen="3" 
 queryClass="Config.NLS.Tables"
 queryName="List"
 OnExecuteResultSet="ExecuteOutputTo"
>
<parameter value="XLT"/>
<parameter value="Unicode"/>
<parameter value="*"/>
</dataCombo>
<spacer height="2"/>
<dataCombo id="cmbInputFrom" label="Input from:"
 dropdownWidth="400"
 multiColumn="true" 
 displayColumns="2,4"
 choiceColumn="2"
 valueColumn="2"
 searchKeyLen="3" 
 queryClass="Config.NLS.Tables"
 queryName="List"
 OnExecuteResultSet="ExecuteInputFrom"
>
<parameter value="XLT"/>
<parameter value="*"/>
<parameter value="Unicode"/>
</dataCombo>

<label id="lblInputTo" label="to:"/>
</vgroup>
</hgroup>
<spacer height="1"/>
<html><hr/></html>
<hgroup align="center">
	<button caption="Save" onclick="zenPage.saveIOTable();"/>
	<spacer width="2"/>
	<button id="btnRemove" caption="Remove" disabled="true" onclick="zenPage.removeIOTable();"/>
	<spacer width="2"/>
</hgroup>

<label id="msgIOTable" controlClass="brownnote"/>

</form>
</fieldSet>

<fieldSet id="menu5" labelPosition="left" label="Defaults for Internal Tables" labelClass="fieldSetLabel" hidden="true">
<combobox id="PatternTable" label="Pattern table"/>
<combobox id="IdentifierTable" label="Identifier table"/>
<combobox id="UpperCaseTable" label="Uppercase table"/>
<combobox id="LowerCaseTable" label="Lowercase table"/>
<combobox id="TitleCaseTable" label="Titlecase table"/>
<combobox id="AccentTable" label="Accent table"/>
<combobox id="CollationTable" label="Collation table"/>
<combobox id="XYTable" label="$X/$Y table"/>
<html><hr/></html>
<button id="btnSave5" caption="Save" onclick="zenPage.save(5);"/>

</fieldSet>
<fieldSet id="menu6" labelPosition="left" label="Defaults for Input/Output" labelClass="fieldSetLabel" hidden="true">
<text id="TranZCVT" label="Process" size="20"/>
<text id="TranProgrammer" label="IRIS terminal" size="20"/>
<text id="TranTerminal" label="Other terminal" size="20"/>
<text id="TranSequential" label="File" size="20"/>
<text id="TranMagTape" label="Mag tape" size="20"/>
<text id="TranTCP" label="TCP/IP" size="20"/>
<text id="TranSystemCall" label="System call" size="20"/>
<text id="TranPrinter" label="Printer" size="20"/>
<html><hr/></html>
<button id="btnSave6" caption="Save" onclick="zenPage.save(6);"/>
</fieldSet>
<fieldSet id="menu7" labelPosition="left" label="Strings" labelClass="fieldSetLabel" hidden="true">
<text id="AM" label="AM suffix" size="20"/>
<text id="PM" label="PM suffix" size="20"/>
<text id="Noon" label="Noon suffix" size="20"/>
<text id="Midnight" label="Midnight suffix" size="20"/>
<spacer height="4"/>
<hgroup label="Weekdays:" labelStyle="font-weight:bold;">
<vgroup label="Names" labelStyle="color:#6699ff;font-size:0.8em;" labelPosition="left">
<text id="WeekdayName1" size="10"/>
<text id="WeekdayName2" size="10"/>
<text id="WeekdayName3" size="10"/>
<text id="WeekdayName4" size="10"/>
<text id="WeekdayName5" size="10"/>
<text id="WeekdayName6" size="10"/>
<text id="WeekdayName7" size="10"/>
</vgroup>
<vgroup label="Abbreviations" labelStyle="color:#6699ff;font-size:0.8em;" labelPosition="left">
<text id="WeekdayAbbr1" size="10"/>
<text id="WeekdayAbbr2" size="10"/>
<text id="WeekdayAbbr3" size="10"/>
<text id="WeekdayAbbr4" size="10"/>
<text id="WeekdayAbbr5" size="10"/>
<text id="WeekdayAbbr6" size="10"/>
<text id="WeekdayAbbr7" size="10"/>
</vgroup>
</hgroup>
<spacer height="2"/>
<hgroup label="Months:" labelStyle="font-weight:bold;">
<vgroup label="Names" labelStyle="color:#6699ff;font-size:0.8em;" labelPosition="left">
<text id="MonthName1" size="10"/>
<text id="MonthName2" size="10"/>
<text id="MonthName3" size="10"/>
<text id="MonthName4" size="10"/>
<text id="MonthName5" size="10"/>
<text id="MonthName6" size="10"/>
<text id="MonthName7" size="10"/>
<text id="MonthName8" size="10"/>
<text id="MonthName9" size="10"/>
<text id="MonthName10" size="10"/>
<text id="MonthName11" size="10"/>
<text id="MonthName12" size="10"/>
</vgroup>
<vgroup label="Abbreviations" labelStyle="color:#6699ff;font-size:0.8em;" labelPosition="left">
<text id="MonthAbbr1" size="10"/>
<text id="MonthAbbr2" size="10"/>
<text id="MonthAbbr3" size="10"/>
<text id="MonthAbbr4" size="10"/>
<text id="MonthAbbr5" size="10"/>
<text id="MonthAbbr6" size="10"/>
<text id="MonthAbbr7" size="10"/>
<text id="MonthAbbr8" size="10"/>
<text id="MonthAbbr9" size="10"/>
<text id="MonthAbbr10" size="10"/>
<text id="MonthAbbr11" size="10"/>
<text id="MonthAbbr12" size="10"/>
</vgroup>
</hgroup>
<html><hr/></html>
<button id="btnSave7" caption="Save" onclick="zenPage.save(7);"/>
</fieldSet>
</form>
</hgroup>
</pane>
}

/// User clicked a menu. menu=0 means to return to Local Properties.
ClientMethod selectMenu(menu) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var htmlDisplay = zen("htmlDisplay");
	var btnReturn = zen("btnReturn");
	var menuid;
	for (var x = 1; x <= 7; x++) {
		menuid = "menu" + x;
		zen(menuid).setHidden(true);
	}
	zen("lblSuccess").setHidden(true);
	if (menu!="0") {
		htmlDisplay.setHidden(true);
		btnReturn.setHidden(false);
		zen("menu"+menu).setHidden(false);
	} else {
		btnReturn.setHidden(true);
		htmlDisplay.setHidden(false);
	}
}

/// User selected a Input/Output table. Fill in edit fields.
ClientMethod selectIOTables(comp) [ Language = javascript ]
{
	zen("frmIOTables").setHidden(false);
	var table = comp.getValue();
	var txt = zen("txtIOTable");
	txt.setValue(comp.getProperty("text"));
	txt.setProperty("disabled",true);
	var proxy = this.EditIOTable(table,comp.getProperty("text"));
	var cmbOutputTo = zen("cmbOutputTo");
	cmbOutputTo.setValue(proxy.OutputTo); 
	cmbOutputTo.focus();
	zen("cmbInputFrom").setValue(proxy.InputFrom); 
	zen("btnRemove").setProperty("disabled",false);
	zen("msgIOTable").setValue("");
}

/// Reset the form programmatically
ClientMethod newIOTable() [ Language = javascript ]
{
	zen("frmIOTables").setHidden(false);
	var txt = zen("txtIOTable");
	txt.setProperty("disabled",false);
	txt.setValue("");
	txt.focus();
	zen("cmbOutputTo").setValue(""); 
	zen("cmbInputFrom").setValue("");
	zen("btnRemove").setProperty("disabled",true);
	zen("msgIOTable").setValue("");
}

/// User clicked the Remove button for IO table
ClientMethod removeIOTable() [ Language = javascript ]
{
	if (confirm(this.msgConfirmIOTable) == false) return;
	var proxy = new zenProxy();
	proxy.table = zen("txtIOTable").getValue();
	if (proxy.table=="") return;
	proxy.locale = this.cmbLocale;
	var ok = this.RemoveIOTables(proxy);
	if (ok == 1) {
		location.reload();
	} else {
		zen("msgIOTable").setValue(ok);
	}
}

/// User clicked the Save button for IO table
ClientMethod saveIOTable() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	var txt = zen("txtIOTable");
	proxy.table = txt.getValue();
	if (proxy.table == "") {
		zen("msgIOTable").setValue(this.msgIOTableName);
		txt.focus();
		return;
	}
	
	var output = zen("cmbOutputTo");
	proxy.OutputTo = output.getValue();
	if (proxy.OutputTo == "") {
		zen("msgIOTable").setValue(this.msgIOTableOutput);	
		output.focus();
		return;
	}
	
	var input = zen("cmbInputFrom");
	proxy.InputFrom = input.getValue();
	if (proxy.InputFrom == "") {
		zen("msgIOTable").setValue(this.msgIOTableInput);	
		input.focus();
		return;
	}
	
	proxy.locale = this.cmbLocale;
	proxy.characterset = this.CharacterSet;
	var ok = this.SaveIOTables(proxy);
	if (ok == 1) {
		// refresh page to reload the list
		if (txt.getProperty("disabled")==false) {
			location.reload();
		} else {
			zen("msgIOTable").setValue(this.msgSaved);
		}
	} else {
		zen("msgIOTable").setValue(ok);	
	}
}

/// User clicked a Save button 
ClientMethod save(menu) [ Language = javascript ]
{
	var ok = 1;
	var menuname = "menu" + menu;
	var proxy = new zenProxy();
	proxy.locale = this.cmbLocale;
	switch(menu) {
		case 1:
			proxy.Description = zen("Description").getValue();
			proxy.Currency = zen("Currency").getValue();
			ok = this.SaveBasics(proxy);
			if (ok == 1) zen("lblLocale").refreshContents();
			break;
		case 2:
			proxy.DateFormat = zen("DateFormat").getValue();
			proxy.DateSeparator = zen("DateSeparator").getValue();
			proxy.TimeFormat = zen("TimeFormat").getValue();
			proxy.TimeSeparator = zen("TimeSeparator").getValue();
			proxy.TimePrecision = zen("TimePrecision").getValue();
			proxy.MinusSign = zen("MinusSign").getValue();
			proxy.PlusSign = zen("PlusSign").getValue();
			proxy.DecimalSeparator = zen("DecimalSeparator").getValue();
			proxy.NumericGroupSeparator = zen("NumericGroupSeparator").getValue();
			proxy.NumericGroupSize = zen("NumericGroupSize").getValue();
			ok = this.SaveFormats(proxy);
			break;
		case 3:
			var cnt1 = zen("lstselect1").getOptionCount();
			if (cnt1 < 1) {
				ok = this.msgPatternTables;
				break;
			}
			var cnt2 = zen("lstselect2").getOptionCount();
			if (cnt2 < 1) {
				ok = this.msgIdenTables;
				break;
			}
			var cnt6 = zen("lstselect6").getOptionCount();
			if (cnt6 < 1) {
				ok = this.msgCollationTables;
				break;
			}
			var cnt7 = zen("lstselect7").getOptionCount();
			if (cnt7 < 1) {
				ok = this.msgXYTables;
				break;
			}
            var cnt8 = zen("lstselect8").getOptionCount();
			proxy.lst1 = "";
			proxy.lst2 = "";
			proxy.lst3 = "";
			proxy.lst4 = "";
			proxy.lst5 = "";
			proxy.lst6 = "";
			proxy.lst7 = "";
			proxy.lst8 = "";
			for (i=0;i<cnt1;i++) { proxy.lst1 = proxy.lst1 + "," + zen("lstselect1").getOptionValue(i); }
			for (i=0;i<cnt2;i++) { proxy.lst2 = proxy.lst2 + "," + zen("lstselect2").getOptionValue(i); }
			for (i=0;i<zen("lstselect3").getOptionCount();i++) { proxy.lst3 = proxy.lst3 + "," + zen("lstselect3").getOptionValue(i); }
			for (i=0;i<zen("lstselect4").getOptionCount();i++) { proxy.lst4 = proxy.lst4 + "," + zen("lstselect4").getOptionValue(i); }
			for (i=0;i<zen("lstselect5").getOptionCount();i++) { proxy.lst5 = proxy.lst5 + "," + zen("lstselect5").getOptionValue(i); }
			for (i=0;i<zen("lstselect6").getOptionCount();i++) { proxy.lst6 = proxy.lst6 + "," + zen("lstselect6").getOptionValue(i); }
			for (i=0;i<cnt7;i++) { proxy.lst7 = proxy.lst7 + "," + zen("lstselect7").getOptionValue(i); }
			for (i=0;i<cnt8;i++) { proxy.lst8 = proxy.lst8 + "," + zen("lstselect8").getOptionValue(i); }
			ok = this.SaveIntTables(proxy);
			break;    
		case 4:
			proxy.table = zen("txtTable").getValue();
			proxy.OutputTo = zen("OutputTo").getValue();
			proxy.InputFrom = zen("InputFrom").getValue();
			proxy.characterset = this.CharacterSet;
			ok = this.SaveIOTables(proxy);
			break;
		case 5:
			proxy.IdentifierTable = zen("IdentifierTable").getValue();
			proxy.PatternTable = zen("PatternTable").getValue();
			proxy.XYTable = zen("XYTable").getValue();
			proxy.CollationTable = zen("CollationTable").getValue();
			proxy.UpperCaseTable = zen("UpperCaseTable").getValue();
			proxy.LowerCaseTable = zen("LowerCaseTable").getValue();
			proxy.TitleCaseTable = zen("TitleCaseTable").getValue();
			proxy.AccentTable = zen("AccentTable").getValue();
			ok = this.SaveInternalDefaults(proxy);
			break;    
		case 6:
			proxy.TranZCVT = zen("TranZCVT").getValue();
			proxy.TranProgrammer = zen("TranProgrammer").getValue();
			proxy.TranTerminal = zen("TranTerminal").getValue();
			proxy.TranSequential = zen("TranSequential").getValue();
			proxy.TranMagTape = zen("TranMagTape").getValue();
			proxy.TranTCP = zen("TranTCP").getValue();
			proxy.TranSystemCall = zen("TranSystemCall").getValue();
			proxy.TranPrinter = zen("TranPrinter").getValue();
			ok = this.SaveIODefaults(proxy);
			break;    
		case 7:
			proxy.AM = zen("AM").getValue();
			proxy.PM = zen("PM").getValue();
			proxy.Noon = zen("Noon").getValue();
			proxy.Midnight = zen("Midnight").getValue();
			proxy.WeekdayName = "";
			proxy.WeekdayAbbr = "";
			proxy.MonthName = "";
			proxy.MonthAbbr = "";
			for (var i=1;i<=7;i++) {
				proxy.WeekdayName = proxy.WeekdayName + " " + zen("WeekdayName"+i).getValue();
				proxy.WeekdayAbbr = proxy.WeekdayAbbr + " " + zen("WeekdayAbbr"+i).getValue();
			}
			for (i=1;i<=12;i++) {
				proxy.MonthName = proxy.MonthName + " " + zen("MonthName"+i).getValue();
				proxy.MonthAbbr = proxy.MonthAbbr + " " + zen("MonthAbbr"+i).getValue();
			}
			ok = this.SaveStrings(proxy);
			break;
		default:
			break;
	}
	if (ok == 1) {
		zen(menuname).setHidden(true);
		zen("btnReturn").setHidden(true);
		zen("lblSuccess").setHidden(false);
		var htmlDisplay = zen("htmlDisplay");
		htmlDisplay.setHidden(false);		
		htmlDisplay.seed = proxy.locale;
		htmlDisplay.refreshContents();
	} else {
		alert(ok); 	
	}
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	Set ..%GetComponentById("DescriptionHelp").label = $$$Text("Suggested format: <Language>, <Country>, <Character set>.")

	Set tSC = ##class(Config.NLS.Locales).Get(..cmbLocale,.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	
	#; Loadable Internal Tables
	Do ..DrawIntTables()

	#; Loadable Input/Output Tables
	#; Clear temp session data for saved table edit.
	Kill %session.Data("iotable")
	Set tCombo = ..%GetComponentById("cmbIOTables")
	Set XLTTables = ..ArrayToString("XLTTables","",.Properties,",")
	If XLTTables'="" {
		For n = 1:1:$L(XLTTables,",") {
			Set item=$P(XLTTables,",",n)
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = item
			Set tOption.value = Properties("XLTTables",item)
	 	}
	}
 	Set ..%GetComponentById("lblOutputFrom").value = Properties("CharacterSet")
 	Set ..%GetComponentById("lblInputTo").value = Properties("CharacterSet")
	Set ..CharacterSet = Properties("CharacterSet")
	
	Set WeekdayName = Properties("WeekdayName")
	For x = 2:1:8 Set ..%GetComponentById("WeekdayName"_(x-1)).value = $P(WeekdayName," ",x)
	Set WeekdayAbbr = Properties("WeekdayAbbr")
	For x = 2:1:8 Set ..%GetComponentById("WeekdayAbbr"_(x-1)).value = $P(WeekdayAbbr," ",x)

	Set MonthName = Properties("MonthName")
	For x = 2:1:13 Set ..%GetComponentById("MonthName"_(x-1)).value = $P(MonthName," ",x)
	Set MonthAbbr = Properties("MonthAbbr")
	For x = 2:1:13 Set ..%GetComponentById("MonthAbbr"_(x-1)).value = $P(MonthAbbr," ",x)
	
	Quit $$$OK
}

/// Load Default Internal Tables
Method DrawIntTables()
{
	#; Get all properties
	Set st = ##class(Config.NLS.Locales).Get(..cmbLocale,.LocProps)
	#; Get internal table types
	Do GetFields^NLS(.Tables,"IntTables")
	Set tab = ""
	Set tab = $O(Tables(tab))
	While tab '= "" {
		Set class = $P(Tables(tab),"^",1)
		Set ty = $E(class,1,$L(class)-6)
		Set:ty="Collation" ty="COL" Set:ty="Identifier" ty="Ident"	
		#; Selected Tables:
		Kill IntTables
		Merge IntTables = LocProps(class)
		Set controlname = "lstselect"_tab
		Set tCombo = ..%GetComponentById(controlname)
		#; Prepare to set up drop-down for Defaults as well
		Set deftablename = $E(class,1,$L(class)-1)
		Set tDefCombo = ..%GetComponentById(deftablename)
		Set item = $O(IntTables(""))
 		While (item'="") {
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = item
			Set tOption.value = item
	 		#; Set the default table drop-down
			Do tDefCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)

	 		Set item = $O(IntTables(item))
 		}

		#; Available Tables:
		Set controlname = "lst"_tab
		Set tCombo = ..%GetComponentById(controlname)
		Set tCombo.label = $$$FormatText($$$Text("Compatible with %1"),LocProps("CharacterSet"))
		Kill Tabs
		Do GetTables^NLS1(.Tabs,ty,LocProps("CharacterSet"))
		Set item = $O(Tabs(""))
 		While (item'="") {
	 		#; Do not include the ones that are already selected.
	 		If '$D(IntTables(Tabs(item))) {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tCombo.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = Tabs(item)
				Set tOption.value = Tabs(item)
	 		}
	 		Set item = $O(Tabs(item))
 		}
		#; Get next table type:
		Set tab = $O(Tables(tab))
	}
}

Method DrawLocale(pSeed As %String) As %Status
{
	Set CurrentLocale =  $G(^%SYS("LOCALE","CURRENT"),"enu8")
	Set (tDescription,tCurrDescription) = CurrentLocale_" ("_##class(%CSP.UI.Portal.NLS).GetLocaleDescription(CurrentLocale)_")"
	If ..cmbLocale '= CurrentLocale {
		Set tDescription = ..cmbLocale_" ("_##class(%CSP.UI.Portal.NLS).GetLocaleDescription(..cmbLocale)_")"
	}
	Set tmsg = $$$FormatText($$$Text("Locale properties of %1: "),tDescription)
	&html<<div class="Text1">#($ZCVT(tmsg,"O","HTML"))#</div>>
	&html<<div class="normal">#($$$FormatText($$$Text("Your current locale is: %1"),tCurrDescription))#</div>>
	Quit $$$OK
}

/// Method for loading I/O Tables Output to field.
Method ExecuteOutputTo(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set pRS.RuntimeMode = 1
	Set tSC = pRS.Execute("XLT",%page.CharacterSet,"*")
	Quit tSC
}

/// Method for loading I/O Tables Input from field.
Method ExecuteInputFrom(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set pRS.RuntimeMode = 1
	Set tSC = pRS.Execute("XLT","*",%page.CharacterSet)
	Quit tSC
}

/// Save values to Basics properties
ClassMethod SaveBasics(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set Properties("Description") = pProxy.Description
		Set Properties("Currency") = pProxy.Currency
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Save values to Date, Time, Number Formats
ClassMethod SaveFormats(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set Properties("DateFormat") = pProxy.DateFormat
		Set Properties("DateSeparator") = pProxy.DateSeparator
		Set Properties("TimeFormat") = pProxy.TimeFormat
		Set Properties("TimeSeparator") = pProxy.TimeSeparator
		Set Properties("TimePrecision") = pProxy.TimePrecision
		Set Properties("MinusSign") = pProxy.MinusSign
		Set Properties("PlusSign") = pProxy.PlusSign
		Set Properties("DecimalSeparator") = pProxy.DecimalSeparator
		Set Properties("NumericGroupSeparator") = pProxy.NumericGroupSeparator
		Set Properties("NumericGroupSize") = pProxy.NumericGroupSize
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

ClassMethod SaveIntTables(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set lst1 = pProxy.lst1
		Set lst2 = pProxy.lst2
		Set lst3 = pProxy.lst3
		Set lst4 = pProxy.lst4
		Set lst5 = pProxy.lst5
		Set lst6 = pProxy.lst6
		Set lst7 = pProxy.lst7
		Set lst8 = pProxy.lst8
		For n = 2:1:$L(lst1,",") Set lst = $P(lst1,",",n) If lst '= "" Set Properties("PatternTables", lst) = ""
		For n = 2:1:$L(lst2,",") Set lst = $P(lst2,",",n) If lst '= "" Set Properties("IdentifierTables", lst) = ""
		For n = 2:1:$L(lst3,",") Set lst = $P(lst3,",",n) If lst '= "" Set Properties("UpperCaseTables", lst) = ""
		For n = 2:1:$L(lst4,",") Set lst = $P(lst4,",",n) If lst '= "" Set Properties("LowerCaseTables", lst) = ""
		For n = 2:1:$L(lst5,",") Set lst = $P(lst5,",",n) If lst '= "" Set Properties("TitleCaseTables", lst) = ""
		For n = 2:1:$L(lst6,",") Set lst = $P(lst6,",",n) If lst '= "" Set Properties("AccentTables", lst) = ""
		For n = 2:1:$L(lst7,",") Set lst = $P(lst7,",",n) If lst '= "" Set Properties("CollationTables", lst) = ""
		For n = 2:1:$L(lst8,",") Set lst = $P(lst8,",",n) If lst '= "" Set Properties("XYTables", lst) = ""
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Load I/O table details
ClassMethod EditIOTable(table, tablename) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		#; If user has modified this table but has not refreshed the page, use the new values here
		If $G(%session.Data("iotable",tablename)) '= "" {
			Set tProxy.OutputTo = $P(%session.Data("iotable",tablename),"^",1)
			Set tProxy.InputFrom = $P(%session.Data("iotable",tablename),"^",2)
		} Else {
			Set tProxy.OutputTo = $LI(table,4)
			Set tProxy.InputFrom = $LI(table,1)
		}
	} Catch Error {
	}
	Quit tProxy
}

/// Validate and Save values to Input/Output Tables.
ClassMethod SaveIOTables(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Set errorMsg = ""
	Try {
		If '##class(Config.NLS.Tables).Exists("XLT",pProxy.characterset,pProxy.OutputTo) {
			Set errorMsg = $$$FormatText($$$Text("For Output, Table(XLT,%1,%2) is not available. "),pProxy.characterset,pProxy.OutputTo)
		}
		If '##class(Config.NLS.Tables).Exists("XLT",pProxy.InputFrom,pProxy.characterset) {
			Set errorMsg = $S(errorMsg'="":errorMsg_"<br>",1:"")_$$$FormatText($$$Text("For Input, Table(XLT,%1,%2) is not available. "),pProxy.InputFrom,pProxy.characterset)
		}
		If errorMsg '= "" Throw

		Set tSC = ##class(Config.NLS.Locales).Get(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set Properties("XLTTables",pProxy.table) = $LB(pProxy.InputFrom, pProxy.characterset, pProxy.characterset, pProxy.OutputTo)
		
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

	  	Set %session.Data("iotable",pProxy.table) = pProxy.OutputTo_"^"_pProxy.InputFrom
	} Catch Error {
		If errorMsg '= "" {
			Set result = $ZCVT(errorMsg,"O","JS")
		} Else {
			Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
		}
	}
	Quit result
}

/// Remove an existing IO table from locale
ClassMethod RemoveIOTables(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set tSC = ##class(Config.NLS.Locales).Get(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Kill Properties("XLTTables",pProxy.table)
		If '$D(Properties("XLTTables")) Set Properties("XLTTables") = ""
		
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Save values to Defaults for Internal Tables (InternalDefaults)
ClassMethod SaveInternalDefaults(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set Properties("IdentifierTable") = pProxy.IdentifierTable
		Set Properties("PatternTable") = pProxy.PatternTable
		Set Properties("XYTable") = pProxy.XYTable
		Set Properties("CollationTable") = pProxy.CollationTable
		Set Properties("UpperCaseTable") = pProxy.UpperCaseTable
		Set Properties("LowerCaseTable") = pProxy.LowerCaseTable
		Set Properties("TitleCaseTable") = pProxy.TitleCaseTable
		Set Properties("AccentTable") = pProxy.AccentTable
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Save values to Defaults for Input/Output (IODefaults)
ClassMethod SaveIODefaults(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set Properties("TranZCVT") = pProxy.TranZCVT
		Set Properties("TranProgrammer") = pProxy.TranProgrammer
		Set Properties("TranTerminal") = pProxy.TranTerminal
		Set Properties("TranSequential") = pProxy.TranSequential
		Set Properties("TranMagTape") = pProxy.TranMagTape
		Set Properties("TranTCP") = pProxy.TranTCP
		Set Properties("TranSystemCall") = pProxy.TranSystemCall
		Set Properties("TranPrinter") = pProxy.TranPrinter
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Save values to Defaults for Input/Output (IODefaults)
ClassMethod SaveStrings(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set result = $$$OK
	Try {
		Set Properties("AM") = pProxy.AM
		Set Properties("PM") = pProxy.PM
		Set Properties("Noon") = pProxy.Noon
		Set Properties("Midnight") = pProxy.Midnight
		Set Properties("WeekdayName") = pProxy.WeekdayName
		Set Properties("WeekdayAbbr") = pProxy.WeekdayAbbr
		Set Properties("MonthName") = pProxy.MonthName
		Set Properties("MonthAbbr") = pProxy.MonthAbbr
		Set tSC = ##class(Config.NLS.Locales).Modify(pProxy.locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set result = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit result
}

/// Draw All Properties of a Locale
Method DrawProperties(pSeed As %String) As %Status
{
	Set tSC = ##class(Config.NLS.Locales).Get(..cmbLocale,.Properties)
	If $$$ISERR(tSC) Write !,$$$TextHTML("Cannot open class Config.NLS.Locales!") Quit $$$OK
	
	Set IsSystemLocale = $E(..cmbLocale,1) '= "y"
	Set disabledFlag = $S(IsSystemLocale:"disabled",..IsEMSReadOnly:"disabled",1:"")
	If IsSystemLocale Write !,"<span style='font-size:0.8em;'>","(",$$$FormatText($$$Text("%1 is a system locale. Edit is not allowed."),..cmbLocale),")</span>"
	Set btnEdit = $$$TextHTML("Edit")
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Basic Properties"))#</td><td align="right"><input type="button" value="#(btnEdit)#" #(disabledFlag)# onclick="zenPage.selectMenu(1);"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Name"))#</th><th>#($$$TextHTML("Value"))#</th></th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Country"))#</td><td class="DetailValue" >#(Properties("Country"))# (#(Properties("CountryAbbr"))#)</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Language"))#</td><td class="DetailValue" >#(Properties("Language"))# (#(Properties("LanguageAbbr"))#)</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Character set"))#</td><td class="DetailValue" >#(Properties("CharacterSet"))#</td></tr>
	<tr  class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Currency"))#</td><td class="DetailValue" >#(Properties("Currency"))#</td></tr>
	</table><br>>

	Set dateList="DD Mmm [YY]YY^MM/DD/[YY]^DD Mmm [YY]YY^YYYY-MM-DD^DD/MM/[YY]YY^Mmm D, YYYY^Mmm D YYYY^Mmm DD [YY]YY^YYYYMMDD^Mmmmmm D, YYYY^W^Www^Wwwwww^[D]D/[M]M/YYYY^nnn"	
	Set timeList="hh:mm:ss,hh:mm,hh:mm:ss[AM/PM],hh:mm[AM/PM]"
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Date, Time and Number Formats"))#</td><td align="right"><input type="button" value="#(btnEdit)#" #(disabledFlag)# onclick="zenPage.selectMenu(2);"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Name"))#</th><th align="center">#($$$TextHTML("Value"))#</th></th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("$ZDate format"))#</td><td align="center">#($P(dateList,"^",Properties("DateFormat")+1))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Date separator"))#</td><td align="center">#(Properties("DateSeparator"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Time format"))#</td><td align="center">#($P(timeList,",",Properties("TimeFormat")))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Time separator"))#</td><td align="center">#(Properties("TimeSeparator"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Time precision"))#</td><td align="center">#(Properties("TimePrecision"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Minus sign"))#</td><td align="center">#(Properties("MinusSign"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Plus sign"))#</td><td align="center">#(Properties("PlusSign"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Decimal separator"))#</td><td align="center">#(Properties("DecimalSeparator"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Numeric group separator"))#</td><td align="center">#(Properties("NumericGroupSeparator"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Numeric group size"))#</td><td align="center">#(Properties("NumericGroupSize"))#</td></tr>

	</table><br>>

	Set PatternTables = ..ArrayToString("PatternTables", Properties("PatternTable"), .Properties)
	Set IdentifierTables = ..ArrayToString("IdentifierTables", Properties("IdentifierTable"), .Properties)
	Set UpperCaseTables = ..ArrayToString("UpperCaseTables", Properties("UpperCaseTable"), .Properties)
	Set LowerCaseTables = ..ArrayToString("LowerCaseTables", Properties("LowerCaseTable"), .Properties)
	Set TitleCaseTables = ..ArrayToString("TitleCaseTables", Properties("TitleCaseTable"), .Properties)
	Set AccentTables = ..ArrayToString("AccentTables", Properties("AccentTable"), .Properties)
	Set CollationTables = ..ArrayToString("CollationTables", Properties("CollationTable"), .Properties)
	Set XYTables = ..ArrayToString("XYTables", Properties("XYTable"), .Properties)
	Set btnEditTables = $$$TextHTML("Edit Tables")
	Set btnEditDefaults = $$$TextHTML("Edit Defaults")
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Internal Tables"))#</td><td align="right"><input type="button" value="#(btnEditTables)#" #(disabledFlag)# onclick="zenPage.selectMenu(3);">&nbsp;&nbsp;<input type="button" value="#(btnEditDefaults)#" #(disabledFlag)# onclick="zenPage.selectMenu(5);"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Internal Tables"))#</th><th>#($$$TextHTML("Default"))#</th><th>#($$$TextHTML(" Additional "))#</th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Pattern match tables"))#</td><td class="DetailValue" >#(Properties("PatternTable"))#</td><td class="DetailValue" nowrap>#(PatternTables)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Identifier tables"))#</td><td class="DetailValue" nowrap>#(Properties("IdentifierTable"))#</td><td class="DetailValue" nowrap>#(IdentifierTables)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Uppercase tables"))#</td><td class="DetailValue" nowrap>#(Properties("UpperCaseTable"))#</td><td class="DetailValue" nowrap>#(UpperCaseTables)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Lowercase tables"))#</td><td class="DetailValue" nowrap>#(Properties("LowerCaseTable"))#</td><td class="DetailValue" nowrap>#(LowerCaseTables)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Titlecase tables"))#</td><td class="DetailValue" nowrap>#(Properties("TitleCaseTable"))#</td><td class="DetailValue" nowrap>#(TitleCaseTables)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Accent tables"))#</td><td class="DetailValue" nowrap>#(Properties("AccentTable"))#</td><td class="DetailValue" nowrap>#(AccentTables)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Collation tables"))#</td><td class="DetailValue" nowrap>#(Properties("CollationTable"))#</td><td class="DetailValue" nowrap>#(CollationTables)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("$X/$Y action tables"))#</td><td class="DetailValue" nowrap>#(Properties("XYTable"))#</td><td class="DetailValue" nowrap>#(XYTables)#</td></tr>
	</table>
	<br>
	>
	Set XLTTables = ..ArrayToString("XLTTables", "", .Properties)
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Input/Output Tables"))#</td><td align="right"><input type="button" value="#(btnEdit)#" #(disabledFlag)# onclick="zenPage.selectMenu(4);"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">>
	&html<<tr class="EvenRow">> 
	For n = 1:1:$L(XLTTables,",") {
		Set item=$P(XLTTables,",",n)
		Set c = "OddRow"
		&html<<td>#($ZCVT(item,"O","HTML"))#</td>>
		If '(n#4) Set c="EvenRow" &html<</tr><tr class="#(c)#">> 
	}
	&html<
	</table>
	<br>
	>
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Input/Output Defaults"))#</td><td align="right"><input type="button" value="#(btnEdit)#" #(disabledFlag)# onclick="zenPage.selectMenu(6);"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Input/Output"))#</th><th>#($$$TextHTML("Default"))#</th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Process"))#</td><td class="DetailValue" >#($ZCVT(Properties("TranZCVT"),"O","HTML"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("IRIS terminal"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranProgrammer"),"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Other terminal"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranTerminal"),"O","HTML"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("File"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranSequential"),"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Mag tape"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranMagTape"),"O","HTML"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("TCP/IP"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranTCP"),"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("System call"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranSystemCall"),"O","HTML"))#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Printer"))#</td><td class="DetailValue" nowrap>#($ZCVT(Properties("TranPrinter"),"O","HTML"))#</td></tr>
	</table>
	<br>
	>
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Strings"))#</td><td align="right"><input type="button" value="#(btnEdit)#" #(disabledFlag)# onclick="zenPage.selectMenu(7);"></td></tr></table>

	<table class="PropTable" border="0" cellspacing="5" cellpadding="0">
	<tr>
	<td class="tc">#($$$TextHTML("AM suffix"))#:</td><td>#($ZCVT(Properties("AM"),"O","HTML"))#</td>
	</tr>
	<tr>
	<td class="tc">#($$$TextHTML("PM suffix"))#:</td><td>#($ZCVT(Properties("PM"),"O","HTML"))#</td>
	</tr>
	<tr>
	<td class="tc">#($$$TextHTML("Noon suffix"))#:</td><td>#($ZCVT(Properties("Noon"),"O","HTML"))#</td>
	</tr>
	<tr>
	<td class="tc">#($$$TextHTML("Midnight suffix"))#:</td><td>#($ZCVT(Properties("Midnight"),"O","HTML"))#</td>
	</tr>
	</table>
	<br>
	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Weekdays"))#</th><th>#($$$TextHTML("Abbreviations"))#</th>
	>
	For n = 2:1:8 &html<<tr class="#($S(n#2:"OddRow",1:"EvenRow"))#"><td class="DetailValue" nowrap>#($ZCVT($P(Properties("WeekdayName")," ",n),"O","HTML"))#</td><td class="DetailValue" nowrap>#($ZCVT($P(Properties("WeekdayAbbr")," ",n),"O","HTML"))#</td></tr>>
	&html<
		<tr><th>#($$$TextHTML("Months"))#</th><th>#($$$TextHTML("Abbreviations"))#</th>
	>
	For n = 2:1:13 &html<<tr class="#($S(n#2:"OddRow",1:"EvenRow"))#"><td class="DetailValue" nowrap>#($ZCVT($P(Properties("MonthName")," ",n),"O","HTML"))#</td><td class="DetailValue" nowrap>#($ZCVT($P(Properties("MonthAbbr")," ",n),"O","HTML"))#</td></tr>>
	&html<</table>
	<table class="fieldStyle"><tr><td colspan="2">&nbsp;</td></tr></table>
	>
	Kill c
	Quit 1
}

/// ------------------ Utility Methods for Moving between lstboxes ------------------ ///
/// Moving a list item from one box to the next, then remove it from the original box ///
ClientMethod arrowClick(from, to) [ Language = javascript ]
{
	var fromCtl = zen(from);
	var currIndex = fromCtl.selectedIndex;
	if ( (currIndex < 0) || (currIndex >= fromCtl.getOptionCount()) ) return;	
	var optionValue = fromCtl.getOptionValue(currIndex);
	var optionText = fromCtl.getOptionText(currIndex);
	var toCtl = zen(to);
	toCtl.appendOption(optionValue,optionText);
	
	fromCtl.removeOption(currIndex);
}

/// Return additional tables from array. Used by DrawProperties.
/// name = table name, e.g. PatternTables, CollationTables
/// def  = default, e.g. LocProps("CollationTable")
/// LocProps = array containing all current settings
ClassMethod ArrayToString(name As %String, def As %String, ByRef LocProps As %String, delim As %String = ", ") As %String
{
	Set str = ""
	Set item = $O(LocProps(name,""))
	While item '= "" {
		If item '= def {
			Set str = str_item_delim
		}
		Set item = $O(LocProps(name,item))
	}
	If str '= "" {
		Quit $P(str,delim,1,$L(str,delim)-1)
	}
	Quit str
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))	
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Locale Definitions","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?cmbLocale="_..EscapeURL(..cmbLocale)_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Locale Properties")
}

}
