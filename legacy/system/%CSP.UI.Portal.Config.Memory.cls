/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Memory Settings
Class %CSP.UI.Portal.Config.Memory Extends %CSP.UI.Portal.Config.AdvancedTable [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Memory Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Memory.zen";

Parameter HELPADDRESS = "Home,Configuration,Advanced Memory Settings";

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Memory" ];

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Advanced Memory Settings")
}

}
