/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane handles displaying, selecting, and compiling classes and routines.
Class %CSP.UI.System.FindPane Extends %CSP.Util.ExpPane [ System = 4 ]
{

Method CreateResultSet(ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	Set Query = "%RoutineMgr:StudioOpenDialog"
	If %request.PageName [ "Routine" {
		Set SEARCHMASK = ..GetSearchMask()
		#;YSD1759 If SEARCHMASK '[ ";" Set Query = "%Routine:RoutineList"
	} Else {
		If %request.PageName [ "Global" Set Query = "%SYS.GlobalQuery:NameSpaceList"
	}
	Set pRS = ##class(%ResultSet).%New(Query)
	If ('pRS.QueryIsValid()) {
		Quit $$$ERROR($$$GeneralError,"Invalid Query: " _ Query)
	}
	Quit tSC
}

Method DrawTable(ByRef pRS As %String)
{
	&html<<table class="DetailTable" border="0" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">>
	Set ColMax = 3
	Set tRow = 0
	Set tCol = 1
	Set tTotalRows = 1
	While pRS.Next() {
		If pRS.GetData(1) '[ "(" {
			Set tRow = tRow + 1
			If tRow = 1 Do ..DrawButtons(ColMax) &html<<tr class="OddRow">>
			Set tId = "cb_"_tRow
			Set tName = pRS.GetData(1)
			&html<<td nowrap><input type="checkbox" name="#(tId)#" id="#(tId)#" value='#($ZCVT(tName,"O","HTML"))#'>#($ZCVT(tName,"O","HTML"))#</td>>
			If tCol < ColMax {
				Set tCol = tCol + 1
			} Else {
				Set tCol = 1
				Set tTotalRows = tTotalRows + 1
				&html<</tr>>
				&html<<tr class="#($S(tTotalRows#2:"OddRow",1:"EvenRow"))#">>
			}
		}
	}
	For t = tCol:1:ColMax &html<<td>&nbsp;</td>>
	&html<<input type="hidden" name="TotalRows" id="TotalRows" value="#(tRow)#">>
	If tRow = 0 {
		&html<<td nowrap>#($$$Text("No match found."))#</td>>
	} Else {
		&html<<tr><td cols="3" nowrap>#($$$Text("Total: "))##(tRow)#</td>>
		&html<</table>>
	}
	&html<</form>>
}

/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, SEARCHMASK As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	
	Set showSystemItems = $G(%request.Data("showSystemItems",1)) = "on"
	If %request.PageName [ "Class" {
		If $E(SEARCHMASK,$L(SEARCHMASK)-3,$L(SEARCHMASK))'=".cls" Set SEARCHMASK = SEARCHMASK_".cls"
		Set tSC = pRS.Execute(SEARCHMASK,,,showSystemItems,1,1)  //flat is set to 1,NotStudio is set to 1
	} ElseIf %request.PageName [ "Routine" {
		#;YSD1759 Set tSC = pRS.Execute(SEARCHMASK,1,1)
		Set tNewSpec = ..GetMask(SEARCHMASK)
		Set tSC = pRS.Execute(tNewSpec,,,showSystemItems,1,1)
	} Else {
		Set tSC = pRS.Execute($namespace,SEARCHMASK,showSystemItems)
	}
	
Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Overwritten by subclasses to draw anything this pane needs for the BODY section.
Method DrawBODY(pInstance As PageInstance) As %Status
{

	&html<<div class="Text1">#(..GetDescriptiveText())#</div>>

	&html<
	<script language="javascript">
function openFind(thisForm,replace)
{
	var TotalRows = document.getElementById("TotalRows").value;
	var cbState = "";
	for (var i = 1; i <= TotalRows; i++) {
		if (self.document.getElementById("cb_"+i).checked == true) {
			cbState = cbState + "," + self.document.getElementById("cb_"+i).value;
			break;
		}
	}
	document.getElementById("cbState").value = cbState;
	if (cbState.length < 1) {
		alert('#($$$TextJS("Nothing selected."))#');
	} else {
		document.getElementById("rep").value = replace;
		var cbAction = document.getElementById("cbAction").value;
		var wid = self.screen.width;
		var hgt = self.screen.height;
		wid = wid * 0.8;
		hgt = hgt * 0.8;
		var top = self.screen.height * 0.1;
		var left = self.screen.width * 0.1;
		var emptypage = document.getElementById("emptypage").value;
		// this will make the submit open in the popup window and you can close it without browser confirming for closing.
		self.autopagePopupWindow = window.open(emptypage,'autopagePopup','left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable');
	}
}
// generic function called from /csp/sys/UtilFileSelect.csp
function update(remotefile)
{
	document.getElementById("RemoteFileName").value = remotefile;
}
// onSubmit check: if user did not choose any item, abort submit
function check()
{
	if (document.getElementById("cbState").value == "") {
		return false;	
	} else {
		return true;	
	}
}

</script>	
	
	>
	Do ..DrawCommandForm(pInstance)

	Set FileName = $G(%request.Data("RemoteFileName",1))
	If FileName = "" Set FileName = $zu(12)_"export.xml"
	Set findpage = ##class(%CSP.Page).Link("/csp/sys/exp/UtilExpFindReplace.csp")
	Set actionpage = %request.PageName_"?$NAMESPACE="_$namespace
	Set emptypage = ##class(%CSP.Page).Link("/csp/sys/UtilEmpty.csp")
	&html<<form name="expform" method="post" target="" action="#(actionpage)#" >>
	&html<<input type="hidden" name="$NAMESPACE" id="$NAMESPACE" value="#($ZCVT($namespace,"O","HTML"))#">>
	&html<<input type="hidden" name="actionpage" id="actionpage" value="#(actionpage)#">>
	&html<<input type="hidden" name="emptypage" id="emptypage" value="#(emptypage)#">>
		
	Set SEARCHMASK = ..DrawSearchField("Fin")
	
	&html<</form><form name="listForm"  method="post" target="autopagePopup" action="#(findpage)#" onsubmit="return check();">>
	&html<<input type="hidden" name="cbAction" id="cbAction" value="#($S(%request.PageName["Global":"Global",1:"Routine"))#">>
	&html<<input type="hidden" name="cbState" id="cbState" value="">>
	&html<<input type="hidden" name="rep" id="rep" value="">>
	If %request.PageName["Global" &html<<p class="ltcaption">#($$$Text("Select globals from the list. Selecting fewer globals results in a faster search. "))#</p>>
	Else  &html<<p class="ltcaption">#($$$Text("Select routines from the list. Selecting fewer routines results in a faster search. "))#</p>>
	Set tSC = ..CreateResultSet(.pRS)
	If $$$ISERR(tSC) {
		&html<#($ZCVT($System.Status.DisplayErrorText(tSC),"O","HTML"))#>
	} Else {
		Set tSC = ..ExecuteResultSet(.pRS,SEARCHMASK)
		Do ..DrawTable(pRS)
	}
	Quit $$$OK
}

Method DrawButtons(ColMax As %Integer)
{
	&html<<tr><td colspan="#(ColMax)#" align="left"><input type="button" name="SelectAll" value='#($$$Text("Select All"))#' onclick="toggleCheckboxes(true);">>
	&html<<input type="button" name="UnselectAll" value='#($$$Text("Unselect All"))#' onclick="toggleCheckboxes(false);">>
	&html<<input type="submit" name="OK" id="OK" value='#($$$Text("Find..."))#' onclick="openFind(form,0);">>
	#;YSD2381 If $System.Security.Check("%Development","USE") &html<<input type="submit" name="btnReplace" id="btnReplace" value='#($$$Text("Replace..."))#' onclick="openFind(form,1);">>
	If $System.Security.Check("%Development","USE"),$namespace '= "%SYS" &html<<input type="submit" name="btnReplace" id="btnReplace" value='#($$$Text("Replace..."))#' onclick="openFind(form,1);">>
}

}
