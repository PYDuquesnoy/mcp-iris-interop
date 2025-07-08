/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a boolean value.
/// Internally, this is stored as an integer with value of 0 (false) or 1 (true).
Class %xsd.boolean Extends %Boolean [ Not ProcedureBlock, System = 2 ]
{

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "boolean";

}
