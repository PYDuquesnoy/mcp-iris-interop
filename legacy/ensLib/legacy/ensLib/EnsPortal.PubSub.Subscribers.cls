/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PubSub Subscribers.
Class EnsPortal.PubSub.Subscribers Extends (%CSP.Util.AutoPage, EnsPortal.PubSub.Utils) [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter STYLESHEET = "intersystems.css";

Parameter SECURITYRESOURCE = "%Ens_PubSub:READ";

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	Set tPane = ##class(%CSP.Util.TablePane).%New()
	Set tPane.Text = $$$Text("The following PubSub Subscribers are currently defined.")

	// commands
	Do ..AddBasicCommands(tPane)

	Set tCanEdit = ..CanEdit()
	If tCanEdit {
		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.SubscriberEdit"
		Set tAction.Caption = $$$Text("Create New Subscriber")
		Do tPane.Commands.Insert(tAction)
	}

	Set tPane.Query = "EnsLib.PubSub.Subscriber:Enumerate"
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
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.SubscriberEdit"
		Set tAction.Caption = $$$Text("Edit")
		Set tAction.Popup = $$$Text("Edit this Subscriber definition.")
		Set tAction.IDExprList = "{ID}"
		Do tPane.Actions.SetAt(tAction, "$A")
	}

	Set tAction = ##class(%CSP.Util.Action).%New()
	Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Subscriptions"
	Set tAction.Caption = $$$Text("Subscriptions")
	Set tAction.Popup = $$$Text("View subscriptions for this subscriber.")
	Set tAction.IDExprList = "{ID}"
	Do tPane.Actions.SetAt(tAction, "$B")

	If tCanEdit {
		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Subscribers&$AUTOFORM_DELETE=1&$CLASS=EnsLib.PubSub.SubscriberForm"
		Set tAction.Caption = $$$Text("Delete")
		Set tAction.Popup = $$$Text("Delete this Subscriber definition.")
		Set tAction.Confirm = $$$Text("Do you really wish to delete this Subscriber definition?")
		Set tAction.IDExprList = "{ID}"
		Do tPane.Actions.SetAt(tAction, "$C")
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
	Write "PubSub: Subscribers list",!
	Write "-->"
	Write !,!
	Do ..DrawHTML()
	Quit 1
}

}
