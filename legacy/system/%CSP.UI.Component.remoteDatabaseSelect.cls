/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %CSP.UI.Component.remoteDatabaseSelect <br>
/// For use on the SMP Remote Database dialog. <br>
/// Extends dataCombo, adding a callback that disables the component <br>
/// and displays a message if the query resturned no results <br>
/// (i.e. a connection to the remote server could not be established.)
Class %CSP.UI.Component.remoteDatabaseSelect Extends %ZEN.Component.dataCombo [ System = 3 ]
{

Method LoadDropDownContents(searchParm As %String, cached As %Boolean = 0) [ Internal, ZenMethod ]
{
	Do ##super(searchParm,cached)
	Do ..DisableIfNotConnected()
}

Method DisableIfNotConnected() [ Internal ]
{
	Set RemoteServer = $$$ZENVAL(..parameters.GetAt(1).value)
	Set State = ##class(SYS.ECP).GetServerConnState(RemoteServer)
	If (State '= 5) {
		&js<
			zenPage.showServerWarning(0);
			document.getElementById('zenModalDiv').style.display = 'none';
		>
	}
}

}
