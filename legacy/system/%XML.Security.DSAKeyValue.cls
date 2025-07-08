/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML KeyInfo type of DSAKeyValue.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.DSAKeyValue Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property P As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

Property Q As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

Property G As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

Property Y As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal, Required ];

Property J As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

Property Seed As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

Property PgenCounter As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal ];

}
