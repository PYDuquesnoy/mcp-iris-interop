/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PubSub Domain Edit.
Class EnsPortal.PubSub.DomainEdit Extends (%CSP.Util.AutoPage, EnsPortal.PubSub.Utils) [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter STYLESHEET = "intersystems.css";

Parameter SECURITYRESOURCE = "%Ens_PubSub:WRITE";

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Set tPane = ##class(%CSP.Util.FormPane).%New()
	Set tPane.Text = $$$Text("Create a new PubSub Domain name using the form below:")
	Set tPane.Align ="left"

	// commands
	Do ..AddBasicCommands(tPane)

	Set tPane.SubmitPage = "EnsPortal.PubSub.Domains.cls"
	Set tPane.FormClass = "EnsLib.PubSub.DomainName"

	// Create instance of object used for form
	Merge tID = pInstance.IDValues
	Set tPane.FormObject = ##class(EnsLib.PubSub.DomainName).CreateInstance(.tID)

	Quit tPane
}

ClassMethod GetTitlePane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Quit $$$NULLOREF
}

ClassMethod OnPage() As %Status
{
	Do ..OnPageCSPROOT()
	Quit $$$OK
}

ClassMethod OnPageCSPROOT() As %Boolean
{
	Write "<!--",!
	Write "PubSub: Domain name editor",!
	Write "-->"
	Write !,!
	Do ..DrawHTML()
	Quit 1
}

}
