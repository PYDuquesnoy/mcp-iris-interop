/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// LifetimeType type from WS-Trust 1.3.
Class %SOAP.WST.Lifetime Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property Created As %xsd.dateTime(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLREF = 1);

Property Expires As %xsd.dateTime(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLREF = 1);

/// Create a Lifetime element with specified interval in seconds.
ClassMethod Create(interval As %Integer = 300) As %SOAP.WST.Lifetime
{
	Set lifetime=##class(%SOAP.WST.Lifetime).%New()
	Set now=$ztimestamp
	Set lifetime.Created=$zdt(now,3)

	If interval'="" {
		Set day=$piece(now,",",1)
		Set sec=$piece(now,",",2)+interval
		Set secsInDay=60*60*24
		Set lifetime.Expires=$zdt((day+(sec\secsInDay))_","_(sec#secsInDay),3)
	} Else {
		Set lifetime=""
	}
	Quit lifetime
}

}
