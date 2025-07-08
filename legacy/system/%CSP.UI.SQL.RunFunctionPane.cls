/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occODBC

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>An AutoPage pane that lets a user enter an parameters for a SQL query and execute it.
Class %CSP.UI.SQL.RunFunctionPane Extends %CSP.Util.ExpPane [ System = 4 ]
{

/// Copied from %CSP.Util.SQLQueryPane
Method OnDrawHEADTablePane(pInstance As %CSP.Util.PageInstance) As %Status
{
	&html<
<style type="text/css">

h2 {
	color: darkblue;
	border-top: 1px solid darkblue;
	font-weight: bold;
	font-size: 1.0em;
}

table.DetailTable {
	border: 1px solid black;
	/* make tables with few columns, small */
	width: 10%;
}

table.DetailTable th {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	padding-left: 2px;
	padding-right: 8px;
	font-weight: bold;
	text-align: left;
	color: #888888;
}

table.DetailTable td {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	padding-left: 2px;
	padding-right: 2px;
}


</style>
<script language="javascript">

</script>
>
	Quit $$$OK
}

/// Overwritten by subclasses to draw anything this pane needs for the BODY section.
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Do ..DrawCommands(pInstance)
	Merge tID = pInstance.IDValues
	Do {
		&html<<div class="Text1">#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))#</div>>
		If $G(tID(1)) = "" Do ..DrawError($$$Text("Schema name missing.")) Quit
		If $G(tID(2)) = "" Do ..DrawError($$$Text("Procedure name missing.")) Quit
		If $G(tID(3)) = "" Do ..DrawError($$$Text("Class name missing.")) Quit
		If $G(tID(4)) = "" Do ..DrawError($$$Text("Method name missing.")) Quit
		Set tLink = ##class(%CSP.Page).Link("/csp/sys/exp/UtilExpClass.csp")_"&$ID1="_##class(%CSP.Page).EscapeURL((tID(3)))
		&html<<p class="ltcaption"><a href="#(tLink)#">#($ZCVT(tID(3),"O","HTML"))#</a> : #($ZCVT(tID(4),"O","HTML"))#</p>>
		&html<<form name="RunQueryForm" method="post">>
		&html<<input type="hidden" name="$ID1" value="#($ZCVT(tID(1),"O","HTML"))#">>
		&html<<input type="hidden" name="$ID2" value="#($ZCVT(tID(2),"O","HTML"))#">>
		&html<<input type="hidden" name="$ID3" value="#($ZCVT(tID(3),"O","HTML"))#">>
		&html<<input type="hidden" name="$ID4" value="#($ZCVT(tID(4),"O","HTML"))#">>
		Set SCHEMA=$zcvt(tID(1),"u"),PROC=$zcvt(tID(2),"u")
		/*Set tSC = $$GetSPInfo^%ourProcedure(SCHEMA_"."_PROC,1,.qsc,.metadata,1)
		If tSC '= 0 {
			Do ..DrawError(%lasterr)	
			Quit
		}
		Set ParamCount = $lg(metadata,2)
		*/
		//Set total = ParamCount * 6 + 1
		Set ParamCount = +$G(^oddPROC(SCHEMA,PROC,"c"))
		Set (InputParamCount,OutParamCount) = 0
		//For tCount = 13:6:total Set tCol = tCol + 1, Params(tCol) = $lg(metadata,tCount)
		For tCount = 1:1:ParamCount {
			Set tType = +$G(^oddPROC(SCHEMA,PROC,"c",tCount,14))
			If tType=$$$SQLPARAMINPUT!(tType=$$$SQLPARAMINPUTOUTPUT) Set InputParamCount = InputParamCount + 1, Params(InputParamCount) = $G(^oddPROC(SCHEMA,PROC,"c",tCount,5))_"^"_tCount
			//If tType>2 Set OutParamCount = OutParamCount + 1   // this is not used yet
		}
		If InputParamCount > 0 Do ..DrawOptions(.Params, ParamCount, SCHEMA, PROC)
		Do ..DrawButtons()
		If $G(%request.Data("btnRun",1)) '= "" {
			Do ..OnDrawHEADTablePane()
			Set tSC = ..DrawFunctionResult(.tID, .Params, .FunctionResult)
			If tSC'=1,tSC'=0,$$$ISERR(tSC) {
				Do ..DrawError($P(tSC,"[",1))
			}
		}
		&html<</form>>
 
	} While (0)
	Quit $$$OK
}

Method DrawOptions(ByRef Params As %String, ParamCount As %Integer, SCHEMA As %String, PROC As %String)
{
	Set msgType = $$$Text("xDBC Type")
	&html<<p class="ltcaption">#($$$TextHTML("Enter values for the procedure parameters"))#: </p>>
	&html<<table class="Options">>
	&html<<tr><td><table class="Option"><tr><td>&nbsp;</td><td>&nbsp;</td><td><b><u>#(msgType)#</u></b></td></tr>>
	Set tRow = $O(Params(""))
	While tRow '="" {
		Set tValue = $G(%request.Data(Params(tRow),1))
		Set maxlen = $G(^oddPROC(SCHEMA,PROC,"c",tRow,4))
		Set maxlen = $S(maxlen>50:55,maxlen="":55,1:maxlen+5)
		&html<<tr><td nowrap>#($P(Params(tRow),"^"))#</td>>
		&html<<td><input type="text" name="#(Params(tRow))#" value="#($ZCVT(tValue,"O","HTML"))#" size="#(maxlen)#"></td>>
		&html<<td nowrap>#($ZCVT($G(^oddPROC(SCHEMA,PROC,"c",$P(Params(tRow),"^",2),8)),"O","HTML"))#</td>>
		Set tRow = $O(Params(tRow))
	}
	&html<</table></td></tr></table><br>>
}

Method DrawButtons()
{
	
	&html<<input type="submit" name="btnRun" id="btnRun" value='#($$$Text("Run Procedure"))#'>>
}

Method DrawResult(ByRef tRS As %ResultSet, tGlobals As %String, tStart As %String)
{
	Do {

		Set msgStatistics = $ZCVT($$$Text("Performance"),"O","HTML")
		Set msgSeconds = $ZCVT($$$Text("seconds"),"O","HTML")
		Set msgGloRefs = $ZCVT($$$Text("global references"),"O","HTML")
		Set hlpStatistics = $ZCVT($$$Text("These statistics show the rough cost of executing this query. These values include some cost for displaying the query results."),"O","HTML")
	
		Set cmdSQLCODE = $ZCVT($$$Text("SQLCODE"),"O","HTML")
		Set cmdRowCount = $ZCVT($$$Text("Row count"),"O","HTML")
	
		Set hlpSQLINFO = $ZCVT($$$Text("SQLCODE is the SQL error code value returned by this query. Row count is the number of rows processed by this query. For SELECT statements, these values are only set when all rows are loaded."),"O","HTML")
		If ($G(%session.Data("$SQLMAXROWS")) '= "") {
			Set tMaxRows = +%session.Data("$SQLMAXROWS")
		} Else {
			Set tMaxRows = 1000
		}
		&html<<table><tr>>
		&html<<td nowrap align="left" valign="middle"><span title="#(hlpSQLINFO)#" style="color: darkblue; font-size: 0.8em; line-height: 150%; margin-left: 20px;" nowrap>
		#(cmdSQLCODE)#: <b><a href="javascript:launchPopupWindow('/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_sqlerrors');"><span id='sqlcode'>N/A</span></a></b>&nbsp;&nbsp;#(cmdRowCount)#: <b><span id='rowcount'>N/A</span></b>
		</td><td>&nbsp;</td>>
		&html<<td nowrap align="left" valign="middle"><span title="#(hlpStatistics)#" style="color: darkblue; font-size: 0.8em; line-height: 150%; margin-left: 20px;" id="statistics">&nbsp;</span></td>>
		&html<</tr></table>>

		Set tCols = tRS.GetColumnCount()
		&html<<p>>
		&html<<table class="DetailTable" border="0" cellspacing="0">>
		&html<<tr>>

		// write out headers and get column types
		For i = 1:1:tCols {
			&html<<th>#($ZCVT(tRS.GetColumnHeader(i),"O","HTML"))#</th>>		
 			// 2:date 3:float,5:integer,10:string,12:binstream,13:charstream
			Set type = tRS.GetColumnType(i)
	 		Set tAlign(i) = $Case(type,3:"right",5:"right",:"left")
	 		Set tIsStream(i) = $Case(type,12:1,13:1,:0)
 		}

		&html<</tr>>
		Set tSC = $$$OK
		Set row = 0
		While (tRS.Next(.tSC) && (row<tMaxRows)) {
			If ($$$ISERR(tSC)) {
				Do ..DrawStatusError(tSC)
				Quit
			}
			Set bg = $Case(row#2,1:"#DDEEFF",:"white")
			Set tRowStyle = "style=""background:" _ bg _ ";"""
			&html<<tr #(tRowStyle)#>>

			// get col values (include hidden values)
			For i=1:1:tCols {
				Set val = tRS.GetData(i)
				If (tIsStream(i) && (val'="")) { Set val = "<stream>" }
				Set:$L(val)>100 val=$E(val,1,100)_"..."
				&html<<td nowrap align="#(tAlign(i))#">#($ZCVT(val,"O","HTML"))#&nbsp;</td>>
			}
		
			&html<</tr>>
			Set row = row + 1
		}

		Set hasMore = tRS.Next()
		&html<<tr><td colspan="#(tCols+1)#">&nbsp;>

		If (hasMore) {
			Set msgMore = $$$Text("More data...")
		}
		Else {
			Set msgMore =  $$$Text("Complete")
		}
			
		&html<<i>#(msgMore)#</i>>
		&html<</td></tr>>
		&html<</table></p><hr>>
		
		Set tTime = $ZH - tStart
		Set tGlobals = $$$GlobalRefs - tGlobals

		Write "<script language='JavaScript'>",!
		Write " var CSPPage = self;",!

		Set tStats = msgStatistics _": <b>"_$FN(tTime,"",3) _ "</b> "_msgSeconds_"&nbsp;&nbsp;<b>" _ tGlobals _ "</b> " _ msgGloRefs
			&js<if (self.document.getElementById("statistics")) { self.document.getElementById("statistics").innerHTML = '#(tStats)#'; }>
			&js<if (self.document.getElementById("sqlcode")) { self.document.getElementById("sqlcode").innerHTML = '#(%sqlcontext.SQLCode)#'; }>
			&js<if (self.document.getElementById("rowcount")) { self.document.getElementById("rowcount").innerHTML = '#(%sqlcontext.RowCount)#'; }>
		Kill %sqlcontext
		Write "</script>",!

	} While(0)
}

/// Draws error message directly
Method DrawError(errormsg)
{
	&html<<div style="color:red; margin-left: 20px;" align="left" ><br>>
	&html<<b>#($ZCVT(errormsg,"O","HTML"))#</b><br>>
	&html<</div>>
}

/// Run function procedure and display result.
Method DrawFunctionResult(ByRef pID As %String, ByRef Params As %String, ByRef FunctionResult As %String) As %String [ PublicList = tRS ]
{
	New tRS
	Set tRS = $$$OK
	Set $ZT="Trap"
	Set %sqlcontext = ##class(%ProcedureContext).%New()
	Set tGlobals = $$$GlobalRefs
	Set tStart = $ZH
	Set qt = """"
	// Need to know 
	// 1) Is it a class method
	// Set a = ##class(%CompiledMethod).%OpenId(ClassName:Method)
 	// If a.ClassMethod = 1 then it is classmethod
	// 2) Does it return value
	// ^oddPROC(SCHEMA,PROC,18) = 1 means it returns a value
	// Or write a.ReturnType
	//%Library.ResultSet or "" if nothing
	Set (IsClassMethod,IsResultSet) = 0
	Set ReturnType = ""
	Set oMethod = ##class(%Dictionary.CompiledMethod).%OpenId(pID(3)_"||"_pID(4))
	If $IsObject(oMethod) {
		Set IsClassMethod = oMethod.ClassMethod
		Set ReturnType = oMethod.ReturnType
	}
	// Build the argument string
	Set r = ""
	Set tRow = $O(Params(""))
	While tRow '="" {
		Set tValue = $G(%request.Data(Params(tRow),1))
		SEt r = r_qt_tValue_qt
		Set tRow = $O(Params(tRow))
		If tRow '= "" Set r = r_","
	}
	If IsClassMethod = 1 {
		If ReturnType '= "" {
			If r '= "" {
				Set rs = "Set tRS = $$ClassMethod^%apiOBJ("_qt_pID(3)_qt_","_qt_pID(4)_qt_","_r_")"
				Xecute rs
			} Else {
				Set tRS = $$ClassMethod^%apiOBJ(pID(3),pID(4))
			}
			If $IsObject(tRS) {
				Set IsResultSet = tRS.%IsA("%Library.ResultSet")		
			}
		} Else {
			If r '= "" {
				Set rs = "Do ClassMethod^%apiOBJ("_qt_pID(3)_qt_","_qt_pID(4)_qt_","_r_")"
				Xecute rs
			} Else {
				Do ClassMethod^%apiOBJ(pID(3),pID(4))
			}
		}
	} Else {
		If ReturnType '= "" {
			If r '= "" {
				Set rs = "Set tRS = $$Method^%apiOBJ("_qt_pID(3)_qt_","_qt_pID(4)_qt_","_r_")"
				Xecute rs
			} Else {
				Set tRS = $$Method^%apiOBJ(pID(3),pID(4))
			}
			If $IsObject(tRS) {
				Set IsResultSet = (tRS.%IsA("%Library.ResultSet")=1!(tRS.%IsA("%Library.IResultSet")=1))		
			}
		} Else {
			If r '= "" {
				Set rs = "Do Method^%apiOBJ("_qt_pID(3)_qt_","_qt_pID(4)_qt_","_r_")"
				Xecute rs
			} Else {
				Do Method^%apiOBJ(pID(3),pID(4))
			}
		}
	}
	&html<<h2>#($$$Text("Returned value: "))# #($zconvert($G(tRS),"O","HTML"))#>

	If IsResultSet = 1 {
		Do ..DrawResult(.tRS,tGlobals,tStart)
	}
	&html<</h2>>
Done
	Quit tRS
Trap
	Set $ZT = ""
	Set tRS = $ZE
	Goto Done
}

}
