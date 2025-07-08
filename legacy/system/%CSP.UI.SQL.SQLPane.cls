/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>An AutoPage pane that displays a table based on a class query.
/// This class is used for SQL Manager utilities
Class %CSP.UI.SQL.SQLPane Extends %CSP.Util.Pane [ System = 4 ]
{

/// Return CQ infor
ClassMethod listCQ(ByRef listRec As %String, ByRef listTH As %String, ByRef tQuery As %String) As %Integer
{
	kill listRec,listTH
	set d1 = $c(22,35,1)	
	set listTH = 2
	set listTH(1) = "Property"
	set listTH(2) = "Value"
	set total = 7
 	#; get data for query (first 80 characters)
 	set rtnname = %request.Get("$ID2")
 	set tQuery = ##class(%SQL.Manager.Catalog).GetCachedQueryInfo(rtnname,.create,.last,.source,.querytype,.cost)
	set listRec(1) = "Routine Name"_d1_rtnname
	set listRec(2) = "Create Date"_d1_create
	set listRec(3) = "Last Used"_d1_last
	set listRec(4) = "Show Source"_d1_$s(source=1:"<a href='a'>Allowed</a>",1:"Not allowed")
	set listRec(5) = "Query Type"_d1_$S(querytype=6:"ODBC Query",querytype=7:"Dynamic Query",1:querytype)
	set listRec(6) = "Cost"_d1_cost
	Quit 6
}

/// Name of the class query that provides info for the Table.<BR>
/// This is a full name: e.g., "Package.Class:QueryName"
/// In this SYSTEM class the Query is used to store the function name
Property Query As %String(MAXLEN = 128);

/// Name of the class method that provides info for the Cached Query.<BR>
/// This is a full name: e.g., "Package.Class:MethodName"
/// In this SYSTEM class the Method is used to store the function name
Property Method As %String(MAXLEN = 128);

/// An array of actions, indexed by column name in the query.
/// These are associated with columns in a table.<BR>
/// If the subscript name starts with a $, then the
/// action is displayed as an additional column in the table.
Property Actions As array Of %CSP.Util.Action(XMLKEYNAME = "name");

/// If true, then rows are displayed using zebra styling.
Property ShowZebra As %Boolean [ InitialExpression = 0 ];

/// If true, then rows numbers are displayed.
Property ShowRowNumbers As %Boolean [ InitialExpression = 0 ];

/// If true, then rows in the table can be sorted.
Property Sortable As %Boolean [ InitialExpression = 0 ];

/// Max number of columns to show.
Property MaxColumns As %Integer;

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Do ..DrawCommands(pInstance)

	// get page ID values
	Merge tID = pInstance.IDValues
	
	Set ID1 = %request.Get("$ID1")
	Set ID2 = %request.Get("$ID2")
	
	If (..Text '= "") {
		// show descriptive text
		&html<<DIV CLASS="Text1" >#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))# #($ZCVT(ID1,"O","HTML"))# #($ZCVT(ID2,"O","HTML"))#</DIV>>
	}
	
	// !!!
	Set pSortCol = $G(%request.Data("$SORTCOL",1))
	Set pSortDir = $G(%request.Data("$SORTDIR",1),1)
	Do GetPortalSettings^%SYS.cspServer2(%session.Username,.PortalSettings)	
	Set tCols = 0
	Set tActionCols = 0
	Set tMaxRows = $G(PortalSettings("MAXROWS"),50)
	
	// build list of actions for the table
	Set tKey=""
	Set tAction = ..Actions.GetNext(.tKey)
	While (tKey'="") {
		// check for any $ actions (which are displayed as an additional column
		If ($E(tKey,1,1) = "$") {
			Set tActionCols = tActionCols + 1
			Set tActionCols(tActionCols) = $LB(tKey,tAction.Caption)
		}
		
		Set tAction(tKey,"HREF") = tAction.HREF
		Set tAction(tKey,"Confirm") = tAction.Confirm
		Set tAction(tKey,"Caption") = tAction.Caption
		Set tAction(tKey,"Encrypted") = tAction.Encrypted

		Merge tAction(tKey,"ID") = tAction.IDValues

		Set tAction(tKey,"Popup") = ..LocalizeText(tAction.Popup)
		Set tAction = ..Actions.GetNext(.tKey)
	}

	Set TABLECLASS = "DetailTable"	
	// draw detail table
	If ..Method = "CQ" {
		Set tMaxRows = ..listCQ(.listRec, .listTH, .tQuery)
	} 

	If (tMaxRows < 1) {
		&html<<DIV ALIGN="center">Nothing to display.</DIV>>
	} Else {
		// get parameters for query from page instance
		//&html<Total rows: #(tMaxRows)#>
		Set tCols = listTH
		If ((+..MaxColumns '= 0) &&  (tCols > +..MaxColumns)) {
			Set tCols = +..MaxColumns
		}
		Set d1 = $c(22,35,1)
		Set tStyle = $S(TABLECLASS = "AutoFormTable":"AutoFormTableTitle",1:"")

		&html<<FORM NAME="theForm" METHOD="POST">>
		&html<<DIV>>
		&html<<TABLE CLASS=#(TABLECLASS)# BORDER="0" COLS="#(tCols + tActionCols + ..ShowRowNumbers)#" CELLSPACING="0" CELLPADDING="3">>
		&html<<TR class=#(tStyle)#>>

		If (..ShowRowNumbers) {
			&html<<TH>#</TH>>
		}

		// show table headers (with or without sort option)

		// data columns
		If (..Sortable) {
			For c = 1:1:tCols {
				Kill tVars
				Set tCols(c) = listTH(c)
				Set tSortDir = 1
				Set tStyle = $S(tCols(c) = pSortCol:"SortCol",1:"")
				
				If ((tCols(c) = pSortCol) && (pSortDir = 1)) {
					// we are already sorting on this column; another click is an inverse sort
					Set tSortDir = -1
					Set tVars("$SORTDIR") = -1
				}
				Set tVars("$SORTCOL") = tCols(c)
				
				&html<<TH CLASS="#(tStyle)#">
					<A HREF='#(pInstance.MakeLink(%request.URL,.tID,.tVars))#'>#($zconvert(tCols(c),"O","HTML"))#</A></TH>>
			}
		}
		Else {
			For c = 1:1:tCols {
				// no sort option
				Set tCols(c) = listTH(c)
				&html<<TH>#($zconvert(tCols(c),"O","HTML"))#</TH>>
			}
		}
				
		// action columns
		For c = 1:1:tActionCols {
			&html<<TH>&nbsp;</TH>>
		}

		&html<</TR>>
		
		// now show the table:
		// either get that data direct from the ResultSet
		// or build a temporary sorted list from the ResultSet and show it...
		
		If (pSortCol '= "") {
			// build a sort file
			//Set tDoSort = ..BuildSortFile(tRS,pSortCol,tCols,.tCols,.tSortFile)
		}
		Else {
			Set tDoSort = 0
		}

		Set tStatus = ""
		Set tRow = 1

		// first row		
		If (tDoSort) {
			// Use temp file
			Set tKey = $O(tSortFile(""),pSortDir)
			Set tNext = (tKey '= "")
		}
		Else {
			// use listRec
			Set tNext = listRec(tRow)
		}
		Set tTDClass = "DetailValue"
		If TABLECLASS = "AutoFormTable" {
			Set tStatus = "AutoFormTableRow"
			Set tTDClass = "AutoFormTableCaption"
		}
	
		While (tRow '> tMaxRows) {
			// use the Status column if present
			// Set tStatus = $G(tRS.Data("Status"),"Active")
			If (..ShowZebra) {
				Set tStatus = $S(tRow#2=0:"EvenRow",1:"OddRow")
			}
			&html<<TR CLASS='#(tStatus)#'>>
			If (..ShowRowNumbers) {
				&html<<TD CLASS="DetailRowNo">#(tRow)#</TD>>
			}

			// data columns
			For c = 1:1:tCols {

				// get values for each column
				If (tDoSort) {
					Set tVal = $G(tSortFile(tKey,tCols(c)))
				}
				Else {
					Set tVal =  $p($G(listRec(tRow)),d1,c)
				}
				
				Set tVal = $ZCVT(tVal,"O","HTML")

				Set:tVal="" tVal = "&nbsp;"

				// see if there is an action for this column
				If ($D(tAction(tCols(c)))) {
					// get id values
					Set n = $O(tAction(tCols(c),"ID",""))
					While (n '= "") {
						Set id = $G(tAction(tCols(c),"ID",n))
						If (id [ "{") {
							// column name (remove {})
							Set id = $P($P(id,"{",2),"}",1)
							If (id = "") {
								Set tRowID(n) = ""
							}
							Else {
								If (tDoSort) {
									Set tRowID(n) = $G(tSortFile(tKey,id))
								}
								Else {
									Set tRowID(n) = $p($G(tNext),d1,c)
								}
							}
						}
						ElseIf (($E(id,1,4) = "$ID(") && (+$E(id,5,*) > 0) )  {
							// value in tID
							Set tRowID(n) = $G(tID(+$E(id,5,*)))
						}
						Else {
							Set tRowID(n) = id
						}
						// encrypt the value if Encrypted is true for this Action
						If $G(tAction(tCols(c),"Encrypted"),0) {
							Set tRowID(n) = ##class(%CSP.Page).Encrypt(tRowID(n))
						}

						Set n = $O(tAction(tCols(c),"ID",n))
					}
					//
	
			
					If ($G(tAction(tCols(c),"Confirm")) '= "") {
						Set tConfirm = " onclick=""return confirm(" _ ##class(%CSP.Page).QuoteJS(tAction(tCols(c),"Confirm")) _ ");"""
					}
					Else {
						Set tConfirm = ""
					}
					&html<<TD CLASS="DetailValue" NOWRAP>
						<DIV WIDTH="100%">
						<A HREF="#(pInstance.MakeLink($G(tAction(tCols(c),"HREF")),.tRowID))#" 
							onmouseover="this.oldcolor=this.style.color; this.style.color='red';" 
							onmouseout="this.style.color=this.oldcolor;" 
							#(tConfirm)#
							TITLE='#(tAction(tCols(c),"Popup"))#'>#(tVal)#</A>
						</DIV></TD>>
				}
				Else {
					If c > 1,TABLECLASS = "AutoFormTable" &html<<TD CLASS="AutoFormTableValue" NOWRAP>#(tVal)#</TD>>
					Else  &html<<TD CLASS=#(tTDClass)# NOWRAP>#(tVal)#</TD>>
				}
			}

			// action columns
			For c = 1:1:tActionCols {

				Set k = $LG(tActionCols(c),1)
				Set tVal = $LG(tActionCols(c),2)
				
				// get id values
				Set n = $O(tAction(k,"ID",""))
				While (n '= "") {
					Set id = $G(tAction(k,"ID",n))
					If (id [ "{") {
						// column name (remove {})
						Set id = $P($P(id,"{",2),"}",1)
						If (id = "") {
							Set tRowID(n) = ""
						}
						Else {
							If (tDoSort) {
								Set tRowID(n) = $G(tSortFile(tKey,id))
							}
							Else {
								Set tRowID(n) = $G(tNext)
							}
						}
					}
					ElseIf (($E(id,1,4) = "$ID(") && (+$E(id,5,*) > 0) )  {
						// value in tID
						Set tRowID(n) = $G(tID(+$E(id,5,*)))
					}
					Else {
						Set tRowID(n) = id
					}
					// encrypt the value if Encrypted is true for this Action
					If $G(tAction(k,"Encrypted"),0) {
						Set tRowID(n) = ##class(%CSP.Page).Encrypt(tRowID(n))
					}
					
					Set n = $O(tAction(k,"ID",n))
				}
				
				If ($G(tAction(k,"Confirm")) '= "") {
					Set tConfirm = " onclick=""return confirm(" _ ##class(%CSP.Page).QuoteJS(tAction(k,"Confirm")) _ ");"""
				}
				Else {
					Set tConfirm = ""
				}
				
				&html<<TD CLASS="DetailValue">
					<A HREF='#(pInstance.MakeLink($G(tAction(k,"HREF")),.tRowID))#' 
						#(tConfirm)#
						TITLE='#(tAction(k,"Popup"))#'>#(tVal)#</A></TD>>
			}

			&html<</TR>>

			Set tRow = tRow + 1

			// next row
			If (tDoSort) {
				// Use temp file
				Set tKey = $O(tSortFile(tKey),pSortDir)
				Set tNext = (tKey '= "")
			}
			Else {
				// use listRec
				Set tNext = $G(listRec(tRow))
			}
		}
		If (tNext) {
			// more to show
			&html<<TR><TD COLSPAN="#(tCols + tActionCols + ..ShowRowNumbers)#" CLASS="DetailMore">#($$$TextHTML("More..."))#</TD></TR>>
		}
		
		
		&html<</TABLE>>
		

		&html<</DIV></FORM>>
		
		&html<<DIV style="padding-top:4px;padding-bottom:4px;">>
			Do ..DrawCommandForm(pInstance)
		&html<</DIV>>
	
		if ..Method = "CQ" {
			Do ##class(%CSP.UI.SQL.QueryPane).DrawSQLShowPlan(tQuery,pInstance)
		
		}

	}
	

	Quit $$$OK
}

/// Sort the data within a ResultSet and place the results in a tempfile.
/// <var>pCol</var> contains the names of the columns ordered by column #.
ClassMethod BuildSortFile(pRS As %ResultSet, pSortCol As %String, pMaxCols As %Integer, ByRef pCols As %String, ByRef pSortFile) As %Boolean
{
	Set tOK = 1
	Set $ZT = ""

	Set tRow = 1
	
	If ((+pMaxCols '= 0) && (pMaxCols < pCols)) {
		Set tCols = pMaxCols
	}
	Else {
		Set tCols = pCols
	}
	
	While (pRS.Next()) {
		Set tKey = $G(pRS.Data(pSortCol))
		If (tKey = "") {
			// NULL
			Set tKey = $c(255) _ tRow
		}
		ElseIf (tKey = +tKey) {
			// numeric value
			Set tKey = +(tKey _ "." _ tRow)
		}
		Else {
			// string
			Set tKey = tKey _ "_" _ tRow
		}
		
		For c = 1:1:tCols {
			Set pSortFile(tKey,pCols(c)) = $G(pRS.Data(pCols(c)))
		}
		
		Set tRow = tRow + 1
	}

Done
	Quit tOK
Trap
	Set $ZT=""
	// an error: do not perform the sort
	Write "ERROR: ",$ZCVT($ZE,"O","HTML"),!
	
	Set tOK = 0
	Kill pSortFile
	Goto Done
}

Method OnGenerateCode() As %String
{
	Set code = ""
	If (..Query '= "") {
		Set code = code _ " Set tPane.Query = " _ ..QuoteCOS(..Query) _ $$$EOL
	}
	If (..Method '= "") {
		Set code = code _ " Set tPane.Method = " _ ..QuoteCOS(..Method) _ $$$EOL
	}
	If (..Sortable '= "") {
		Set code = code _ " Set tPane.Sortable = " _ +..Sortable _ $$$EOL
	}
	If (..MaxColumns '= "") {
		Set code = code _ " Set tPane.MaxColumns = " _ +..MaxColumns _ $$$EOL
	}
	If (..ShowZebra '= "") {
		Set code = code _ " Set tPane.ShowZebra = " _ +..ShowZebra _ $$$EOL
	}

	// actions
	Set code = code _ $$$EOL
	If (..Actions.Count() > 0) {
		Set code = code _ " // actions" _ $$$EOL
	}

	Set tKey=""
	Set tAction = ..Actions.GetNext(.tKey)
	While (tKey '= "") {
		Set code = code _ tAction.GenerateCode()
		Set code = code _ " Do tPane.Actions.SetAt(tAction, "_..QuoteCOS(tKey)_")" _ $$$EOL
		Set code = code _ $$$EOL
		Set tAction = ..Actions.GetNext(.tKey)
	}

	Quit code
}

/// Method to tune all tables in a schema, or an individual table in the background
ClassMethod TuneTables(ByRef pParms As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set HasError = 0
	Do {
		Set NAMESPACE = $G(pParms("NAMESPACE"))
		If NAMESPACE = "" {
	 		Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") _ " "_$$$Text("Missing Namespace")
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("ERROR")
			Quit
		}
		Set Schema = $G(pParms("Schema"))
		If Schema = "" {
	 		Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") _ " "_$$$Text("Missing Schema")
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("ERROR")
			Quit
		}
		#; YSD2003 Set (update,KeepClassUpToDate) = 1
		Set update = 1
		Set KeepClassUpToDate = +$G(pParms("KeepClassUpToDate"),0)
		Set ClearValues = +$G(pParms("ClearValues"),0)
		Set Display = +$G(pParms("DISPLAY"),1)
		Set LogFile = $G(pParms("LogFile"))

		Set $Namespace = NAMESPACE
		// If Table does not exist then this is to tune all tables
		If $G(pParms("Table")) = "" {
			Do $System.SQL.TuneSchema(Schema,update,Display,.err,KeepClassUpToDate,ClearValues,LogFile)
			If $O(err("")) '="" {
				Set tErr = $O(err(""))
				Do ##class(%CSP.UI.System.BackgroundTask).WriteError(err(tErr))
			} Else {
				Do ##class(%CSP.UI.System.BackgroundTask).WriteDone()
			}
		} Else {
			Set tSC = $System.SQL.TuneTable(Schema_"."_pParms("Table"),update,0,.pMessage,KeepClassUpToDate,ClearValues,,pParms("ExtentSize"))
			If $G(pMessage) = "" {
				Set tSC = 1
				Do ##class(%CSP.UI.System.BackgroundTask).WriteDone()
			} Else {
				Set tSC = 0
				Do ##class(%CSP.UI.System.BackgroundTask).WriteError(pMessage)
			}
		}
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($ZE)
	Goto Done
}

}
