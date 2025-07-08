/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Class for building Export/Import Wizard Content
Class %CSP.UI.SQL.ExImWizard Extends %CSP.Page [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

/// Return appropriate label for whether to include header for export or whether the file includes headers for import.
ClassMethod HasHeaderLabel(Wizard)
{
	Quit $S(Wizard="Export":$$$TextHTML("Export column headers?"),1:$$$TextHTML("First row contains column headers?"))
}

/// Draws Table specific content
ClassMethod DrawTableContent(Wizard)
{
	Set lblAva = $$$TextHTML("Available")
	Set lblSel = $$$TextHTML("Selected")
	Set lblSelectColumns = $$$TextHTML("Select Columns.")
	&html<
	<!-- Select Properties -->
	<div id="page2" style="display:none">
	<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr>
	  <td colspan="2" id="id_page2title" class="Text1">#(lblSelectColumns)#</td>
	</tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td>
	  <table border="0">
	  <th>#(lblAva)#</th><th>&nbsp;</th><th>#(lblSel)#</th><th>&nbsp;</th></tr>
	  <td><select name="avaList" id="avaList" size="10" multiple ondblclick="javascript:move('selectone');"></select></td>
	  >
	Do ##class(%CSP.UI.Component.SelectBoxUtils).DrawArrowsOld()
	&html<
	 </td>
	  <td><select name="selList" id="selList" size="10" multiple ondblclick="javascript:move('deselectone');"></select></td>
	  <td>>
	Do ##class(%CSP.UI.Component.SelectBoxUtils).DrawUpArrowsOld()
	&html<	  
	  </td>
	  </table>
	  <div id="Att"></div>
	</tr>
	</table>
	</div>
	>
	Set lblPage31 = $$$TextHTML("What delimiter separates your columns")
	Set lblPage32 = $$$TextHTML("Tab")
	Set lblPage33 = $$$TextHTML("Space")
	Set lblPage34 = $$$TextHTML("Fixed Width")
	Set lblPage35 = $$$TextHTML("Character")
	Set lblPage36 = $$$TextHTML("String quote")
	Set lblPage37 = $$$TextHTML("Date format")
	Set lblPage38 = $$$TextHTML("Time format")
	Set lblPage39 = $$$TextHTML("TimeStamp format")
	Set lblPage40 = $$$TextHTML("Disable validation")
	Set lblPreview = $$$TextHTML("Preview Data")
	Set lblPage310 = $$$TextHTML("* Width will be used for Fixed Width only.")
	Set lblPage311 = $$$TextHTML("Column")
	Set lblPage312 = $$$TextHTML("Name")
	Set lblPage313 = $$$TextHTML("Type")
	Set lblPage314 = $$$TextHTML("Width*")
	Set lblPage51 = $$$TextHTML("Defer Index Building with %SortBegin/%SortEnd")
	&html<
<!-- Attributes -->
<div id="page3" style="display:none">
<table name="SelAttr" width="100%" border="0" cellpadding="2" cellspacing="2" id="SelAttr">
	<tr><td colspan="4" id="id_page3title" class="Text1">
	#($$$TextHTML("Select options describing how data is stored in the ASCII file for schema.table."))#
	</td></tr>
	<tr><td colspan="4"><hr align="center" size="1" color="teal" noshade></td></tr>
	<tr class="wizardltlabel"><td colspan="4">#(lblPage31)#?<br>&nbsp;&nbsp;&nbsp;&nbsp;
	<input type="radio" name="Delimiter" value="0" checked>#(lblPage32)#
	<input type="radio" name="Delimiter" value="1">#(lblPage33)#
	<input type="radio" name="Delimiter" value="2">#(lblPage34)#
	<input type="radio" name="Delimiter" value="3">#(lblPage35)#
	<input type="text" id="DelimiterChar" name="DelimiterChar" size="5" maxlength="10" value="" onchange="Content.Delimiter[3].checked=true;">	
	</td></tr>
	<tr><td nowrap class="wizardlabel">#(..HasHeaderLabel(Wizard))#</td><td width="70%"><input type="checkbox" name="HasHeaders" id="HasHeaders" checked></td></tr>
	<tr><td nowrap class="wizardlabel">#(lblPage36)#:
	    <td width="70%"><select name="StringQuote" id="StringQuote">
	  	<option value="double">"</option>
	  	<option value="single">'</option>
	  	<option value=""></option>
	  	</select>
		</td></tr>
	<tr><td nowrap class="wizardlabel">#(lblPage37)#:</td>
		<td width="70%"><select name="DateFormat" id="DateFormat">
	  	<option value="1" selected>MM/DD/{YY}YY</option>
	  	<option value="2">DD Mmm {YY}YY</option>
	  	<option value="3">YYYY-MM-DD</option>
	  	<option value="4">DD/MM/{YY}YY</option>
	  	<option value="5">Mmm D, YYYY</option>
	  	<option value="6">Mmm D YYYY</option>
	  	<option value="7">Mmm DD, YYYY</option>
	  	<option value="8">YYYYMMDD</option>
	  	<option value="9">Mmmmm D, YYYY</option>
	  	<option value="10">YYYY/MM/DD</option>
		</select>
		</td></tr>
	<tr><td nowrap class="wizardlabel">#(lblPage38)#:</td>
		<td width="70%"><select name="TimeFormat" id="TimeFormat">
	  	<option value="1" selected>hh:mm:ss</option>
	  	<option value="2">hh:mm</option>
	  	<option value="3">hh:mm:ss[AM/PM]</option>
	  	<option value="4">hh:mm[AM/PM]</option>
		</select>
		</td></tr>>
		
	If Wizard = "Import" {		
		&html<
	<tr><td nowrap class="wizardlabel">#(lblPage39)#:</td>
		<td width="70%"><select name="TimeStampFormat" id="TimeStampFormat">
	  	<option value="1" selected>ODBC Format</option>
	  	<option value="2">T-SQL Format [MDY]</option>
	  	<option value="3">T-SQL Format [DMY]</option>
	  	<option value="4">T-SQL Format [YMD]</option>
	  	<option value="5">T-SQL Format [YDM]</option>
	  	<option value="6">T-SQL Format [MYD]</option>
	  	<option value="7">T-SQL Format [DYM]</option>
	  	<option value="8">YYYY-MM-DD-HH:MI:SS</option>
	  	<option value="9">YYYY-MM-DDTHH:MI:SS</option>
		</select>
		</td></tr>
	<tr><td nowarp class="wizardlabel">#(lblPage40)#?</td><td><input type="checkbox" name="NoCheck" id="NoCheck"></td></tr>
	<tr><td nowarp class="wizardlabel">#(lblPage51)#?</td><td><input type="checkbox" name="DeferIndex" id="DeferIndex"></td></tr>>
	}
	&html<<tr><td>&nbsp;</td><td><input type="submit" name="Preview" value="#(lblPreview)#" onclick="markselList()"></td></tr>
	<tr><td colspan="2">
	<table name="SelCopy" width="100%" border="0" cellpadding="2" cellspacing="2" id="SelCopy">
	<tr><td colspan="4">
	</td></tr>
	<tr><td colspan="4"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td class="lb">#(lblPage311)#</th><td class="lb">#(lblPage312)#</th><td class="lb">#(lblPage313)#</th><td class="lb">#(lblPage314)#</th></tr>
	</table>
	<p class="wizardltlabel">#(lblPage310)#
	</td></tr> 
</table>
</div>
>
		Do ..DrawTablePage4(Wizard)
}

/// Draws Link Table page 4 content
ClassMethod DrawTablePage4(Wizard)
{
	Set lblPage41 = $$$TextHTML("Review your selections below. When ready, click the Finish button.")
	Set lblPage42 = $$$TextHTML("File Name")
	Set lblPage43 = $$$TextHTML("Schema")
	Set lblPage44 = $$$TextHTML("Table")
	Set lblPage45 = $$$TextHTML("Columns are delimited by")
	Set lblPage46 = $$$TextHTML("String quote")
	Set lblPage47 = $$$TextHTML("Date format")
	Set lblPage48 = $$$TextHTML("Time format")
	Set lblPage49 = $$$TextHTML("TimeStamp format")
	Set lblPage50 = $$$TextHTML("Disable validation")
	Set lblPage52 = $$$TextHTML("Defer Index Building with %SortBegin/%SortEnd")
	Set lblCharset = $$$TextHTML("Charset")
	&html<
<!-- New Names -->
<div id="page4" style="display:none">
<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr><td colspan="2">#(lblPage41)#</td></tr>
	<tr><td colspan="2">
	</td></tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td colspan="2">
	<tr><td nowrap class="wizardlabel">#(lblPage42)#:</td>
		<td><div id="SelectedFileName"></div></td>
	</tr>
	
	<tr><td nowrap class="wizardlabel">#(lblCharset)#:</td>
		<td><div id="SelectedCharset"></div></td>
	</tr>

	<tr><td nowrap class="wizardlabel">#(lblPage43)#:</td>
	  	<td width="70%"><div id="SelectedSchema"></div></td>
	</tr>
	<tr><td nowrap class="wizardlabel">#(lblPage44)#:</td>
		<td>
		<div id="SelectedTable"></div></td>
	</tr>
	<tr><td nowrap class="wizardlabel">#(lblPage45)#:</td>
		<td><div id="SelectedDelimiter"></div>
	</tr>
	<tr><td nowrap class="wizardlabel">#(..HasHeaderLabel($G(%request.Data("Wizard",1))))#</td>
		<td><div id="SelectedHasHeaders"></div>
	</tr>
	<tr><td class="wizardlabel">#(lblPage46)#:</td>
		<td><div id="SelectedStringQuote"></div>
	</tr>
	<tr><td class="wizardlabel">#(lblPage47)#:</td>
		<td><div id="SelectedDateFormat"></div>
	</tr>
	<tr><td class="wizardlabel">#(lblPage48)#:</td>
		<td><div id="SelectedTimeFormat"></div>
	</tr>	
	>
	
	if Wizard="Import" {
		&html<<tr><td class="wizardlabel">#(lblPage49)#:</td>
		<td><div id="SelectedTimeStampFormat"></div>
		</tr>
			
		<tr><td class="wizardlabel">#(lblPage50)#?</td>
		<td ><div id="SelectedNoCheck"></div></tr>
		<tr><td class="wizardlabel">#(lblPage52)#:</td>
		<td><div id="SelectedDeferIndex"></div>
		</tr>>
	}
	&html<
	</table>
</div>
>
	Do ..DrawResultPage(5)
}

/// Draws Result Page
ClassMethod DrawResultPage(pagenumber)
{
	Set lblResult = $$$TextHTML("Result")
	&html<
	<div id="page#(pagenumber)#" style="display:none">
	#(lblResult)#: <br><textarea id="ResultText" name="ResultText" rows="20" cols="60"></textarea>
	<p id="Result">
	</p>
	</div>
	>
}

}
