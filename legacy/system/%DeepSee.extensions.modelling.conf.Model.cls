/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Model Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property name As %String(XMLPROJECTION = "ATTRIBUTE");

Property args As %Integer(XMLPROJECTION = "ATTRIBUTE");

Property Operations As array Of Operation(XMLKEYNAME = "order");

}
