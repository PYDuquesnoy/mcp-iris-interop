/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Super class for Message types that are identified with DN or CN and Parent or Base
/// Base class for operation messages
/// Base class to LDAP request messages used by operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Message.EntityIdentification Extends %RegisteredObject [ System = 4 ]
{

/// Optional Distinguished name of object <br>
/// If not specified the Distinguished name used in the request
/// is calculated from the other properties. <br>
Property DN As %String(MAXLEN = "");

/// Relative Distinguished Name of object.
/// Includes naming attribute but if not specified cn is used
Property RDN As %String(MAXLEN = "");

/// Optional Parent of CN
Property Parent As %String(MAXLEN = "");

/// Optional Base
Property Base As %String(MAXLEN = "");

/// Method used to calculate Distinguished Name from the properties<br>
/// The first parameter can be used to provide a default base that will
/// be used if RDN is specified but Parent and Base are empty<br>
/// The second parameter is used to control whether the CalculatedDN ought to be
/// escaped as per RFC4514 https://www.ietf.org/rfc/rfc4514.txt. <br>
/// The default is to escape<br>
/// The CalculatedDN is returned As follows: <br>
/// If the property <property>DN</property> is not empty it is returned.<br>
/// If the property <property>DN</property> is empty then the value of the
/// property <property>RDN</property> becomes the first part of the returned value
/// and is then prepended to  <br>
/// the value of the <property>Parent</property> and returned.<br>
/// If <property>Parent</property> is empty then <property>RDN</property> is preprended to
/// <property>Base</property> and returned. <br>
/// If <property>Base</property> is empty then <property>RDN</property> is preprended to
/// parameter <parameter>pDefaultBaseDN</parameter> and returned. <br>
Method CalculatedDN(pDefaultBaseDN As %String = "", pEscapeDN As %Boolean = 1) As %String
{
	#dim tCalculatedDN As %String = ""

	If ..DN '= "" {

		Set tCalculatedDN = ..DN

	} ElseIf ..RDN '= ""  {

		Set tCalculatedDN = ..RDN

		If ..Parent '= ""  {

			Set tCalculatedDN = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(tCalculatedDN ,..Parent,0)

		} ElseIf ..Base '= ""  {

			Set tCalculatedDN = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(tCalculatedDN ,..Base,0)

		} ElseIf pDefaultBaseDN '= "" {

			Set tCalculatedDN = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(tCalculatedDN, pDefaultBaseDN,0)

		}

	}

	If pEscapeDN && (tCalculatedDN'="") Return ##class(EnsLib.LDAP.Util.General).EscapeDN(tCalculatedDN)

	Return tCalculatedDN
}

}
