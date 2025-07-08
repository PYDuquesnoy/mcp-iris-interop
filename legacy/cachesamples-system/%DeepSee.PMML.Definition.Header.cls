/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Header Extends extendableNode [ System = 3 ]
{

Property copyright As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:string");

Property description As %DeepSee.PMML.Datatype.String(MAXLEN = 20000, XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:string");

Property Application As HeaderApplication(XMLPROJECTION = "ELEMENT");

Property Annotation As list Of HeaderAnnotation(XMLPROJECTION = "ELEMENT");

Property Timestamp As HeaderTimestamp(XMLPROJECTION = "ELEMENT");

}
