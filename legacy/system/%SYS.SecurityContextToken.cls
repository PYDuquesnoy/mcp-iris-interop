/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility class to save and load SecurityContextToken from WS-SecureConversation 1.3.
/// This class is used by %SOAP.WSSC.SecurityContextToken to do the work that must be done
/// by a class in the %SYS package.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SYS.SecurityContextToken Extends %RegisteredObject [ System = 3 ]
{

/// Save this SecurityContextToken in a system wide global.
/// The global format is:
///    ^SYS("SOAPContext",Identifier,Instance)=$lb(type,ExpiresInSeconds,Key,AppliesTo,any,wsuId as $list,MustNotSendCancel)
/// The index for cleanup is
///    ^SYS("SOAPContext",0,ExpiresInSeconds,Identifier,Instance)=""
/// where Instance is $c(0) if no Instance and type is always = 1 for SecurityContextToken.
ClassMethod Save(sct As %SOAP.WSSC.SecurityContextToken) As %Status [ Internal ]
{
	Set dir="^^"_$zu(12)

	Do ..Cleanup()
	
	Do ..Remove(sct,1)

	Set instance=$select(sct.Instance="":$c(0),1:sct.Instance)
	Set anylist=""
	If $isobject(sct.any.extension) {
		For i=1:1:sct.any.extension.Count() {
			Set anylist=anylist_$lb(sct.any.extension.GetAt(i))
		}
	}
	Set ^|dir|SYS("SOAPContext",sct.Identifier,instance)=$lb(1,sct.ExpiresInSeconds,sct.Key,sct.AppliesTo,anylist,sct.MustNotSendCancel,sct.GetId())
	Set ^|dir|SYS("SOAPContext",0,sct.ExpiresInSeconds,sct.Identifier,instance)=""

	Quit $$$OK
}

/// Retrieve the SecurityContextToken with this identifier for system wide global.
/// See Save method description for details.
ClassMethod Open(identifier As %xsd.anyURI, instance As %String = "") As %SOAP.WSSC.SecurityContextToken [ Internal ]
{
	Set token=##class(%SOAP.WSSC.SecurityContextToken).%New()
	Set token.Identifier=identifier
	Set token.Instance=instance
	If '..Load(token,0,1) {
		Set token=""
	}
	Quit token
}

/// Retrieve the SecurityContextToken properties for token with this identifier for system wide global.
/// See Save method description for details.
ClassMethod Load(sct As %SOAP.WSSC.SecurityContextToken, keepId As %Boolean = 1, internal As %Boolean = 0) As %Boolean [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	Do ..Cleanup()
	
	Set list=$get(^|dir|SYS("SOAPContext",sct.Identifier,$select(sct.Instance="":$c(0),1:sct.Instance)))
	If list="" Quit 0
	If $listget(list,1)'=1 Quit 0
	
	Set sct.ExpiresInSeconds=$list(list,2)
	Set sct.Key=$list(list,3)
	Set sct.AppliesTo=$list(list,4)
	Set anylist=$list(list,5)
	If anylist'="" {
		Set ext=##class(%XML.ElementExtension).%New()
		For i=1:1:$listlength(anylist) {
			Do ext.extension.Insert($list(anylist,i))
		}
		Set sct.any=ext
	} Else {
		Set sct.any=""
	}
	Set sct.MustNotSendCancel=$list(list,6)
	Set id=$list(list,7)
	If keepId {
		If sct.Id="" Set sct.Id=id
	} Else {
		Set sct.Id=id
	}
	Quit 1
}

/// Log list of SecurityContextTokens
ClassMethod Log(terminal As %Boolean = 0) [ Internal ]
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
	
	Write "------Expiration:",!
	Set expires=""
	For {
		Set expires=$order(^|dir|SYS("SOAPContext",0,expires))
		If expires="" Quit
		Set identifier=""
		For {
			Set identifier=$order(^|dir|SYS("SOAPContext",0,expires,identifier))
			If identifier="" Quit
			Set instance=""
			For {
				Set instance=$order(^|dir|SYS("SOAPContext",0,expires,identifier,instance))
				If instance="" Quit
				Write $zdt((expires\86400)_","_(expires#86400),3)_">>"_identifier_$select(instance=$c(0):"",1:"/"_instance),!
			}
		}
	}
	Write "------Tokens:",!
	Set identifier=""
	For {
		Set identifier=$order(^|dir|SYS("SOAPContext",identifier))
		If identifier=0 Continue
		If identifier="" Quit
		Set instance=""
		For {
			Set instance=$order(^|dir|SYS("SOAPContext",identifier,instance))
			If instance="" Quit
			Set list=^|dir|SYS("SOAPContext",identifier,instance)
			Write identifier_$select(instance=$c(0):"",1:"/"_instance),!
			Set expires=$list(list,2)
			Write "   "_$zdt((expires\86400)_","_(expires#86400),3),!
			Write "   "_$system.Encryption.Base64Encode($list(list,3)),!
			Write "   "_$list(list,4),!
			Write "   "_$list(list,5),!
		}
	}
	
	If 'terminal {
		Close file
		Use io
	}
	Quit
}

/// Remove expired tokens
ClassMethod Cleanup() [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	Set now=$ztimestamp
	Set now=$piece(now,",")*86400+($piece(now,",",2)\1)
	Set expires=""
	For {
		Set expires=$order(^|dir|SYS("SOAPContext",0,expires))
		If (expires="") || (expires>=now) Quit
		Set identifier=""
		For {
			Set identifier=$order(^|dir|SYS("SOAPContext",0,expires,identifier))
			If identifier="" Quit
			Set instance=""
			For {
				Set instance=$order(^|dir|SYS("SOAPContext",0,expires,identifier,instance))
				If instance="" Quit
				Kill ^|dir|SYS("SOAPContext",identifier,instance)
				Kill ^|dir|SYS("SOAPContext",0,expires,identifier,instance)
			}
		}
	}
}

/// Remove this token from context list
ClassMethod Remove(sct As %SOAP.WSSC.SecurityContextToken, internal As %Boolean = 0) [ Internal ]
{
	Set dir="^^"_$zu(12)
	
	Set instance=$select(sct.Instance="":$c(0),1:sct.Instance)
	If $data(^|dir|SYS("SOAPContext",sct.Identifier,instance)) {
		Set expires=$list(^|dir|SYS("SOAPContext",sct.Identifier,instance),2)
		Kill ^|dir|SYS("SOAPContext",sct.Identifier,instance)
		Kill ^|dir|SYS("SOAPContext",0,expires,sct.Identifier,instance)
	}
}

/// Remove all security contexts
ClassMethod RemoveAll() [ Internal ]
{
	Kill ^|"^^"_$zu(12)|SYS("SOAPContext")
}

}
