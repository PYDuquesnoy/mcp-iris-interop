/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <CLASS>%CSP.Stream</CLASS> class implements a base class for multipart/mime
/// streams sent to the CSP Server.
Class %CSP.Stream [ Abstract, ServerOnly = 1, System = 3 ]
{

/// The MIME content type of the stream
Property ContentType As %String [ Calculated ];

/// This property is ignored unless <property>ContentType</property>=text/...
/// Sets the Character Set for the content-type header.
Property CharSet As %String [ Calculated ];

/// If defined this property will set the 'Expires' property of the %response
/// object to allow the stream to be cached.
Property Expires As %String [ Calculated ];

/// When a file is uploaded from the browser this is the filename on the users
/// system of this file.
Property FileName As %String [ Calculated ];

/// When a file is uploaded from the browser this is the mime section of this
/// file.
Property MimeSection As %String [ Calculated ];

/// Full list of the headers associated with this mime section
Property Headers As %String [ Calculated ];

/// Retrieve the value of the ContentType property
Method HeadersGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("Headers")
}

/// Set the value of the ContentType property
Method HeadersSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("Headers",value)
 Quit $$$OK
}

/// Retrieve the value of the ContentType property
Method ContentTypeGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("ContentType")
}

/// Set the value of the ContentType property
Method ContentTypeSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("ContentType",value)
 Quit $$$OK
}

/// Retrieve the value of the CharSet property
Method CharSetGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("CharSet")
}

/// Set the value of the CharSet property
Method CharSetSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("CharSet",value)
 Quit $$$OK
}

/// Retrieve the value of the Expires property
Method ExpiresGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("Expires")
}

/// Set the value of the Expires property
Method ExpiresSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("Expires",value)
 Quit $$$OK
}

/// Retrieve the value of the FileName property
Method FileNameGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("FileName")
}

/// Set the value of the FileName property
Method FileNameSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("FileName",value)
 Quit $$$OK
}

/// Retrieve the value of the MimeSection property
Method MimeSectionGet() As %String [ CodeMode = expression, Final ]
{
..GetAttribute("MimeSection")
}

/// Set the value of the MimeSection property
Method MimeSectionSet(value As %String) As %Status [ Final ]
{
 Do ..SetAttribute("MimeSection",value)
 Quit $$$OK
}

}
