/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Monitor.Matrix Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Type As %String(TRUNCATE = 1);

Property Name As %String(TRUNCATE = 1);

Property Value As array Of %String(MAXLEN = 2000, TRUNCATE = 1);

Property SubItems As list Of %CSP.Monitor.Matrix;

}
