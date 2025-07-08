/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Timestamp element for SOAP Security header.
Class %SOAP.Security.Timestamp Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd";

Property Created As %xsd.dateTime;

Property Expires As %xsd.dateTime;

/// If TimestampAtEnd is false, then this Timestamp element is put first in the element list.
/// The default is false.
/// If TimestampAtEnd is true, then this Timestamp element is put last in the element list.
Property TimestampAtEnd As %Boolean(XMLPROJECTION = "NONE");

/// Return the value of the Id property.
/// Populate the Id property if it is not yet set.
Method GetId() As %String [ Internal ]
{
	If ..Id="" Set ..Id="Timestamp-"_$system.Util.CreateGUID()
	Quit ..Id
}

/// Create a Timestamp element that expires in <interval> seconds.
ClassMethod Create(interval As %Integer = 300) As %SOAP.Security.Timestamp
{
	Set timestamp=..%New()
	Set now=$ztimestamp
	Set timestamp.Created=$zdt(now,3)
	Set day=$piece(now,",",1)
	Set sec=$piece(now,",",2)+interval
	Set secsInDay=60*60*24
	Set timestamp.Expires=$zdt((day+(sec\secsInDay))_","_(sec#secsInDay),3)
	Quit timestamp
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	If ..Expires'="" {
		Set expires=$zdth(..Expires,3)
		Set now=$ztimestamp
		If (now>expires) || 
		   (($piece(now,",",1)=$piece(expires,",",1)) &&
		    ($piece(now,",",2)>$piece(expires,",",2))) {
				If $$$CheckSOAPTestMode {
					$$$SOAPLogSecurity("Security TimeStamp validation failed.  Expires="_..Expires)
				} Else {
					$$$SOAPLogSecurity("Security TimeStamp validation failed.  Expires="_..Expires_", Now="_$zdt(now,3))
				}
				Quit "MessageExpired"
		}
	} Else {
		$$$SOAPLogSecurity("Security TimeStamp has no Expires element")
	}
	$$$SOAPLogSecurity("Security TimeStamp validated")
	Quit ""
}

}
