/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility class to save and load session information from WS-ReliableMessaging 1.2.
/// A session consists of a request and response sequence.
/// This class is used by %SOAP.RM classes to do the work that must be done
/// by a class in the %SYS package.
/// 
/// The persistent operations in this class are used only on the service side.
/// This class is used as a registered object for both the client and the service.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SYS.RMSession Extends %RegisteredObject [ System = 3 ]
{

/// Identifier for the request sequence
Property RequestIdentifier As %xsd.anyURI [ Internal ];

/// Identifier for the response sequence.  ResponseIndentifier="" for a one way session.
Property ResponseIdentifier As %xsd.anyURI [ Internal ];

/// UTC expiration time in seconds
Property ExpiresInSeconds As %Integer [ Internal ];

/// Inactivity timeout interval in seconds
/// Defaults to 600 if not specified.
Property InactivityTimeout As %Integer [ Internal ];

/// The endpoint of the web service to which this token applies
Property AppliesTo As %xsd.anyURI [ Internal ];

/// The time in seconds to wait before retry on client.  Default is 0.
Property RetryInterval As %Float [ Internal ];

/// The maxiumum number of retries on client. Default is 4.
Property MaxRetryCount As %Integer [ Internal ];

/// If InOrder true, deliver in order.
Property InOrder As %Boolean [ InitialExpression = 1, Internal ];

/// Delivery Assurance: "ExactlyOnce", "AtLeastOnce", "AtMostOnce" or "".
Property DeliveryAssurance As %String [ Internal ];

/// Identifier of SecurityContextToken to be used to secure sequence
Property SCTIdentifier As %String [ Internal ];

/// Last message number sent or received
Property MessageNumber As %Integer [ InitialExpression = 0, Internal ];

/// Received messages bit string.
Property Bits As %String [ Internal ];

/// Session Terminated boolean
Property Terminated As %Boolean [ InitialExpression = 0, Internal ];

/// Process no more messages after first gap
Property DiscardFollowingFirstGap As %Boolean [ Internal ];

/// If true the entire Sequence must be protected by the same SSL session.
/// This property is client only.
Property SSLSecurity As %Boolean [ Internal ];

/// Save this RMSession in a system wide global.
/// The global format is:
///    ^SYS("SOAPRMSession",RequestIdentifier)=$lb(type,ResponseIdentifier,ExpiresInSeconds,nextExpiresInSeconds,InactivityTimeout,AppliesTo,InOrder,DeliveryAssurance,SCTIdentifier,MessageNumber,Bits,Terminated,DiscardFollowingFirstGap)
/// The index for cleanup is
///    ^SYS("SOAPRMSession",0,NextExpiresInSeconds,RequestIdentifier)=""
/// where NextExpiresInSeconds is the next expiration which is the smaller of ExpireInSeconds and InactivityTimeinSeconds and
///   type is always = 1 for RMSession.
Method Save() As %Status [ Internal ]
{
	Set dir="^^"_$zu(12)

	If ..InactivityTimeout="" Set ..InactivityTimeout=600

	Do ..Cleanup()
	
	Do ..Remove()

	Set now=$ztimestamp
	Set next=$piece(now,",")*86400+($piece(now,",",2)\1)+..InactivityTimeout
	Set nextExpiresInSeconds=..ExpiresInSeconds
	If (nextExpiresInSeconds="") || (nextExpiresInSeconds>next) {
		Set nextExpiresInSeconds=next
	}
	Set ^|dir|SYS("SOAPRMSession",..RequestIdentifier)=$lb(1,..ResponseIdentifier,..ExpiresInSeconds,nextExpiresInSeconds,..InactivityTimeout,..AppliesTo,..InOrder,..DeliveryAssurance,..SCTIdentifier,..MessageNumber,..Bits,..Terminated,..DiscardFollowingFirstGap)
	Set ^|dir|SYS("SOAPRMSession",0,nextExpiresInSeconds,..RequestIdentifier)=""

	Quit $$$OK
}

/// Retrieve the RMSession with this identifier from system wide global.
/// See Save method description for details.
ClassMethod Open(identifier As %xsd.anyURI) As %SYS.RMSession [ Internal ]
{
	Set session=##class(%SYS.RMSession).%New()
	Set session.RequestIdentifier=identifier
	If 'session.Load() {
		Set session=""
	}
	Quit session
}

/// Retrieve the RMSession properties for token with this identifier from system wide global.
/// See Save method description for details.
Method Load() As %Boolean [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	Do ..Cleanup()
	
	Set list=$get(^|dir|SYS("SOAPRMSession",..RequestIdentifier))
	If list="" Quit 0
	If $listget(list,1)'=1 Quit 0

	Set ..ResponseIdentifier=$list(list,2)	
	Set ..ExpiresInSeconds=$list(list,3)
	Set ..InactivityTimeout=$list(list,5)
	Set ..AppliesTo=$list(list,6)
	Set ..InOrder=$list(list,7)
	Set ..DeliveryAssurance=$list(list,8)
	Set ..SCTIdentifier=$list(list,9)
	Set ..MessageNumber=$list(list,10)
	Set ..Bits=$list(list,11)
	Set ..Terminated=$list(list,12)
	Set ..DiscardFollowingFirstGap=$list(list,13)
	Quit 1
}

/// Log list of RMSessions
ClassMethod Log(terminal As %Boolean = 1, test As %Boolean = 0) [ Internal ]
{
	Set dir="^^"_$zu(12)

	If 'terminal {
		Set file=$get(^ISCSOAP("LogFile"))
		If file="" Quit
	
		Set io=$io
		Open file:"waes":1 else  close file Quit
		Use file
		$$$SETIO("RAW")
	}
	
	If 'test {
		Write "------Expiration:",!
		Set expires=""
		For {
			Set expires=$order(^|dir|SYS("SOAPRMSession",0,expires))
			If expires="" Quit
			Set identifier=$order(^|dir|SYS("SOAPRMSession",0,expires,""))
			Write $zdt((expires\86400)_","_(expires#86400),3)_">>"_identifier,!
		}
	}
	Write "------Tokens:",!
	Set identifier=""
	For {
		Set identifier=$order(^|dir|SYS("SOAPRMSession",identifier))
		If identifier=0 Continue
		If identifier="" Quit
		Set list=^|dir|SYS("SOAPRMSession",identifier)
		If 'test {
			Write identifier,!
			Write "   <"_$list(list,2),!
			Set expires=$list(list,3)
			Write "   "_$zdt((expires\86400)_","_(expires#86400),3),!
			Set next=$list(list,4)
			Write "   "_$zdt((next\86400)_","_(next#86400),3),!
		} Else {
			If $list(list,2)="" Write "   OneWay",!
		}
		Write "   InactivityTimeout="_$list(list,5),!
		Write "   AppliesTo="_$list(list,6),!
		Write "   InOrder="_$list(list,7),!
		Write "   DeliveryAssurance="_$list(list,8),!
		If 'test {
			Write "   SCT="_$list(list,9),!
		} Else {
			Write "   SCT="_$select($list(list,9)'="":"token",1:""),!
		}
		Write "   #"_$list(list,10),!
		Set ranges=##class(%ListOfObjects).%New()
		Do ..BitToRange($list(list,11),ranges)
		For i=1:1:ranges.Count() {
			Set range=ranges.GetAt(i)
			Write "   ("_range.Lower_","_range.Upper_")",!
		}
		If $list(list,12) Write "   Terminated",!
		If $list(list,13) Write "   DiscardFollowingFirstGap",!
	}
	
	If 'terminal {
		Close file
		Use io
	}
	Quit
}

/// Remove expired RMSessions
Method Cleanup() [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	Set now=$ztimestamp
	Set now=$piece(now,",")*86400+($piece(now,",",2)\1)
	Set expires=""
	For {
		Set expires=$order(^|dir|SYS("SOAPRMSession",0,expires))
		If (expires="") || (expires>=now) Quit
		Set identifier=$order(^|dir|SYS("SOAPRMSession",0,expires,""))
		If identifier'="",identifier'=..RequestIdentifier {
			Kill ^|dir|SYS("SOAPRMSession",identifier)
			Kill ^|dir|SYS("SOAPRMSession",0,expires,identifier)
		}
	}
}

/// Remove this RMSession from session list
Method Remove() [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	If $data(^|dir|SYS("SOAPRMSession",..RequestIdentifier)) {
		Set expires=$list(^|dir|SYS("SOAPRMSession",..RequestIdentifier),4)
		Kill ^|dir|SYS("SOAPRMSession",0,expires,..RequestIdentifier)
		Kill ^|dir|SYS("SOAPRMSession",..RequestIdentifier)
	}
}

/// Remove all RMSessions
ClassMethod RemoveAll() [ Internal ]
{
	Kill ^|"^^"_$zu(12)|SYS("SOAPRMSession")
}

/// Get acknowledgement ranges for this RM session
Method GetRange(ranges As %ListOfObjects) [ Internal ]
{
	Set bits=..Bits
	Do ..BitToRange(bits,ranges)
}

/// Convert bit string to acknowledgement ranges for this RM session
ClassMethod BitToRange(bits As %String, ranges As %ListOfObjects) [ Internal ]
{
	Do ranges.Clear()
	Set index=1
	For {
		Set index=$bitfind(bits,1,index)
		If index=0 Quit
		Set nextIndex=$bitfind(bits,0,index)
		Set range=##class(%SOAP.RM.AcknowledgementRange).%New()
		Do ranges.Insert(range)
		Set range.Lower=index
		If nextIndex=0 {
			Set range.Upper=$bitcount(bits)
			Quit
		} Else {
			Set range.Upper=nextIndex-1
			Set index=nextIndex
		}
	}
}

/// Set bit string from acknowledgement ranges for this RM session
Method SetRange(ranges As %ListOfObjects) [ Internal ]
{
	Set bits=""
	For i=1:1:ranges.Count() {
		Set range=ranges.GetAt(i)
		For j=range.Lower:1:range.Upper {
			Set $bit(bits,j)=1
		}
	}
	Set ..Bits=bits
}

/// Update range to indicate last message sent successfully
Method MessageOK() [ Internal ]
{
	Do ..SetMessageState(..MessageNumber,1)
}

/// Set message acknowledged state
Method SetMessageState(messageNumber As %Integer, acknowledged As %Boolean) [ Internal ]
{
	Set bits=..Bits
	Set $bit(bits,messageNumber)=acknowledged
	Set ..Bits=bits
}

/// Get message acknowledged state
Method GetMessageState(messageNumber As %Integer) As %Boolean [ Internal ]
{
	Set bits=..Bits
	Quit $bit(bits,messageNumber)
}

/// Check for gap in received messages
Method CheckGap() As %Boolean [ Internal ]
{
	Set bits=..Bits
	Quit ($bitcount(bits)'=$bitcount(bits,1))
}

/// Check correct SCT (or no SCT) for this session
Method CheckSCT(soapClass As %SOAP.WebBase) As %Boolean [ Internal ]
{
	If ..SCTIdentifier'="" {
		Set sct=soapClass.SecurityIn.SecurityContextToken
		If '$isobject(sct) Quit 0
		If sct.Identifier'=..SCTIdentifier Quit 0
	}
	Quit 1
}

}
