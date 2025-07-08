/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class represents the output generated upon executing a Text Transformation model defined in a
/// <class>%iKnow.TextTransformation.Definition</class> class. By default, instances of this class are
/// populated to represent the sections and key-value pairs identified in the input text, so they can be
/// accessed and acted upon directly.</p>
/// <p>However, instances of this class are not persisted. To enable persisting TT model output, just
/// create a subclass from this class that also inherits from <class>%Persistent</class> and register 
/// its name through the outputClass attribute of the root model element in your TT model definition. 
/// Subclasses can also refine the rest of the output class by defining additional indices and/or adding 
/// custom properties that can be populated in the callbacks of the TT model definition class.</p>
/// <p>If you choose to refine the child classes <class>OutputSection</class> and <class>OutputKeyValue</class>
/// as well, make sure to update the return value for the <method>%GetSectionClassname</method> and 
/// <method>%GetKeyValueClassname</methods> and update the implementation of the <method>AddSection</method>, 
/// <method>GetSectionCount</method> and <method>GetSectionAt</method> methods accordingly.</p>
Class %iKnow.TextTransformation.Output Extends %RegisteredObject [ Deprecated, System = 4 ]
{

///  Reference to the original record, when this object is populated during an %ApplyBatch() call.  
Property Ref As %RawString;

Property Sections As list Of OutputSection [ Internal ];

/// Any "transform" operations in the TT model may have had an impact on the original input text.
/// This propert contains the final form of the text after processing, which the OutputLine numbers in
/// any <class>OutputLocation</class> location references point to.
Property OutputText As %String(MAXLEN = "");

Property ModelClass As %String(MAXLEN = 200);

Index RefIdx On Ref;

Method %GetSectionClassname() As %String
{
 quit "%iKnow.TextTransformation.OutputSection"
}

Method %GetKeyValueClassname() As %String
{
 quit "%iKnow.TextTransformation.OutputKeyValue"
}

Method AddSection(pSection As OutputSection) As %Status
{
	do ..Sections.Insert(pSection)
	quit $$$OK
}

Method GetSectionCount() As %Integer
{
	quit ..Sections.Count()
}

Method GetSectionAt(pPosition As %Integer) As OutputSection
{
	quit ..Sections.GetAt(pPosition)
}

}
