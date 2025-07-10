/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Various utility API methods used by the Publish and Subscribe messaging engine.
Class EnsLib.PubSub.Utils Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Add a PubSub domain to the list of domains
ClassMethod AddDomain(pName As %String, pDescription As %String = "") As %Status
{
	Set tSC = $$$OK
	Do {
		Set tDomain = ##class(DomainName).%New()
		Set tDomain.Name = pName
		Set tDomain.Description = pDescription
		Set tSC = tDomain.%Save()
		If $$$ISERR(tSC) Quit

	} While(0)
	Quit tSC
}

/// Add a subscriber to the list of subscribers
ClassMethod AddSubscriber(pDomain As %String = "", pName As %String, pTarget As %String = "", pAddress As %String = "") As %Status
{
	Set tSC = $$$OK
	Do {
		Set tSubscriber = ##class(Subscriber).%New()
		Set tSubscriber.Name = pName
		Set tSubscriber.Target = pTarget
		Set tSubscriber.Address = pAddress
		Set tSC = tSubscriber.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)
	Quit tSC
}

/// Add a new subscription to the list of subscriptions.
ClassMethod AddSubscription(pDomain As %String = "", pSubscriberName As %String, pTopic As %String) As %Status
{
	Set tSC = $$$OK
	Do {
		Set tSubscriber = ##class(Subscriber).FindSubscriber(pDomain,pSubscriberName)
		If '$IsObject(tSubscriber) {
			Quit
		}

		Set tSubscription = ##class(Subscription).%New()
		Set tSubscription.Subscriber = tSubscriber
		Set tSubscription.DomainName = tSubscriber.DomainName
		Set tSubscription.Topic = pTopic
			
		Set tSC = tSubscription.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)
	Quit tSC
}

/// Public API for finding a list of subscriber IDs for a given topic string.<br>
/// Returns an array of subscriber ID numbers with nodes containing number of matches.
ClassMethod FindSubscribers(pDomain As %String, pTopic As %String, Output pSubscribers As %String) As %Status
{
	Quit ##class(Subscription).FindSubscribers(pDomain, pTopic, .pSubscribers)
}

/// Delete all PubSub domains within this namespace.
/// This will also remove all subscribers and subscriptions for the domain.
/// If <var>pName</var> is not provided, all domains are deleted.
ClassMethod DeleteDomain(pName As %String = "") As %Status
{
	Set tSC = $$$OK
	Do {
		If (pName = "") {
			Set tSC = ##class(DomainName).%KillExtent()
			If $$$ISERR(tSC) Quit

		}
		Else {
			Set tSC = ##class(DomainName).%DeleteId(pName)
			If $$$ISERR(tSC) Quit
		}

		// kill all related subscribers
		Set tSC = ..DeleteSubscriber("",pName)
		If $$$ISERR(tSC) Quit

	} While(0)
	Quit tSC
}

/// Delete one or more subscribers within this namespace.
/// This will also remove any subscriptions associated with the subscribers.<br>
/// If <var>pSubscriberID</var> is not provided, all subscribers are deleted.
/// If <var>pDomain</var> is provided, only subscribers in that domain are deleted.
ClassMethod DeleteSubscriber(pSubscriberID As %String = "", pDomain As %String = "") As %Status
{
	Set tSC = $$$OK
	Do {
		If (pSubscriberID '= "") {
			// kill all subscriptions related to this subscriber
			&SQL(DELETE FROM Subscription WHERE Subscriber = :pSubscriberID)
			&SQL(DELETE FROM Subscriber WHERE %ID = :pSubscriberID)
		}
		Else { 
			If (pDomain = "") {
				// Kill all subscribers
				&SQL(DELETE FROM Subscription)
				&SQL(DELETE FROM Subscriber)
			}
			Else {
				// Kill all subscribers in given domain
				&SQL(DELETE FROM Subscription WHERE DomainName = :pDomain)
				&SQL(DELETE FROM Subscriber WHERE DomainName = :pDomain)
			}
		}
	} While(0)
	Quit tSC
}

/// Delete all subscriptions within this namespace.
/// If <var>pSubscriberID</var> is not provided, all subscriptions are deleted.
/// If <var>pDomain</var> is provided, only subscriptions in that domain are deleted.
ClassMethod DeleteSubscriptions(pSubscriberID As %String = "", pDomain As %String = "") As %Status
{
	Set tSC = $$$OK

	Do {
		If (pSubscriberID '= "") {
			// kill all subscriptions related to this subscriber
			&SQL(DELETE FROM Subscription WHERE Subscriber = :pSubscriberID)
		}
		Else { 
			If (pDomain = "") {
				// Kill all subscriptions
				&SQL(DELETE FROM Subscription)
			}
			Else {
				// Kill all subcriptions in given domain
				&SQL(DELETE FROM Subscription WHERE DomainName = :pDomain)
			}
		}
	} While(0)

	Quit tSC
}

/// Export PubSub information to an XML file.
ClassMethod Export(pFile As %String = "") As %Status
{
	Set tSC = $$$OK

	Do {
		If (pFile '= "") {
			Set io = $IO
			OPEN pFile:"WSN"
			USE pFile
		}
		
		// header
		Write "<?xml version=""1.0"" ?>",!
		Write "<PubSub>",!
		
		// domains
		&sql(DECLARE sqlDomain CURSOR FOR
			SELECT ID INTO :id FROM DomainName
		)
		&sql(OPEN sqlDomain)
		&sql(FETCH sqlDomain)
		While (SQLCODE = 0) {
			Set tDomain = ##class(DomainName).%OpenId(id)
			If $IsObject(tDomain) {
				Do tDomain.XMLExport()
			}
			Set tDomain = ""
			&sql(FETCH sqlDomain)
		}
		&sql(CLOSE sqlDomain)

		// subscribers
		&sql(DECLARE sqlSubscriber CURSOR FOR
			SELECT ID INTO :id FROM Subscriber
		)
		&sql(OPEN sqlSubscriber)
		&sql(FETCH sqlSubscriber)
		While (SQLCODE = 0) {
			Set tSubscriber = ##class(Subscriber).%OpenId(id)
			If $IsObject(tSubscriber) {
				Do tSubscriber.XMLExport()
			}
			Set tSubscriber = ""
			&sql(FETCH sqlSubscriber)
		}
		&sql(CLOSE sqlSubscriber)

		// subscriptions
		&sql(DECLARE sqlSubscription CURSOR FOR
			SELECT ID INTO :id FROM Subscription
		)
		&sql(OPEN sqlSubscription)
		&sql(FETCH sqlSubscription)
		While (SQLCODE = 0) {
			Set tSubscription = ##class(Subscription).%OpenId(id)
			If $IsObject(tSubscription) {
				Do tSubscription.XMLExport()
			}
			Set tSubscription = ""
			&sql(FETCH sqlSubscription)
		}
		&sql(CLOSE sqlSubscription)

		Write "</PubSub>",!
		
		If (pFile '= "") {
			Use io
			CLOSE pFile
		}		

	} While(0)

	Quit tSC
}

/// Import PubSub information from an XML file.
/// If <var>pDelete</var> is true, delete existing data first.
ClassMethod Import(pFile As %String = "", pDelete As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Do {
		// Create an instance of %XML.Reader
		Set tReader = ##class(%XML.Reader).%New()
	
		// Begin processing of the file
		Set tSC = tReader.OpenFile(pFile)
		If $$$ISERR(tSC) Quit
	
		If (pDelete) {
			// Delete existing data
			Set tSC = ..DeleteDomain()
			If $$$ISERR(tSC) Quit
		}

		// Associate a class name with the XML element name
		Do tReader.Correlate("Domain","EnsLib.PubSub.DomainName")
		Do tReader.Correlate("Subscriber","EnsLib.PubSub.Subscriber")
		Do tReader.Correlate("Subscription","EnsLib.PubSub.Subscription")
	    
		// Read objects from xml file
	    While (tReader.Next(.tObject,.tSC)) {
			Set tSC = tObject.%Save()
			If $$$ISERR(tSC) {
				Write !,$System.Status.DisplayError(tSC)
				Quit
			}
		}
		If $$$ISERR(tSC) Quit
	
	} While(0)

	Quit tSC
}

}
