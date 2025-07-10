/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for all Action nodes
Class Ens.DTL.Action Extends Ens.DTL.Node [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter TAGNAME As STRING;

/// Optional setting. Sets the compilation language at level of Action.
/// To be useful, this will differ from the main DTL language.<br/>
/// Example: When the overall DTL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific DTL Code block action to accomodate Embedded <em>Python</em> source code.<br/>
Property LanguageOverride As %String(VALUELIST = ",python,objectscript");

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	If ..#TAGNAME '= "" {
		Do pStream.Write("<" _ ..#TAGNAME)
		If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))
		Do ..WriteExpandedAttribute(pStream)
		Do ..WriteAnnotationXML(pStream,1)
	}
	Quit $$$OK
}

/// This holds an annotation for the action
Property Annotation As %String(MAXLEN = "");

/// This indicates whether the action (and any children of this action) are disabled.
Property Disabled As %Boolean [ InitialExpression = 0 ];

/// This indicates whether the action is marked for showing collapsed in DTL Editor.
Property Expanded As %Boolean [ InitialExpression = 1 ];

Method WriteAnnotationXML(pStream As %BinaryStream, pHandleTag As %Boolean = 0) As %Status
{
	If (..Annotation '= "") {
		If pHandleTag {
			Do pStream.WriteLine(">")
		}
		Do pStream.Write("<annotation>")
		Do pStream.Write($ZCVT(..Annotation,"O","HTML"))
		Do pStream.WriteLine("</annotation>")
		If pHandleTag {
			Do pStream.WriteLine("</" _ ..#TAGNAME _ ">")
		}
	}
	ElseIf pHandleTag {
		Do pStream.WriteLine("/>")
	}
	Quit $$$OK
}

Method WriteExpandedAttribute(pStream As %BinaryStream)
{
	If (..Expanded=0) && $Case(..#TAGNAME,
			"case":1,
			"default":1,
			"if":1,
			"foreach":1,
			"group":1,
			"switch":1,
			:0) {
			Do pStream.Write(" expanded="_$$$EA("false"))
		}
}

}
