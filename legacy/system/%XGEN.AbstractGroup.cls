/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %systemInclude

IncludeGenerator %systemInclude

/// <div style="color:red;padding:5px; border:1px solid black; background:#FFFFAA;">
/// <b>Note:</b> This class is included because it is needed by
/// other parts of the library. You should not use this or any other class within
/// this package within your applications as a future version will
/// be incompatible. If you are interested in this functionality
/// please contact InterSystems.
/// </div><br/>
/// This abstract class is the basis for all groups within XGEN
/// (such as documents or sequences).<br/>
/// See <class>%XGEN.AbstractDocument</class> for an overview of XGEN.<br/>
/// User classes should not extend this class, instead they should extend
/// either <class>%XGEN.AbstractDocument</class> or <class>%XGEN.AbstractSequence</class>.
Class %XGEN.AbstractGroup [ Abstract, PropertyClass = %XGEN.PropertyParameters, System = 3 ]
{

/// This is the set of child nodes that belong to this sequence.
Property children As list Of AbstractNode(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// If this transient property is true, then the children of the group will not
/// be processed. This provides a way for a subclass to disable processing of a group.
Property skipChildren As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Loop over the members of this sequence and fire their
/// <method>%GenerateCode</method> methods.<br/>
/// Subclasses can customize the behavior using the
/// <method>%OnBeforeGenerateCode</method> and <method>%OnAfterGenerateCode</method>
/// callback methods.<br/>
Method %GenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%OnBeforeGenerateCode(pTargetClass,pCode,pDocument)
		If $$$ISERR(tSC) Quit
		
		If ('..skipChildren) {
			Set tCount = ..children.Count()
			For n = 1:1:tCount {
				Set tNode = ..children.GetAt(n)
				Set tNode.%level = ..%level + 1
				Set tSC = tNode.%GenerateCode(pTargetClass,pCode,pDocument)
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
		}
		
		Set tSC = ..%OnAfterGenerateCode(pTargetClass,pCode,pDocument)
		If $$$ISERR(tSC) Quit
	}
	Catch(e) {
		Set tSC = $$$ERROR($$$ObjectScriptError,..%ClassName(1)_":%GenerateCode " _ $ZE)
	}

	Quit tSC
}

/// This callback does not apply to groups, so we stub it out here.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ Final ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// This method is called when a class containing an XGEN
/// document is compiled. It is called <em>before</em> the <method>%GenerateCode</method> method
/// processes its children.<br>
/// <var>pTargetClass</var> is the class that contains the XGEN document.<br/>
/// <var>pCode</var> is a stream containing the generated code.<br/>
/// <var>pDocument</var> is the top-level XGEN document object that contains this node.<br/>
/// A subclass can provide an implementation of this method that will
/// generate specific lines of code.<br/>
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ CodeMode = expression ]
{
$$$OK
}

/// This method is called when a class containing an XGEN
/// document is compiled. It is called <em>after</em> the <method>%GenerateCode</method> method
/// processes its children.<br>
/// <var>pTargetClass</var> is the class that contains the XGEN document.<br/>
/// <var>pCode</var> is a stream containing the generated code.<br/>
/// <var>pDocument</var> is the top-level XGEN document object that contains this node.<br/>
/// A subclass can provide an implementation of this method that will
/// generate specific lines of code.<br/>
Method %OnAfterGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ CodeMode = expression ]
{
$$$OK
}

}
