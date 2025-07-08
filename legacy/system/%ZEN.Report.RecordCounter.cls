/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.RecordCounter Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property currentrow As %Integer [ InitialExpression = 0 ];

Property totalRows As %Integer;

Property currentindex As %String;

Property currentrowsubscript As %Integer;

}
