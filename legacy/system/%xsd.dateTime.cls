/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a time stamp value in the 
/// format <code>YYYY-MM-DD HH:MM:SS.nnnnnnnnn</code>.
Class %xsd.dateTime Extends %TimeStamp [ Not ProcedureBlock, System = 2 ]
{

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "dateTime";

}
