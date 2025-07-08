/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a tiny integer value.
/// <p>This class is identical to the <CLASS>%Integer</CLASS> data type 
/// except that it has odbctype of TINYINT, a default MAXVAL parameter
/// value of 127, and a default MINVAL parameter value of -128.
Class %xsd.byte Extends %Integer [ Not ProcedureBlock, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL = 127;

/// The minimum allowed logical value for the data type.
Parameter MINVAL = -128;

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "byte";

Parameter STRICT = 1;

}
