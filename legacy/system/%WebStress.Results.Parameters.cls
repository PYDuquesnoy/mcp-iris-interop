/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Included for legacy reasons in order for the Excel spreadsheet to work
Class %WebStress.Results.Parameters Extends %RegisteredObject [ System = 4 ]
{

Property ApplicationDirectory As %String [ InitialExpression = {$zutil(12,"")} ];

}
