/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a date in the format <code>YYYY-MM-DD</code>. 
/// Internally, this is stored in InterSystems IRIS $H format.
Class %xsd.date Extends %Date [ Not ProcedureBlock, System = 2 ]
{

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "date";

}
