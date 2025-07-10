/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PubSub Subscription Edit.
Class EnsPortal.PubSub.SubscriptionEdit Extends (%CSP.Util.AutoPage, EnsPortal.PubSub.Utils) [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter STYLESHEET = "intersystems.css";

Parameter SECURITYRESOURCE = "%Ens_PubSub:WRITE";

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Set tPane = ##class(%CSP.Util.FormPane).%New()
	Set tPane.Text = $$$Text("Edit a subscription definition using the form below. A subscription associates a specific topic string with a specific subscriber. A topic string may contain one or more subtopics (A.B.C) and may contain * as a wild card (A.*). When an incoming message has a topic that matches the topic string for a subscription, the message is routed to the associated subscriber.")
	Set tPane.Align ="left"

	// commands
	Do ..AddBasicCommands(tPane)

	Set tPane.SubmitPage = "EnsPortal.PubSub.Subscriptions.cls"
	Set tPane.FormClass = "EnsLib.PubSub.SubscriptionForm"

	// Create instance of object used for form
	Merge tID = pInstance.IDValues
	Set tPane.FormObject = ##class(EnsLib.PubSub.SubscriptionForm).CreateInstance(.tID)

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
	Write "PubSub: Subscription editor",!
	Write "-->"
	Write !,!
	Do ..DrawHTML()
	Quit 1
}

}
