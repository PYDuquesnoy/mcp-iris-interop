/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for all Activity nodes. An Activity is an action of some kind which
/// is executed by the BPL runtime
Class Ens.BPL.Activity Extends Ens.BPL.Node [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the name of the activity..For most activities this name is optional
/// but for some it is required e.g. Ens.BPL.Process
Property Name As %String(MAXLEN = 255);

/// This holds the X position of the gui representation of this node
Property XPos As %Integer;

/// This holds the Y position of the gui representation of this node
Property YPos As %Integer;

/// This holds the X position for the associated closing shape of the gui representation of this node
Property XEnd As %Integer;

/// This holds the Y position for the associated closing shape of the gui representation of this node
Property YEnd As %Integer;

/// This holds the 'disabled' status for the activity.
Property Disabled As %Boolean;

/// This holds the unique id for this activity
Property ActivityID As %Integer;

/// This holds the user documentation for this Activity
Property Annotation As %String(MAXLEN = "");

/// This holds the subactivity list
Parameter SubActivities As String;

/// Optional setting. Sets the compilation language at level of activity.
/// To be useful, this will differ from the main BPL language.<br/>
/// Example 1: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Code block activity to accomodate Embedded <em>Python</em> source code.<br/>
/// Example 2: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Assignment activity expression to accomodate Embedded <em>Python</em> code expression.
Property LanguageOverride As %String(VALUELIST = ",python,objectscript,basic");

Method GenerateAnnotation(pStream As %BinaryStream)
{
	Do pStream.Write("<annotation><![CDATA[")
	Do pStream.Write(..Annotation)
	Do pStream.WriteLine("]]></annotation>")
}

/// This generates the common XML attributes for this Activity
Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If ..XPos'="" Do pStream.Write("xpos="_$$$EA(..XPos))
		If ..YPos'="" Do pStream.Write("ypos="_$$$EA(..YPos))
		If ..XEnd'="" Do pStream.Write("xend="_$$$EA(..XEnd))
		If ..YEnd'="" Do pStream.Write("yend="_$$$EA(..YEnd))
		If ..Disabled'=0 Do pStream.Write("disabled=""true""")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	$$$ASSERT("0:Subclass Responsibility")
	Quit "Subclass Responsibility"
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit ..activityName()_":"_$select(..Name="": "<noname>", 1: ..Name)
}

/// Determine whether this Activity is disabled
Method DisabledGet() As %Boolean
{
	If (i%Disabled="true"||(i%Disabled=1)) Quit 1
	Quit 0
}

}
