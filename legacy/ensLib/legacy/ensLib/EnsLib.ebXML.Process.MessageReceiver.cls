/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Process to receive ebXML messages in accordance with it's CPA
Class EnsLib.ebXML.Process.MessageReceiver Extends Ens.BusinessProcessBPL [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.ebXML.Message' response='EnsLib.ebXML.Message' includes='EnsebXML' height='2000' width='2000' >
<context>
<property name='Ack' type='EnsLib.ebXML.Message' >
</property>
<property name='Try' type='%Integer' initialexpression='0' >
</property>
<property name='CPA' type='EnsLib.ebXML.CPA' >
</property>
<property name='ErrorStatus' type='%Status' initialexpression='$$$OK' >
</property>
</context>
<sequence xend='550' yend='1700' >
<assign name="Find CPA instance" property="context.CPA" value="##class(EnsLib.ebXML.CPA).CPAForMessage(request,.status)" action="set" xpos='550' ypos='200' />
<switch name='Determine Message Pattern' xpos='550' ypos='300' xend='550' yend='650' >
<case condition='(context.CPA.AckRequested="always")  &amp;&amp; &apos;request.IsAcknowledgment() &amp;&amp; (context.CPA.SyncReplyMode&apos;="mshSignalsOnly")' name='AsyncAck' >
<call name='Send Async Ack' target='@process.OutboundTarget' async='1' xpos='685' ypos='450' >
<annotation>Dispatch the Ack back to the caller</annotation>
<request type='EnsLib.ebXML.Message' >
<assign property="status" value="callrequest.BuildAckHeader(request,$$$EnsebXMLMessageIdFromSessionId(process.%SessionId,process.MessageDomain))" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="status" value="$S($IsObject(callresponse):callresponse.MessageErrorStatus(),1:$$$OK)" action="set" />
</response>
</call>
</case>
<case condition='(context.CPA.AckRequested="always")  &amp;&amp; &apos;request.IsAcknowledgment() &amp;&amp; (context.CPA.SyncReplyMode="mshSignalsOnly")' name='SyncAck' >
<assign name="Construct Ack" property="status" value="response.BuildAckHeader(request,$$$EnsebXMLMessageIdFromSessionId(process.%SessionId,process.MessageDomain))" action="set" xpos='955' ypos='450' >
<annotation><![CDATA[Construct an acknowledgement for this request.]]></annotation>
</assign>
<reply name='Respond with Synchronous Ack' xpos='955' ypos='550' />
</case>
<default name='NoAck' />
</switch>
<if name='Ignore Duplicates?' condition='(context.CPA.DuplicateElimination="always") &amp;&amp; ##class(EnsLib.ebXML.MessageTracking).IsMessageTracked(request,.status)' xpos='550' ypos='750' xend='550' yend='1600' >
<false>
<if name='Is Tracked Response?' condition='request.IsResponse() &amp;&amp; ##class(EnsLib.ebXML.MessageTracking).IsMessageIdTracked(request.GetValueAt("Headers(MessageHeader).MessageData.RefToMessageId"),.status)' xpos='685' ypos='900' xend='685' yend='1150' >
<true>
<assign name="Process inbound response" property="status" value="process.DispatchResponse(request)" action="set" xpos='820' ypos='1050' />
</true>
</if>
<if name='Duplicate Tracking Enabled?' condition='(context.CPA.DuplicateElimination="always")'>
<true>
<assign name="Begin Tracking Message" property="status" value='##class(EnsLib.ebXML.MessageTracking).BeginTracking(request,"received")'>
<annotation><![CDATA[If duplicate elimination is enabled, we must keep track of this message in order to discard any later instances of it.]]></annotation>
</assign>
</true>
</if>
<if name='Dispatch Inbound?' condition='process.InboundTarget&apos;=""' xpos='685' ypos='1250' xend='685' yend='1500' >
<true>
<call name='Dispatch Inbound' target='@process.InboundTarget' async='0' timeout='context.CPA.TimeToLive' xpos='955' ypos='1400' >
<request type='EnsLib.ebXML.Message' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="response" value="callresponse" action="set" />
</response>
</call>
</true>
<false>
<assign name="Clear Response" property="response" value="$$$NULLOREF" action="set" xpos='685' ypos='1400' />
</false>
</if>
</false>
</if>
</sequence>
</process>
}

/// Name of the outbound communications path
Property OutboundTarget As Ens.DataType.ConfigName [ Required ];

/// Name of the inbound communications path
Property InboundTarget As Ens.DataType.ConfigName;

/// Message domain (from the production settings)
Property MessageDomain As %String [ InitialExpression = {$GET($$$ConfigProdSetting("MessageDomain"),$system.INetInfo.LocalHostName())}, Required ];

Parameter SETTINGS As %String = "OutboundTarget,InboundTarget,MessageDomain";

/// Dispatch an incoming response to it's intended receipent
Method DispatchResponse(pMessage As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tToken As %String
		
		Set tSC = ##class(EnsLib.ebXML.MessageTracking).UpdateTrackingWithResponse(pMessage, "complete", .tToken)
		Quit:$$$ISERR(tSC)
		
		If $GET(tToken)'="" {
			Set tSC = ..SendDeferredResponse(tToken, pMessage)
			Quit:$$$ISERR(tSC)
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Storage Default
{
<Data name="MessageReceiverDefaultData">
<Subscript>"MessageReceiver"</Subscript>
<Value name="1">
<Value>OutboundTarget</Value>
</Value>
<Value name="2">
<Value>InboundTarget</Value>
</Value>
<Value name="3">
<Value>MessageDomain</Value>
</Value>
</Data>
<DefaultData>MessageReceiverDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
