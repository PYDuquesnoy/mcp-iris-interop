/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents an integer value.
/// Internally, this is stored as an integer.
/// <p>MAXVAL and MINVAL are not set, because they are at the edge of useful ObjectScript integer bounds.
Class %xsd.long Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "long";

Parameter STRICT = 1;

}
