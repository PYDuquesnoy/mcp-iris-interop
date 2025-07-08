/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane handles displaying, selecting, and compiling classes and routines.
Class %CSP.UI.System.DeletePane Extends %CSP.Util.ExpPane [ System = 4 ]
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
	Set showSystemItems = $S($G(%request.Data("showSystemItems",1))="on":1,1:"")	
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
function legacyFormat(thisForm)
{
	var legacy = document.getElementById("LegacyFormat");
	if (thisForm.DeleteFormat.options[thisForm.ExportFormat.selectedIndex].value == "GO") {
		legacy.style.display = "block";	
	} else {
		legacy.style.display = "none";
	}
}
// generic function called from /csp/sys/UtilFileSelect.csp
function update(remotefile)
{
	document.getElementById("RemoteFileName").value = remotefile;
}
function deleteclick(flag)
{
	document.getElementById("isdelete").value = flag;
}
function validate()
{
	var a = document.getElementById("isdelete").value;
	if (document.getElementById("isdelete").value == 0) return true;
	if (confirm('#($$$TextJS("Are you sure you want to delete selected items?"))#') == false) {
		deleteclick(0);
		return false;
	} else {
		return true;	
	}
}
</script>	
	
	>
	Set msgBackground = $$$TextHTML("Check here to run delete in the background")	
	Do ..DrawCommandForm(pInstance)
	#;YSD1796 Set SEARCHMASK = ..GetSearchMask()
	//Set ^IRIS.Temp.MgtPortalSettings($UserName,"SEARCHMASK",%request.PageName) = SEARCHMASK
	Set FileName = $G(%request.Data("RemoteFileName",1))
	If FileName = "" Set FileName = $zu(12)_"export.xml"
	Set ServerName = $zu(110)
	&html<<form name="expform" method="post" action="#(%request.PageName)#?$NAMESPACE=#($namespace)#" onsubmit="return validate();">>
	&html<<p class="ltcaption"><input type="checkbox" name="chkBackground" #($S($G(%request.Data("chkBackground",1))'="":"checked",1:""))#>#(msgBackground)#</p>>
	&html<<input type="hidden" name="$NAMESPACE" value="#($namespace)#">>
	&html<<input type="hidden" name="isdelete" id="isdelete" value="0">>
	
	Set SEARCHMASK = ..DrawSearchField("Del")

	If $G(%request.Data("OK",1)) '= "" {
		Do ..DrawResult(FileName)
	} Else {
		Set tSC = ..CreateResultSet(.pRS)
		If $$$ISERR(tSC) {
			&html<#($ZCVT($System.Status.DisplayErrorText(tSC),"O","HTML"))#>
		} Else {
			Set tSC = ..ExecuteResultSet(.pRS,SEARCHMASK)
			#;YSD2501 If %request.PageName["Routine" Do ..DrawOptions()
			Do ..DrawTable(pRS)
			Do ##class(%CSP.Util.ExpPane).WriteBackupMsg(SEARCHMASK)
		}
	}
	Quit $$$OK
}

Method DrawResult(FileName)
{
	Set $ZT = "Trap"
	Do {
		Set TotalRows = +$G(%request.Data("TotalRows",1))
		If TotalRows = 0 &html<<p nowrap>#($$$Text("No match found."))#</p>>
		Set chkBackground = $G(%request.Data("chkBackground",1))
		#;YSD2501 Set RoutineDeleteOption = $G(%request.Data("RoutineDeleteOption",1),1)
		Set DeleteType = $S(%request.PageName["Global":"G",%request.PageName["Routine":"R",1:"C")
		Set tName = ""
		Set (tRow,tTotal) = 0
		If chkBackground '= "" {
			While tRow < TotalRows {
				Set tRow = tRow + 1
				Set tId = "cb_"_tRow
				If $G(%request.Data(tId,1))'="" {
					Set tTotal = tTotal + 1
					Set tItems(%request.Data(tId,1))=""
					// YSD1368 Set $li(tParms("Columns"),tTotal) = %request.Data(tId,1)
				}
			}
			Set tParms("TotalColumns") = tTotal
			#;YSD2501 Set tParms("RoutineDeleteOption") = RoutineDeleteOption
			Set tParms("DeleteType") = DeleteType
			Set msg1 = $$$TextHTML("This task will be run in the background.")
			Set msg2 = $$$TextHTML("Click here to view the background tasks page.")
			Set linkpage = ##class(%CSP.Page).Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen")

		 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("Delete",$namespace,.tParms,.tItems,.tJob)
			If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
		 	&html<<h2>#(msg1)#&nbsp;<a href="#(linkpage)#">#(msg2)#</a></h2>>					
		} Else {
			&html<<pre>>
			Set tRow = 0
			Set tItems = 0
			Set lblDelete = $$$Text("Deleting")
			If DeleteType = "R" {
				#;YSD2501 Set ^IRIS.Temp.MgtPortalSettings($UserName,"RoutineDeleteOption") = RoutineDeleteOption
				#;YSD2501 &html<<input type="hidden" name="RoutineDeleteOption" value="#(RoutineDeleteOption)#">>		
			}
			While tRow < TotalRows {
				Set tRow = tRow + 1
				Set tId = "cb_"_tRow
				If $G(%request.Data(tId,1))'="" {			
					Set tItems = tItems + 1
					Set tName = %request.Data(tId,1)
					If DeleteType = "G" {
						Set tName = "^"_tName
						Write !,lblDelete," ",$zconvert(tName,"O","HTML")
						Set tSC = ##class(%Studio.Global).Kill(tName, 1)
						Do ..DoneMsg(tSC)
					} Else {
						Write !,lblDelete," ",$zconvert(tName,"O","HTML")
						If DeleteType = "R" {
							#;YSD2501 Set tSC = ##class(%Routine).Delete(tName,RoutineDeleteOption)
							Set tSC = ##class(%RoutineMgr).Delete(tName)
							Do ..DoneMsg(tSC)
						} Else { // classes
							Set tSC = $System.OBJ.Delete(tName,"-d")
							Do ..DoneMsg(tSC)
						} 
					}
				}
			}
			If tItems = 0 {
				Write !,$$$Text("Nothing selected.")
			} Else {
				Write !!,$$$Text("Completed at "),$ZDT($h,3)
			}
			&html<</pre>>
		}
	} While(0)
Done
	Quit	
Trap
	Set $ZT=""	
	Write "Error trap: ",$ZE,!
	Goto Done
}

Method DrawButtons(ColMax As %Integer)
{
	&html<<tr><td colspan="#(ColMax)#" align="left"><input type="button" name="SelectAll" value='#($$$Text("Select All"))#' onclick="toggleCheckboxes(true);">>
	&html<<input type="button" name="UnselectAll" value='#($$$Text("Unselect All"))#' onclick="toggleCheckboxes(false);">>
	&html<<input type="submit" name="OK" id="OK" value='#($$$Text("Delete"))#' onclick="deleteclick(1);"></td></tr>>
}

/// Write common message after action is commited.
ClassMethod DoneMsg(tSC)
{
	Write " "
	If tSC = 1 Write $$$Text("...Done.")
	Else  Write $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
}

/// Draws routine delete options (Obsolete see YSD2501)
Method DrawOptions()
{
	Set RoutineDeleteOption = $G(%request.Data("RoutineDeleteOption",1))
	If RoutineDeleteOption = "" Set RoutineDeleteOption = $G(^IRIS.Temp.MgtPortalSettings($UserName,"RoutineDeleteOption"),1)
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"RoutineDeleteOption") = RoutineDeleteOption
	Set Opt(1) = $$$TextHTML("Delete entire routine (e.g. deleting a mac routine will also delete int and obj routine)")
	Set Opt(2) = $$$TextHTML("Delete just the named routine")
	Set Opt(3) = $$$TextHTML("Delete all the source code but leave any OBJ code")
	&html<<p class="ltcaption">#($$$TextHTML("Delete options"))#: </p>>
	&html<<table class="Options">>
	&html<<tr><td><table class="Option">>

	Set tRow = 1
	While tRow < 4 {
		Set tId = "cp_"_tRow
		Set tValue = tRow - 1
		&html<<tr><td nowrap><input type="radio" name="RoutineDeleteOption" id="#(tId)#" value="#($zconvert(tValue,"O","HTML"))#" #($S(RoutineDeleteOption=tValue:"checked",1:""))#>#(Opt(tRow))#</td></tr>>
		Set tRow = tRow + 1
	}
	&html<</table></td></tr></table><br>>
}

/// Method to Delete in the background 
/// tItems array is passed in for selected items
ClassMethod Delete(ByRef pParms As %String, ByRef tItems As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set msgDone = $$$Text("Done")
	Set HasError = 0
	Do {
		Set DeleteType = $G(pParms("DeleteType"))
		#;YSD2501 Set RoutineDeleteOption = $G(pParms("RoutineDeleteOption"))
		Set tName = $O(tItems(""))
		While tName '= "" {
			If DeleteType = "G" {
				Set tSC = ##class(%Studio.Global).Kill("^"_tName, 1)
				If $$$ISERR(tSC) Set HasError=1 Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
			} Else {
				If DeleteType = "R" {
					#;YSD2501 Set tSC = ##class(%Routine).Delete(tName,RoutineDeleteOption)
					Set tSC = ##class(%RoutineMgr).Delete(tName)
					If $$$ISERR(tSC) Set HasError=1 Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
				} Else { // classes
					Set tSC = $System.OBJ.Delete(tName,"-d")
					If $$$ISERR(tSC) Set HasError=1 Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
				} 
			}
			Set tName = $O(tItems(tName))
		}
		If HasError = 1 Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("ERROR")
		Else  Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = msgDone
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($ZE)
	Goto Done
}

}
