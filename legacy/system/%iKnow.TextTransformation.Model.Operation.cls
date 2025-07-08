/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents an atomic operation in the sequence of operations making up a TT model.
Class %iKnow.TextTransformation.Model.Operation Extends node [ Deprecated, System = 3 ]
{

///  Name of this operation. This should correspond to the class name of a subclass of <class>%iKnow.TextTransformation.Annotate</class>
/// or <class>%iKnow.TextTransformation.Transform</class>. If the class belongs to the %iKnow.TextTransformation package, 
/// the package name can be left out. 
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

///  Display name of the operation. 
Property displayName As %String(XMLPROJECTION = "NONE") [ Calculated ];

///  Operation type 
Property type As %String(VALUELIST = ",annotate,transform", XMLPROJECTION = "ATTRIBUTE");

Property description As %String(XMLPROJECTION = "ATTRIBUTE");

Method typeGet() As %String [ Internal, ServerOnly = 1 ]
{
	#dim sc As %Status
	if (i%type '= "") {
		Quit i%type
	}
	
	set cDef = ##class(%Dictionary.CompiledClass).%OpenId(..GetClassname(),,.sc)
	Throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	if (cDef.Super [ "%iKnow.TextTransformation.Transform") {
		Quit "transform"
	} elseif (cDef.Super [ "%iKnow.TextTransformation.Annotate") {
		Quit "annotate"
	}
	
	Quit "<UNDEFINED>"
}

Method displayNameGet() As %String [ Internal, ServerOnly = 1 ]
{
	Set tDisplayName = ..name
	Set tClassName = ..GetClassname()
	If (tClassName '= "") {
		Try {
			Set tDisplayParam = $parameter(tClassName,"DisplayName")
			If (tDisplayParam '= "") {
				Set tDisplayName = tDisplayParam
			}
		}
		Catch {}
	}
	Quit tDisplayName
}

///  Returns the full classname for the operation class referred to in <property>name</property>. 
Method GetClassname() As %String
{
	if (i%name [ ".") {
		quit i%name
	}
	quit "%iKnow.TextTransformation."_i%name
}

}
