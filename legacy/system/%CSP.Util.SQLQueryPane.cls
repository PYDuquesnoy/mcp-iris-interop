/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane displays the results of an SQL query within an HTML table.
Class %CSP.Util.SQLQueryPane Extends %CSP.Util.TablePane [ System = 4 ]
{

/// Default localization domain used for column headers
Parameter COLUMNDOMAIN = "%UtilityColumns";

/// Default localization domain used for column headers help messages
Parameter COLUMNHELPDOMAIN = "%UtilityColumnHelp";

/// If true (default) run column name through localization
Property LocalizeColumns As %Boolean [ InitialExpression = 1 ];

Method OnDrawHEADTablePane(pInstance As %CSP.Util.PageInstance) As %Status
{
	&html<
<style type="text/css">

h2 {
	color: darkblue;
	border-top: 1px solid darkblue;
	font-weight: bold;
	font-size: 1.2em;
}

table.DetailTable {
	border: 1px solid gray;
	/* make tables with few columns, small */
	width: 10%;
}

table.DetailTable th {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding-left: 2px;
	padding-right: 8px;
	font-weight: bold;
	text-align: left;
}

table.DetailTable td {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding-left: 2px;
	padding-right: 2px;
}


</style>
<script language="javascript">

</script>
>
	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"

	// Get text line for page; subclass can customize this behavior
	Set tText = ..GetDescriptiveText()

	// get page ID values
	Merge tID = pInstance.IDValues

	Set msgStatistics = $ZCVT($$$Text("Performance"),"O","HTML")
	Set msgSeconds = $ZCVT($$$Text("seconds"),"O","HTML")
	Set msgGloRefs = $ZCVT($$$Text("global references"),"O","HTML")
	Set msgRoutineName = $ZCVT($$$Text("Routine"),"O","HTML")
	Set hlpStatistics = $ZCVT($$$Text("These statistics show the rough cost of executing this query. These values include some cost for displaying the query results."),"O","HTML")

	Set cmdSQLCODE = $ZCVT($$$Text("SQLCODE"),"O","HTML")
	Set cmdRowCount = $ZCVT($$$Text("Row count"),"O","HTML")

	Set hlpSQLINFO = $ZCVT($$$Text("SQLCODE is the SQL error code value returned by this query. Row count is the number of rows processed by this query. For SELECT statements, these values are only set when all rows are loaded."),"O","HTML")

	Do {
		Do ..DrawCommands(pInstance)

		If (tText '= "") {
			Set updatemsg = $ZCVT($$$Text("Last update: "),"O","HTML")

			&html<<table border="0" cellpadding="3" cellspacing="0" width="90%"><tr>
				<td valign="bottom"><div class="Text1"><span style="font-size:0.8em;">#($ZCVT((tText),"O","HTML"))#</span></div></td>
				<td align="left" class="Text" nowrap width="30%" style='cursor:pointer;'>
				<div align="left" width="100%">
				<a class="LastUpdate">#(updatemsg)#<b>
				<span id="lastUpdate">#($ZDT($ZU(188),3,,3))#</span></b>&nbsp;</a>
				</div>
				</td>
				<td>&nbsp;</td>
				</tr></table>
			>
		}

		If (..#SHOWSTATISTICS || ..#SHOWSQLINFO) {
			&html<<table><tr>>
			If (..#SHOWSQLINFO) {
				Set DocPageName = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls",,1)
				&html<<td nowrap align="left" valign="middle"><span title="#(hlpSQLINFO)#" style="color: darkblue; font-size: 0.8em; line-height: 150%; margin-left: 20px;" nowrap>
				#(cmdSQLCODE)#: <b><a href="javascript:launchPopupWindow('#(DocPageName)#KEY=RSQL_sqlerrors');"><span id='sqlcode'>N/A</span></a></b>&nbsp;&nbsp;#(cmdRowCount)#: <b><span id='rowcount'>N/A</span></b>
				</td><td>&nbsp;</td>>
			}
	
			If (..#SHOWSTATISTICS) {
				&html<<td nowrap align="left" valign="middle"><span title="#(hlpStatistics)#" style="color: darkblue; font-size: 0.8em; line-height: 150%; margin-left: 20px;" id="statistics">&nbsp;</span></td>>
			}
			&html<</tr></table>>
		}
		
		&html<<br>>

		// build list of actions for the table
		// (move to superclass!)
		Set tActionCols = 0
		Set tKey=""
		Set tAction = ..Actions.GetNext(.tKey)
		While (tKey'="") {
			// check for any $ actions (which are displayed as an additional column)
			If ($E(tKey,1,1) = "$") {
				Set tActionCols = tActionCols + 1
				Set tActionCols(tActionCols) = $LB(tKey,tAction.Caption)
			}
			
			Set tAction(tKey,"HREF") = tAction.HREF
			Set tAction(tKey,"Confirm") = tAction.Confirm
			Set tAction(tKey,"Type") = tAction.Type
			Set tAction(tKey,"Target") = $S(tAction.TargetFrame="":"_top",1:tAction.TargetFrame)
	
			Kill ids
			Do tAction.GetIDValues(.ids)
			Merge tAction(tKey,"ID") = ids
			//YSD727
			If $G(ids(1)) = "",$G(pID(1)) '= "" Set tAction(tKey,"ID",1) = pID(1)
			If $G(ids(2)) = "",$G(pID(2)) '= "" Set tAction(tKey,"ID",2) = pID(2)
			Set tAction(tKey,"Popup") = tAction.Popup
			Set tAction = ..Actions.GetNext(.tKey)
		}
		
		// build list of conditions for the table
		// organized by column name
		For i=1:1:..Conditions.Count() {
			Set tCondition = ..Conditions.GetAt(i)
			If (tCondition.ColumnName '= "") {
				If (tCondition.CellStyle '= "") {
					Set tTarg = $S(tCondition.TargetColumn'="":tCondition.TargetColumn,1:tCondition.ColumnName)
					Set idx = 1 + $G(tCellCondition(tTarg))
					Set tCellCondition(tTarg) = idx
					Set tCellCondition(tTarg,idx) = tCondition
				}
				If (tCondition.RowStyle '= "") {
					Set idx = 1 + $G(tRowCondition)
					Set tRowCondition = idx
					Set tRowCondition(idx) = tCondition
				}
			}
		}

		// build array of "hidden" columns
		For n = 1:1:$L(..HiddenColumns,",") {
			Set t = $P(..HiddenColumns,",",n)
			If (t '= "") {
				Set tHiddenCols(t) = ""
			}
		}
		// execute query / build temp file
		#; YSD1736 Make sure that if query errors out from CreateResultSet or Execute, SQLCODE is updated.
		If (..#SHOWSQLINFO) {
			Set %sqlcontext = ##class(%ProcedureContext).%New()
			Set %sqlcontext.SQLCode = $$$Text("N/A")
			Set %sqlcontext.RowCount = $$$Text("N/A")
		}

		#; YSD1949: initialize to prevent %sqlcontext.RowCount to return wrong number
		New %ROWCOUNT
		Set %ROWCOUNT = 0

		#;YSD1936 Write " var CSPPage = self;",!
		// create query
		Set tRS = ""
		Set tSC = ..CreateResultSet(.tID,.tRS)

		If ($$$ISERR(tSC)) {
			If (..#SHOWSQLINFO) {
				Write "<script language='JavaScript'>",!
				&js< 
				if (self.document.getElementById("sqlcode")) { self.document.getElementById("sqlcode").innerHTML = '#(%sqlcontext.SQLCode)#'; }
				>
				Write "</script>",!
			}
			Do ..DrawStatusError(tSC)
			Quit
		}
		
		If '$IsObject(tRS) {
			// no result set; most likely empty query string
			Quit
		}

		Set tGlobals = $$$GlobalRefs
		Set tStart = $ZH

		Set tRS.RuntimeMode = 2
		Set tSC = ..ExecuteResultSet(tRS,.tID)
		If ($$$ISERR(tSC)) {
			If (..#SHOWSQLINFO) {
				Write "<script language='JavaScript'>",!
				&js< 
				if (self.document.getElementById("sqlcode")) { self.document.getElementById("sqlcode").innerHTML = '#(%sqlcontext.SQLCode)#'; }
				>
				Write "</script>",!
			}
			Do ..DrawStatusError(tSC)
			Quit
		}
		Set tColorBy = ..GetColorByColumn()
		Set tAtStart = 1
		
		Set tCols = tRS.GetColumnCount()
		Set tCachedQueryName = tRS.GetCachedQueryName()

		&html<<table class="DetailTable" style="width:96%" border="0" cellspacing="0">>
		&html<<tr>>
		If (..ShowRowNumbers) {
			&html<<th width="1%" nowrap>#</th>>
		}

		// write out headers and get column types
		For i = 1:1:tCols {
			Set tColName = tRS.GetColumnHeader(i)
			// get localized column header
			If (+..LocalizeColumns) {
				Set lcname = ..LocalizeColumnName(tColName,.tHelpMsg)
			}
			Else {
				Set lcname = tColName
			}
			Set lcname = $ZCVT(lcname,"O","HTML")
			//Set lcname = $ZCVT($ZCVT(lcname,"O","HTML"),"O","JS")
			//Set tHelpMsg = $ZCVT($ZCVT(tHelpMsg,"O","HTML"),"O","JS")

			// index of col name to # (including hidden cols)
			Set tColIndex(tColName) = i

			If ('$D(tHiddenCols(tColName))) {
				Set tColSet(i) = ""
				&html<<th nowrap>#(lcname)#</th>>
	
				// 2:date 3:float,5:integer,10:string,12:binstream,13:charstream
				Set type = tRS.GetColumnType(i)
	 			Set tAlign(i) = $Case(type,3:"right",5:"right",:"left")
	 			Set tIsStream(i) = $Case(type,12:0,13:1,:0)
	 			Set tIsBinaryStream(i) = $Case(type,12:1,13:0,:0)
			}
 		}
		// action columns
		For c = 1:1:tActionCols {
			&html<<th>&nbsp;</th>>
		}

		&html<</tr>>
		// figure out max rows to display
		If ($G(%session.Data("$SQLMAXROWS")) '= "") {
			Set tMaxRows = +%session.Data("$SQLMAXROWS")
		}
		Else {
			Set tMaxRows = ..MaxResults
		}
		If %request.PageName [ "UtilSqlOpen" Set tMaxRows = ##class(%CSP.UI.SQL.BrowseTablePane).GetOpenTableMaxRows()		

		Set tSC = $$$OK
		Set row = 0
		#;YSD1565 While (tRS.Next(.tSC) && (row<tMaxRows)) {
		While (row < tMaxRows) {
			Quit:'tRS.Next(.tSC)
			// get col values (include hidden values)
			For i=1:1:tCols {
				Set tValue(i) = tRS.GetData(i)
			}
			
			// make distinct color for row
			If (..ShowZebra && (tColorBy = "")) {
				#;YSD2331 Set bg = $Case(row#2,1:"#DDEEFF",:"white")
				Set bg = $Case(row#2,1:"#F1F0E7",:"white")
				
			}
			Else {
				If (tColorBy = "") {
					Set bg = "#FFFFFF"
				}
				Else {
					Set num = $G(tRS.Data(tColorBy))
					If (num '= +num) {
						// convert string to #; ignore anything after (
						Set num = $ZCRC($P(num,"(",1),6)
					}
					
					If (num = 0) {
						Set bg = "#FFFFEE"
					}
					Else {
						Set bg = "#"_$J($ZHEX(((num*113)#127)+128),2)_$J($ZHEX(((num*7)#127)+128),2)_$J($ZHEX(((num*17)#127)+128),2)
						Set bg = $TR(bg," ",0)
					}
				}
			}

			// if no row condition, use special color
			Set tRowStyle = "style=""background:" _ bg _ ";"""
			
			// see if there are any row conditions
			Set idx = $O(tRowCondition(""))
			While (idx '= "") {
				// evaluate condition
				Set tCondition = tRowCondition(idx)
				Set tEval = tCondition.Eval2(.tColIndex,.tValue)
				If (tEval) {
					Set tRowStyle = "style=""" _ tCondition.RowStyle _ """"
					Quit
				}
				Set idx = $O(tRowCondition(idx))
			}

			&html<<tr #(tRowStyle)#>>
			If (..ShowRowNumbers) {
				&html<<td align="right">#(row+1)#</td>>
			}
			// draw columns: no actions within data columns!!
			Set tEmpty = $$$TextHTML("<empty>")
			Set i = $O(tColSet(""))
			While (i '= "") {
				Set val = tValue(i)
				If (tIsStream(i) && (val'="")) { 
					Set tStream = ##class(%Stream.Object).%Open(val)
					If $IsObject(tStream) {
						Set val = tStream.Read(110)
						Set:$L(val)>100 val=$E(val,1,100)_"..."
					}
					Else {
						Set val = "<stream>"
					}
					Set tStream = ""
				}
				If (tIsBinaryStream(i) && (val'="")) { Set val = "<binary>" }

				Set tNb = $S($a(val)=0:tEmpty,val="":"&nbsp;",1:"")
				&html<<td class="DetailValue" align="#(tAlign(i))#">#($ZCVT(val,"O","HTML"))##(tNb)#</td>>
				Set i = $O(tColSet(i))
			}

			// additional action columns
			For c = 1:1:tActionCols {
				Set k = $LG(tActionCols(c),1)
				Set tVal = $LG(tActionCols(c),2)
				Set tCellStyle = ""
				Set tADisabled = ""
				Set tNoWrap = "nowrap"
						
				// get id values
				Kill tRowID
				Set n = $O(tAction(k,"ID",""))
				While (n '= "") {
					Set actid = $G(tAction(k,"ID",n))
					If (actid [ "{") {
						// column name (remove {})
						Set actid = $P($P(actid,"{",2),"}",1)
						If (actid = "") {
							Set tRowID(n) = ""
						}
						Else {
							// find data by col name
							Set tRowID(n) = tValue(tColIndex(actid))
						}
					}
					ElseIf (($E(actid,1,4) = "$ID(") && (+$E(actid,5,*) > 0) )  {
						// value in pID
						Set tRowID(n) = $G(pID(+$E(actid,5,*)))
					}
					Else {
						Set tRowID(n) = actid
					}
					
					Set n = $O(tAction(k,"ID",n))
				}
						
				If ($G(tAction(k,"Type")) = "popup") {
					Set tURL = pInstance.MakePopupLink($G(tAction(k,"HREF")),.tRowID)
				}
				ElseIf ($G(tAction(k,"Type")) = "help") {
					Set tURL = ##class(%CSP.Util.Librarian).FindDocBookLink(.tRowID)
				}
				Else {
					// link
					Set tURL = pInstance.MakeLink($G(tAction(k,"HREF")),.tRowID)
				}
		
				If ($G(tAction(k,"Confirm")) '= "") {
					Set tConfirm = " onclick=""return confirm('" _ $ZCVT((tAction(k,"Confirm")),"O","JS") _ "');"""
				}
				Else {
					Set tConfirm = ""
				}
						
				// see if there are cell conditions for this column
				Set idx = $O(tCellCondition(k,""))
				While (idx '= "") {
					// evaluate condition
					Set tCondition = tCellCondition(k, idx)
					Set tEval = tCondition.Eval2(.tColIndex,.tValue)
					If (tEval) {
						Set tCellStyle = tCondition.CellStyle
						If (tCondition.CellStyle [ "disabled") {
							Set tADisabled = "disabled"
						}
						Quit
					}
					Set idx = $O(tCellCondition(k,idx))
				}
		
				Set tTitle = tAction(k,"Popup")
				Set tTarget = $G(tAction(k,"Target"))

				If (tADisabled '= "") {
					Set tHREF = ""
					Set tCellStyle = tCellStyle _ "color: gray;"
				}
				Else { 
					Set tHREF = "href=""" _ $ZCVT(tURL,"O","HTML") _ """"
				}

				Set:tCellStyle'="" tCellStyle = "style=""" _ tCellStyle _ """"

				If (tADisabled'="disabled") {
					&html<<td class="DetailValue" #(tNoWrap)# #(tCellStyle)#>>
					&html<<a #(tADisabled)# #(tHREF)# #(tConfirm)# target="#(tTarget)#" title="#($ZCVT(tTitle,"O","HTML"))#">#($ZCVT(tVal,"O","HTML"))#</a>>
				} Else {
					&html<<td class="DetailValue" align="center" #(tCellStyle)#>>
					&html<->
				}
				&html<</td>>
			}
			// end of action columns

			&html<</tr>>
			Set row = row + 1
		}
		If ($$$ISERR(tSC)) {
			Do ..DrawStatusError(tSC)
			Quit
		}

		Set hasMore = tRS.Next()
		&html<<tr><td colspan="#(tCols+(+..ShowRowNumbers))#">&nbsp;>

		If (hasMore) {
			Set msgMore = $$$TextHTML("More data...")
		}
		Else {
			Set msgMore =  $$$TextHTML("Complete")
		}
			
		&html<<i>#(msgMore)#</i>>
		&html<</td></tr>>
		&html<</table><hr>>

		Set tTime = $ZH - tStart
		Set tGlobals = $$$GlobalRefs - tGlobals

		Write "<script language='JavaScript'>",!
		#;YSD1936 Write " var CSPPage = self;",!
		
		// write statistics
		If (..#SHOWSTATISTICS) {
			Set tStats = msgStatistics _": <b>"_$FN(tTime,"",3) _ "</b> "_msgSeconds_"&nbsp;&nbsp;<b>" _ tGlobals _ "</b> " _ msgGloRefs _ " &nbsp;&nbsp;"_msgRoutineName_": "
			#; YSD2759 - produce link for the Execute Query page only. 
			//If $g(tCachedQueryName) '= "",$G(%request.Data("$CQ",1)) '= 1 {
			//	Set tCQInfoLink = ##class(%CSP.Page).Link("UtilSqlCQInfo.csp",,1)_"$ID1=&$ID2=&$ID3="_$ZCVT(tCachedQueryName,"O","URL")
			//	Set tStats = tStats_"<b><a href="_tCQInfoLink_">" _ tCachedQueryName _ "</a></b>"
			//} Else {
				Set tStats = tStats_"<b>" _ $ZCVT(tCachedQueryName,"O","HTML") _ "</b>"
			//}
			&js<if (self.document.getElementById("statistics")) { self.document.getElementById("statistics").innerHTML = '#(tStats)#'; }>
		}

		If (..#SHOWSQLINFO) {
			&js<if (self.document.getElementById("sqlcode")) { self.document.getElementById("sqlcode").innerHTML = '#(%sqlcontext.SQLCode)#'; }>
			&js<if (self.document.getElementById("rowcount")) { self.document.getElementById("rowcount").innerHTML = '#(%sqlcontext.RowCount)#'; }>
			Kill %sqlcontext
		}

		Write "</script>",!


	} While(0)

Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Subclass can override this to specify the name of column used 
/// to distinctly color rows
Method GetColorByColumn() As %String
{
	Quit ""
}

/// Lookup a column name in the localization global and return localized
/// version if present
ClassMethod LocalizeColumnName(pName As %String, Output pHelpMsg) As %String
{
	// get key, lookup in localization global
	Set tKey = $ZCVT(pName,"L")

	// assume % domain for now!
	// look up help message
	Set pHelpMsg = $$$GetSysMessage($$$SessionLanguage,..#COLUMNHELPDOMAIN,tKey,"")

	Quit $$$GetSysMessage($$$SessionLanguage,..#COLUMNDOMAIN,tKey,pName_"*")
}

}
