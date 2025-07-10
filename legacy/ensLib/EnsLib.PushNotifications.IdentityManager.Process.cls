/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.PushNotifications.IdentityManager.Process Extends Ens.BusinessProcessBPL [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.PushNotifications.IdentityManager.NotificationByIdentityRequest' response='EnsLib.PushNotifications.IdentityManager.NotificationByIdentityResponse' height='2000' width='2000' >
<context>
<property name='IdentitySearchResults' type='EnsLib.PushNotifications.IdentityManager.DeviceTracking' collection='list' >
</property>
<property name='CurrentIdentity' type='EnsLib.PushNotifications.IdentityManager.DeviceTracking' >
</property>
<property name='PendingCalls' type='%String' >
<parameters>
<parameter name='MAXLEN'  value='' />
</parameters>
</property>
</context>
<sequence xend='200' yend='800' >
<assign name="Do Identity Search" property="status" value="process.IdentitySearch(request.AssociatedAppToken,context)" action="set" xpos='200' ypos='250' />
<if name='Found Matches?' condition='context.IdentitySearchResults.Count() &gt; 0' xpos='200' ypos='350' xend='200' yend='700' >
<true>
<foreach name='Process Identities' property='context.IdentitySearchResults' key='context.CurrentIdentity' xpos='470' ypos='500' xend='200' yend='350' >
<call name='@(process.MakePendingCall("PushServiceCall",context,.status))' target='@process.NotificationServiceTarget' async='1' xpos='200' ypos='250' >
<request type='EnsLib.PushNotifications.NotificationRequest' >
<assign property="status" value="##class(EnsLib.PushNotifications.NotificationInfo).CopyFrom(request,callrequest)" action="set" />
<assign property="callrequest.Service" value="context.CurrentIdentity.Service" action="set" />
<assign property="callrequest.AppIdentifier" value="context.CurrentIdentity.AppIdentifier" action="set" />
<assign property="callrequest.Identifiers" value="context.CurrentIdentity.Identifier" action="append" />
</request>
<response type='EnsLib.PushNotifications.NotificationResponse' >
<assign property="response.NotificationCount" value="response.NotificationCount + 1" action="set" />
</response>
</call>
</foreach>
<sync name='Wait for Notification(s)' calls='@(context.PendingCalls)' type='all' xpos='470' ypos='600' />
</true>
<false>
<assign property="response.NotificationCount" value="0" action="set" xpos='200' ypos='500' />
<trace value='"No Devices found for Identity"' xpos='200' ypos='600' />
</false>
</if>
</sequence>
</process>
}

/// Specify the outbound notification service component/message router
Property NotificationServiceTarget As Ens.DataType.ConfigName [ Required ];

Parameter SETTINGS As %String = "NotificationServiceTarget";

/// Add a pending call
Method MakePendingCall(pCallPrefix As %String, pContext, ByRef pStatus As %Status) As %String
{
	#dim tSC As %Status
	#dim tCallKey As %String = ""
	Set tSC=$$$OK,$ZT=""
	Do {
		
		Set tCallKey = pCallPrefix _ $L(pContext.PendingCalls,",")
		
		If pContext.PendingCalls'="" {
			Set pContext.PendingCalls = pContext.PendingCalls _ ","
		}
		
		// Append our new call key
		Set pContext.PendingCalls = pContext.PendingCalls _ tCallKey
		
	} While (0)
Exit
	Set pStatus = tSC
	
	Quit tCallKey
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method IdentitySearch(pIdentity As %String, pContext) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT=""
	Do {
		#dim tRS As %ResultSet
		
		// Run an SQL query ...
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "EnsLib.PushNotifications.IdentityManager.DeviceTracking"
		Set tRS.QueryName = "DeviceSearchByAppToken"
		
		Set tSC = tRS.Execute(pIdentity)
		Quit:$$$ISERR(tSC)
		
		// Process the results ...
		While (tRS.Next(.tSC) && $$$ISOK(tSC)) {
			
			#dim tID     As %String        = tRS.Data("ID")
			#dim tDevice As DeviceTracking = ##class(DeviceTracking).%OpenId(tID,,.tSC)
			
			Quit:$$$ISERR(tSC)
			
			// Remember this ...
			Do pContext.IdentitySearchResults.Insert(tDevice)
		}
		
		Do tRS.Close()
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Storage Default
{
<Data name="ProcessDefaultData">
<Subscript>"Process"</Subscript>
<Value name="1">
<Value>NotificationServiceTarget</Value>
</Value>
</Data>
<DefaultData>ProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
