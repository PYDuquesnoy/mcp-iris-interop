/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Pane for Databases 
Class %CSP.UI.System.JournalPane Extends %CSP.Util.TablePane [ System = 4 ]
{

/// This method creates the %ResultSet object
/// that is used for the table pane.<br>
/// A subclass can override this to customize the 
/// table displayed by this pane.<br>
/// <var>pID</var> is array of page variables...
Method CreateResultSet(ByRef pID As %String, ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	
	/// default version: use associated class query
	If (..SQLQuery '= "") {
		Set pRS = ##class(%ResultSet).%New()
		Set tSC = pRS.Prepare(..SQLQuery)
	}
	Else {
		Set pRS = ##class(%ResultSet).%New(..Query)
		If ('pRS.QueryIsValid()) {
			Quit $$$ERROR($$$GeneralError,"Invalid Query: " _ ..Query)
		}
		if ..Query = "%SYS.Journal.File:ByTimeReverseOrder" {
			Set pID(1) = ""
		}
		if ..Query = "%SYS.Journal.File:MirrorByTimeReverseOrder" {
			Set pID(2) = $G(%request.Data("MIRRORNAME",1))
		}
	}

	Quit tSC
}

/// Show Last Update box
Method DrawLastUpdate()
{
	// Get text line for page; subclass can customize this behavior
	Set tText = ..GetDescriptiveText()

	Set msgUpdate = $$$Text("Last update: ")
	Set msgAuto = $$$Text("Auto")
	Set hlpUpdate = $$$Text("Click here to refresh this table.")
	Set hlpTime = $$$Text("Time when the contents of this page were last refreshed.")
	Set hlpAuto = $$$Text("If checked, then contents of this page will automatically refresh.")

	// show descriptive text
	&html<<table border="0" cols="2" cellpadding="3" width="80%"><tr>
		<td align="left" class="Text1">#($ZCVT(tText,"O","HTML"))#</td>
		<td align="left" class="Text" nowrap width="30%" style='cursor:pointer;' valign="bottom">>
		
	If ..ShowLastUpdate {
		&html<<div align="left" width="100%">
		<span style="vertical-align: middle;">
		<a class="LastUpdate" title="#($ZCVT(hlpUpdate,"O","HTML"))#" onclick="refreshTable();">&#032;#($ZCVT(msgUpdate,"O","HTML"))#
		<span id="lastupdate" title="#($ZCVT(hlpTime,"O","HTML"))#" style="font-weight: bold;">#($ZDT($ZU(188),3,,3))#</span></a>
		>
		If ..enableAutoRefresh {
			&html<
				&#032;
				<input id="cbAuto" title="#($ZCVT(hlpAuto,"O","HTML"))#" style="vertical-align: middle; font-size: 0.5em;" type="checkbox" #($Case(..AutoRefresh,1:"checked",:""))# onclick="setAutoRefresh(this.checked);">
				<span title="#($ZCVT(hlpAuto,"O","HTML"))#" onclick="cspToggleCheckbox('cbAuto');">#($ZCVT(msgAuto,"O","HTML"))#&#032;</span>
				>
		}
		&html<
		</span>
		</div>>
	}

	&html<</td></tr>>
		Do ..DrawChoices()
	&html<</table>>
}

/// Draw Mirrored choices for primary and backup failover members, for this pane below the tTitle and above the table.
Method DrawChoices()
{
	If $System.Mirror.GetInfo() [",DEFINED," {
		If $SYSTEM.Mirror.IsMember() {
			Set link1 = $$$TextHTML("All Journal Files")
			Set linkm = $$$TextHTML("Mirror Journal Files Of '")
			Set EndQ = $$$TextHTML("'")
			Set url1 = ##class(%CSP.Page).Link("UtilSysJournals.csp")
			&html<
			<tr><td colspan="2"><a href="#(url1)#">#(link1)#</a>&nbsp;&nbsp;>
			Set rs=##class(%ResultSet).%New("Config.Mirrors:List")
			Do rs.Execute()
			While (rs.Next()) {
				Set link2 = linkm_$ZCVT(rs.Data("Name"),"O","HTML")_EndQ
				Set url2 = ##class(%CSP.Page).Link("UtilSysJournalsMirror.csp?MIRRORNAME="_rs.Data("Name"))
				&html<<a href="#(url2)#">#(link2)#</a>&nbsp;&nbsp;>
			}
			&html<</td></tr>
			>
		} 
	}
}

}
