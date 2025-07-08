/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%ExactString</b> data type class represents a subclass of %String with the EXACT default collation.
Class %Library.ExactString Extends %String [ Not ProcedureBlock, System = 2 ]
{

/// The default collation value used for this data type.
Parameter COLLATION [ Constraint = ",ALPHAUP,EXACT,MINUS,MVR,PLUS,SPACE,COLLATE,SQLSTRING,SQLUPPER,STRING,TRUNCATE,UPPER", Flags = ENUMEDIT ] = "EXACT";

}
