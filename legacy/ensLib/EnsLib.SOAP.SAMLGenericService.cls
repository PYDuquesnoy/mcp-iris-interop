/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SOAP Generic Service that can validate the signature and timestamps on a SAML token
Class EnsLib.SOAP.SAMLGenericService Extends EnsLib.SOAP.GenericService [ System = 4 ]
{

/// Specifies types of Assertion validation to perform on <saml:Assertion> element: <ul>
/// <li>t - must contain a signed SAML token </li>
/// <li>a - token must contain an Assertion </li>
/// <li>u - token must contain an unsigned Assertion. If not found the error text is "No Unsigned Assertion".
/// <li>If both a and u are specified then either a signed or unsigned assertion needs to be present.</li>
/// <li>s - combine with u - if unsigned assertions exist the s requires them be a children of signed elements.
/// Note: The Assertion might be wrapped in a structure that does not follow from schema.</li>
/// <li>r - require Assertions to contain NotBefore/NotOnOrAfter time conditions </li>
/// <li>v - verify Assertion signatures using a Trusted X.509 certificate and, if present, NotBefore/NotOnOrAfter conditions </li>
/// If option 'u' is specified and 'v' NotBefore/NotOnOrAfter conditions will also be checked.</li>
/// <li>o - validate other signed nodes within the assertion such as TimeStamp. Signed reference elements
/// with attribute name of ID or Id will be searched for.</li>
/// </ul> If 1 is specified it is equivalent to 'tarvo'.<p/>
/// When checking the NotBefore/NotOnOrAfter time conditions the default clock skew allowance is 90 seconds. <br/>
/// To change the skew allowance Set ^Ens.Config("SAML","ClockSkew",&ltConfigName&gt) for a specific item
/// or ^Ens.Config("SAML","ClockSkew") for all items using this validation to the desired number of seconds. <br/>
/// Set to -1 to prevent NotBefore/NotOnOrAfter condition checking for the relevant item or items.<br/>
/// This does not validate the XML schema used for the SAML token.<br/>
Property Validation As %String [ InitialExpression = "1" ];

/// Location of a file containing certificates that can be used to verify the signatures on received SAML tokens.
/// The file should contain one or more trusted X.509 certificates in PEM-encoded format.
/// These certificates should complete a 'chain of trust' from the signatures contained in the SAML tokens to a trusted root Certificate Authority.
/// If empty and the 'mgr' directory contains a 'iris.cer' file then that file will be used.
Property TrustedX509File As %String(MAXLEN = 900);

/// Comma separated list of attributes to record for statistics. <br/>
/// The attribute names are case sensitive. <br/>
Property SAMLAttributes As %String;

Parameter SETTINGS = "Validation:Connection,TrustedX509File:Connection";

/// Return non-zero to prevent default validation of the message (if any);
Method OnValidate(pMsg As EnsLib.SOAP.GenericMessage, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Set pStatus = $$$OK
	Quit:pValSpec="" 1
	Set pValSpec=..normalizeValSpec(pValSpec)
	Try {
		Set tClockSkew = $G($$$EnsConfig("SAML","ClockSkew",..%ConfigName),$G($$$EnsConfig("SAML","ClockSkew"),90)),tAttributesToRemember=0
		If ##class(Ens.Util.Statistics).StatsStarted(..%ConfigName),(..SAMLAttributes'="") {
			Set tSAMLAttributeCount=$L(..SAMLAttributes,","),tAssertionAttributes=0,tAttributesToRemember=1
			For tAC=1:1:tSAMLAttributeCount {
				Set tAttribute=$P(..SAMLAttributes,",",tAC)
				If (tAttribute'="") Set tAssertionAttributes(tAttribute)="",tAssertionAttributes=tAssertionAttributes+1
			}
		}
		Set pStatus=##class(Ens.Util.XML.SecuritySignature).ValidateSAML(pMsg.EnvelopeStream,pValSpec,..TrustedX509File,tClockSkew,.tAttributes,.tAssertionAttributes)
		If $$$ISERR(pStatus) Quit
		If tAttributesToRemember {
			If $D(tAssertionAttributes) {
				Set tAttributeValues=""
				Set tAttribute=$O(tAssertionAttributes(""))
				While (tAttribute'="") {
					Set tAttributeValues=tAttributeValues_$S((tAttributeValues=""):"",1:" ")_tAttribute
					For tVC=1:1:tAssertionAttributes(tAttribute) {
						Set tAttributeValues=tAttributeValues_" "_$G(tAssertionAttributes(tAttribute,tVC))
					}
					Set tAttribute=$O(tAssertionAttributes(tAttribute))
				}
				If (tAttributeValues'="") {
					Do ##class(Ens.Util.Statistics).SetStatsUserDimension(..%ConfigName,tAttributeValues)
					Do pMsg.HTTPHeaders.SetAt($LB(..SAMLAttributes,tAttributeValues),"EnsAttribute")
				}
			}
		}
	} Catch {Set pStatus=$$$SystemError}
	If $$$ISERR(pStatus) $$$LOGSTATUS(pStatus)
	Quit 1
}

/// Convert to lower case, with inverse spec chars converted to upper case
ClassMethod normalizeValSpec(pValSpec As %String) As %String
{
	Set:pValSpec=1 pValSpec="tarvo"  Set pValSpec=$ZCVT(pValSpec,"L")
	Set new="",neg=0 For i=1:1:$L(pValSpec) { Set c=$E(pValSpec,i)
		If "-"=c Set neg='neg  Continue
		Set new=new_$S(neg:$ZCVT(c,"U"),1:c), neg=0
	}
	Quit new
}

}
