/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Super class for explorer activity pane
Class %CSP.Util.ExpPane Extends %CSP.Util.Pane [ System = 4 ]
{

Method DrawTable(ByRef pRS As %String)
{
	&html<<table class="DetailTable" border="0" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">>
	Set ColMax = 3
	Set tRow = 0
	Set tCol = 1
	Set tTotalRows = 1
	While pRS.Next() {
		Set tRow = tRow + 1
		If tRow = 1 Do ..DrawButtons(ColMax) &html<<tr class="OddRow">>
		Set tId = "cb_"_tRow
		Set tName = pRS.GetData(1)
		&html<<td nowrap><input type="checkbox" name="#(tId)#" id="#(tId)#" value='#(tName)#'>#($ZCVT(tName,"O","HTML"))#</td>>
		If tCol < ColMax {
			Set tCol = tCol + 1
		} Else {
			Set tCol = 1
			Set tTotalRows = tTotalRows + 1
			&html<</tr>>
			&html<<tr class="#($S(tTotalRows#2:"OddRow",1:"EvenRow"))#">>
		}
	}
	For t = tCol:1:ColMax &html<<td>&#032;</td>>
	&html<<input type="hidden" name="TotalRows" id="TotalRows" value="#(tRow)#">>
	If tRow = 0 {
		&html<<td nowrap>#($$$Text("No match found."))#</td>>
	} Else {
		&html<<tr><td cols="3" nowrap>#($$$Text("Total: "))##(tRow)#</td>>
		If tRow > 1 {
			Do ..DrawButtons(ColMax)
		}

		&html<</table>>
	}
	&html<</form>>
}

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{

	&html<<script language="JavaScript">
// set all the checkboxes true or false
function toggleCheckboxes(cbState)
{
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		cb.checked = cbState;
	}
}
// User clicked a routine extension link. Update the search mask and submit.
function loadMask(mask,type)
{
	self.document.getElementById("$SEARCHMASK").value = mask;
	if (type == "Exp") {
		if (mask=="*.obj") self.document.getElementById("ExportOBJ").checked = true;
		else self.document.getElementById("ExportOBJ").checked = false;
	}
	self.document.expform.submit();
}
function hint()
{
	var style = document.getElementById("id_hint").style;
	if (style.display == "none") style.display = "block";
	else style.display = "none";
}
	</script>

	>
	&html<
		<style type="text/css">
.ltcaption {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	color: darkblue;
	text-align: left;
	font-weight: bold;
}
.rednote {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	color: red;
	text-align: left;
	font-weight: bold;
}
.note {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	text-align: left;
	font-weight: normal;
}
table.Options {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	margin: 0px;
	padding: 0px;
	border: 1px solid gray;
}
table.Option {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	margin: 0px;
	padding: 0px;
}
table.vline {
	border-right: 1px solid gray;
}

</style>
	>	
	Quit $$$OK
}

/// Write common message after action is commited.
ClassMethod DoneMsg(tSC)
{
	Write " "
	If tSC = 1 Write "..."_$$$Text("Done")
	Else  Write $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
}

/// Write out error log
Method DrawErrorLog(err)
{
	If $G(err) > 0 {
		Use 0
		Write !,$$$Text("Error Log")_": "
		Set errcnt = $o(err(""))
		While errcnt '= "" {
			Write !,errcnt,?10,$g(err(errcnt))
			Set errname = ""
			For  Set errname = $O(err(errcnt,errname)) Quit:errname=""  Write !,?5,errname,?25,$ZCVT($G(err(errcnt,errname)),"O","HTML")
			Set errcnt = $o(err(errcnt))	
		}
		Write !
	}
}

Method DrawButtons(ColMax As %Integer)
{
	&html<<tr><td colspan="#(ColMax)#" align="center">>
	&html<<input type="button" name="SelectAll" value='#($$$Text("Select All"))#' onclick="toggleCheckboxes(true);">>
	&html<<input type="button" name="UnselectAll" value='#($$$Text("Unselect All"))#' onclick="toggleCheckboxes(false);">>
	&html<<input type="submit" name="OK" id="OK" value='#($$$Text(" OK "))#'></td></tr>>
}

/// Return (localized) text message displayed near top of page.
/// Ignore value in CSP file
Method GetDescriptiveText()
{
	Set tType = ..GetPageType()
	Set msg = ""
	// see if we are in a namespace or an implied namespace
	Set svr = ""
	Set tIsImpliedNS = ($E($namespace,1,1)="^")
	If (tIsImpliedNS) {
		Set tContainer = "database"
		Set t = $E($namespace,2,*)
		Set tNS = $P(t,"^",$L(t,"^"))
		Set tServer = $P(t,"^",$L(t,"^")-1)
		If tType = "Routines" {
			If tServer = "" {
				Set msg = $$$FormatText($$$Text("Routines in database %1"),tNS)
			} Else {
				Set msg = $$$FormatText($$$Text("Routines in database %1 on server %2"),tNS, tServer)				
			}
		} ElseIf tType = "Classes" {
			If tServer = "" {
				Set msg = $$$FormatText($$$Text("Classes in database %1"),tNS)				
			} Else {
				Set msg = $$$FormatText($$$Text("Classes in database %1 on server %2"),tNS, tServer)				
			}
		} ElseIf tType = "GlobalView" {
			If tServer = "" {
				Set msg = $$$FormatText($$$Text("View global in database %1"),tNS)				
			} Else {
				Set msg = $$$FormatText($$$Text("View global in database %1 on server %2"),tNS, tServer)				
			}
		} ElseIf tType = "GlobalDrill" {
			If tServer = "" {
				Set msg = $$$FormatText($$$Text("Edit global in database %1"),tNS)				
			} Else {
				Set msg = $$$FormatText($$$Text("Edit global in database %1 on server %2"),tNS, tServer)				
			}
		} ElseIf tType = "Globals" {
			If tServer = "" {
				Set msg = $$$FormatText($$$Text("Globals in database %1"),tNS)				
			} Else {
				Set msg = $$$FormatText($$$Text("Globals in database %1 on server %2"),tNS, tServer)				
			}
		}
	}
	Else {
		Set tNS = $namespace
		If tType = "Routines" {
			Set msg = $$$FormatText($$$Text("Routines in namespace %1"),tNS)	
		} ElseIf tType = "Classes" {
			Set msg = $$$FormatText($$$Text("Classes in namespace %1"),tNS)
		} ElseIf tType = "GlobalView" {
			Set msg = $$$FormatText($$$Text("View global in namespace %1"),tNS)		
		} ElseIf tType = "GlobalDrill" {
			Set msg = $$$FormatText($$$Text("Edit global in namespace %1"),tNS)		
		} ElseIf tType = "Globals" {
			Set msg = $$$FormatText($$$Text("Globals in namespace %1"),tNS)			
		}
	}
		
	Quit msg_":"
}

/// This method returns the page type based on PageName
Method GetPageType() As %String
{
	Set PageName = %request.PageName
	If PageName [ "Routine" Quit "Routines"
	If PageName [ "Class" Quit "Classes"
	If PageName [ "GlobalView" Quit "GlobalView"
	If PageName [ "GlobalDrill" Quit "GlobalDrill"
	If PageName [ "Global" Quit "Globals"
	Quit "Files"
}

/// Generic method to draw error message for object status code, copied from %CSP.Util.TablePane
ClassMethod DrawStatusError(tSC As %String)
{
	Kill err
	Do $System.Status.DecomposeStatus(tSC,.err)
	&html<<div style="color:red; margin-left: 20px;" align="left" ><br>>
	Set ecnt = ""
	For  Set ecnt = $O(err(ecnt)) Quit:ecnt=""  &html<<b>#($ZCVT(err(ecnt),"O","HTML"))#</b><br>>
	&html<</div>>
}

ClassMethod SetAlarmTimeout()
{
	Set responseTimeout = %request.GatewayTimeout - 5
	If responseTimeout < 15 Set responseTimeout = 15
	Do $System.Alarm.Set(responseTimeout)
}

ClassMethod GetAlarmTimeout() As %Integer
{
	Set responseTimeout = %request.GatewayTimeout - 5
	If responseTimeout < 15 Set responseTimeout = 15
	Quit responseTimeout
}

/// Generic Method being called from the Routine panes to return search mask.
ClassMethod GetSearchMask() As %String
{
	#; submitted from particular pane for Search
	Set SEARCHMASK = $G(%request.Data("$SEARCHMASK",1))
	#; passed in from routine list page
	If SEARCHMASK = "" Set SEARCHMASK = $G(%request.Data("$ID1",1))
	#; get from last save
	If SEARCHMASK = "" Set SEARCHMASK = $G(^IRIS.Temp.MgtPortalSettings($UserName,"SEARCHMASK",%request.PageName))
	#; if search mask contains ";" that means user wants to see back up routines. We only support all back routines
	#; i.e. the query will not be able to return *.*;1 that matches ;1 so all will be returned such as *.*;*
	If SEARCHMASK [ ";" Set SEARCHMASK = $P(SEARCHMASK,";",1)_";*"
	#; set default if nothing
	If SEARCHMASK = "" Set SEARCHMASK = $S(%request.PageName["Class":"*.cls",%request.PageName["Routine":"*.mac",1:"*")
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"SEARCHMASK",%request.PageName) = SEARCHMASK
	Quit SEARCHMASK
}

/// Generic Method being called from the Routine panes to write out message for backup routines.
ClassMethod WriteBackupMsg(SEARCHMASK)
{
	If SEARCHMASK [ ";",%request.PageName [ "Routine" &html<<div class="back-to-top" nowrap>#($$$Text("You have elected to display legacy backup routines."))#</div><br>>
}

/// Generic Method for Export/Delete/Find/Compile for Classes/Globals/Routines when applicable
/// SEARCHMASK is returned
ClassMethod DrawSearchField(type) As %String
{
	Set SEARCHMASK = ##class(%CSP.Util.ExpPane).GetSearchMask()	
	Set showSystemItems = $G(%request.Data("showSystemItems",1))
	Set sSystemTitle = $$$Text("Include system items in search.")
	Set sHint = $$$TextHTML("You may use ""*"" as wildcard and use commas for multiple. ")
	&html<<p class="ltcaption">#($$$TextHTML("Enter search mask"))#:>
	&html<<input type="text" name="$SEARCHMASK" id="$SEARCHMASK" size="40" value="#($zconvert(SEARCHMASK,"O","HTML"))#">>
	&html<<input type="submit" name="Search" value='#($$$Text("Search"))#'>>
	&html<<input type="checkbox" name="showSystemItems" id="showSystemItems" title="#(sSystemTitle)#" onclick="document.expform.submit();" #($S(showSystemItems="on":"checked",1:""))#>#($$$TextHTML("System"))#>

	&html<<br><a class="back-to-top" href="javascript:hint();">#($$$TextHTML("hint"))#</a>>
	If %request.PageName [ "Routine" {
		Set sHint = sHint _ $$$TextHTML("Use semicolon for legacy backup routines only.")
		&html<&nbsp;&nbsp;&nbsp;&nbsp;>
		Do ..DrawRoutineLinks(type)
	} ElseIf %request.PageName [ "Global" {
		Set sHint = sHint _ $$$TextHTML("Example: 'C*' will list all globals starting with 'C'.")
	}
	&html<<div id="id_hint" class="back-to-top" style="display:none">#(sHint)#</div>>	
	&html<</p>>
	Quit SEARCHMASK
}

/// Generic Method - Draws the extention links for routines under the Search text field.
ClassMethod DrawRoutineLinks(type)
{
	Set titleText = $$$TextJS("click to search this type of routine")
	#;YSD1850 Set links = "*.mac,*.int,*.inc,*.bas,*.mvb,*.mvi,*.obj"
	#;YSD2501 Set links = "*.mac,*.int,*.inc,*.bas,*.obj"
	Set links = "*.mac,*.int,*.inc,*.bas,*.mvb,*.mvi,*.obj"
	&html<<span class="FilterLabel">>
	For p = 1:1:7 Set mask = $P(links,",",p) &html<<a href="javascript:loadMask('#(mask)#','#(type)#')" title="#(titleText)#">#(mask)#</a>&nbsp;>			
	&html<</span>>
	Quit
}

/// Generic Method - This method takes in what user typed in the mask field for ROUTINES and
/// build it into a mask that the query will be able to process.
ClassMethod GetMask(tSpec) As %String
{
	Set tRoutineTypes = ",.mac,.int,.inc,.bas,.mvb,.mvi,.obj,"
	Set tNewSpec = ""
	Set tFound = 0
	Set tCnt = 1
	Set:tSpec'["." tSpec = tSpec_".*"
	Set p1 = $P(tSpec,",",tCnt)
	While p1 '= ""&('tFound)  {
		Set p0 = $E(p1,*-1,*)
		#; YSD2067/YSD2804 - if user enters no extension, add all. Otherwise query will return non-routines too.
		If p0 = ".*" {
			Set p1 = $E(p1,1,*-2)	
			For i = 2:1:8 Set tArray(p1_$P(tRoutineTypes,",",i))=""						
		} Else {
			Set tExt = $ZCVT($E(p1,*-3,*),"L")
			#; Filter out the none routine extentions
			If tRoutineTypes [ (","_tExt_",") {
				Set tArray(p1) = ""
			} Else {
				#; If user entered at least one *.* then we build the array and quit the loop
				If p1="*"!(p1="*.*") {
					Set tLenth = $S(p1="*":7,1:8)
					For i = 2:1:tLenth Set tArray("*"_$P(tRoutineTypes,",",i))=""
					Set tFound = 1
				} ElseIf p1[".",$E(p1,*) = "*" {
					Set tArray(p1) = ""	
				} Else {
					#; user entered non-routine or none-sense extensions. Add routine extension to the end.
					For i = 2:1:7 Set tArray(p1_$P(tRoutineTypes,",",i))=""
				}
			}
		}
		Set tCnt = tCnt + 1
		Set p1 = $P(tSpec,",",tCnt)	
	}
	Set p1 = "" 
	For  Set p1 = $O(tArray(p1)) Quit:p1=""  Set tNewSpec = tNewSpec _$S(tNewSpec'="":",",1:"")_ p1
	Quit tNewSpec
}

}
