/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Zen Mobile Cloud Messaging Device Tracking
Class EnsLib.PushNotifications.IdentityManager.DeviceTracking Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, System = 4 ]
{

/// Service type descriptor
Property Service As %String(DISPLAYLIST = ",Apple Push Notification Service,Google Cloud Messaging", VALUELIST = ",APNS,GCM") [ Required ];

/// Device Identifier (i.e. DeviceToken, or Registration Id)
Property Identifier As %String(MAXLEN = 512) [ Required ];

/// App Identifier
Property AppIdentifier As %String(MAXLEN = 512) [ Required ];

/// Associated Application Token
Property AssociatedAppTokens As list Of %String(MAXLEN = 512) [ Required ];

/// Last updated-at timestamp
Property LastUpdatedUTC As %TimeStamp [ InitialExpression = {$ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)}, Required ];

/// Index the associated app tokens (all of them) with this object
Index AssociatedAppTokensIndex On AssociatedAppTokens(ELEMENTS);

/// Index the service
Index ServiceIndex On Service;

/// Index the device identifier
Index IdentifierIndex On Identifier;

/// Index the app identifier
Index AppIdentifierIndex On AppIdentifier;

/// Associate an application token with a deviceid/appid. <p>
/// <var>pIdentifier</var> is the device token given to the remote device by the notification service. </br>
/// <var>pAppId</var> is the application identifier (if applicable, not needed for APNS) associated with your application. </br>
/// <var>pService</var> is the service identifier, one of:
/// <ul><li>APNS: Apple Push Notification Service</li>
/// <li>GCM: Google Cloud Messaging</li></ul>
/// <var>pAppToken</var> is the unique application token/identifier that you wish associated with this device.
ClassMethod AssociateDeviceWithAppToken(pIdentifier As %String, pAppId As %String, pService As %String, pAppToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tDevice As EnsLib.PushNotifications.IdentityManager.DeviceTracking

		Set tSC = ..FindDeviceByDeviceAndAppIds(pIdentifier,pAppId,pService,.tDevice,1)
		Quit:$$$ISERR(tSC)
		
		If tDevice.AssociatedAppTokens.Find(pAppToken)="" {
			Do tDevice.AssociatedAppTokens.Insert(pAppToken)
			Set tDevice.LastUpdatedUTC = $ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)
			
			Set tSC = tDevice.%Save()
			Quit:$$$ISERR(tSC)
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Disassociate an application token from an identifier/appid. <p>
/// <var>pIdentifier</var> is the device token given to the remote device by the notification service. </br>
/// <var>pAppId</var> is the application identifier (if applicable, not needed for APNS) associated with your application. </br>
/// <var>pService</var> is the service identifier, one of:
/// <ul><li>APNS: Apple Push Notification Service</li>
/// <li>GCM: Google Cloud Messaging</li></ul>
/// <var>pAppToken</var> is the unique application token/identifier that you associated with this device.
ClassMethod DisassociateDeviceWithAppToken(pIdentifier As %String, pAppId As %String, pService As %String, pAppToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tDevice As EnsLib.PushNotifications.IdentityManager.DeviceTracking
		#dim tIndex As %Integer

		Set tSC = ..FindDeviceByDeviceAndAppIds(pIdentifier,pAppId,pService,.tDevice,0)
		Quit:$$$ISERR(tSC)
		
		Set tIndex = tDevice.AssociatedAppTokens.Find(pAppToken)
		If tIndex '= "" {
			Do tDevice.AssociatedAppTokens.RemoveAt(tIndex)
			
			If tDevice.AssociatedAppTokens.Count() = 0 {
				// No more app tokens, let's delete this ...
				Set tSC = ..%DeleteId(tDevice.%Id())
				Quit:$$$ISERR(tSC)
			} Else {
				// Save this updated object (less one app token)
				Set tDevice.LastUpdatedUTC = $ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)
				
				Set tSC = tDevice.%Save()
				Quit:$$$ISERR(tSC)
			}
		} Else {
			Set tSC = $$$ERROR($$$EnsPushNotificationsErrInvalidDeviceIdAppIdAppTokenAssociation)
			Quit
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Helper to locate and/or create a device tracking object from a deviceid/appid pair
ClassMethod FindDeviceByDeviceAndAppIds(pIdentifier As %String, pAppId As %String, pService As %String, ByRef pDevice As EnsLib.PushNotifications.IdentityManager.DeviceTracking, pCreate As %Boolean = 0) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tId As %String = ""
		#dim SQLCODE As %Integer
		
		Set pDevice = $$$NULLOREF
		Set SQLCODE=0
		&sql(SELECT %ID INTO :tId
				FROM DeviceTracking
				WHERE (Service = :pService) AND (Identifier = :pIdentifier) AND (AppIdentifier = :pAppId))

		If SQLCODE=0 {
			
			// Open the object ...
			Set pDevice = ..%OpenId(tId)
			
		} ElseIf SQLCODE'=100 {
			// Some other error
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		} Else {
			// Not found ...
			Set pDevice = ..%New()
			Set pDevice.Service = pService
			Set pDevice.Identifier = pIdentifier
			Set pDevice.AppIdentifier = pAppId
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Locate a device tracking object by an app token
ClassMethod FindDeviceByAppToken(pAppToken As %String, ByRef pDevice As EnsLib.PushNotifications.IdentityManager.DeviceTracking) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tId As %String = ""
		#dim SQLCODE As %Integer
		
		Set pDevice = $$$NULLOREF
		Set SQLCODE=0
		&sql(SELECT %ID INTO :tId
				FROM DeviceTracking
				WHERE FOR SOME %ELEMENT(AssociatedAppTokens) (%Value = :pAppToken))

		If SQLCODE=0 {
			
			// Open the object ...
			Set pDevice = ..%OpenId(tId)
			
		} ElseIf SQLCODE'=100 {
			// Some other error
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}
		// Else SQLCODE=100 means not found ...
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Search for devices matching the associated app token
Query DeviceSearchByAppToken(pAppToken As %String) As %SQLQuery(CONTAINID = 1)
{
SELECT %ID, Service, Identifier, LastUpdatedUTC FROM DeviceTracking
 WHERE FOR SOME %ELEMENT(AssociatedAppTokens) (%Value = :pAppToken)
}

Storage Default
{
<Data name="DeviceTrackingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Service</Value>
</Value>
<Value name="3">
<Value>Identifier</Value>
</Value>
<Value name="4">
<Value>AppIdentifier</Value>
</Value>
<Value name="5">
<Value>AssociatedAppTokens</Value>
</Value>
<Value name="6">
<Value>LastUpdatedUTC</Value>
</Value>
</Data>
<DataLocation>^EnsLib.Push216E.DeviceTrackingD</DataLocation>
<DefaultData>DeviceTrackingDefaultData</DefaultData>
<IdLocation>^EnsLib.Push216E.DeviceTrackingD</IdLocation>
<IndexLocation>^EnsLib.Push216E.DeviceTrackingI</IndexLocation>
<StreamLocation>^EnsLib.Push216E.DeviceTrackingS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
