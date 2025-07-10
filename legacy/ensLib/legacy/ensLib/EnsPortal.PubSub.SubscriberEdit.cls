/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PubSub Domain Edit.
Class EnsPortal.PubSub.SubscriberEdit Extends (%CSP.Util.AutoPage, EnsPortal.PubSub.Utils) [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter STYLESHEET = "intersystems.css";

Parameter SECURITYRESOURCE = "%Ens_PubSub:WRITE";

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Set tPane = ##class(%CSP.Util.FormPane).%New()
	Set tPane.Text = $$$Text("Edit the Subscriber definition using the form below. A subscriber can subscribe to one or more topics; when a message is published that matches a subscriber's topic it will be sent to the Target operation defined for the subscriber. Address is an additional piece of information that can be used by the Target operation to send the request.")
	Set tPane.Align ="left"

	// commands
	Do ..AddBasicCommands(tPane)

	Set tPane.SubmitPage = "EnsPortal.PubSub.Subscribers.cls"
	Set tPane.FormClass = "EnsLib.PubSub.SubscriberForm"

	// Create instance of object used for form
	Merge tID = pInstance.IDValues
	Set tPane.FormObject = ##class(EnsLib.PubSub.SubscriberForm).CreateInstance(.tID)

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
	Write "PubSub: Subscriber editor",!
	Write "-->"
	Write !,!
	Do ..DrawHTML()
	Quit 1
}

}
