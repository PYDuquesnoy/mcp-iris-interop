/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Manage Locks 
Class %CSP.UI.Portal.Locks Extends %CSP.UI.Portal.LocksView [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Locks.zen";

Parameter HELPADDRESS = "Home,Locks";

/// Displayed name of this page.
Parameter PAGENAME = "Manage Locks";

/// Store translated targetCol linkCaption for <condition>
Property colProcess As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove_all_locks_for_process")} ];

Property colRemoteClient As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove_all_locks_from_remote_client")} ];

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	##; Add columns and conditions specific to Manage Locks
	Set tbl = %page.%GetComponentById("table")
	Set col = ##class(%ZEN.Auxiliary.column).%New()
	Set col.link="javascript:zenPage.doRemove('#(%query.DeleteID)#',0,'#(%query.RemoteOwner)#');"
	Set col.linkCaption=$$$Text("Remove")
	Set col.linkConfirm=$$$Text("Are you sure you want to delete this lock?")
	Do tbl.columns.Insert(col)
	Do %page.%AddComponent(col)
	Set col = ##class(%ZEN.Auxiliary.column).%New()
	Set col.link="javascript:zenPage.doRemove('#(%query.PidInternal)#',1,'#(%query.RemoteOwner)#');"
	Set col.linkCaption=..colProcess
	Set col.linkConfirm=$$$Text("Are you sure you want to delete all locks for this process?")
	Do tbl.columns.Insert(col)
	Do %page.%AddComponent(col)
	Set col = ##class(%ZEN.Auxiliary.column).%New()
	Set col.link="javascript:zenPage.doRemoveRemote('#(%query.PidInternal)#',1,'#(%query.RemoteOwner)#');"
	Set col.linkCaption=..colRemoteClient
	Set col.linkConfirm=$$$Text("Are you sure you want to delete all locks from remote client '%1'?")
	Do tbl.columns.Insert(col)
	Do %page.%AddComponent(col)
	Set cond = ##class(%ZEN.Auxiliary.condition).%New()
	Set cond.cellStyle="disabled"
	Set cond.colName="RemoteOwner"
	Set cond.targetCol=..colRemoteClient
	Set cond.value=0
	Do tbl.conditions.Insert(cond)
	Do %page.%AddComponent(cond)
	Set cond = ##class(%ZEN.Auxiliary.condition).%New()
	Set cond.cellStyle="disabled"
	Set cond.colName="RemoteOwner"
	Set cond.targetCol=..colProcess
	Set cond.value=1
	Do tbl.conditions.Insert(cond)
	Do %page.%AddComponent(cond)
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String [ CodeMode = expression ]
{
$$$Text(..#PAGENAME)
}

/// To remove all remote add "C" as preface.
ClientMethod doRemoveRemote(DeleteID, RemoveAll, RemoteOwner) [ Language = javascript ]
{
	this.doRemove("C"+DeleteID, RemoveAll, RemoteOwner);
}

/// Remove a lock. If "RemoveAll" is 1 then all locks for that process is removed.
/// If RemoveAll is 0, then DeleteID is the lock reference.
/// If RemoveAll is 1, then DeleteID is the Pid/Client or Owner.
ClientMethod doRemove(DeleteID, RemoveAll, RemoteOwner) [ Language = javascript ]
{
	if (DeleteID == "") {
		return;
	} else {
		// if it is a local process, then check if the lock is in open transaction and confirm with user if it is.
		if (RemoteOwner == false) {
			var inTrans = this.InTransaction(DeleteID);
			if (inTrans != 1) {
				if (!confirm(inTrans)) return;
			}
		}
		var result = this.RemoveLocks(DeleteID, RemoveAll);
		if (result.ok == 1) {
			if (result.Message != "") {
				this.showMsg(result.Message,0);
			} else {
				var table = zen("table");
				table.executeQuery();
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
		}
	}
}

/// This method is called to check whether a local lock is currently in an option transaction. 
ClassMethod InTransaction(DeleteID) As %String [ ZenMethod ]
{
	If $zu(61,19,DeleteID) = 0 Quit 1
	Quit $$$TextJS("This lock is currently in an open transaction. Are you sure you want to delete it?")
}

/// Remove locks from server. If RemoveAllLocksForProcess, then DeleteID is PID. OW DeleteID contains three pieces lock reference delimited by comma.
ClassMethod RemoveLocks(DeleteID, RemoveAllLocksForProcess) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""
	Set LocksNotRemoved = ""
	If RemoveAllLocksForProcess {
		Set sta = ##class(SYS.Lock).DeleteAllLocks(DeleteID)
		If $$$ISERR(sta) Set tProxy.ok = 0,tProxy.ErrorMessage = $$$FormatText($$$Text("Unable to remove locks for process %1."),DeleteID)
	} Else {
		Set sta = ##class(SYS.Lock).DeleteOneLock(DeleteID,"",1)
		If $$$ISERR(sta) Set tProxy.ok = 0,tProxy.ErrorMessage = $$$FormatText($$$Text("Unable to remove lock. Lock reference: %1, error=%2."),DeleteID,$SYSTEM.Status.GetErrorText(sta))		
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ok = 0
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

}
