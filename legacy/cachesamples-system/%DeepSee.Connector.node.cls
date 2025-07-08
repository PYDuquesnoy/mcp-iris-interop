/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for DeepSee Connector Definition meta-data objects.<br/>
Class %DeepSee.Connector.node Extends abstractNode [ Abstract, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/connector/output";

Parameter XMLINCLUDEINGROUP = 1;

/// Logical name of this element.
Property name As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Optional description for this node.
Property description As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Disabled flag. If true, then this member will be ignored when the
/// DeepSee Connector is compiled.
Property disabled As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

}
