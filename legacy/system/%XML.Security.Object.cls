/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.Object Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property content As %XML.GlobalCharacterStream(XMLPROJECTION = "content");

Property Id As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property MimeType As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property Encoding As %xsd.anyURI(XMLPROJECTION = "attribute");

}
