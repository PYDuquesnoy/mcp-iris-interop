/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Extension.DataSource Extends ISCExtension [ Abstract, System = 3 ]
{

Property name As %String(MAXLEN = 200, XMLPROJECTION = "ATTRIBUTE");

Property description As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property idField As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property Fields As list Of FieldMap(XMLNAME = "X-FieldMap", XMLPROJECTION = "ELEMENT");

}
