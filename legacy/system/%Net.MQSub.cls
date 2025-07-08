/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.MQSub Extends %Net.MQRecv [ System = 3 ]
{

/// MQ type
Property qtype As %Integer [ InitialExpression = 3, Internal ];

/// For the default case, the optional topicName needs to be created
/// beforehand, using WebSphere MQ Explorer or this MQSC command:
/// DEFINE TOPIC(STOCKS) TOPICSTR(NYSE) REPLACE;
/// Topic name
Property TopicName As %String;

/// Topic String
Property TopicString As %String;

/// <b>%Connect</b> creates a connection for a Subscription.&nbsp; A connection 
/// is required before messages from the subscription can be received.&nbsp;
/// <p>User must first set the standard MQSeries initialization arguments
/// <p>QName: Host Queue Name (Optional). Note if QName is not provided, the Subscription must be a Managed Subscription.
/// <p>QMgr: Host Queue Manager name. Passing "" connects to the default queue manager. (Optional)
/// <p>Channel: Host Channel name (Optional)
/// <p>Transport: Transport type (TCP, LU62, NETBIOS, SPX) (Optional)
/// <p>Connection: Connection spec, e.g., "127.0.0.1(1401)" (Optional)
/// <p>TName: topic name (Required)
/// <p>SName: subscription name. (Required)
/// <p>durable: Set durable to 1 if the subscription is to be a durable subscription. (Optional)
/// <p>See IBM MQ documentation on establishing defaults, and MQ authentication.
Method %Connect() As %Boolean
{
 If (..mDesc = -1) {
	 w "Invalid Q",!
     Quit 0
 }
 
 // Set channel options
 s rs = $ZF(-5, ..mDllid, ..MQSetChannelID, ..mDesc, ..Channel, ..Transport, ..Connection)
 Q:'rs 0

 // Connect to Queue Manager
 s rs = $ZF(-5, ..mDllid, ..MQConnectID, ..mDesc, ..QMgr, ..QMBehavior)
 Q:'rs 0

 // Open the Subscription
 s rs = $ZF(-5, ..mDllid, ..MQSubscribeID, ..mDesc, ..TopicName, ..TopicString)
 Q rs
}

}
