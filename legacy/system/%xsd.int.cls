/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents an integer value.
Class %xsd.int Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL = 2147483647;

/// The minimum allowed logical value for the data type.
Parameter MINVAL = -2147483648;

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "int";

Parameter STRICT = 1;

}
