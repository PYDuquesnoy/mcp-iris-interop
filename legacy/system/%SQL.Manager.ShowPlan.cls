/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL Manager Class to Show Query Plan
Class %SQL.Manager.ShowPlan Extends %CSP.Util.AutoPage [ Not ProcedureBlock, System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter SECURITYRESOURCE = "%Development:USE";

ClassMethod OnPage() As %Status
{
 &html<<html><head>
 <style type="text/css">
 DIV.result { 
  	font-family: courier new;	
 	font-size:	10pt;
 	}
 blockquote {
	margin: 0 0 0 10px;
	padding: 10px 15px 0px 10px;
}
 </style></head>>
 &html<<body bgcolor="#ffffff">>
 &html<<div align="center">>
 &html<<table cellpadding="0" cellspacing="1" border="0" width="100%">>
 &html<<tr bgcolor="#818181"><td valign="top" align="center">>

 new querytext,m,current,namespace,username,ImportPackage
 // -----
 // When this page is accessed via http://ipaddress:port/csp/sys, the current namespace is %SYS.
 // So we need to change to SQL Manager connected namespace.
 // After work is done, return to original namespace - %Cachelib.
 // -----
 set current = $namespace
 set namespace = $zcvt(%request.Get("namespace"),"U")
 if namespace'="",current'=namespace zn namespace
 //set (%msql,username) = %request.Get("username")
 set username = %session.Username
 set querytext = $g(^mqh(username))
 set ImportPackage = $g(^mqh(username,"schema"))
 if username = "" write !,$$$Text("No Username")
 if querytext = "" write !,$$$Text("No query text")
 else  set m = ..ShowPlan(querytext,ImportPackage,1) write !,m

 &html<</table>>
 &html<</div></body>>
 &html<</html>>
 if namespace'="",current'=namespace zn current
 Quit $$$OK
}

/// This method is called from %CSP.UI.SQL.ShowPlanPane to display HTML for show plan. "" is always returned. 
ClassMethod ShowPlan(querytext, ImportPackage = "", preparse, frozenplan As %Boolean = 0, selectmode = "Runtime", addDeclare = 0, schemaPath = "", stats = "", AltPlan = "", minStats = 0, nofplan = 0, silent = 1, verbose = 0, isbackground = 0, noRTPC = 0) As %String
{
 try {
 	new backgrnd,cssLinkHref,current,error,errorMsg,from,i,j,line,namespace,nSub,piece,%plan,sc,showErr,sql,sqlBlock,sqlModule,sqlprep,sqlStats,text,webInterface,wrtref
 	set (current,namespace) = $namespace
 	#; check so this method may be called when not using the Sys Mgr Portal
 	set webInterface=0
 	If $IsObject($G(%request)) {
 		set webInterface=1
 		set namespace = $G(%request.Data("$NAMESPACE",1))
 	} 
 	if namespace'="",current'=namespace zn namespace
 	// -----
 	//  set css style for html output
 	// -----

 	set cssLinkHref=$s(webInterface:..Link("/csp/sys/intersystems.css"),1:"/csp/sys/intersystems.css")

 	//  --- Call to build '%plan' for the first time ---
 	kill %plan,sql
 	#; If query text is passed in as an array, then use it as is; Otherwise, parse it into an array
 	if $O(querytext("")) '= "" { merge sql = querytext } 
 	else {
 		#; --- Parse $c(10) from each line of query text and put into an array ---
 		for piece=1:1:$l(querytext,$c(10)) { set sql($I(sql))=$tr($p(querytext,$c(10),piece),$c(13)) }
 	}
 	#; If this is a SELECT query, add on a "DECLARE CURSOR QRS FOR " so the showplan will match the statement index for a dynamic query that may have already been executed and had it's plan frozen.
 	#; This will allow the statment to match and use the frozen plan
 	#;  Remeber, it might be ( SELECT, or any number of "("s before the SELECT token
 	if addDeclare {
		for i=1:1:sql {
			if $$$UPPER($e($zstrip(sql(i),"<W","("_$c(13,10)),1,6))="SELECT" {	// line begins with SELECT
		 		set sql(i)="DECLARE QRS CURSOR FOR "_sql(i)
		 		quit
	 		}
	 		if $zstrip(sql(i),"<W","("_$c(13,10))="" { continue }			// blank line
			if $e($zstrip(sql(i),"<W","("_$c(13,10)),1,2)="--" { continue }		// line begins with a comment
	 		quit	// something other than SELECT or blank line
		}
 	}
 	#; If you want to show "stats" then pass in the parameter stats in the URL.
 	#; stats=2 means lookup in %SYS.PTools.SQLStats
 	#; stats=1 means generate new routine, execute and display stats, Need preparse =0 so parameters will work
 	if webInterface {
		set:stats="" stats = %request.Get("stats")
    	set:AltPlan="" AltPlan = %request.Get("AltPlan")
    	set verboseHold=verbose
    	set verbose=%request.Get("verbose")
    	set:verbose="" verbose=+verboseHold
 	}
	 set:+stats=1 preparse = 0
 
 	set backgrnd=1,wrtref="showErr"	// Record any SQL errors in the 'showErr' array
 	if AltPlan="" { do ShowPlan^%apiSQL(.sql,1,,stats,ImportPackage,schemaPath,.preparse,selectmode,nofplan,silent,,,verbose,,noRTPC)}  // DPV3693, preparse then show the plan
 	else { 
 		do ShowPlanAlt^%apiSQL(.sql,1,,stats,ImportPackage,schemaPath,.preparse,AltPlan,silent,,,verbose) 
 		m %plan=%AltPlan(AltPlan)
 	}	

 	do:$d(@wrtref)>1 ..ShowPlanSQLError(.@wrtref)	// Display SQL Errors with proper formatting!

 	#; 
 	#;  ShowPlan^%apiSQL returns array named %plan with integer subscript incremented by 1
 	#;  the total number of lines in the array is set in %plan. e.g. %plan=3 means there are three lines
 	#; 

 	if '$g(%plan)&&'$g(@wrtref@(0)) {	// --- Show 'No Plan' Message if no errors in @wrtref@() ---
 		set %plan($I(%plan))="<plan>"
 		set %plan($I(%plan))="<sql>"
 		for j=1:1:sql { set %plan($I(%plan))=sql(j) }
 		set %plan($I(%plan))="</sql>"
 		set %plan($I(%plan))=$$$TextHTML("No plan created for this statement")
 		set %plan($I(%plan))="</plan>"
 	}

 	#;  Convert each line to HTML format
 	#;  Return text when string exceeds 5000 characters
 	if (isbackground) {
 		merge ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"%plan") = %plan
		set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"params")=frozenplan_"^"_minStats_"^"_stats_"^"_cssLinkHref_"^"_$job
 		if $d(@wrtref)>1 {
	 		merge ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"%planerror") = @wrtref	
 		}
 	}
	set error=""
	set sc=$s('$g(%plan):$$$OK,1:$$planHTML^%qaqplan(.%plan,cssLinkHref,frozenplan,minStats,stats=2))
 	set:$$$ISERR(sc) error=$system.Status.GetErrorText(sc)
		
 }
 catch {
	Do BACK^%ETN

	set error="ERROR #"_$$$ERRORCODE($$$GeneralError)_": General error: $ZE='"_$REPLACE($REPLACE($ZE,"<","&lt;"),">","&gt;")_"' ["_$ZN_":"_$NAMESPACE_"]"
	RETURN ""
 }	

 QUIT ""
}

/// This method is called from several locations to process & display SQL Errors with proper formatting:
///    - %SQL.Manager.ShowPlan.CLS
///         - ShowPlan()
///    - %SYS.PTools.SQLUtilities.CLS
///         - PossiblePlansExecute()
///         - PossiblePlansStatsExecute()
ClassMethod ShowPlanSQLError(sqlError)
{
	&html<
		<style type="text/css">

		  body {
			 	margin: 0;
			 	padding: 0;
			 	font-family: Arial,sans-serif;
		  }

		  /* --- Error --- */
          table.qp-error-container {
	        	color: black;
	         	background-color: white;
	         	width: 100%;
             	height: 12px;
             
			 	text-align: left;
	         	font-family: Arial, Helvetica, sans-serif;
	         	font-size: 12px;
	         
	         	margin: 0 0 0 0;
	         	padding: 0 0 0 0;

			 	border-color: grey;
			 	border-style: solid;
			 	border-width: 1px;
			 	border-spacing: 0;
			 	border-collapse: collapse;
          }

	      .qp-header {
	         	color: white;
	         	width: 100%;
             	height: 16px;
             
			 	text-align: center;
             	vertical-align: bottom;
			 	font-family: Arial,sans-serif;
	         	font-size: 16px;
             	font-weight: bold;
          }

	      .qp-error-header {
		     	/* Use CSS 'qp-header' first in the class definition */
             	background: rgb(255,66,66); /* For browsers that do not support gradients */
             	background: -webkit-linear-gradient(rgb(255,66,66),rgb(217,0,0));  /* For Safari 5.1 to 6.0 */
             	background: -o-linear-gradient(rgb(255,66,66),rgb(217,0,0)); 	    /* For Opera 11.1 to 12.0 */
             	background: -moz-linear-gradient(rgb(255,66,66),rgb(217,0,0)); 	/* For Firefox 3.6 to 15 */
             	background: linear-gradient(rgb(255,66,66),rgb(217,0,0)); 	 	    /* Standard syntax (must be last) */
          }

          .qp-error-body {
			 	text-align: left;
	         	font-family: monospace;
	         	white-space: normal;
  
  			 	padding-top:    10px;
	         	padding-bottom: 10px;
	
          }
          
          table.qp-error-container td {
	         	padding-left:   5px;
	         	padding-right:   5px;
	         	padding-bottom: 5px;
          }
          
		</style>
	>

	&html<<table class="qp-error-container">> 
	&html<<tr class="qp-header qp-error-header"><td>#($$$TextHTML("Error"))#</td></tr>>
	&html<<tr><td><div class="qp-error-body">>
	
	set nSub=0
	While 1 {
		set errorMsg=""
		set nSub=$o(sqlError(nSub),1,errorMsg)
		QUIT:'+nSub  // No More Errors!
	
		set error=$g(sqlError(nSub,"error"))
		set:errorMsg="" errorMsg=$LG(error,7) 
		if errorMsg="" {
			set errorMsg=$LG(error,4)
			if errorMsg["<<<" { set errorMsg=..fullErrorMsg(errorMsg,error) }
			elseif errorMsg'="" { set errorMsg=errorMsg_":  "_$LG(error,1) }
			else { 
		   		set errorMsg=$LG(error,6) 
		   		set:errorMsg="" errorMsg="Unexpected Error:  "_$LG(error,1)
			}
		}
		set errorMsg=$$$StripLeadingWhiteSpace(errorMsg)
		set:errorMsg["<" errorMsg=$REPLACE(errorMsg,"<","&lt;")
		set:errorMsg[">" errorMsg=$REPLACE(errorMsg,">","&gt;")
	
		if $LG(error,5)'="" {
			if nSub>1 { &html<<br/><br/>> } 
			&html<<span style="font-family: Arial, Helvetica, sans-serif; font-weight: bold; text-decoration: underline; line-height: 20px;">#($$$TextHTML("SQL Error Details"))#</span></br>>
			&html<#("SQLCODE="_$LG(error,5))#<br/>>
			&html<#("&nbsp;&nbsp;&nbsp;"_errorMsg)#>
		}
		elseif errorMsg'="" { 
			if nSub>1 { &html<<br/><br/>> } 
			&html<<span style="font-family: Arial, Helvetica, sans-serif; font-weight: bold; text-decoration: underline; line-height: 20px;">#($$$TextHTML("Raw Error Details"))#</span></br>>
			&html<#(errorMsg)#>
		}
	}
    
	&html<</div></td></tr>>
	&html<</table>>
}

/// This method is called from %CSP.UI.Portal.Dialog.SQLStatementDetails to display HTML for sql text. "" is always returned. 
/// Plan itself cannot be shown because the frozen plan has an error.
/// Or there is another reason the plan cannot be show and that reason is passed in via noPlanReasonTxt argument
ClassMethod ShowPlanError(querytext, noPlanReasonTxt = "") As %String
{
 try {
 	new cssLinkHref,current,error,frozenplan,j,minStats,namespace,sc,webInterface,piece,%plan,sql,webInterface
 
 	set error=""
 	set (current,namespace)=$namespace
 	set frozenplan=0,minStats=0
 	set webInterface=0
 	if $IsObject($G(%request)) {
 		set namespace = $G(%request.Data("$NAMESPACE",1))
 		set webInterface=1 
 	} 
 	if namespace'="",current'=namespace zn namespace

 	set cssLinkHref=$s(webInterface:..Link("/csp/sys/intersystems.css"),1:"/csp/sys/intersystems.css")

 	//  --- Call to build '%plan' for the first time ---

 	#; If query text is passed in as an array, then use it as is; Otherwise, parse it into an array
 	if $O(querytext("")) '= "" { merge sql = querytext } 
 	else {
 		#; --- Parse $c(10) from each line of query text and put into an array ---
 		for piece=1:1:$l(querytext,$c(10)) { set sql($I(sql))=$tr($p(querytext,$c(10),piece),$c(13)) }
 	}

 	#;  ShowPlan^%apiSQL returns array named %plan with integer subscript incremented by 1
 	#;  The total number of lines in the array is set in %plan. 
 	#;     e.g. %plan=3 means there are three lines: %plan(1), %plan(2), %plan(3)
  	
 	if '$g(sql) { set error="["_$$$TextHTML("No SQL Statement")_"]" QUIT }

 	set %plan($I(%plan))="<plan>"
 	set %plan($I(%plan))="<sql>"
 	for j=1:1:sql { set %plan($I(%plan))=sql(j) }
 	set %plan($I(%plan))="</sql>"
 	set %plan($I(%plan))="<error>"
 	if noPlanReasonTxt="" { set %plan($I(%plan))=$$$TextHTML("Plan could not be determined due to an error in the frozen plan") }
 	else { set %plan($I(%plan))=noPlanReasonTxt }
 	set %plan($I(%plan))="</error>"
 	set %plan($I(%plan))="</plan>"

 	set sc=$$planHTML^%qaqplan(.%plan,cssLinkHref,frozenplan,minStats)
 	set:$$$ISERR(sc) error=$system.Status.GetErrorText(sc)
 }
 catch {
	Do BACK^%ETN

	set error="ERROR #"_$$$ERRORCODE($$$GeneralError)_": General error: $ZE='"_$REPLACE($REPLACE($ZE,"<","&lt;"),">","&gt;")_"' ["_$ZN_":"_$NAMESPACE_"]"
	RETURN error
 }	
	QUIT error
}

/// Process the 'errorMsg' and replace all references to <<<#>>> with $LG(error,#)
ClassMethod fullErrorMsg(errorMsg, error) As %String
{
	While errorMsg["<<<" {
		set errorMsg=$p(errorMsg,"<<<",1)_$LG(error,+$p(errorMsg,"<<<",2))_$p(errorMsg,">>>",2,*)
	}
	
	QUIT errorMsg
}

}
