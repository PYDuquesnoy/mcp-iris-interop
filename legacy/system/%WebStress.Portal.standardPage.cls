/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.standardPage Extends %ZEN.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// URL of home page (used in links).
Parameter HOMEPAGE = "%25CSP.Portal.Home.cls";

Parameter RESOURCE As STRING = "%Development";

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hmenu id="navMenu" width="100%">
<menu caption="Scripts" help="WebStress Scripts Menu" layout="vertical">
<menuItem caption="Record" link="%25WebStress.Portal.Record.cls"/>
<menuItem caption="Edit" link="%25WebStress.Portal.Script.cls"/>
</menu>
<menu caption="Tests" help="WebStress Tests Menu" layout="vertical">
<menuItem caption="Edit" link="%25WebStress.Portal.Tests.cls"/>
<menuItem caption="Run" link="%25WebStress.Portal.Run.cls"/>
</menu>
<menu caption="Machines" help="WebStress Machines Menu" layout="vertical">
<menuItem caption="Generators" link="%25WebStress.Portal.Generators.cls"/>
<menuItem caption="Web Servers" link="%25WebStress.Portal.WebServers.cls"/>
<menuItem caption="App Servers" link="%25WebStress.Portal.AppServers.cls"/>
</menu>
<menu caption="Tables" help="WebStress Tables Menu" layout="vertical">
<menuItem caption="No Results" link="%25WebStress.Portal.NoResults.cls"/>
<menuItem caption="No Delays" link="%25WebStress.Portal.NoDelays.cls"/>
</menu>
<menu caption="Info" help="WebStress Information Menu" layout="vertical">
<menuItem caption="Errors" link="%25WebStress.Portal.Errors.cls"/>
<menuItem caption="Run History" link="%25WebStress.Portal.RunHistory.cls"/>
<menuItem caption="Controller Info" link="%25WebStress.Portal.Controller.cls"/>
</menu>
</hmenu>
<vgroup width="100%" valign="top">
<pane paneName="detailPane" width="100%"/>
</vgroup>

</pane>
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("WebStress Portal")
}

}
