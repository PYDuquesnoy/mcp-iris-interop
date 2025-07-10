/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Form object used to create a new subscriber.
Class EnsLib.PubSub.SubscriberForm Extends (%RegisteredObject, %CSP.Util.AutoForm) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Property DomainName As %CSP.Util.Choice(CAPTIONCOLUMN = "Name", QUERYCLASS = "EnsLib.PubSub.DomainName", QUERYNAME = "Enumerate", VALUECOLUMN = "Name");

Property Name As %String(MAXLEN = 128);

Property Target As %String(MAXLEN = 128);

Property Address As %String(MAXLEN = 128);

ClassMethod CreateInstance(ByRef pID As %String) As SubscriberForm
{
	Set tObj = ..%New()
	
	// see if there is a subscriber object
	Set tSubID = $G(pID(1))
	Set tSubscriber = ##class(Subscriber).%OpenId(tSubID)
	If ($IsObject(tSubscriber)) {
		Set tObj.DomainName = tSubscriber.DomainNameGetObjectId()
		Set tObj.Name = tSubscriber.Name
		Set tObj.Target = tSubscriber.Target
		Set tObj.Address = tSubscriber.Address
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
			// delete this subscriber (and its subscriptions)
			Set id = $G(pID(1))
			Set tSC = ##class(Utils).DeleteSubscriber(id)
			Quit
		}
		
		If (pSubmit = "$AUTOFORM_SAVE") {

			// test for domain name
			Set tDomain = ""
			If (..DomainName '= "") {
				Set tDomain = ##class(DomainName).%OpenId(..DomainName)
				If ('$IsObject(tDomain)) {
					Quit
				}
			}
	
			Set tSubID = $G(pID(1))
			Set tSubscriber = ##class(Subscriber).%OpenId(tSubID)
			If ('$IsObject(tSubscriber)) {
				// new
				Set tSubscriber = ##class(Subscriber).%New()
			}
			
			Set tSubscriber.Name = ..Name
			Set tSubscriber.DomainName = tDomain
			Set tSubscriber.Target = ..Target
			Set tSubscriber.Address = ..Address
	
			Set tSC = tSubscriber.%Save()
			If $$$ISERR(tSC) Quit
			
			// pass new id back to page
			Set %response.Context("$ID1") = tSubscriber.%Id()
		}
	} While (0)

	Quit tSC
}

}
