/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %OAuth2.Server.Claim defines a claim that is requested for an access token, userinfo endpoint or IDToken.
/// The value to be returned for the claim will have the same key in the ClaimValues property of %OAuth2.Server.Properties.
Class %OAuth2.Server.Claim Extends %SerialObject [ System = 4 ]
{

/// Essential is true if the claim is essential.  Default is false for voluntary claim.
Property Essential As %Boolean [ InitialExpression = 0 ];

/// Values is the list of permissible values for this claim 
/// either from the value or values property of the claims object.
Property Values As list Of %String(MAXLEN = 2048);

/// Serialize claim defintion for logging
ClassMethod LogString(claim As %OAuth2.Server.Claim) As %String [ Internal ]
{
	If claim="" Quit ""
	
	Set str=claim.Essential
	If claim.Values.Count()>0 {
		Set str=str_":"
		For i=1:1:claim.Values.Count() {
			Set str=str_claim.Values.GetAt(i)_","
		}
		Set str=$extract(str,1,*-1)
	}
	Quit str
}

Storage Default
{
<Data name="ClaimState">
<Value name="1">
<Value>Essential</Value>
</Value>
<Value name="2">
<Value>Values</Value>
</Value>
</Data>
<State>ClaimState</State>
<StreamLocation>^OAuth2.Server.ClaimS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
