/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Compatibility Settings
Class %CSP.UI.Portal.Config.Compatibility Extends %CSP.UI.Portal.Config.AdvancedTable [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Compatibility Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Compatibility.zen";

Parameter HELPADDRESS = "Home,Configuration,Compatibility Settings";

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Miscellaneous" ];

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Compatibility Settings")
}

}
