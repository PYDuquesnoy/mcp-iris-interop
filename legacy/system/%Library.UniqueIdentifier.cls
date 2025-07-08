/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%UniqueIdentifier</b> data type class represents a GUID.
Class %Library.UniqueIdentifier Extends %DataType [ ClientDataType = BINARY, OdbcType = GUID, System = 1 ]
{

/// Tests if the logical value <var>%val</var>, which is a GUID, is valid.
ClassMethod IsValid(%val As %RawString) As %Status [ ServerOnly = 0 ]
{
		#; Make sure the value is 36 character long
	QUIT:$translate(%val,"0123456789abcdefABCDEF","000000000000000000000000")'="00000000-0000-0000-0000-000000000000" $$$ERROR($$$DTNotGUID,%val,36)
	QUIT $$$OK
}

}
