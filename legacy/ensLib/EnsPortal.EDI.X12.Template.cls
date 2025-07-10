/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.EDI.X12.Template Extends EnsPortal.EDI.Template [ Abstract, System = 4 ]
{

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2) = $LB($$$Text("X12 Schemas","Ensemble"),"EnsPortal.EDI.X12.SchemaMain.zen") 
	Set pLink(3) = $LB(..%OnGetPageName(),"#")
	Quit $$$OK
}

}
