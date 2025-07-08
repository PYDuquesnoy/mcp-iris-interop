/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a non-negative integer value.
/// <p>This is identical to the <CLASS>%xsd.integer</CLASS> data type 
/// except that it has a default MINVAL parameter of 0.
/// <p>MAXVAL is not set because it is at the edge of useful ObjectScript integer bounds.
Class %xsd.unsignedLong Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// The minimum allowed logical value for the data type.
Parameter MINVAL = 0;

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "unsignedLong";

Parameter STRICT = 1;

}
