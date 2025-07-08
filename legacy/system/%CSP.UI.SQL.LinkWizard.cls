/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Class for building Link Wizard Content
Class %CSP.UI.SQL.LinkWizard Extends %CSP.Page [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

/// Draws Link Table specific content
ClassMethod DrawLinkTableContent(Wizard)
{
	Set lblAva = $$$TextHTML("Available")
	Set lblSel = $$$TextHTML("Selected")
	Set lblSelectColumns = $$$TextHTML("Select Columns.")
	&html<
	<!-- Select Properties -->
	<div id="page2" style="display:none">
	<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr>
	  <td colspan="2" class="Text1">#(lblSelectColumns)#</td>
	</tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td align="center">
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
	  <div id="Att" style="display:block"></div>
	</tr>
	</table>
	</div>
	>

	Set lblPage31 = $$$TextHTML("You may specify attributes for each selected column, and modify Property or Column Name in each designated text box.")
	Set lblCol1 = $$$TextHTML("Column Name From Linked Table")
	Set lblCol2 = $$$TextHTML("Read Only")
	Set lblCol3 = $$$TextHTML("New Property Name")
	Set lblCol4 = $$$TextHTML("New SQL Field Name")
	Set lblCol41= $$$TextHTML("(SQL Field Name)")
	Set lblSelectAll = $$$TextHTML("select_all")
	
	Set MaxLength = $$$MAXCLASSNAMELENGTH

	&html<
	<!-- Attributes -->
	<div id="page3" style="display:none">
	<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr>
	  <td colspan="2" class="Text1">#(lblPage31)#</td>
	</tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td colspan="2">
	<table name="SelAttr" id="SelAttr" class="columnsTable" border="0" cellpadding="2" cellspacing="2" width="96%">
	<input type="hidden" name="MaxLength" id="MaxLength" value="#(MaxLength)#">
	<tr class="ColumnHeader"><td class="ltcaption" nowrap>#(lblCol1)#</td>
	<td class="ltcaption" nowrap>#(lblCol2)#</td>
	<td class="ltcaption" nowrap>#(lblCol3)#</td>
	<td class="ltcaption" nowrap>#(lblCol4)#</td>
	</tr>
	<tr><td class="wizardlabel">&nbsp;</td>
	<td><input type="checkbox" name="checkReadOnly" onClick="selDefAll(this,'readonly');">
	<font size="2px">#(lblSelectAll)#</font></td><td>&nbsp;</td><td><font size="2px">#(lblCol41)#</font></td></tr>
	</table>
	</td></tr>
	</table>
	</div>
	>
	If Wizard = "LinkTable" {
		Do ..DrawTablePage4()
	} ElseIf Wizard = "LinkProcedure" {
		Do ..DrawProcPage4()
	} Else {
		Do ..DrawDataPage4()	
	}
}

/// Draws Link Table page 4 content
ClassMethod DrawTablePage4()
{
	Set lblPage41 = $$$TextHTML("Completing the Wizard.")
	Set lblPage42 = $$$TextHTML("Primary Key")
	Set lblPage43 = $$$TextHTML("May be a composite key, a comma separated list")
	Set MaxLength = $$$MAXCLASSNAMELENGTH
	Set lblMaxClassName = $$$TextHTML("Maximum class name length allowed")_" = "_MaxLength
	Set lblHelpKeys = $$$Text("click to select primary key")
	Set lblBrowse = $$$Text("Browse...")
	&html<
<!-- New Names -->
<div id="page4" style="display:none">
<table width="100%" border="0" cellpadding="2" cellspacing="2">

	<tr><td colspan="2" class="Text1">#(lblPage41)#
	<tr><td colspan="2">
	<div id="SelectedConnection"></div>
	<div id="SelectedSchema"></div>
	</td></tr>

	</td></tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td colspan="2">
		<div id="idPrimaryKey" style="display:none">
		<table width="100%"><tr>
	  	<td width="30%" class="wizardlabel" id="PrimaryKeyCaption">
		#(lblPage42)#*:
	  	</td>
	  	<td>
	  	<input type="text" name="PrimaryKey" id="PrimaryKey" size="40" readonly style="background:#DCDCDC;">
	  	<input type="button" id="btnBrowse" name="btnBrowse" value="#(lblBrowse)#" 
	  	title="#(lblHelpKeys)#" onclick="launchWindow('700','400');"/>
	  	</td>
		</tr>
		<tr><td>&nbsp;</td><td class="back-to-top">(#(lblPage43)#)</td></tr>
		<tr>
	  	<td width="30%" class="wizardlabel" id="NewClassNameCaption">
	  	</td>
	  	<td width="70%">
	  		<input type="text" name="NewClassName" id="NewClassName" size="40">
	  	</td>
		</tr>
		<tr><td>&nbsp;</td><td class="back-to-top">(#(lblMaxClassName)#)</td></tr>
		</table>
		</div>
	</td></tr>
	<tr>
	  <td width="30%" class="wizardlabel">
		<div id="NewTableNameCaption"></div>
	  </td>
	  <td width="70%">
	  	<input type="text" name="NewTableName" id="NewTableName" size="40">
	  </td>
	</tr>
</table>
</div>
>
	Do ..DrawResultPage(5)
}

/// Draws Link Procedure page 4 content
ClassMethod DrawProcPage4()
{
	Set lblPage41 = $$$TextHTML("Completing the Wizard.")
	Set lblPage42 = $$$TextHTML("New package name")
	Set lblPage43 = $$$TextHTML("New class name")
	Set lblPage44 = $$$TextHTML("New procedure name")
	Set lblPage45 = $$$TextHTML("Method name")
	Set lblPage46 = $$$TextHTML("Description")
	Set MaxLength = $$$MAXCLASSNAMELENGTH
	Set lblMaxClassName = $$$TextHTML("Maximum class name length allowed")_" = "_MaxLength
	&html<
<!-- New Names -->
<div id="page4" style="display:none">
<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr><td colspan="2" class="Text1">#(lblPage41)#</td></tr>
	<tr><td colspan="2">
	<div id="SelectedConnection"></div>
	<div id="SelectedSchema"></div>
	</td></tr>

	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr>
	  <td width="30%" nowrap class="wizardlabel" id="NewTableNameCaption">
		#(lblPage42)#*:<input type="hidden" name="PrimaryKey" id="PrimaryKey">
	  </td>
	  <td width="70%">
	  	<input type="text" name="NewTableName" id="NewTableName" size="40">
	  </td>
	</tr>
	<tr><td colspan="2">
	<div id="idPrimaryKey" style="display:none">
		<table width="100%">
		<tr>
	  	<td width="30%" class="wizardlabel" id="NewClassNameCaption">
		#(lblPage43)#*:
	  	</td>
	  	<td width="70%" nowrap>
	  	<input type="text" name="NewClassName" id="NewClassName" size="40">
	  	</td>
		</tr>
		<tr><td>&nbsp;</td><td class="back-to-top">(#(lblMaxClassName)#)</td></tr>
		<tr>
	  	<td width="30%" class="wizardlabel" nowrap>
		#(lblPage44)#*:
	  	</td>
	  	<td width="70%">
	  	<input type="text" name="ProcedureName" id="ProcedureName" size="40">
	  	</td>
		</tr>
		<tr><td class="wizardlabel">#(lblPage45)#*:</td>
		<td><input type="text" name="MethodName" size="40"></td>
		</tr>
		<tr><td class="wizardlabel">#(lblPage46)#:</td>
		<td><input type="text" maxlength="100" name="Description" size="40">
		</tr>
		</table>
	</div>
	</td></tr>

</table>
</div>
>
	Do ..DrawResultPage(5)
}

/// Draws Data Migration page 4 content
ClassMethod DrawDataPage4()
{
	Set lblCol1 = $$$TextHTML("New Schema")
	Set lblCol2 = $$$TextHTML("Name")
	Set lblCol3 = $$$TextHTML("Type")
	Set lblCol4 = $$$TextHTML("Copy Definition")
	Set lblCol5 = $$$TextHTML("Copy Data")
	Set lblSelectAll = $$$TextHTML("select_all")
	Set lblChangeAll = $$$TextHTML("change_all")
	Set lblPage31 = $$$TextHTML("You may specify new schema name(s), and whether you want to copy definition or data for each table/view.")

	&html<
	<div id="page4" style="display:none">
	<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr>
	  <td colspan="2" class="Text1">#(lblPage31)#</td>
	</tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td colspan="2">

	<table name="SelCopy" id="SelCopy" class="columnsTable" border="0" cellpadding="2" cellspacing="2" width="96%">
	<tr class="ColumnHeader"><td class="ltcaption">#(lblCol1)#</td><td class="ltcaption">#(lblCol2)#</td><td class="ltcaption">#(lblCol3)#</td><td class="ltcaption">#(lblCol4)#</td><td class="ltcaption">#(lblCol5)#</td></tr>
	<tr><td><input type="text" name="txtAllNewSchema" id="txtAllNewSchema" size="12" value=""><input type="button" name="btnAllNewSchema" id="btnAllNewSchema" value="#(lblChangeAll)#" onclick="changeAllNewSchema();"></td>
	<td>&nbsp;</td><td>&nbsp;</td><td><input type="checkbox" name="CopyDefAll" checked onClick="selDefAll(this,'copyDef');"><font size="2px">#(lblSelectAll)#</font></td><td><input type="checkbox" name="CopyDataAll" checked onClick="selDefAll(this,'copyData');"><font size="2px">#(lblSelectAll)#</font></td></tr>
	<input type="hidden" name="PrimaryKey" id="PrimaryKey">
	</table>
	</td></tr></table>
	</div>
>
	Do ..DrawDataPage5()
}

/// Draws Data Migration page 5 content (YSD1997) to set NOCHECK,DeferIndices,NOTRIGGER,DeleteExistingData,MaxErrors
ClassMethod DrawDataPage5()
{
	Set lblPage51 = $$$TextHTML("Completing the Wizard.")
	Set lblDisable = $$$TextHTML("Disable validation")
	Set msgDisable = $$$TextHTML("If checked, import will insert with %NOCHECK")
	Set lblDefer = $$$TextHTML("Defer indices")
	Set msgDefer = $$$TextHTML("Generate indices after importing data")
	Set lblNoTrigger = $$$TextHTML("Disable triggers")
	Set msgNoTrigger = $$$TextHTML("If checked, import will insert with %NOTRIGGER")
	Set lblNoJournal = $$$TextHTML("Disable journaling for the importing process")
	Set msgNoJournal = $$$TextHTML("If checked, the importing process will disable journaling")
	Set lblDelete = $$$TextHTML("Delete existing data from table before importing")
	Set lblTuneTable = $$$TextHTML("Tune Table after data migration is done")
	Set msgTuneTable = $$$TextHTML("Cached queries will be purged before tune table is run for affected tables")
	Set lblMaxErrors = $$$TextHTML("Maximum errors to report per table")
	Set msgMaxErrors = $$$TextHTML("Maximum number of data import errors to report per table when copying data. Default is 30.")
	&html<
	<div id="page5" style="display:none">

	<table width="100%" border="0" cellpadding="2" cellspacing="2">

	<tr><td colspan="2" class="Text1">#(lblPage51)#
	<tr><td colspan="2">
	<div id="SelectedConnection"></div>
	<div id="SelectedSchema"></div>
	</td></tr>

	</td></tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr><td colspan="2">
		<table width="100%">
	  	<tr><td width="30%" class="wizardlabel">#(lblDisable)#:</td>
	  	<td width="70%" class="back-to-top"><input type="checkbox" name="NoCheck" checked>(#(msgDisable)#)</td></tr>
		
		<tr><td width="30%" class="wizardlabel">#(lblDefer)#:</td>
	  	<td width="70%" class="back-to-top"><input type="checkbox" name="DeferIndices" checked>(#(msgDefer)#)</td></tr>
		
		<tr><td width="30%" class="wizardlabel">#(lblNoTrigger)#:</td>
	  	<td width="70%" class="back-to-top"><input type="checkbox" name="NoTrigger" checked>(#(msgNoTrigger)#)</td></tr>
		
		<tr><td width="30%" class="wizardlabel">#(lblNoJournal)#:</td>
	  	<td width="70%" class="back-to-top"><input type="checkbox" name="NoJournal">(#(msgNoJournal)#)</td></tr>
	  	
		<tr><td width="30%" class="wizardlabel">#(lblDelete)#:</td>	
	  	<td width="70%"><input type="checkbox" name="DeleteExistingData" checked></td></tr>
		
		<tr><td width="30%" class="wizardlabel">#(lblTuneTable)#:</td>
	  	<td width="70%" class="back-to-top"><input type="checkbox" name="TuneTable" checked>(#(msgTuneTable)#)</td></tr>

		</table>
		
	</td></tr>
</table>
</div>
>
}

/// Draws Result Page
ClassMethod DrawResultPage(pagenumber)
{
	Set msg = $$$TextHTML("Process in progress. Please wait...")
	&html<
	<div id="page#(pagenumber)#" style="display:none">
	<table width="100%" border="0" cellpadding="2" cellspacing="2">
	<tr><td colspan="2" class="Text1"></td></tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></tr>
	<tr>
	  <td nowrap>
	  </td>
	  <td>
	  </td>
	</tr>
	<tr><td colspan="2"><hr align="center" size="1" color="teal" noshade></td></tr>
	<tr><td colspan="2"><div id="idProgress" style="display:none">
	<img src="#(..Link("/csp/sys/images/aniclock0.gif"))#" width="100" height="100" border="0">
	<br>
	#(msg)#
	</div></td></tr>

	</table>
	</div>
	>
}

}
