/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents binary data that will be encoded using base64 for XML serialization.
/// Internally, this is stored as a string containing a binary value.
/// 
/// <p>When a <b>%xsd.base64Binary</b> data type value is projected to a client application,
/// such as when it is used in a Java, Visual Basic (ActiveX), ODBC, or JDBC application,
/// the Object Server performs no translations or conversions on it.
/// That is, the actual binary data is sent to and from the client without any Unicode (or other) translations.
Class %xsd.base64Binary Extends %Binary [ Not ProcedureBlock, System = 2 ]
{

/// There is no length restriction for %xsd binary types.
Parameter MAXLEN As INTEGER;

}
