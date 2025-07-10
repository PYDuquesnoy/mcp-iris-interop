/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.PubSub.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

ClassMethod AddBasicCommands(pPane As %CSP.Util.Pane = "") As %Status
{
	If $IsObject(pPane) {
		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Domains"
		Set tAction.Caption = $$$Text("Show Domains")
		Do pPane.Commands.Insert(tAction)

		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Subscribers"
		Set tAction.Caption = $$$Text("Show Subscribers")
		Do pPane.Commands.Insert(tAction)

		Set tAction = ##class(%CSP.Util.Action).%New()
		Set tAction.HREF = "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=EnsPortal.PubSub.Subscriptions"
		Set tAction.Caption = $$$Text("Show Subscriptions")
		Do pPane.Commands.Insert(tAction)
	}
	Quit $$$OK
}

ClassMethod CanEdit() As %Boolean [ CodeMode = expression ]
{
$system.Security.Check("%Ens_PubSub","WRITE")
}

}
