/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for DeepSee KPI meta-data objects.<br/>
Class %DeepSee.Model.KPI.node Extends %DeepSee.Model.abstractNode [ Abstract, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/kpi";

Parameter XMLINCLUDEINGROUP = 1;

/// Logical name of this element.
Property name As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Description of this element.
Property description As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Localized name of this element.
Property displayName As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Disabled flag. If true, then this member will be ignored when the
/// KPI class is compiled.
Property disabled As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

}
