/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Process to send ebXML messages in accordance with it's CPA
Class EnsLib.ebXML.Process.MessageSender Extends Ens.BusinessProcessBPL [ ClassType = persistent, ProcedureBlock, System = 4 ]
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
<sequence xend='550' yend='750' >
<assign name="Find CPA instance" property="context.CPA" value="##class(EnsLib.ebXML.CPA).CPAForMessage(request,.status)" action="set" xpos='550' ypos='200' />
<switch name='Determine Message Pattern' xpos='550' ypos='300' xend='550' yend='650' >
<case condition='(context.CPA.AckRequested="always") &amp;&amp; &apos;request.IsAcknowledgment() &amp;&amp; (context.CPA.SyncReplyMode="mshSignalsOnly")' name='SyncAck' >
<while name='Try to send' condition='context.Try&lt;context.CPA.Retries' xpos='550' ypos='450' xend='550' yend='1100' >
<annotation>Send the ebXML message and look for a synchronous ack.</annotation>
<call name='@("RetryInterval"_context.Try)' target='Ens.Alarm' async='1'>
<annotation>Set up an alarm to track the RetryInterval</annotation>
<request type='Ens.AlarmRequest'>
<assign property='callrequest.Timeout' value='context.CPA.RetryInterval' action='set'/>
</request>
</call>
<scope xpos='550' ypos='200' xend='550' yend='550' >
<call name='Dispatch Message' target='@process.OutboundTarget' async='0' timeout='context.CPA.RetryInterval' xpos='550' ypos='300' >
<annotation>Dispatch the outbound ebXML message</annotation>
<request type='EnsLib.ebXML.Message' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="context.Ack" value="callresponse" action="set" />
<assign property="context.ErrorStatus" value="$S($IsObject(callresponse):callresponse.MessageErrorStatus(),1:$$$OK)" action="set" />
</response>
</call>
<faulthandlers>
<catchall name='Handle Send Error(s)' xpos='550' ypos='400' xend='550' yend='300' >
<annotation>Send failed, we should try again.</annotation>
<assign name="Clear Ack" property="context.Ack" value="$$$NULLOREF" action="set" xpos='550' ypos='200' />
</catchall>
</faulthandlers>
</scope>
<if name='Received Response Ack?' condition='($IsObject(context.Ack) &amp;&amp; context.Ack.IsAcknowledgmentTo(request))' xpos='550' ypos='650' xend='550' yend='900' >
<true>
<break name='Success, stop trying' xpos='820' ypos='800' />
</true>
<false>
<sync name="Wait for RetryInterval" calls='@("RetryInterval"_context.Try)' timeout="context.CPA.RetryInterval" type="all"/>
<assign name="Increment Try count" property="context.Try" value="context.Try+1" action="set" xpos='550' ypos='800' />
</false>
</if>
<assign name="Raise any pending ebXML errors" property="status" value="context.ErrorStatus" action="set" xpos='550' ypos='1000' />
</while>
<if name='Ack Failed?' condition='(&apos;$IsObject(context.Ack) || &apos;context.Ack.IsAcknowledgmentTo(request))'>
<true>
<assign name="Raise a DeliveryFailure error" property="status" value="$$$ERROR($$$EnsebXMLErrUndeliverableMessage)" action="set" />
</true>
</if>
</case>
<case condition='(context.CPA.AckRequested="always") &amp;&amp; &apos;request.IsAcknowledgment() &amp;&amp; (context.CPA.SyncReplyMode&apos;="mshSignalsOnly")' name='AsyncAck' >
<call name='Prefetch Ack' target='EnsLib.ebXML.Operation.MessageTracker' async='1' xpos='1090' ypos='450' >
<annotation>Send the ebXML message and look for an asynchronous ack.</annotation>
<request type='EnsLib.ebXML.Operation.MessageTrackerTrackAcknowledgement' >
<assign property="callrequest.Request" value="request" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="context.Ack" value="callresponse" action="set" />
</response>
</call>
<while name='Try to send' condition='context.Try&lt;context.CPA.Retries' xpos='1090' ypos='550' xend='550' yend='1200' >
<call name='@("RetryInterval"_context.Try)' target='Ens.Alarm' async='1'>
<annotation>Set up an alarm to track the RetryInterval</annotation>
<request type='Ens.AlarmRequest'>
<assign property='callrequest.Timeout' value='context.CPA.RetryInterval' action='set'/>
</request>
</call>
<scope xpos='550' ypos='200' xend='550' yend='650' >
<call name='Dispatch Message' target='@process.OutboundTarget' async='0' timeout='context.CPA.RetryInterval' xpos='550' ypos='300' >
<annotation>Dispatch the outbound ebXML message</annotation>
<request type='EnsLib.ebXML.Message' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="context.ErrorStatus" value="$S($IsObject(callresponse):callresponse.MessageErrorStatus(),1:$$$OK)" action="set" />
</response>
</call>
<sync name='Wait for asynchronous ack' calls='Prefetch Ack' timeout='context.CPA.RetryInterval' type='all' xpos='550' ypos='400' />
<faulthandlers>
<catchall name='Handle Send Error(s)' xpos='550' ypos='500' xend='550' yend='300' >
<annotation>Send failed, we should try again.</annotation>
<assign name="Clear Ack" property="context.Ack" value="$$$NULLOREF" action="set" xpos='550' ypos='200' />
</catchall>
</faulthandlers>
</scope>
<if name='Received Response Ack?' condition='($IsObject(context.Ack) &amp;&amp; context.Ack.IsAcknowledgmentTo(request))' xpos='550' ypos='750' xend='550' yend='1000' >
<true>
<break name='Success, stop trying' xpos='820' ypos='900' />
</true>
<false>
<sync name="Wait for RetryInterval" calls='@("RetryInterval"_context.Try)' timeout="context.CPA.RetryInterval" type="all"/>
<assign name="Increment Try count" property="context.Try" value="context.Try+1" action="set" xpos='550' ypos='900' />
</false>
</if>
<assign name="Raise any pending ebXML errors" property="status" value="context.ErrorStatus" action="set" xpos='550' ypos='1100' />
</while>
<if name='Ack Failed?' condition='(&apos;$IsObject(context.Ack) || &apos;context.Ack.IsAcknowledgmentTo(request))'>
<true>
<assign name="Raise a DeliveryFailure error" property="status" value="$$$ERROR($$$EnsebXMLErrUndeliverableMessage)" action="set" />
</true>
</if>
</case>
<default name="NoAck">
<call name='Dispatch Message' target='@process.OutboundTarget' async='0' xpos='820' ypos='450' >
<annotation>Dispatch the outbound ebXML message</annotation>
<request type='EnsLib.ebXML.Message' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='EnsLib.ebXML.Message' >
<assign property="status" value="$S($IsObject(callresponse):callresponse.MessageErrorStatus(),1:$$$OK)" action="set" />
</response>
</call>
</default>
</switch>
<if name="Check for valid response" condition="$IsObject(response) &amp;&amp; &apos;response.IsResponseTo(request)">
<true>
<assign name="Clear Response" property="response" value="$$$NULLOREF"/>
</true>
</if>
</sequence>
</process>
}

/// Name of the outbound communications path
Property OutboundTarget As Ens.DataType.ConfigName [ Required ];

Parameter SETTINGS As %String = "OutboundTarget";

Storage Default
{
<Data name="MessageSenderDefaultData">
<Subscript>"MessageSender"</Subscript>
<Value name="1">
<Value>OutboundTarget</Value>
</Value>
</Data>
<DefaultData>MessageSenderDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
