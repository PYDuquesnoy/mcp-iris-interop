/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PubSub Subscriptions.
Class EnsPortal.PubSub.Subscriptions Extends (%CSP.Util.AutoPage, EnsPortal.PubSub.Utils) [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter STYLESHEET = "intersystems.css";

Parameter SECURITYRESOURCE = "%Ens_PubSub:READ";

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Set tPane = ##class(%CSP.Util.TablePane).%New()
	Set tPane.Text = $$$Text("The following PubSub Subscriptions are currently defined. A subscription associates a Subscriber with a given topic.")

	// commands
	Do ..AddBasicCommands(tPane)

	Set tCanEdit = ..CanEdit()
	If tCanEdit {
		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.SubscriptionEdit"
		Set tAction.Caption = $$$Text("Create New Subscription")
		Do tPane.Commands.Insert(tAction)
	}

	Set tPane.Query = "EnsLib.PubSub.Subscription:Enumerate"
	Set tPane.HiddenColumns = "ID"
	Set tPane.Sortable = 1
	Set tPane.ShowFilter = 1
	Set tPane.ShowZebra = 1
	Set tPane.AutoRefresh = 0
	Set tPane.ShowRowNumbers = 1
	Set tPane.ShowCheckboxes = 0
	Set tPane.MaxResults = 10000
	Set tPane.ItemsPerPage = 20
	Set tPane.ShowLastUpdate = 1
	Set tPane.cellpadding = 5
	Set tPane.border = 1

	// actions
	If tCanEdit {
		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.SubscriptionEdit"
		Set tAction.Caption = $$$Text("Edit")
		Set tAction.Popup = $$$Text("Edit this Subscription definition.")
		Set tAction.IDExprList = "{ID}"
		Do tPane.Actions.SetAt(tAction, "$A")

		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Subscriptions&$AUTOFORM_DELETE=1&$CLASS=EnsLib.PubSub.SubscriptionForm"
		Set tAction.Caption = $$$Text("Delete")
		Set tAction.Popup = $$$Text("Delete this Subscription definition.")
		Set tAction.Confirm = $$$Text("Do you really wish to delete this Subscription definition?")
		Set tAction.IDExprList = "{ID}"
		Do tPane.Actions.SetAt(tAction, "$B")
	}

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
	Write "PubSub: Subscription list",!
	Write "-->"
	Write !,!
	Do ..DrawHTML()
	Quit 1
}

}
