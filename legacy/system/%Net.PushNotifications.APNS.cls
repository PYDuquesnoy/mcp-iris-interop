/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// // Implements Apple Push Notification Service connectivity
Class %Net.PushNotifications.APNS Extends %RegisteredObject
{

Parameter BUFFERSIZE As INTEGER = 16384;

Parameter DEVICETOKENLENGTH As INTEGER = 32;

/// Hostname of the Apple Push Notification Server.
Property PushServerAddress As %String(MAXLEN = 1024) [ Required ];

/// Port for the Apple Push Notification Server interface.
Property PushServerPort As %String [ Required ];

/// Configuration name in the table of SSL configurations.  The SSL is associated with the app and must be provided by Apple for the APNS service.
Property SSLConfig As %String [ Required ];

/// SSL Connection timeout period in seconds.  The connection is terminated after this period of inactivity.
Property ConnectTimeout As %Integer [ InitialExpression = 30, Required ];

/// Time period in seconds to wait for a response to a connection request.
Property ResponseTimeout As %Integer [ InitialExpression = 5, Required ];

/// I/O device
Property Device As %String [ Internal, Private ];

/// Connect to the Apple Push Notification Service
Method Connect() As %Status
{
	#dim tSC As %Status
	#dim tIO As %String
	Set tIO=$IO,tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tDevice As %String = ""
		#dim tSSLError As %String
		
		// Validate the settings
		Set tSC = ..%ValidateObject()
		Quit:$$$ISERR(tSC)
		
		// Build the device name
		Set tDevice="|TCP|"_..PushServerPort_"|"_$P($J,":")
		
		// Open the device
		Open tDevice:(..PushServerAddress:..PushServerPort:"S"::..#BUFFERSIZE:..#BUFFERSIZE:/TCPNOXY:/SSL=..SSLConfig):..ConnectTimeout

		// Check for connection timeout		
		If '$TEST {
			Set tSC=$$$ERROR($$$APNSConnectionTimedOut,"TCP/SSL:"_..PushServerAddress_":"_..PushServerPort,..ConnectTimeout)
			Quit
		}
		
		Use tDevice
		
		Set tSSLError = $system.Security.Users.SSLGetLastError()
		If tSSLError'="" {
			Set tSC=$$$ERROR($$$SSLHandShakeFailed,tSSLError)
			Quit
		}
		
		Set ..Device = tDevice
	}
	While (0)
Exit
	// Restore the IO device
	If tIO '= $IO Use tIO

	Quit tSC	
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError, $ZE)
	Goto Exit
}

Method Disconnect() As %Status
{
	#dim tSC As %Status
	#dim tDevice As %String
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		If ..Device'="" {
			Close ..Device
			Set ..Device = ""
		}
	}
	While (0)
Exit	
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError, $ZE)
	Goto Exit
}

/// Send a "simple" push notification.  The pDeviceToken represents a device identifier, the pNotificationData
/// is an array of the aps values (see the APNS docs) and pCustomData contains any additional data items
/// to be included.
Method SimplePushNotification(pDeviceToken As %String, ByRef pNotificationData) As %Status
{
#define I16N(%n) $RE($ZWC(%n))
	
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tMsg As %String
		#dim tReply As %String
		#dim tDeviceTokenData As %Binary
		#dim tPayload As %String
		
		Set tPayload = ##class(Util).ConvertArrayToJSON(.pNotificationData)
		
		// Validate it
		Set tSC = ..PackDeviceToken(pDeviceToken,.tDeviceTokenData)
		Quit:$$$ISERR(tSC)
		
		// This is the Simple Notification Format (Legacy)
		Set tMsg = $C(0)
				   _ $$$I16N($L(tDeviceTokenData))	// DeviceToken length (network byte order)
				   _ tDeviceTokenData  				// 32-binary bytes
				   _ $$$I16N($L(tPayload))			// Payload length (network byte order)
				   _ tPayload

		Set tSC = ..doMessageIO(tMsg)

		// NOTE: With the Simple Notification Format, there is NO response.  If there
		//       is some kind of error, then the connection will be severed.
		
		If $$$ISERR(tSC) {
			// Most likely a TCP disconnect ... make sure we disconnect
			Do ..Disconnect()
			
			Quit
		}

		// Simple notifications have no response ...		

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Send a notification using the "enhanced" mechanism. The pDeviceToken represents a device identifier, the pNotificationData
/// is an array of the aps values (see the APNS docs) and pCustomData contains any additional data items
/// to be included.
Method EnhancedPushNotification(pDeviceToken As %String, pRequestId As %Integer, pExpiresUTC As %TimeStamp, ByRef pNotificationData) As %Status
{
#define I32N(%n) $RE($ZLC(%n))
#define I16N(%n) $RE($ZWC(%n))
#define N32I(%n) $ZLA($RE(%n))
	
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tMsg As %String
		#dim tReply As %String
		#dim tPayload As %String
		#dim tExpiresUTC As %Integer
		#dim tDeviceToken As %String
		#dim tDeviceTokenData As %Binary
		
		Set tPayload = ##class(Util).ConvertArrayToJSON(.pNotificationData)

		// Validate it
		Set tSC = ..PackDeviceToken(pDeviceToken,.tDeviceTokenData)
		Quit:$$$ISERR(tSC)

		// Convert the local timestamp into a UNIX UTC based timestamp (in whole seconds)
		Set tExpiresUTC = ##class(Util).TimeStampToUnix(pExpiresUTC,1)\1
		
		// This is the Enhanced Notification Format (Legacy)
		Set tMsg = $C(1)
				   _ $$$I32N(pRequestId)			// Request Id
				   _ $$$I32N(tExpiresUTC)			// Expiration date (in unix time)
				   _ $$$I16N($L(tDeviceTokenData))	// DeviceToken length (network byte order)
				   _ tDeviceTokenData		   		// 32-binary bytes
				   _ $$$I16N($L(tPayload))			// Payload length (network byte order)
				   _ tPayload

		Set tSC = ..doMessageIO(tMsg,.tReply,6)
		If $$$ISERR(tSC) {
			// Most likely a TCP disconnect ... make sure we disconnect
			Do ..Disconnect()
			
			Quit
		}

		If $L(tReply)>0 {
			#dim tCmdCode As %Integer    = $A(tReply,1)
			#dim tStatusCode As %Integer = $A(tReply,2)
			#dim tIdent As %Integer      = $$$N32I($E(tReply,3,6))
			
			// Command code is always 8
			If $L(tReply)=6,tCmdCode=8 {
				
				If tStatusCode'=0 {
					// Enhanced notification failed ...
					#dim tReason As %String
					Set tReason = $CASE(tStatusCode,
										1:"Processing Error",
										2:"Missing device token",
										3:"Missing topic",
										4:"Missing payload",
										5:"Invalid token size",
										6:"Invalid topic size",
										7:"Invalid payload size",
										8:"Invalid token",
										10:"Shutdown",
										:"Unknown "_tStatusCode)
										
					Set tSC = $$$ERROR($$$APNSPushNotificationFailedWithReason,tReason)
				}
				
				// ELSE: No error ...
				
			} Else {
				Set tSC = $$$ERROR($$$APNSInvalidResponse,tReply)
			}
			
			Quit:$$$ISERR(tSC)
		}

		// ELSE: There's no response (unless there is an error ...)		
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Pack the token string into a 32-byte binary buffer
ClassMethod PackDeviceToken(pToken As %String, ByRef pTokenData As %Binary) As %Status [ Internal ]
{
	#dim tIndex As %Integer = 1
	
	If $L(pToken)'=(..#DEVICETOKENLENGTH * 2) {
		Quit $$$ERROR($$$InvalidDeviceToken)
	}
	
	Set pTokenData = ""
	
	While (tIndex < $L(pToken)) {
		Set pTokenData = pTokenData _ $C($ZHEX($E(pToken,tIndex,tIndex+1)))
		Set tIndex = tIndex + 2
	}
	
	Quit $$$OK
}

Method doMessageIO(pSend As %String, ByRef pRecv As %String, pRecvSize As %Integer = 0) As %Status [ Internal ]
{
	#dim tSC As %Status
	#dim tIO As %String
	Set tIO=$IO,tSC=$$$OK,$ZT="Trap"
	Do {
		Use ..Device
		Write pSend,*-3  // Write the message and flush it
		
		If pRecvSize>0 {
			// Read a response ... annoyingly, there is no response if the message was accepted!
			Read pRecv#pRecvSize:..ResponseTimeout
			
			If '$TEST {
				// No response ... notification was ok
				Set pRecv = ""
			}
		}

	} While (0)
Exit
	If tIO'=$IO Use tIO
	
	Quit tSC
Trap
	Set $ZT=""
	// Handle <READ> and <WRITE> errors as a disconnect
	If "<WRITE><READ>"[($P($ZE,">")_">") {
		#dim tSSLError As %String = $system.Security.Users.SSLGetLastError()
		If tSSLError'="" {
			// SSL Failed ...
			Set tSC=$$$ERROR($$$SSLHandShakeFailed,tSSLError)
		} Else {
			Set tSC=$$$ERROR($$$APNSConnectionTerminated)
		}
		Set tSC=$$$EMBEDSC(tSC,$$$ERROR($$$ObjectScriptError,$ZE))
	} Else {
		Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	Goto Exit
}

}
