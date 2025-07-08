/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a calculatedMember
/// within a <class>%DeepSee.Component.pivotTable</class> component.
Class %DeepSee.Component.calculatedMember Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Name of the dimension this calculated member belongs to.
Property dimension As %DeepSee.Datatype.entityName;

/// Name of the calculated member.
Property memberName As %DeepSee.Datatype.entityName;

/// MDX expression that defines the value of this calculated member.
Property valueExpression As %DeepSee.Datatype.string(MAXLEN = 32000);

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100);

/// Optional solve order to apply to this member.
Property solveOrder As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Create a clone of this object.
ClientMethod clone(ascomp) [ Internal, Language = javascript ]
{
	var clone;
	if (ascomp) {
		// create as a component
		clone = zenPage.createComponentNS('http://www.intersystems.com/deepsee','calculatedMember');
	}
	else {
		// transient object
		clone = new Object();
		clone.clone = _DeepSee_Component_calculatedMember_clone;
	}
	clone.dimension = this.dimension;
	clone.memberName = this.memberName;
	clone.valueExpression = this.valueExpression;
	clone.formatString = this.formatString;
	return clone;
}

}
