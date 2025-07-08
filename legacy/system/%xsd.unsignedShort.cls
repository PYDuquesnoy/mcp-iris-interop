/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a non-negative integer value.
/// <p>This is identical to the <CLASS>%xsd.integer</CLASS> data type 
/// except that it has a default MINVAL parameter of 0 and MAXVAL of 65535.
Class %xsd.unsignedShort Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL = 65535;

/// The minimum allowed logical value for the data type.
Parameter MINVAL = 0;

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "unsignedShort";

Parameter STRICT = 1;

}
