/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane is used to display system journal file contents
Class %CSP.UI.System.OpenJournalPane Extends %CSP.Util.Pane [ System = 4 ]
{

Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<
<style type="text/css">
DIV.TitleText {
	padding-left: 10px;
}
table.DetailTable td {
	border-bottom: #CBCBCB solid 1px;
}
table.InfoTable {
	margin-left: 0px;	
}
table.InfoTable th.header {
	border-bottom: #CBCBCB solid 1px;
	border-right: #CBCBCB solid 1px;
	font-weight: 600;
	font-size: 18px;
}
table.InfoTable th.headerR {
	border-bottom: #CBCBCB solid 1px;
	font-weight: 600;
	font-size: 14px;
}
table.InfoTable td.data { 
	border-bottom: #CBCBCB solid 1px;
	border-right: #CBCBCB solid 1px;
}
table.InfoTable td.dataR {
	border-bottom: #CBCBCB solid 1px;
	font-size: 14px;
	padding: 6px 30px;
}

</style>
<script language="javascript">

function sortProfile(sort)
{
	var loc = self.document.location.toString();
	if (loc.indexOf('&SORT=') != -1) {
		var s = loc.split('&SORT=');
		loc = s[0];
	}
	self.document.location = loc + '&SORT=' + sort;
}

function setSearch(fld,val)
{
	var fctrl = self.document.getElementById('ctrlField');
	var vctrl = self.document.getElementById('ctrlValue');
	var octrl = self.document.getElementById('ctrlOp');
	if (fctrl && vctrl && octrl) {
		fctrl.value = fld;
		vctrl.value = val;
		if (octrl.value == '') {
			octrl.value = '=';
		}
	}
}

function gotoNextPage(lastoff)
{
	document.theForm.OFFSET.value = (lastoff*1) + 1;
	document.theForm.submit();
}

function gotoPrevPage(firstoff)
{
	document.theForm.PREV.value = 1;
	document.theForm.OFFSET.value = firstoff;
	document.theForm.submit();
}

// jump to record that does not have this field value
function jumpForward(fld,val,lastoff)
{
	document.theForm.JFWD.value = fld;
	document.theForm.JVAL.value = val;
	document.theForm.OFFSET.value = (lastoff*1) + 1;
	document.theForm.submit();
}

</script>
>	

	#; write out methods that perform the hyper-calls
	Write "<script language=""javascript"">",!
	Write "function showRecordDetails(file,offset)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall("%CSP.UI.System.OpenJournalPane.ShowRecordDetails","file,offset",0)
 	Write ";",!
	Write "}",!

	Write "function cancelProfile(file)",!
	Write "{",!
	Write "if (refreshId) { self.clearTimeout(refreshId); } ",! 
	Write ##class(%CSP.Page).HyperEventCall("%CSP.UI.System.OpenJournalPane.CancelProfile","file",0)
 	Write ";",!
	Write "}",!

	Write "function refreshProfile(clear,file)",!
	Write "{",!
	Write "var sort = self.document.getElementById('rbGlobal').checked ? 'global' : 'size';",!
	Write ##class(%CSP.Page).HyperEventCall("%CSP.UI.System.OpenJournalPane.RefreshProfile","clear,file,sort",0)
 	Write ";",!
	Write "}",!

	Write "</script>",!
	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set tSC = $$$OK

	Do ..DrawCommands(pInstance)

	// get page ID values
	Merge tID = pInstance.IDValues

	Set msgYes = $$$Text("Yes")
	Set msgNo = $$$Text("No")

	Set tFile = $G(tID(1))
	Set tMaxRows = +$G(%request.Data("ROWS",1),250)
	Set tOffset = +$G(%request.Data("OFFSET",1))
	Set tReverse = 0
	Set tAtStart = 0

	Set tField = $G(%request.Data("FIELD",1))
	Set tOp = $G(%request.Data("OP",1))
	Set tValue = $G(%request.Data("VALUE",1))
	Set tColorBy = $G(%request.Data("COLORBY",1),"ProcessID")

	// make sure offset is within valid range
	Set:tOffset<0 tOffset = 0
	Set:tOffset>4294967295 tOffset = 4294967295

	If (tField = "InTransaction") {
		// convert y/n to 1/0
		Set tValue = $Case(tValue,msgYes:1,msgNo:0,:tValue)
	}

	If ((tField="")||(tOp="")) {
		Set tField="",tOp="",tValue=""
	}
	
	#; check for profile
	If ($G(tID(2))="PROFILE") {
		Set tSortBy = $G(%request.Data("SORT",1))
		Set tClear = 0
		Set tRecalc = +$G(%request.Data("RECALC",1))
		If (tRecalc	> +$G(^IRIS.Temp.JournalProfile(tFile,"TIME"))) {
			Set tClear = 1
		}

		&html<<div id="profile">>
		Do ..DrawJournalProfile(tClear,tFile,tSortBy,0)
		&html<</div>>
		Quit
	}

	// find offsets of first & last records
	Set tFirstOffset = 0
	Set tLastOffset = 0
	Set tJournal = ##class(%SYS.Journal.File).%OpenId(tFile)
	If $IsObject(tJournal) {
		Set tRecord = tJournal.FirstRecord
		If $IsObject(tRecord) {
			Set tFirstOffset = tRecord.Address
		}

		Set tRecord = tJournal.LastRecord
		If $IsObject(tRecord) {
			Set tLastOffset = tRecord.Address
		}
	}
	Set tRecord = ""

	If ($D(%request.Data("MYSUBMIT_RESET",1))) {
		Set tField="",tOp="",tValue=""
		Set tOffset = 0
		Set tAtStart = 1
	}
	ElseIf ($D(%request.Data("MYSUBMIT_START",1))) {
		// start with first record
		Set tOffset = tFirstOffset
		Set tAtStart = 1
	}
	ElseIf (($G(%request.Data("JFWD",1))'="") && ($G(%request.Data("JVAL",1))'="")) {
		// request to jump forward
		If $IsObject(tJournal) {
			Set tRecord = tJournal.GetRecordAt(tOffset-1)
			If $IsObject(tRecord) {
				Set c("Address")=""
				Set tMatch = ""
				If ((tField'="")&&(tOp'="")) {
					Set tMatch = $LB(tField,tOp,tValue)
				}

				Set tMatch2 = $LB($G(%request.Data("JFWD",1)),"'=",$G(%request.Data("JVAL",1)))

				// go forward until value does not match
				Set tOffset = tRecord.Address

				Do {
					Set tRecord = tRecord.Next
					If '$IsObject(tRecord) Quit

					Set tOffset = tRecord.Address
					If ((tMatch="") || tRecord.Fetch(.out,.c,tMatch)) {
						If (tRecord.Fetch(.out,.c,tMatch2)) {
							Quit
						}
					}
	
				} While (1)
			}
		}
	}
	ElseIf (+$G(%request.Data("PREV",1)) || $D(%request.Data("MYSUBMIT_END",1))) {
		// find previous page or last record, go back to find top of page
		If $IsObject(tJournal) {
			Set tMatch = ""
			If ((tField'="")&&(tOp'="")) {
				Set tMatch = $LB(tField,tOp,tValue)
				Set c("Address")=""
			}

			If (+$G(%request.Data("PREV",1))) {
				// go to prev page
				Set tRecord = tJournal.GetRecordAt(tOffset)
			}
			Else {
				// start from end of journal
				Set tRecord = tJournal.LastRecord
			}

			If $IsObject(tRecord) {
				Set tOffset = tRecord.Address
				#;YSD1680 - change to next line Set count = 0
				Set count = 1
				While (count < tMaxRows) {
					Set tRecord = tRecord.Prev
					If '$IsObject(tRecord) Quit

					// test for match
					If ((tMatch = "") || (tRecord.Fetch(.out,.c,tMatch))) {
						Set tOffset = tRecord.Address
						Set count = count + 1
					}
				}
				If (count < tMaxRows) {
					Set tAtStart = 1 // no prior rows
				}
			}
		}
		Set tRecord = ""
	}
	Else {
		// go forward from current offset
		Set tAtStart = (tOffset <= tFirstOffset)
	}

	Set tJournal = ""

	Set msgTitle = $$$Text("Contents of journal file")
	Set msgTitle2 = $$$Text("Use the search box to filter results. Click on offset number to view details for a journal record. Double-click on a cell to use its value for the search criteria.")

	Set msgFirstOffset = $$$Text("First offset")
	Set msgLastOffset = $$$Text("Last offset")
	Set msgAccessDenied = $$$Text("read access denied")

	Set cmdOffset = $$$Text("Offset")
	Set cmdPageSize = $$$Text("Page size")
	Set cmdMatch = $$$Text("Match")
	Set cmdColorBy = $$$Text("Color by")
	Set cmdSearch = $$$Text("Search")
	Set cmdReset = $$$Text("Reset")
	Set cmdStart = " |&lt;&lt; "
	Set cmdEnd = " &gt;&gt;| "
	Set cmdPrev = $$$Text("Previous page")
	Set cmdNext = $$$Text("Next page")
	
	Set helpSearch = $$$Text("Find journal records that match the search criteria.")
	Set helpReset = $$$Text("Reset the search criteria.")
	Set helpStart = $$$Text("Display the start (oldest contents) of the journal file.")
	Set helpEnd = $$$Text("Display the end (most recent contents) of the journal file.")
	Set helpDetails = $$$Text("Display details for this journal record.")

	Set helpNext = $$$Text("Display next page of records that match the current search criteria.")
	Set helpPrev = $$$Text("Display previous page of records that match the current search criteria.")

	Set helpJumpFwd = $$$Text("Double click to skip ahead to the next record with a different value for this column.")

	Set opEQ = $$$Text("equal to")
	Set opNEQ = $$$Text("not equal to")
	Set opGT = $$$Text("greater than")
	Set opLT = $$$Text("less than")
	Set opCT = $$$Text("contains")
	Set opNCT = $$$Text("does not contain")

	Set cbTime = $$$Text("Time")
	Set cbProcess = $$$Text("Process")
	Set cbType = $$$Text("Type")
	Set cbExtType = $$$Text("ExtendedType")
	Set cbInTransaction = $$$Text("InTransaction")
	Set cbGlobal = $$$Text("Global")
	Set cbDatabase = $$$Text("Database")
	Set cbMirrorDB = $$$Text("MirrorDBName")

	// ignore Text, show custom message
	Do {
		&html<<div class="Text1">#(msgTitle)#: <b>#($ZCVT(tFile,"O","HTML"))#</b>&nbsp;&nbsp;&nbsp;&nbsp;<span nowrap>#(msgFirstOffset)#: <b>#(tFirstOffset)#</b>&nbsp;&nbsp;#(msgLastOffset)#: <b>#(tLastOffset)#</b></span></div>>
		&html<<div class="Text">#(msgTitle2)#</div>
		<hr>>

		// display search form
		&html<<form name="theForm" id="theForm">
		<table class="FilterTable" border="0" cellpadding="3" cellspacing="0"><tr><td nowrap>
		<input class="FilterInput" style="color: black;width:70px;" type="SUBMIT" title="#(helpSearch)#" name="MYSUBMIT" value="#(cmdSearch)#">
		<input class="FilterInput" style="color: black;width:70px;" type="SUBMIT" title="#(helpReset)#" name="MYSUBMIT_RESET" value="#(cmdReset)#">
		<input class="FilterInput" style="color: black; width:35px;" type="SUBMIT" title="#(helpStart)#" name="MYSUBMIT_START" value="#(cmdStart)#">
		<input class="FilterInput" id="btnPrev" style="color: black; width:35px;" type="BUTTON" title="#(helpPrev)#" value="&lt;" onclick="gotoPrevPage(firstOffset);">
		<input class="FilterInput" id="btnNext" style="color: black; width:35px;" type="BUTTON" title="#(helpNext)#" value="&gt;" onclick="gotoNextPage(lastOffset);">
		<input class="FilterInput" style="color: black; width:35px;" type="SUBMIT" title="#(helpEnd)#" name="MYSUBMIT_END" value="#(cmdEnd)#">
		<input type="hidden" name="$ID1" value="#($zconvert(tFile,"O","HTML"))#">
		<input type="hidden" name="PREV" value="0">
		<input type="hidden" name="JFWD" value="">
		<input type="hidden" name="JVAL" value="">
		<span class="FilterLabel">#(cmdPageSize)#:</span>
		<input class="FilterInput" type="text" size="4" name="ROWS" value="#($zconvert(tMaxRows,"O","HTML"))#">&nbsp;
		<span class="FilterLabel">#(cmdOffset)#:</span>
		<input class="FilterInput" type="text" size="8" name="OFFSET" value="#($zconvert(tOffset,"O","HTML"))#">
		&nbsp;
		<span class="FilterLabel">#(cmdColorBy)#:</span>
		<select id="ctrlColorBy" name="COLORBY" onchange="self.document.getElementById('theForm').submit();">
			<option value=""></option>
			<option value="TimeStamp" #($S(tColorBy="TimeStamp":"selected",1:""))#>#(cbTime)#</option>
			<option value="ProcessID"#($S(tColorBy="ProcessID":"selected",1:""))#>#(cbProcess)#</option>
			<option value="TypeName" #($S(tColorBy="TypeName":"selected",1:""))#>#(cbType)#</option>
			<option value="ExtTypeName" #($S(tColorBy="ExtTypeName":"selected",1:""))#>#(cbExtType)#</option>
			<option value="InTransaction" #($S(tColorBy="InTransaction":"selected",1:""))#>#(cbInTransaction)#</option>
			<option value="GlobalNode" #($S(tColorBy="GlobalNode":"selected",1:""))#>#(cbGlobal)#</option>
			<option value="DatabaseName" #($S(tColorBy="DatabaseName":"selected",1:""))#>#(cbDatabase)#</option>
		</select>
		&nbsp;
		<span class="FilterLabel">#(cmdMatch)#:</span>
		<select id="ctrlField" name="FIELD">
			<option value=""></option>
			<option value="TimeStamp" #($S(tField="TimeStamp":"selected",1:""))#>#(cbTime)#</option>
			<option value="ProcessID"#($S(tField="ProcessID":"selected",1:""))#>#(cbProcess)#</option>
			<option value="TypeName" #($S(tField="TypeName":"selected",1:""))#>#(cbType)#</option>
			<option value="ExtTypeName" #($S(tField="ExtTypeName":"selected",1:""))#>#(cbExtType)#</option>
			<option value="InTransaction" #($S(tField="InTransaction":"selected",1:""))#>#(cbInTransaction)#</option>
			<option value="GlobalNode" #($S(tField="GlobalNode":"selected",1:""))#>#(cbGlobal)#</option>
			<option value="DatabaseName" #($S(tField="DatabaseName":"selected",1:""))#>#(cbDatabase)#</option>
			<option value="MirrorDatabaseName" #($S(tField="MirrorDatabaseName":"selected",1:""))#>#(cbMirrorDB)#</option>
		</select>
		<select id="ctrlOp" name="OP">
			<option value=""></option>
			<option value="=" #($S(tOp="=":"selected",1:""))#>#(opEQ)#</option>
			<option value="'=" #($S(tOp="'=":"selected",1:""))#>#(opNEQ)#</option>
			<option value="]]" #($S(tOp="]]":"selected",1:""))#>#(opGT)#</option>
			<option value="']]" #($S(tOp="']]":"selected",1:""))#>#(opLT)#</option>
			<option value="[" #($S(tOp="[":"selected",1:""))#>#(opCT)#</option>
			<option value="'[" #($S(tOp="'[":"selected",1:""))#>#(opNCT)#</option>
		</select>
		<input class="FilterInput" type="text" size="25" id="ctrlValue" name="VALUE" value="#($ZCVT(tValue,"O","HTML"))#">&nbsp;
		</td></tr></table></form>>

		// display contents of journal
		Set tRS = ##class(%ResultSet).%New("%SYS.Journal.Record:List")

		Set tTypeList = "Address,Type,TypeName,ExtType,ExtTypeName,TimeStamp,InTransaction,ProcessID,GlobalNode,DatabaseName"
		Set tMatch = ""
		If ((tField'="")&&(tOp'="")) {
			Set tMatch = $LB(tField,tOp,tValue)
		}

		Set tSC = tRS.Execute(tFile,tTypeList,tOffset,tReverse,tMatch)
		If $$$ISERR(tSC) Quit

		Set lblOffset = $$$Text("Offset")

		Set n=0
		Set n=n+1,tCol(n)="Address",tCaption(n)=$$$Text("Offset"),tHelp(n)=$$$Text("Offset number for the record within the journal file. Click to see details for journal record.")
		Set n=n+1,tCol(n)="TimeStamp",tCaption(n)=$$$Text("Time"),tHelp(n)=$$$Text("Time when the journal buffer containing this record was created.")
		Set n=n+1,tCol(n)="ProcessID",tCaption(n)=$$$Text("Process"),tHelp(n)=$$$Text("ID of process that created the journal record.")
		Set n=n+1,tCol(n)="TypeName",tCaption(n)=$$$Text("Type"),tHelp(n)=$$$Text("Type of journal record.")
		Set n=n+1,tCol(n)="ExtTypeName",tCaption(n)=$$$Text("ExtendedType"),tHelp(n)=$$$Text("Extended type of journal record.")
		Set n=n+1,tCol(n)="InTransaction",tCaption(n)=$$$Text("InTransaction"),tHelp(n)=$$$Text("Indicates whether this activity occurred within a transaction or not.")
		Set n=n+1,tCol(n)="GlobalNode",tCaption(n)=$$$Text("GlobalNode"),tHelp(n)=$$$Text("Global node that was changed.")
		Set n=n+1,tCol(n)="DatabaseName",tCaption(n)=$$$Text("Database"),tHelp(n)=$$$Text("Database in which the change occurred.")

		&html<<table class="DetailTable" border="0" cellspacing="0">>
		&html<<tr>>
		For i = 1:1:n {
			&html<<th nowrap title="#($ZCVT(tHelp(i),"O","HTML"))#">#($ZCVT(tCaption(i),"O","HTML"))#</th>>
		}
		&html<</tr>>

		// loop over rows and display
		Kill tDBPriv 	// this tells us if we have access to a given db, indexed by DB name

		Set firstoff = 0
		Set lastoff = tOffset
		Set row = 0
		While (tRS.Next() && (row<tMaxRows)) {
			// make distinct color for row
			If (tColorBy = "") {
				Set bg = "#FFFFFF"
			}
			Else {
				Set num = $G(tRS.Data(tColorBy))
				If (num '= +num) {
				    // convert string to #
				    If (tColorBy = "ExtTypeName") {
					Set num = $ZCRC(num,6)
				    } else {
					// for global, ignore subscripts
					Set num = $ZCRC($P(num,"(",1),6)
				    }
				}
				
				If (num = 0) {
					Set bg = "#FFFFEE"
				}
				Else {
					#;YSD2150 - strip off punctuations
					Set num = $ZSTRIP(num,"*P")
					Set bg = "#"_$J($ZHEX(((num*113)#127)+128),2)_$J($ZHEX(((num*7)#127)+128),2)_$J($ZHEX(((num*17)#127)+128),2)
					Set bg = $TR(bg," ",0)
				}
			}

			// highlight begin/end of transactions
			Set hi = $Case(+$G(tRS.Data("Type")),4:"font-weight:bold;",5:"font-weight:bold;",:"")

			// differentiate in/out of transaction
			Set hi = hi_$Case(+$G(tRS.Data("InTransaction")),0:"color:#333695;",:"")

			Set lastoff = +$G(tRS.Data("Address"))
			If (firstoff = 0) {
				Set firstoff = lastoff
			}
			
			// check for permission to see data
			Set showData = ""
			Set db = $G(tRS.Data("DatabaseName"))
			If (db '= "") {
				If '$D(tDBPriv(db)) {
					// figure out if we have access to db
					Set tDBPriv(db) = ..HasDBPermission(db)
				}
				Set showData = tDBPriv(db)
			}

			&html<<tr style="background: #(bg)#; #(hi)#">>
			// special case: make offset a link
			&html<<td><a title="#(helpDetails)#" href="javascript:showRecordDetails('#($ZCVT(tFile,"O","JS"))#','#(lastoff)#');">#(lastoff)#</a>&nbsp;</th>>
			For i = 2:1:n {
				If (tCol(i)="InTransaction") {
					Set val(i) = $Case($G(tRS.Data(tCol(i))),1:msgYes,:msgNo)
				}
  				ElseIf ((tCol(i)="GlobalNode") && (showData=0)) {
	 				// suppress global subscripts
					Set val(i) = $P($G(tRS.Data(tCol(i))),"(",1) _ " [" _ msgAccessDenied _"]"
				}
  				ElseIf ((tCol(i)="GlobalNode")) {
	 				// suppress global subscripts
					i $G(tRS.Data(tCol(i)))'="" {
						Set val(i) = $$FormatName^%qcr($G(tRS.Data(tCol(i))),1)
					} else {
						Set val(i) = ""
					}
				}
				Else {
					Set val(i) = $G(tRS.Data(tCol(i)))
				}
				&html<<td nowrap ondblclick="setSearch('#(tCol(i))#','#($ZCVT($ZCVT(val(i),"O","JS"),"O","HTML"))#');">#($ZCVT(val(i),"O","HTML"))#&nbsp;</th>>
			}

			&html<</tr>>
			Set row = row + 1
		}

		Set hasMore = tRS.Next()

		If (hasMore) {
			// repeat headers (with jumpForward link)
			&html<<tr><th nowarp>#(lblOffset)#</th>>
			For i = 2:1:n {
				&html<<th nowarp title="#(helpJumpFwd)#" ondblclick="jumpForward('#(tCol(i))#','#($ZCVT($ZCVT($G(val(i)),"O","JS"),"O","HTML"))#',#(+lastoff)#);">#(tCaption(i))#</th>>
			}
			&html<</tr>>
		}
		
		&html<<tr><td colspan="#(n)#">&nbsp;>

		if ('tAtStart) {
			&html<<a href="javascript:gotoPrevPage(#(+firstoff)#);" title="#(helpPrev)#">
					<i>#(cmdPrev)#</i>
					</a>&nbsp;>
		}

		If (hasMore) {
			&html<
				<a href="javascript:gotoNextPage(#(+lastoff)#);" title="#(helpNext)#">
				<i>#(cmdNext)#</i>
				</a>>
		}
		&html<</td></tr>>
		&html<</table><hr>>

		#; offset vars
		Write "<script language=""javascript"">",!
		&js<
var firstOffset = #(+$G(firstoff))#;
var lastOffset = #(+$G(lastoff))#;
		>
		If (tAtStart) {
		&js<self.document.getElementById('btnPrev').disabled = true;>
		}
		If ('hasMore) {
		&js<self.document.getElementById('btnNext').disabled = true;>
		}

		&html<</script>>


	} While(0)

	Quit tSC
}

/// Returns whether current user's base permissions allow access to given database (directory)
ClassMethod HasDBPermission(tDB As %String) As %Boolean
{
	Quit:tDB="" 1

	// make sure to use base resources
	New $Roles
	Set $Roles = ""

	// get resource name of db
	Set rsc = $P($zu(49,$ZU(12,tDB)),",",25)
	Set tRet = $System.Security.Check(rsc,"READ")

	Quit tRet
}

/// Called by client to show details for a journal record
ClassMethod ShowRecordDetails(pFile As %String, pOffset As %Integer)
{
	Set tMsg = $ZCVT($$$Text("Details for journal record"),"O","JS")_"\n"
	Set tMsg = tMsg _ "----------------------------------------\n"

	New %zzzmode0,%zzzmode1
	Set %zzzmode0="",%zzzmode1=""  // %qcr variables


	Set tJournal = ##class(%SYS.Journal.File).%OpenId(pFile)
	If $IsObject(tJournal) {
		Set tRecord = tJournal.GetRecordAt(pOffset)
		If $IsObject(tRecord) {
			Set tMsg = tMsg _ $ZCVT($$$Text("Offset:"),"O","JS")_"\t\t" _ $ZCVT(tRecord.Address,"O","JS") _ "\n"
			Set tMsg = tMsg _ $ZCVT($$$Text("Process ID:"),"O","JS")_"\t" _ $ZCVT(tRecord.ProcessID,"O","JS") _ "\n"
			Set tMsg = tMsg _ $ZCVT($$$Text("Record type:"),"O","JS")_"\t" _ $ZCVT(tRecord.TypeName,"O","JS") _ "\n"
			Set tMsg = tMsg _ $ZCVT($$$Text("ECP system ID:"),"O","JS")_"\t" _ $ZCVT(tRecord.ECPSystemID,"O","JS") _ "\n"

			If (tRecord.%IsA("%SYS.Journal.SetKillRecord")) {
				Set tMsg = tMsg _ $ZCVT($$$Text("Database:"),"O","JS")_"\t" _ $ZCVT(tRecord.DatabaseName,"O","JS") _ "\n"
				If tRecord.MirrorDatabaseName'="" Set tMsg = tMsg _ $ZCVT($$$Text("Mirror Database Name:"),"O","JS")_"\t" _ $ZCVT(tRecord.MirrorDatabaseName,"O","JS") _ "\n"
				Set tMsg = tMsg _ $ZCVT($$$Text("In transaction:"),"O","JS")_"\t" _ $ZCVT(tRecord.InTransaction,"O","JS") _ "\n"

				// test for read permission on db to show old/new values
 				If ..HasDBPermission(tRecord.DatabaseName) {
	 				Set noValue = "<"_$$$Text("No Value")_">"	
	 			
			        If (tRecord.%IsA("%SYS.Journal.BitSetRecord") || tRecord.ExistsOldValue()) {
						Set oldValue = $$Format^%qcr(tRecord.OldValue,1)
					}
					Else {
						Set oldValue = noValue
					}
					If (tRecord.ExistsNewValue()) {
						Set newValue = $$Format^%qcr(tRecord.NewValue,1)
					}
					Else {
						Set newValue = noValue
					}

					Set tMsg = tMsg _ $ZCVT($$$Text("Global Node:"),"O","JS")_"\t" _ $ZCVT($$FormatName^%qcr(tRecord.GlobalNode,1),"O","JS") _ "\n"
					Set tMsg = tMsg _ $ZCVT($$$Text("Global Reference:"),"O","JS")_"\t" _ $ZCVT($$FormatName^%qcr(tRecord.GlobalReference,1),"O","JS") _ "\n"
 					If $L(oldValue) > 200 Set oldValue = $E(oldValue,1,200)_ "..."
 					If $L(newValue) > 200 Set newValue = $E(newValue,1,200)_ "..."
 					If (tRecord.%IsA("%SYS.Journal.VectorSetKillRecord")) {
 						Set tMsg = tMsg _ $ZCVT($$$Text("Vector (type: "),"O","JS")_$ZCVT(tRecord.VecType,"O","JS")
 						Set tMsg = tMsg _ $ZCVT($$$Text(", index: "),"O","JS")_$ZCVT(tRecord.VecIndex,"O","JS")_")\n"
 					}
 					Set tMsg = tMsg _ $ZCVT($$$Text("Old value:"),"O","JS")_"\t" _ $ZCVT(oldValue,"O","JS") _ "\n"
					Set tMsg = tMsg _ $ZCVT($$$Text("New value:"),"O","JS")_"\t" _ $ZCVT(newValue,"O","JS") _ "\n"
				}
				Else {
					Set tMsg = tMsg _ $ZCVT($$$Text("Global Node:"),"O","JS")_"\t" _ $ZCVT($P(tRecord.GlobalNode,"(",1),"O","JS") _ " [read access denied]\n"
				}
			}
		}
		Else {
			Set tMsg = tMsg _ $ZCVT($$$Text("Unable to open journal record."),"O","JS")_"\n"
		}
		Set tRecord = ""
	}
	Set tJournal = ""

	&js<alert('#(tMsg)#');>
}

/// Given a journal file name, Draw an HTML profile of the contents
/// of the journal.
ClassMethod DrawJournalProfile(pClear As %Boolean, pFile As %String, pSortBy As %String = "", pMode As %Integer = 0) As %Status
{
	If (pSortBy '= "size") {
		Set tSC = ..GetJournalProfile(pFile,.tProfile,pClear)
		If $$$ISERR(tSC) Quit tSC
	}
	Else {
		#; sort by size
		Set tSC = ..GetJournalProfile(pFile,.tList,pClear)
		If $$$ISERR(tSC) Quit tSC
		Set a = $O(tList(""))
		While (a '= "") {
			If (a '= "OTHER") {
				Set b = $O(tList(a,""))
				While (b '= "") {
					#; index on negative size
					Set tProfile(-$G(tList(a,b)),a) = b
					Set b = $O(tList(a,b))
				}
			}
			Set a = $O(tList(a))
		}
		Set tProfile(-$G(tList("OTHER")),"OTHER") = ""
	}

	Set msgTitle = $$$Text("Journal file profile")
	Set msgTitle2 = $$$Text("The following table shows a summary of the contents of the selected journal file.")
	Set msgGlobal = $$$TextHTML("Global")
	Set msgSize = $$$TextHTML("Size")
	Set msgCalc = $$$Text("Recalculate")
	Set msgCancel = $$$Text("Cancel")
	Set tComplete = +$G(^IRIS.Temp.JournalProfile(pFile,"PROGRESS"))
	Set tError = $G(^IRIS.Temp.JournalProfile(pFile,"ERROR"))

	#; not done, auto-refresh (only for mode=0 (non-hyper event))
	If ((pMode=0) && '$G(^IRIS.Temp.JournalProfile(pFile))) {
	&html<<script language="JavaScript">
	var refreshId = setTimeout("refreshProfile(0,'#($ZCVT($ZCVT(pFile,"O","JS"),"O","JS"))#')",1500);
	</script>>
	}

	&html<
	<div style="padding:10px;">
	<div >#($$$TextHTML("Sort by:"))#&nbsp;
	<input id="rbGlobal" name="sort" type="radio" #($S(pSortBy'="size":"checked",1:""))# onclick="sortProfile('');" />#(msgGlobal)#&nbsp;
	<input id="rbSize" name="sort" type="radio" #($S(pSortBy="size":"checked",1:""))# onclick="sortProfile('size');"/>#(msgSize)#&nbsp;&nbsp;&nbsp;>
	
	&html<&nbsp;&nbsp;&nbsp;
	<input type="button" id="btnRecalc" onclick="refreshProfile(1,'#($ZCVT($ZCVT(pFile,"O","JS"),"O","HTML"))#');" value="#(msgCalc)#" #($S((tComplete>0)&&(tComplete<1):"disabled",1:""))#/>
	<input type="button" id="btnCancel" onclick="cancelProfile('#($ZCVT($ZCVT(pFile,"O","JS"),"O","HTML"))#');" value="#(msgCancel)#" #($S((tComplete>0)&&(tComplete<1):"",1:"disabled"))#/>
	&nbsp;&nbsp;
	>

	If (tComplete < 1) {
		&html<<b>#($FN(tComplete*100,"",1))#%</b> #($$$TextHTML("completed..."))#>
	}
	Else {
		&html<#($$$TextHTML("Ready"))#>
	}

	&html<</div><br/>>

	If ((tError'="")&&$$$ISERR(tError)) {
		Do $System.Status.DecomposeStatus(tError,.msg)
		&html<<div style="color:red;">#($G(msg(1)))#</div>>
	}

	&html<<table class="InfoTable" border="0" cellspacing="0">>
	&html<<tr><th class="title" height="30" colspan="3">&nbsp;<csp:text>#($ZCVT(pFile,"O","HTML"))#</csp:text></a>>
	&html<<tr>
	<th class="header">#($$$TextHTML("Database"))#</th>
	<th class="header">#($$$TextHTML("Global"))#</th>
	<th class="headerR">#($$$TextHTML("Size (Bytes)"))#</th>
	</tr>>

	Set tRow = 0
	Set a = $O(tProfile(""))
	While (a '= "") {
		If (a '= "OTHER") {
			Set b = $O(tProfile(a,""))
			While (b '= "") {
				Set tRow = tRow + 1
				&html<<tr>>
				If (pSortBy = "size") {
					If b = "OTHER" &html<<td class="data">#($$$TextHTML("OTHER"))#</td>>
					Else  &html<<td class="data">#($ZCVT(b,"O","HTML"))#</td>>
					&html<<td class="data">#($G(tProfile(a,b)))#&nbsp;</td>
					<td class="dataR" align="right">&nbsp;#($ZCVT(-a,"O","HTML"))#</td>>
				}
				Else {
					&html<<td class="data">#($ZCVT(a,"O","HTML"))#</td>
					<td class="data">#($ZCVT(b,"O","HTML"))#</td>
					<td class="dataR"align="right">&nbsp;#($G(tProfile(a,b)))#</td>>
				}
				&html<</tr>>
				Set b = $O(tProfile(a,b))
			}
		}
		Set a = $O(tProfile(a))
	}

	If (pSortBy '= "size") {
		&html<<tr><td colspan="2" class="data">#($$$TextHTML("OTHER"))#</td><td class="dataR" align="right">&nbsp;#($G(tProfile("OTHER")))#</td></tr>>
	}

	&html<</table><br/></div>>

	Quit tSC
}

/// Called from client to update the profile page
ClassMethod RefreshProfile(pClear As %Boolean, pFile As %String, pSortBy As %String = "")
{
	&js<var div = self.document.getElementById('profile');>
	Write "div.innerHTML = '"
	Set io = $$$GETIO
	$$$SETIO("JSML")
	Do ..DrawJournalProfile(pClear, pFile,pSortBy,1)
	$$$SETIO(io)
	Write "';",!

	#; note double JS escape!
	If ('$G(^IRIS.Temp.JournalProfile(pFile))) {
	&js<
	self.refreshId = setTimeout("refreshProfile(0, '#($ZCVT($ZCVT(pFile,"O","JS"),"O","JS"))#','')",1000);
	>
	}
}

/// Called from client to stop a profile calculation.
ClassMethod CancelProfile(pFile As %String)
{
	Set ^IRIS.Temp.JournalProfile(pFile,"CANCEL") = 1
	&js<
	var btn = self.document.getElementById('btnCancel');
	if (btn) { btn.disabled = true; }
	var btn = self.document.getElementById('btnRecalc');
	if (btn) { btn.disabled = false; }
	>
}

/// Given a journal file name, build a profile of the contents
/// of the journal within a temp global. This takes the form:<br/>
/// ^IRIS.Temp.JournalProfile(pFile) = status: 0 running, 1 complete<br/>
/// ^IRIS.Temp.JournalProfile(pFile,"ERROR") = error (if any)<br/>
/// ^IRIS.Temp.JournalProfile(pFile,"PROFILE",database,global) = size of records for this db.global<br>
/// ^IRIS.Temp.JournalProfile(pFile,"PROFILE","OTHER") = size of other records<br>
ClassMethod ComputeJournalProfileOld(pFile As %String)
{
	Quit:pFile=""

	#; find offsets of last record
	Set tLastOffset = 0
	Set tJournal = ##class(%SYS.Journal.File).%OpenId(pFile)
	If $IsObject(tJournal) {
		Set tRecord = tJournal.LastRecord
		Set:$IsObject(tRecord) tLastOffset = tRecord.Address
	}

	Set tRS = ##class(%ResultSet).%New("%SYS.Journal.Record:List")

	Set tTypeList = "Address,GlobalNode,DatabaseName"
	Set tMatch = ""
	Set tOffset = 0
	Set tReverse = 0

	Kill ^IRIS.Temp.JournalProfile(pFile)
	Set ^IRIS.Temp.JournalProfile(pFile)=0
	Set tSC = tRS.Execute(pFile,tTypeList,tOffset,tReverse,tMatch)
	If $$$ISERR(tSC) {
		Set ^IRIS.Temp.JournalProfile(pFile)=1
		Set ^IRIS.Temp.JournalProfile(pFile,"ERROR")=tSC
		Quit
	}

	#; get relative timestamp
	Set ^IRIS.Temp.JournalProfile(pFile,"TIME")=$ZH\1
	Set tCancel = 0

	While (tRS.Next(.tSC)) {
		If $$$ISERR(tSC) Quit

		#; test cancel flag
		If $D(^IRIS.Temp.JournalProfile(pFile,"CANCEL")) {
			Set tCancel = 1
			Quit
		}

		#; get info about this record
		Set tAddress = $G(tRS.Data("Address"))
		Set tGlobal = $G(tRS.Data("GlobalNode"))
		Set tDB = $G(tRS.Data("DatabaseName"))

		#; compute progress
		Set:tLastOffset>0 ^IRIS.Temp.JournalProfile(pFile,"PROGRESS")=(tAddress/tLastOffset)

		#; use magic zu to get record size
		#; (record *could* be a big string)
		Set tSize = $zu(78,42,tAddress)
		Set tGlobal = $P(tGlobal,"(",1)
		If ((tDB'="")&&(tGlobal'="")&&(tSize>0)) {
			Set x = $I(^IRIS.Temp.JournalProfile(pFile,"PROFILE",tDB,tGlobal),tSize)
		}
		ElseIf (tSize>0) {
			Set x = $I(^IRIS.Temp.JournalProfile(pFile,"PROFILE","OTHER"),tSize)
		}
	}
	If (tCancel) {
		Kill ^IRIS.Temp.JournalProfile(pFile)
	}
	Else {
		Set ^IRIS.Temp.JournalProfile(pFile,"PROGRESS")=1
		Set ^IRIS.Temp.JournalProfile(pFile)=1
		If $$$ISERR(tSC) {
			Set ^IRIS.Temp.JournalProfile(pFile,"ERROR")=tSC
		}
	}
}

/// Given a journal file name, build a profile of the contents
/// of the journal within a temp global. This takes the form:<br/>
/// ^IRIS.Temp.JournalProfile(pFile) = status: 0 running, 1 complete<br/>
/// ^IRIS.Temp.JournalProfile(pFile,"ERROR") = error (if any)<br/>
/// ^IRIS.Temp.JournalProfile(pFile,"PROFILE",database,global) = size of records for this db.global<br>
/// ^IRIS.Temp.JournalProfile(pFile,"PROFILE","OTHER") = size of other records<br>
ClassMethod ComputeJournalProfile(pFile As %String)
{
	Quit:pFile=""

	s dev=$zu(78,5,pFile,0) i dev<0 d $zu(9,"","unable to open "_pFile) q
	s $zt="exit",$ze=""
	d $zu(78,6,dev)
	Kill ^IRIS.Temp.JournalProfile(pFile)
	Set ^IRIS.Temp.JournalProfile(pFile)=0
	#; get relative timestamp
	Set ^IRIS.Temp.JournalProfile(pFile,"TIME")=$ZH\1
	Set tCancel = 0
	Set tLastOffset = $zu(78,18,0)
	s addr=65536*2
	#; length of main body of record @addr (excl. its EXTRECs if any)
	s prvlen=$zu(78,42,addr)
	f  {
		s next=$zu(78,17,addr) i next'>0 q
		s curlen=$zu(78,42,next)
		#; size of all EXTRECs = next-(addr+prvlen)
		s tSize=next+curlen-(addr+prvlen)
		#;tSize is the size of the record @next, not the one @addr
		s addr=next
		s type=$zu(78,8,addr)
		i 5<type,type<15,type-13 { ;from SET (6) to BITSET (14), excl. MARKER (13)
			s glo=$zu(78,13,addr)
			s tDB=$p(glo,"""",2) ;with "^^" prefix
			s tDB=$e(tDB,3,*) ;w/o "^^" prefix
			i tDB'="" {
				s glob=$p(glo,"("),tGlobal=$p(glob,"]",$l(glo,"]"))
				i tGlobal'="",$I(^IRIS.Temp.JournalProfile(pFile,"PROFILE",tDB,tGlobal),tSize)
			}
		} else {
			i $I(^IRIS.Temp.JournalProfile(pFile,"PROFILE","OTHER"),tSize)
		}
		s (tAddress,addr)=next,prvlen=curlen
		#; compute progress
		Set:tLastOffset>0 ^IRIS.Temp.JournalProfile(pFile,"PROGRESS")=(tAddress/tLastOffset)
		#; test cancel flag
		If $D(^IRIS.Temp.JournalProfile(pFile,"CANCEL")) {
			Set tCancel = 1
			Quit
		}
	}
	If (tCancel) {
		Kill ^IRIS.Temp.JournalProfile(pFile)
	}
	Else {
		Set ^IRIS.Temp.JournalProfile(pFile,"PROGRESS")=1
		Set ^IRIS.Temp.JournalProfile(pFile)=1
	}
exit s $zt="" i $ze'="" d $zu(9,"",$ze)
	d $zu(78,7,dev)
	q
}

/// Given a journal file name, build a profile of the contents
/// of the journal. This takes the form:<br/>
/// pProfile(database,global) = size of records for this db.global<br>
/// pProfile("OTHER") = size of other records<br>
ClassMethod GetJournalProfile(pFile As %String, Output pProfile, pClear As %Boolean = 0) As %Status
{
	#; make sure we can read journal
	Set tSC = $$$OK
	Set tRS = ##class(%ResultSet).%New("%SYS.Journal.Record:List")

	Set tTypeList = "Address,GlobalNode,DatabaseName"
	Set tMatch = ""
	Set tOffset = 0
	Set tReverse = 0

	Set tSC = tRS.Execute(pFile,tTypeList,tOffset,tReverse,tMatch)
	If $$$ISERR(tSC) Quit tSC

	#; get result from temp global; if not present run background job
	If (pClear || '$D(^IRIS.Temp.JournalProfile(pFile))) {
		Job ##class(%CSP.UI.System.OpenJournalPane).ComputeJournalProfile(pFile)
		Hang 1
	}

	If ($D(^IRIS.Temp.JournalProfile(pFile))) {
		Merge pProfile = ^IRIS.Temp.JournalProfile(pFile,"PROFILE")
	}

	Quit tSC
}

}
