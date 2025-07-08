/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Startup Settings
Class %CSP.UI.Portal.Config.Startup Extends %CSP.UI.Portal.Config.AdvancedTable [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Startup Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Startup.zen";

Parameter HELPADDRESS = "Home,Configuration,Startup Settings";

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Startup" ];

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Startup Settings")
}

}
