/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Form object used to create a new subscription.
Class EnsLib.PubSub.SubscriptionForm Extends (%RegisteredObject, %CSP.Util.AutoForm) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Property Subscriber As %CSP.Util.Choice(CAPTION = "Domain / Subscriber", CAPTIONCOLUMN = "Name", QUERYCLASS = "EnsLib.PubSub.Subscriber", QUERYNAME = "SubscriberList", VALUECOLUMN = "ID");

Property Topic As %String(MAXLEN = 128);

ClassMethod CreateInstance(ByRef pID As %String) As SubscriptionForm
{
	Set tObj = ..%New()
	
	// see if there is a subscription object
	Set tSubID = $G(pID(1))
	Set tSubscription = ##class(Subscription).%OpenId(tSubID)
	If ($IsObject(tSubscription)) {
		Set tObj.Topic = tSubscription.Topic
		Set tObj.Subscriber = tSubscription.SubscriberGetObjectId()
	}

	Quit tObj
}

Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
	Set tSC = $$$OK

	Do {
		If ((pSubmit = "$AUTOFORM_DELETE") || (pSubmit = "$AUTOFORM_SAVE")) && '$system.Security.Check("%Ens_PubSub","WRITE") {
			Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
			Quit
		}
		If (pSubmit = "$AUTOFORM_DELETE") {
			Set id = $G(pID(1))
			&SQL(DELETE FROM Subscription WHERE %ID = :id)
			Quit
		}

		If (pSubmit = "$AUTOFORM_SAVE") {

			// save the subscription
			// test for valid subscriber:
			Set tSubscriber = ##class(Subscriber).%OpenId(..Subscriber)
			If ('$IsObject(tSubscriber)) {
				Quit
			}
	
			// Subscription domain matches subscriber domain
			Set tDomain = tSubscriber.DomainName
	
			Set tSubID = $G(pID(1))
			Set tSubscription = ##class(Subscription).%OpenId(tSubID)
			If ('$IsObject(tSubscription)) {
				// new
				Set tSubscription = ##class(Subscription).%New()
			}
			
			Set tSubscription.Subscriber = tSubscriber
			Set tSubscription.DomainName = tDomain
			Set tSubscription.Topic = ..Topic
			
			Set tSC = tSubscription.%Save()
			If $$$ISERR(tSC) Quit
			
			// pass new id back to page
			Set %response.Context("$ID1") = tSubscription.%Id()
		}
	} While (0)

	Quit tSC
}

}
