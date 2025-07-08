/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements an EntityResolver that always returns an empty stream.
/// It can be used to defeat the default entity resolution performed by the SAX, XPATH 
/// and XSLT processors. You may want to defeat such processing because even though you
/// may not be performing validation on an XML document, the processors will still attempt
/// to resolve external entities which can be very time consuming, especially if they are
/// referenced by an URL on the network
Class %XML.SAX.NullEntityResolver Extends %XML.SAX.EntityResolver [ System = 4 ]
{

Method resolveEntity(publicID As %Library.String, systemID As %Library.String) As %Library.Integer
{
	Quit ##class(%XML.SAX.StreamAdapter).%New(##class(%Stream.TmpBinary).%New())
}

}
