/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Audit.Detail Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "AuditDetail";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.Detail.zen";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Audit Details";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Switch namespace for this page: 
Parameter AUTONS As BOOLEAN = 0;

Property PID As %ZEN.Datatype.string(ZENURL = "PID");

XData Style
{
<style type="text/css">
table.InfoTable td.caption {
	font-weight: bold;
}
table.InfoTable td {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	font-size: 0.8em;
	padding: 2px 5px;
}
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<vgroup cellStyle="padding-top:2px;" containerStyle="padding:10px;">
<hgroup cellStyle="padding-right:2px;">
<button caption="Close" onclick="zenPage.cancelPopup();"/>
</hgroup>
<html label="Audit Details:" OnDrawContent="DrawDetails" seed="#(%page.PID)#"/>
<spacer height="4px"/>
</vgroup>
</page>
}

ClassMethod DrawDetails(PID As %String) As %Status
{
	Set Audit = ##class(%SYS.Audit).%OpenId(PID)
	
	&html<<table class="InfoTable" border="1" cellpadding="4" cellspacing="0">>
	If Audit="" {
		Set tmsg = ..EscapeHTML(($$$FormatText($$$Text("Unable to open id: %1"),PID)))
		&html<<tr><td colspan="4"><div class="rednote">#(tmsg)#</div></td></tr></table>>
		Quit $$$OK
	} Else  {
		Set TimeStamp = ##Class(%SYS.Audit).ConvertUTCToLocal(Audit.UTCTimeStamp)
		Set UTCTimeStamp = $PIECE(PID,"||",1)
		&html<
		<tr><td class="caption" nowrap width="150">#($$$TextHTML("Description"))#</td>
		<td colspan="3" nowrap>#(..EscapeHTML(Audit.Description))#</td></tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Timestamp"))#</td>
		<td nowrap>#(..EscapeHTML(TimeStamp))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("UTCTimestamp"))#</td>
		<td nowrap>#(..EscapeHTML(UTCTimeStamp))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Event Source"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.EventSource))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Event Type"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.EventType))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Event"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.Event))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Username"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.Username))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Pid"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.Pid))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("JobId"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.JobId))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("JobNumber"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.JobNumber))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$Text("IP Address (from client)"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.ClientIPAddress))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$Text("IP Address (at server)"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.StartupClientIPAddress))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Executable"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.ClientExecutableName))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("System ID"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.SystemID))#</td>
		</tr>
		<tr class="OddRow">
		<td class="caption" nowrap>#($$$TextHTML("Index"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.AuditIndex))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Roles"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.Roles))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Authentication"))#</td>
		<td nowrap>#(..EscapeHTML($$AuthenticationLogicalToDisplay^%SYS.SECURITY(Audit.Authentication)))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Namespace"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.Namespace))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Routine"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.RoutineSpec))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("User Info"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.UserInfo))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("O/S Username"))#</td>
		<td nowrap>#(..EscapeHTML(Audit.OSUsername))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Status"))#</td>
		<td class="DetailValue"> #(..EscapeHTML($SYSTEM.Status.GetErrorText(Audit.Status)))# #(..SQLErrs(Audit.EventData))# </td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("Event Data"))#</td>
		<td class="DetailValue">#(..LoopValue(Audit.EventData))#</td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("JSON Data"))#</td>
		<td class="DetailValue"> #((..JSONValue(Audit.EventData)).%ToJSON())# </td>
		</tr>
		<tr>
		<td class="caption" nowrap>#($$$TextHTML("SQL Statement Index"))#</td>
		<td class="DetailValue">
		<a href="#(..Link(..LinkTarget(Audit.EventData)))#" target="_blank"> #(..LinkValue(Audit.EventData))# </a>
		</td>
		</tr>
		</table>>
	}
	Quit $$$OK
}

ClassMethod LoopValue(InputValue As %String) As %String
{
	Set cD = "@@@"
	Set InputValue = $P(InputValue," JSONData: "_cD, 1)
 	RETURN:InputValue="" "&nbsp;"
 	Set InputValue = $TR(..EscapeHTML(InputValue),$c(13))
 	Set OutputValue = $P(InputValue,$c(10),1)
 	Set Total = $L(InputValue,$c(10)) + 1
 	Set n = 2
 	While n '> Total {
 		Set OutputValue = OutputValue_"</br>"_$P(InputValue,$c(10),n)
 		Set n = n + 1
 	}
 	RETURN OutputValue
}

ClassMethod JSONValue(InputValue As %String) As %String
{
	set cD = "@@@"
	set statementtext = $P($P(InputValue," JSONData: "_cD, 1),$c(13,10)_"Parameter values:",1)
 	set InputValue = $P(InputValue," JSONData: "_cD, 2)
 	RETURN:InputValue="" ##class(%DynamicObject).%New()
	set DynObj = {}.%FromJSON(InputValue)
	set DynObj."StatementText" = $ZSTRIP(statementtext,"*",$c(9,10,13))
	if DynObj."%msg" = "" { do DynObj.%Remove("%msg") }
	if DynObj."ROWCOUNT" = "" { do DynObj.%Remove("ROWCOUNT") }
	if DynObj."ROWID" = "" { do DynObj.%Remove("ROWID") }
	do DynObj.%Remove("$namespace")
	do DynObj.%Remove("SQL Statement Index")
	RETURN DynObj
}

ClassMethod LinkValue(InputValue As %String) As %String
{
	set cD = "@@@"
	set InputValue = $P(InputValue," JSONData: "_cD, 2)
 	RETURN:InputValue="" ""
 	RETURN ({}.%FromJSON(InputValue))."SQL Statement Index"
}

ClassMethod LinkTarget(InputValue As %String) As %String
{
	set cD = "@@@"
	set InputValue = $P(InputValue," JSONData: "_cD, 2)
 	RETURN:InputValue="" ""
 	Set HashValue = ({}.%FromJSON(InputValue))."SQL Statement Index"
	Set NamespaceValue = ({}.%FromJSON(InputValue))."$namespace"
	if NamespaceValue = "%SYS" { set NamespaceValue = "%25SYS" }

	RETURN "/csp/sys/exp/_CSP.UI.Portal.Dialog.SQLStatementDetails.zen?&NAMESPACE="_NamespaceValue_"&SCHEMA=&STMTHASH="_HashValue_"&OpenInTab=1"
}

ClassMethod SQLErrs(InputValue As %String) As %String
{
	set cD = "@@@"
	set InputValue = $P(InputValue," JSONData: "_cD, 2)
	RETURN:InputValue="" ""
	set DynObj = {}.%FromJSON(InputValue)
	set SQLCODEstr = DynObj."SQLCODE"
	set %msgstr = DynObj."%msg"
	if ((SQLCODEstr<0) && (SQLCODEstr'=-100)) {
		RETURN $system.Status.GetErrorText($$$ERROR($$$SQLError,SQLCODEstr,%msgstr))
	}
	else { RETURN "" }
}

}
