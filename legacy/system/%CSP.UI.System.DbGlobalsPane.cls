/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane handles Executing query with only one parameter.
Class %CSP.UI.System.DbGlobalsPane Extends %CSP.Util.TablePane [ System = 4 ]
{

Parameter HIDEFILTERWHENEMPTY = 0;

/// This method performs the actual execution of the ResultSet
/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	
	Set tMask = $G(pID(3),"*")
	Set:tMask="1" tMask="*"
	Set tSC = pRS.Execute($G(pID(1)),,tMask,+$G(pID(4)))

Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This callback draws the search mask within the filter box.
Method OnDrawFilter(pInstance As %CSP.Util.PageInstance) As %Status
{
	Set tSC = $$$OK

	Do {
		Merge tID = pInstance.IDValues

		Set cmdGlobal = $$$Text("Globals")
		Set cmdSearch = $ZCVT($$$Text("Go"),"O","HTML")
		Set cmdSysItems = $ZCVT($$$Text("System"),"O","HTML")
		Set hlpSysItems = $ZCVT($$$Text("Include system items in search."),"O","HTML")
		Set hlpSearch = $ZCVT($$$Text("Reload page using current search pattern."),"O","HTML")
		Set hlpMask = $ZCVT($$$Text("Enter a search pattern. This can include * as a wildcard."),"O","HTML")
		Set tMask = $G(tID(3),"*") Set:tMask="1" tMask="*"
		Set tSystem = +$G(tID(4))
		Set ID1 = $G(%request.Data("$ID1",1))
		Set ID2 = $G(%request.Data("$ID2",1))
		&html<<input type="hidden" name="$ID1" id="$ID1" value="#($ZCVT(ID1,"O","HTML"))#">>
		&html<<input type="hidden" name="$ID2" id="$ID2" value="#($ZCVT(ID2,"O","HTML"))#">>
		&html<<span title="#(hlpMask)#" class="FilterLabel">#(cmdGlobal)#:</span>
			<input type="text" size="12" id="searchMask" style="color:blue;" value="#($ZCVT(tMask,"O","HTML"))#"><input type="button" style="font-size:0.8em;" title="#(hlpSearch)#" value="#(cmdSearch)#" onclick="doSearch();">
			&nbsp;<input type="checkbox" id="showSystemItems" #($Case(tSystem,1:"checked",:""))#><span title="#(hlpSysItems)#" class="FilterLabel" onclick="toggleSysItems();">#(cmdSysItems)#</span>
			>
		
		&html<
			&nbsp;
<script language="javascript">
// execute search
function doSearch()
{
	var ID1 = self.document.getElementById("$ID1").value;
	var ID2 = self.document.getElementById("$ID2").value;
	var maskctrl = self.document.getElementById("searchMask");
	var sysctrl = self.document.getElementById("showSystemItems");
	if (maskctrl) {
		var mask = maskctrl.value;
		var sys = '';
		if (sysctrl && sysctrl.checked) {
			sys = '&$ID4=1';
		}
		self.document.location = '#(%request.PageName)#?$ID1=' + cspEncodeUTF8(ID1) + '&$ID2=' + cspEncodeUTF8(ID2) + '&$NAMESPACE=' + escape('#($ZCVT($G(%request.Data("$NAMESPACE",1)),"O","JS"))#') + '&$ID3=' + cspEncodeUTF8(mask) + sys;
	}
}

function toggleSysItems()
{
	var sysctrl = self.document.getElementById("showSystemItems");
	if (sysctrl) {
		sysctrl.checked = !sysctrl.checked;
	}
}
</script>
			>
	
	} While (0)

	Quit tSC
}

}
