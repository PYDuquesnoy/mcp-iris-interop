/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.SVG.templatePage Extends %ZEN.SVGComponent.svgPage [ Abstract, System = 4 ]
{

/// Ensure that user has sufficient privileges to view the application in the current namespace.
/// Also avoid writing out the session cookie if we are in a Studio session.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If $get(%request.Data("STUDIO",1)) Set %session.Data("Ensemble","StudioSession",$namespace) = 1
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	
	Set tReturn = ##super()
	If 'tReturn Quit tReturn
	
	If '##class(EnsPortal.Application).CheckPrivileges() {
		Set %response.Status = "403 Forbidden"
		Set %response.ContentType = "text/html"
		Quit 0
	}
	Quit 1
}

}
