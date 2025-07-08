/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a non-positive integer value.
/// <p>This is identical to the <CLASS>%xsd.integer</CLASS> data type 
/// except that it has a default MAXVAL parameter of 0.
Class %xsd.nonPositiveInteger Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL = 0;

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "nonPositiveInteger";

Parameter STRICT = 1;

}
