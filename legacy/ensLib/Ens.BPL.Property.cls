/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This defines a property which will appear in the processes context and as such
/// properties may only be defined as elements within a <context> tag. A property MUST
/// have a name. If the 'collection' attribute is set ( either 'array' or 'list')
/// then the property will be automatically instantiated as a collection of that type.
/// For non-collection properties the 'initialexpression' and 'instantiate' attributes 
/// dictate how the object will be intialized. If 'instantiate' is set to 'true' (1), 
/// then a call to new the object will be generated. If an 'initialexpression' is specified 
/// then the result of the expression will be assigned to the object. Note that 'instantiate'
/// should be used to initialize properties of instantible type, whilst 'initialexpression' 
/// should be used to intialize datatype classes such as %String.
Class Ens.BPL.Property Extends Ens.BPL.Node [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<context>
<property name="Index" type="%Integer" initialexpression="6"/>
<property name="Name" type="%string">
<annotation>This is the documentation for this property</annotation>
<parameters>
<parameter name='MAXLEN' value='1024'/>
</parameters>
</property>
<property name="Person" type="Sample.Person" instantiate="true"/>
</context>
}

/// This holds the name of the property
Property Name As %String;

/// This holds the value to assign to the property
Property Type As %String;

/// This holds the (optional) initial expression
Property InitialExpression As %String;

/// This holds the (optional) collection type
/// Collections may be of type 'array' or 'list' only
Property Collection As %String;

/// This holds the (optional) create flag. If set to true then
/// the property will be instantiated in on creation of the containg context
/// class
Property Instantiate As %Boolean;

/// This holds the (optional) parameters
Property Parameters As array Of %String;

/// This holds the user documentation for this property
Property Annotation As %String(MAXLEN = "");

/// Setter for instantiate (true,false,0 or 1 allowed by schema)
Method InstantiateSet(pValue) As %Status
{
	Set i%Instantiate=$Select(pValue="true":1,pValue="false":0,1:pValue)
	Quit $$$OK
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		
		Set tProperty=##class(%Dictionary.PropertyDefinition).%New()
		$$$ASSERT($IsObject(tProperty))
		
		Set tProperty.Name=..Name
		
		#; Adjust sql field name for potential sql reserved word clash
		If $System.SQL.IsReservedWord(tProperty.Name) {
			Set tProperty.SqlFieldName = "_"_tProperty.Name
		}
		
		#; Types is optional
		If ..Type'="" Set tProperty.Type=..Type
		
		#; Initial expression is optional
		If ..InitialExpression'="" Set tProperty.InitialExpression=..InitialExpression
		
		#; Collection is optional
		If ..Collection'="" {
#if $system.Version.GetNumber()>5.0
			// For Ensemble 4.0, we must map the types characterstream and binarystream to %GlobalCharacterStream
			// and %GlobalBinaryStream
			If ..Collection = "characterstream" {
				Set tProperty.Type = "%GlobalCharacterStream"
			} ElseIf ..Collection = "binarystream" {
				Set tProperty.Type = "%GlobalBinaryStream"
			} Else {
				Set tProperty.Collection=..Collection
			}
#else
			// Ensemble 3.X on 5.0.X behavior
			Set tProperty.Collection=..Collection
#endif
		}
		
		#; Add the name to the list of properties to new if required
		If ..Instantiate=1 Do pCompiler.PropertiesToNew.Insert(..Name)
		
		#; Add the parameters if specified
		If ..Parameters.Count() {
			
			Set tKey=..Parameters.Next("")
			While tKey'="" {
				Do tProperty.Parameters.SetAt($ZCVT(..Parameters.GetAt(tKey),"O","HTML"),tKey)
				Set tKey=..Parameters.Next(tKey)
			}
		}
		
		Do pCompiler.Context.Properties.Insert(tProperty)

	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<property name="_$$$EA(..Name))
		If ..Type'="" Do pStream.Write("type="_$$$EA(..Type))
		If ..InitialExpression'="" Do pStream.Write("initialexpression="_$$$EA(..InitialExpression))
		If ..Collection'="" Do pStream.Write("collection="_$$$EA(..Collection))
		If ..Instantiate'="" Do pStream.Write("instantiate="_$$$EA(..Instantiate))
		
		If ..Parameters.Count() || (..Annotation'="") {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do pStream.Write("<annotation><![CDATA[")
				Do pStream.Write(..Annotation)
				Do pStream.WriteLine("]]></annotation>")
			}
			
			If ..Parameters.Count() {
				
				Do pStream.WriteLine("<parameters>")
			
				Set tKey=..Parameters.Next("")
				While tKey'="" {
					Do pStream.WriteLine("<parameter name="_$$$EA(tKey)_" value="_$$$EA(..Parameters.GetAt(tKey))_"/>")
					Set tKey=..Parameters.Next(tKey)
				}
				Do pStream.WriteLine("</parameters>")
			}
			
			Do pStream.WriteLine("</property>")
		} else {
			Do pStream.WriteLine("/>")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the Name
		If ..Name="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"name",..DisplayName()))
		}
				
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Property:"_..Name
}

}
