/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for DeepSee Quality Measure meta-data objects.<br/>
Class %DeepSee.Model.QualityMeasure.node Extends %DeepSee.Model.abstractNode [ Abstract, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/qualityMeasure";

Parameter XMLINCLUDEINGROUP = 1;

/// Logical name of this element.
Property name As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Display name of this element.
Property caption As %ZEN.Datatype.caption(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Disabled flag. If true, then this member will be ignored at compile time.
Property disabled As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

}
