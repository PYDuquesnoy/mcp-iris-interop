/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
///  <p>An AutoPage pane that displays a Query Plan
Class %CSP.UI.SQL.ShowPlanPane Extends %CSP.Util.Pane [ System = 4 ]
{

///  Add pre style to the header, to wrape the sql query in the plan-display
Method DrawHEAD(pInstance As PageInstance) As %Status
{
		&html<
<style type="text/css">
pre {	
 white-space: normal;
 word-wrap: break-word;
}
</style>
>
	Quit $$$OK
}

///  Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Merge tID = pInstance.IDValues
	Do ..DrawCommands(pInstance)
	&html<<div class="Text1">#($$$Text("The execution plan is displayed below:"))#</div>>

	// look to see if this is from CQ
	If $G(%request.Data("$CQ",1)) = 1 {
		If $G(tID(1)) = ""||'$D($$$CQ("QueryRoutine",tID(1))) {
		Set errmsg = $$$TextHTML("Cached query is no longer defined. Unable to continue.")	
		&html<<p>#(errmsg)#</p>>
		Quit
		}
		Set tQuery = ##class(%SQL.Manager.API).GetCachedQueryInfo(tID(1),.sCreate,.sLast,.bSource,.sQueryType)
	} Else {
	#; look to see if this a request from History first. If it is get the query text from global.
		If ($G(tID(1)) = "$SHOWPLAN") {
			Set tQuery = $G(^mqh($UserName,+$G(tID(2))))
		} 
		#;YSD2100 If $G(tQuery) = "" Set tQuery = $G(tID(1),$G(%session.Data("$SQLQUERY")))
		If $G(tQuery) = "" {
			Set tQuery = $ZCVT($G(tID(1)),"O","HTML")
			If tQuery = "" Set tQuery = $G(%session.Data("$SQLQUERY"))
		}
	}
	If tQuery = "" {
		&html<<div class="ErrorBox" align="center"><b>#($$$Text("No query provided."))#</b><br><br></div>>
		Quit $$$OK
	}

	// show query plan as HTML	
	&html<<div>>
	&html<<table cellpadding="0" cellspacing="1" border="0" width="100%">>
	&html<<tr bgcolor="#818181"><td valign="top" align="center">>
	Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlan(tQuery,,1)
	&html<#($zconvert(tPlan,"O","HTML"))#>
	&html<</table>
	</div>>

	Quit $$$OK
}

}
