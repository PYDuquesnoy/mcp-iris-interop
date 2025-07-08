/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

/// <div style="color:red;padding:5px; border:1px solid black; background:#FFFFAA;">
/// <b>Note:</b> This class is included because it is needed by
/// other parts of the library. You should not use this or any other class within
/// this package within your applications as a future version will
/// be incompatible. If you are interested in this functionality
/// please contact InterSystems.
/// </div><br/>
/// This is the base class for all elements within an XGEN document.<br/>
/// There are 3 type of element within XGEN document:
/// <ol>
/// <li>document: a container for the entire XGEN document. These are subclasses of <class>%XGEN.AbstractDocument</class>.</li>
/// <li>sequence: a collection of one or more elements. These are subclasses of <class>%XGEN.AbstractSequence</class>.</li>
/// <li>node: a single activity within an XGEN document. These are subclasses of <class>%XGEN.AbstractNode</class>.</li>
/// </ol>
/// See <class>%XGEN.AbstractDocument</class> for an overview of XGEN.
Class %XGEN.AbstractElement Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, PropertyClass = %XGEN.PropertyParameters, ServerOnly = 1, System = 3 ]
{

/// By setting this 1, we ignore the difference between null and empty nodes within XGEN.
Parameter XMLIGNORENULL = 1;

/// By setting this to 0, we disallow use of invalid attribute names.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// This is the name of the XGEN document class that this node belongs to.
Parameter XGENDOCUMENT As CLASSNAME;

/// Define a projection to clean up the Schema Global when a node is compiled.
Projection Projection As %XGEN.Projection;

/// This is the logical name of this node. This provides a common way to
/// name elements within an XGEN document.
Property name As %String(MAXLEN = "");

/// Internal property.<br/>
/// Number of levels this node is nested within the document.
Property %level As %Integer(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Generate code for this node.<br/>
Method %GenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Helper method.<br/>
/// Returns a string containing the correct number of tabs for indenting code for this node.
Method %Indent(pIndent As %Integer = 0) As %String [ CodeMode = expression ]
{
$TR($J("",..%level+pIndent)," ",$C(9))
}

}
