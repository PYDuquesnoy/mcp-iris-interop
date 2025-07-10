/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a template page used for pages within the 'Interoperate' section of the Portal
Class EnsPortal.EDI.Template Extends EnsPortal.Template.standardPage [ Abstract, System = 4 ]
{

/// User must have READ permissions on the %Ens_EDISchema resource to view this page and subclasses.
Parameter RESOURCE = "%Ens_EDISchema:READ";

/// User must have WRITE permissions on the %Ens_EDISchema resource to make changes on this page or in any subclasses.
Parameter EDITRESOURCE = "%Ens_EDISchema:WRITE";

Parameter CSSINCLUDES = "ensemble/Ensemble_EDI.css";

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2)=$LB(..%OnGetPageName(),"#")
	Quit $$$OK
}

ClassMethod DrawError(errorDetail As %String) As %Status
{
  Set errorTxt = $$$TextHTML("Definition does not exist!")
  &html<<div class="errorTxt"><span class="errorDetail">#($zconvert(errorDetail,"O","HTML"))#</span> #(errorTxt)#</div>>
  Quit $$$OK
}

}
