/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used to provide a context for the validation of the DTL parse tree.
Class Ens.DTL.ValidationContext Extends %RegisteredObject [ System = 3 ]
{

Property IsFatal As %Library.Boolean [ InitialExpression = 0 ];

}
