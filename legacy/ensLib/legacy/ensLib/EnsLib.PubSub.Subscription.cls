/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The class holds the list of subscriptions for a Publish / Subscribe table.
/// Topics are strings of the form A.B.C where A, B, or C can be up
/// to 50 characters; Any of A, B, or C, can be "*" which indicates a
/// wild card match.
Class EnsLib.PubSub.Subscription Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLIGNORENULL = 1;

/// Maximum length of subtopics
Parameter SUBTOPICLEN = 50;

/// Location of topic index
Parameter TOPICINDEX = "^EnsLib.PubSub.SubscriptionI";

/// Domain value used to keep this subscription list separate from others.
Property DomainName As DomainName(XMLNAME = "Domain", XMLPROJECTION = "ATTRIBUTE", XMLREFERENCE = "ID");

/// Link to subscriber name (used for Export).
Property SubscriberName As %String(XMLNAME = "Subscriber", XMLPROJECTION = "ATTRIBUTE") [ Transient ];

/// Topic that this subscription is based upon.<br>
/// This is a string containing a series of subtopics of the form A.B.C.;
/// Any subtopic may be "*" for a wild card match.
Property Topic As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Used to remember old values when modifying a subscription.
Property OldValues As %String(MAXLEN = 1000, XMLPROJECTION = "NONE") [ MultiDimensional, Transient ];

/// Subscriber
Relationship Subscriber As Subscriber(XMLPROJECTION = "NONE") [ Cardinality = one, Inverse = Subscriptions, Required ];

/// Find a list of subscribers for a given topic string.<br>
/// Look directly into index for the answer<br>
/// Returns an array of subscriber ID numbers with nodes containing number of matches.
ClassMethod FindSubscribers(pDomain As %String, pTopic As %String, Output pSubscribers As %String) As %Status
{
	Set tSC = $$$OK

	Kill pSubscribers

	// collate domain
	Set tDomain = " " _ $ZCVT(pDomain,"U")

	// split topic into collated sub topics
	Set tLevel = $L(pTopic,".")
	For i = 1:1:tLevel {
		Set input(i) = " "_$ZCVT($E($P(pTopic,".",i),1,..#SUBTOPICLEN),"U")
	}

	// now find every permutation of wildcards: A.B, A.*, *.B, *.*
	// and construct index reference
	// this has to include shorter levels with trailing * as well:
	// i.e.,  "A.B.C" has to search for "*", "A.*", etc.
	Set tStartGLVN = ..#TOPICINDEX_"(""TopicIndex"",""" _ tDomain _ """)"

	For tSubLevel = 1:1:tLevel {
		Set tFinal = (tSubLevel = tLevel)
		Kill v
		For i = 1:1:tSubLevel {
			Set v(i) = "*"
		}
		Set tPerms = 2**tSubLevel

		For p = 1:1:tPerms {
			Set n = tSubLevel
			Set done = 0
			
			#; find next permutation
			While ('done) {
				Set v(n) = $S(v(n)="*":input(n),1:"*")
				If (v(n)="*" && (n > 1)) {
					Set n = n - 1
				}
				Else {
					Set done = 1
				}
			}
	
			#; for sub levels, we are only interested in matching trailing *
			If (tFinal || (v(tSubLevel)="*")) {
				#; build GLVN
				Set tGLVN = tStartGLVN
				For n = 1:1:tSubLevel {
					Set tSubTopic = $S(v(n)="*":" ",1:v(n))
					Set tGLVN = $Name(@tGLVN@(tSubTopic))
				}
				Do SearchLoop(tGLVN)
			}
		}
	}

	
	Quit tSC

SearchLoop(tGLVN)
	#; inline search code:
	#; tGLVN is index node to test
	If ($D(@tGLVN)) {
		#; find subscriber id; make sure number of subscripts matches
		Set id = $O(@tGLVN@(""))
		While (id '= "") {
			Set id2 = $O(@tGLVN@(id,"")) // 1st subscription id
			If ($D(@tGLVN@(id,id2)) = 1) {
				Set idcount = $I(pSubscribers(id))
			}
			Set id = $O(@tGLVN@(id))
		}
	}
	Quit
}

/// Provide a list of subscriptions.
Query Enumerate() As %SQLQuery(CONTAINID = 1)
{
	SELECT %ID,DomainName,Topic,Subscriber->Name As Subscriber
	FROM Subscription
 	ORDER BY DomainName,Topic
}

/// This callback maintains the special topic index 
Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	// maintain special index: TOPICINDEX
	// ^EnsLib.PubSub.SubscriptionI("TopicIndex",DOMAIN,LEVEL,ST1,ST2,...,SUBSCRIBERID)
	Set tID = ..%Id()

	If ('insert) {
		Do ..ClearIndexEntry(..OldValues("DomainName"), ..OldValues("Topic"), ..OldValues("Subscriber"), tID)
	}

	// set new index values
	Set tDomain = " " _ $ZCVT(i%DomainName,"U")
	Set tLevel = $L(..Topic,".")
	Set tGLVN = ..#TOPICINDEX_"(""TopicIndex"",""" _ tDomain _ """)"
	For i = 1:1:tLevel {
		Set tSubTopic = " "_$ZCVT($E($P(..Topic,".",i),1,..#SUBTOPICLEN),"U")
		Set:tSubTopic=" *" tSubTopic=" "
		Set tGLVN = $Name(@tGLVN@(tSubTopic))
	}
	Set tGLVN = $Name(@tGLVN@(i%Subscriber))
	Set tGLVN = $Name(@tGLVN@(tID))
	Set @tGLVN = ""

	// remember old values in order to update special index
	Set ..OldValues("Topic") = i%Topic
	Set ..OldValues("DomainName") = i%DomainName
	Set ..OldValues("Subscriber") = i%Subscriber

	Quit $$$OK
}

/// Clear out an entry in the special index
ClassMethod ClearIndexEntry(pDomainName As %String, pTopic As %String, pSubscriber As %String, pID As %String)
{
	If ((pTopic '= "") && (pSubscriber '= "")) {
		Set tDomain = " " _ $ZCVT(pDomainName,"U")
		Set tLevel = $L(pTopic,".")
		Set tGLVN = ..#TOPICINDEX_"(""TopicIndex"",""" _ tDomain _ """)"
		For i = 1:1:tLevel {
			Set tSubTopic = " "_$ZCVT($E($P(pTopic,".",i),1,..#SUBTOPICLEN),"U")
			Set:tSubTopic=" *" tSubTopic=" "
			Set tGLVN = $Name(@tGLVN@(tSubTopic))
		}
		Set tGLVN = $Name(@tGLVN@(pSubscriber))
		Set tGLVN = $Name(@tGLVN@(pID))
		Kill @tGLVN
	}
}

Method %OnOpen() As %Status [ Private ]
{
	// remember old values in order to update special index
	Set ..OldValues("Topic") = i%Topic
	Set ..OldValues("DomainName") = i%DomainName
	Set ..OldValues("Subscriber") = i%Subscriber
	Quit $$$OK
}

/// Purge the special index used by the subscription table.
ClassMethod PurgeSpecialIndex(pDomain As %String = "")
{
	If (pDomain = "") {
		Set tGLVN = ..#TOPICINDEX_"(""TopicIndex"")"
	}
	Else {
		Set tDomain = " " _ $ZCVT(pDomain,"U")
		Set tGLVN = ..#TOPICINDEX_"(""TopicIndex"",""" _ tDomain _ """)"
	}
	Kill @tGLVN
}

/// Clean up special subscription index
Trigger SQLDeleteTrigger [ Event = DELETE ]
{
	Do ##class(Subscription).ClearIndexEntry({DomainName},{Topic},{Subscriber},{ID})
}

/// Override of property accessor
Method SubscriberNameGet() As %String
{
	Quit ..Subscriber.Name
}

/// Override of property accessor
Method SubscriberNameSet(%val As %String) As %Status
{
	// set Subscriber oref
	Set i%Subscriber = ##class(Subscriber).FindSubscriberId(i%DomainName,%val)
	Quit $$$OK
}

Storage Default
{
<Data name="SubscriptionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DomainName</Value>
</Value>
<Value name="3">
<Value>SubTopic1</Value>
</Value>
<Value name="4">
<Value>SubTopic2</Value>
</Value>
<Value name="5">
<Value>SubTopic3</Value>
</Value>
<Value name="6">
<Value>Subscriber</Value>
</Value>
<Value name="7">
<Value>Topic</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PubSub.SubscriptionD</DataLocation>
<DefaultData>SubscriptionDefaultData</DefaultData>
<IdLocation>^EnsLib.PubSub.SubscriptionD</IdLocation>
<IndexLocation>^EnsLib.PubSub.SubscriptionI</IndexLocation>
<StreamLocation>^EnsLib.PubSub.SubscriptionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
