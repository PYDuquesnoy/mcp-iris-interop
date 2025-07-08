/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a Text Transformation model, as defined in its <xdata>Transformation</xdata> XData
/// block. See the <method>%Apply</method> and <method>%ApplyBatch</method> methods for ways how
/// to invoke this model on input text.
Class %iKnow.TextTransformation.Definition Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Parameter DEFAULTSECTIONHEADER = "no header";

/// The XML definition for this class' Text Transformation.
/// See also <class>%iKnow.TextTransformation.Model.Model</class>.
XData Transformation [ XMLNamespace = "http://www.intersystems.com/iknow/transformation" ]
{
}

///  This callback method is invoked before a record is processed, after the Output object has been instantiated. 
Method %OnBeforeTransformation(ByRef pOutput As Output) As %Status
{
	quit $$$OK
}

///  This callback method is invoked after a record has been processed, before the Output object is saved. 
Method %OnAfterTransformation(ByRef pOutput As Output) As %Status
{
	quit $$$OK
}

/// Callback method invoked upon the creation of a Section object. 
/// Use this callback to customize behavior upon creating sections. Setting <var>pSection</var> to
/// null will remove the section from the output.
Method %OnCreateSection(ByRef pSection As OutputSection, ByRef pOutput As Output) As %Status
{
	quit $$$OK
}

/// Callback method invoked upon the creation of a KeyValue object. 
/// Use this callback to customize behavior upon creating key-value pairs. Setting <var>pKeyValue</var> 
/// to null will prevent the key-value pair from being added to the output.
Method %OnCreateKeyValue(ByRef pKeyValue As OutputKeyValue, ByRef pOutput As Output) As %Status
{
	quit $$$OK
}

/// Invokes the transformation model on a character stream. See also <method>%Apply</method>.
ClassMethod %ApplyStream(pStream As %Stream.Object, Output pOutput As %iKnow.TextTransformation.Output) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		// convert stream to text array
		kill tTextArray
		set tSC = pStream.Rewind()
		quit:$$$ISERR(tSC)
		while 'pStream.AtEnd {
			set tTextArray($i(tTextArray)) = pStream.ReadLine(,.tSC)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..%Apply(.tTextArray, .pOutput)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Invokes the model defined in <XData>Transformation</XData> on the string <var>pString</var>, identifying
/// sections, headers and key-value pairs as specified in the model. These elements are returned through
/// an <var>pOutput</var> object of the output class specified in the model, defaulting to
/// <class>%iKnow.TextTransformation.Output</class>.</p>
/// <p><var>pString</var> may also be supplied as an array of strings representing consecutive lines of 
/// text (by reference). To invoke the model in batch on a bunch of records, use <method>%ApplyBatch</method>.</p>
ClassMethod %Apply(ByRef pString As %String, Output pOutput As %iKnow.TextTransformation.Output) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		set pOutput = $classmethod(..%GetOutputClass(), "%New")
		set pOutput.ModelClass = $classname()
		set tModel = ..%New()
		if (tModel="") {
			set tSC = $g(%objlasterror)
			quit
		}
		
		set tSC = tModel.%OnBeforeTransformation(.pOutput)
		quit:$$$ISERR(tSC)
		set tSC = tModel.%ApplyInternal(.pString, .pOutput)
		quit:$$$ISERR(tSC)
		set tSC = tModel.%OnAfterTransformation(.pOutput)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Invokes the model specified in <xdata>Transformation</xdata> on all records retrieved by 
/// <var>pResultSet</var>, populating and saving an output object for each record. The first column of
/// <var>pResultSet</var> is used as an identifier and saved as the Ref property of the output object.
/// The second column is assumed to contain the text to be transformed by this model.</p>
/// <p>Note that the output object used for this batch operation should inherit from <class>%Persistent</class>
/// in order for the output to be effectively persisted.</p>
/// <p>See also <method>%Apply</method>.</p>
ClassMethod %ApplyBatch(pResultSet As %ResultSet) As %Status [ CodeMode = objectgenerator, Final, ForceGenerate, GenerateAfter = %GetOutputClass ]
{
	set tSC = $$$OK
	try {
		if %class.Abstract {
			do %code.WriteLine("	quit $$$ERROR($$$GeneralError, ""not available for abstract classes"")")
			quit
		}
		
		set tOutputClass = ..%GetOutputClass()
		set tOutputPersistent = $classmethod(tOutputClass, "%IsA", "%Persistent")
		
		do %code.WriteLine("	set tSC = $$$OK")
		do %code.WriteLine("	try {")
		do %code.WriteLine("		set tModel = ..%New()")
		
		if (tOutputPersistent) {
			do %code.WriteLine("		set tSC = ##class("_tOutputClass_").%SortBegin()")
			do %code.WriteLine("		quit:$$$ISERR(tSC)")
		}
		
		do %code.WriteLine("		while pResultSet.%Next() {")
		do %code.WriteLine("			set tRef = pResultSet.%GetData(1)") // TODO: need more flexibility?
		do %code.WriteLine("			set tText = pResultSet.%GetData(2)") // TODO: need more flexibility?
		
		do %code.WriteLine("			set tOutput = ##class("_tOutputClass_").%New()")
		do %code.WriteLine("			set tOutput.%Ref = tRef")
		do %code.WriteLine("			set tOutput.ModelClass = $classname()")
		
		do %code.WriteLine("			set tSC = tModel.%OnBeforeTransformation(.tOutput)")
		do %code.WriteLine("			quit:$$$ISERR(tSC)")
		do %code.WriteLine("			set tSC = tModel.%ApplyInternal(tText, .tOutput)")
		do %code.WriteLine("			quit:$$$ISERR(tSC)")
		do %code.WriteLine("			set tSC = tModel.%OnAfterTransformation(.tOutput)")
		do %code.WriteLine("			quit:$$$ISERR(tSC)")
		
		if (tOutputPersistent) {
			do %code.WriteLine("			set tSC = tOutput.%Save()")
			do %code.WriteLine("			quit:$$$ISERR(tSC)")
		}
		
		do %code.WriteLine("		}")
		do %code.WriteLine("		quit:$$$ISERR(tSC)")
		
		if (tOutputPersistent) {
			do %code.WriteLine("		set tSC = ##class("_tOutputClass_").%SortEnd()")
			do %code.WriteLine("		quit:$$$ISERR(tSC)")
		}
		
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set tSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  Transforms input strings into a text array representing actual lines of text 
Method %ProcessInput(ByRef pString As %String, Output pTextArray) As %Status [ Internal, Private ]
{
	// transform the input into a line array if still required
	kill pTextArray
	if $d(pString)>1 {
		merge pTextArray = pString
	} else {
		set tSC = ##class(%iKnow.TextTransformation.StringToTextArray).Run(pString, .pTextArray)
		quit:$$$ISERR(tSC) tSC
	}
	quit $$$OK
}

///  Transforms the <var>pOutputArray</var> produced by a sequence of transformations and annotations into an output object. 
Method %ProcessOutput(ByRef pOutputArray, ByRef pOutput As %iKnow.TextTransformation.Output) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		// process output array
		quit:'$g(pOutputArray)
		set tFullText=""
		set tSC = ..%InitializeSection(.pOutput, .tCurrentSection, ..#DEFAULTSECTIONHEADER, ##class(OutputLocation).%New(0))
		quit:$$$ISERR(tSC)
		
		for ii=1:1:pOutputArray {
			set tFullText = tFullText_pOutputArray(ii)_$c(13,10)
			
			if $g(pOutputArray(ii,"type","x")) {
				set tSC = ..%CreateKeyValue(.pOutput, .tCurrentSection, pOutputArray(ii,"x"), 1, ##class(OutputLocation).%New(ii))
				quit:$$$ISERR(tSC)
				continue
			}
			
			if $g(pOutputArray(ii,"type","key")) {
				s key=$o(pOutputArray(ii,"key",""))
				if key="" s key="***"
				set tSC = ..%CreateKeyValue(.pOutput, .tCurrentSection, key, pOutputArray(ii,"key",key), ##class(OutputLocation).%New(ii))
				quit:$$$ISERR(tSC)
				continue
			}

			if $g(pOutputArray(ii,"type","header")) {
				set tSC = ..%FinalizeSection(.pOutput, .tCurrentSection, ##class(OutputLocation).%New(ii-1))
				quit:$$$ISERR(tSC)
				set tSC = ..%InitializeSection(.pOutput, .tCurrentSection, $zstrip(pOutputArray(ii),"<>W"), ##class(OutputLocation).%New(ii))
				continue
			}


			s tCurrentSection.Text = tCurrentSection.Text_pOutputArray(ii)_$c(10,13)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..%FinalizeSection(.pOutput, .tCurrentSection, ##class(OutputLocation).%New(ii))
		quit:$$$ISERR(tSC)
		
		set pOutput.OutputText = tFullText
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Internal method applying the model to a text array. The code for this method is automatically
/// generated based on the mode definition in <xdata>Transformation</xdata>.
Method %ApplyInternal(ByRef pString As %String, Output pOutput As %iKnow.TextTransformation.Output) As %Status [ CodeMode = objectgenerator, Final, ForceGenerate, GenerateAfter = %GetDefinition, Internal, Private ]
{
	set tSC = $$$OK
	try {
		quit:%class.Abstract
		
		#dim tModel as %iKnow.TextTransformation.Model.Model
		set tSC = ..%GetDefinition(%class.Name, .tModel)
		quit:$$$ISERR(tSC)||'$isobject($g(tModel))
		
		// set as local var for other code-generated methods to reuse
		set %ttmodel = tModel
		
		#define WriteLine(%c) do %code.WriteLine($c(9)_%c)
		$$$WriteLine("set tSC = $$$OK")
		$$$WriteLine("try {")
		
		$$$WriteLine("	set tSC = ..%ProcessInput(.pString, .tTextArray)")
		$$$WriteLine("	quit:$$$ISERR(tSC)")
		
		$$$WriteLine("	// executing model: "_tModel.name)
		
		for i = 1:1:tModel.Operations.Count() {
			$$$WriteLine("	// operation "_i)
			#dim tOperation As %iKnow.TextTransformation.Model.Operation = tModel.Operations.GetAt(i)
			if (tOperation.type="annotate") {
				$$$WriteLine("	set tSC = ##class("_tOperation.GetClassname()_").Run(.tTextArray, .tChanged)")
				$$$WriteLine("	quit:$$$ISERR(tSC)")
			} else {
				$$$WriteLine("	set tSC = ##class("_tOperation.GetClassname()_").Run(.tTextArray, .tOutArray, .tChanged)")
				$$$WriteLine("	quit:$$$ISERR(tSC)")
				$$$WriteLine("	kill tTextArray")
				$$$WriteLine("	merge tTextArray = tOutArray")
			}
			$$$WriteLine("")
		}
		
		$$$WriteLine("	set tSC = ..%ProcessOutput(.tTextArray, .pOutput)")
		$$$WriteLine("	quit:$$$ISERR(tSC)")
		
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Initializes a new section object (returned through <var>pSection</var>.
Method %InitializeSection(ByRef pOutput As Output, Output pSection As OutputSection, pHeader As %String, pLocation As OutputLocation) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		set pSection = $classmethod(pOutput.%GetSectionClassname(), "%New")
		set pSection.Header = pHeader
		set pSection.Location = pLocation
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Finalizes a section object <var>pSection</var>, ensuring the <method>%OnCreateSection</method>
/// callback is invoked.
Method %FinalizeSection(ByRef pOutput As Output, ByRef pSection As OutputSection, pLocationEnd As OutputLocation) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		// if this is an empty section, just skip it
		if (pSection.Header = ..#DEFAULTSECTIONHEADER) && (pSection.Text="") 
				&& (pSection.Location.OutputLine=0) {
			quit
		}
		
		set tSC = pSection.Location.SetEndLocation(pLocationEnd)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%OnCreateSection(.pSection, .pOutput)
		quit:$$$ISERR(tSC)
		
		// callback may have decided to skip this one
		if (pSection'="") {
			do pOutput.AddSection(pSection)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Helper method to create a Section object. Custom code in any of the callbacks (such as 
/// <method>%OnBeforeTransformation</method>) may invoke this method to add default sections.
/// Note that no further callbacks are invoked for key-value pairs in the <var>pKeyValues</var> array.
Method %CreateSection(ByRef pOutput As Output, pHeader As %String, pText As %String, pLocation As OutputLocation, ByRef pKeyValues) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		set tSection = $classmethod(pOutput.%GetSectionClassname(), "%New")
		set tSection.Header = pHeader
		set tSection.Text = pText
		set tSection.Location = pLocation
		
		set i = ""
		for {
			set i = $order(pKeyValues(i), 1, tKV)
			quit:i=""
			do tSection.AddKeyValue(tKV)
		}
		
		set tSC = ..%OnCreateSection(.tSection, .pOutput)
		quit:$$$ISERR(tSC)
		
		// callback may have decided to skip this one
		if (tSection'="") {
			do pOutput.AddSection(tSection)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Helper method to create a KeyValue object. Custom code in any of the callbacks (such as 
/// <method>%OnBeforeTransformation</method>) may invoke this method to add default key value pairs.
Method %CreateKeyValue(ByRef pOutput As Output, pHeader As %String, pKey As %String, pValue As %String, pLocation As OutputLocation) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		
		set tKeyValue = $classmethod(pOutput.%GetKeyValueClassname(), "%New")
		set tKeyValue.Header = pHeader
		set tKeyValue.Key = pKey
		set tKeyValue.Value = pValue
		set tKeyValue.Location = pLocation
		
		set tSC = ..%OnCreateKeyValue(.tKeyValue, .pOutput)
		quit:$$$ISERR(tSC)
		
		// callback may have decided to skip this one
		if (tKeyValue'="") {
			do pOutput.AddKeyValue(tKeyValue)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  Returns the class name of the output class for this TT model, as specified in <xdata>Transformation</xdata>. 
ClassMethod %GetOutputClass() As %String [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = %LoadKeysAndHeaders, Internal ]
{
	set tSC = $$$OK
	try {
		set tOutputClass = "%iKnow.TextTransformation.Output"
	
		if $d(%ttmodel, tModel) && $isobject(tModel) && (tModel.outputClass'="") {
			set tOutputClass = tModel.outputClass
			if '$$$defClassDefined(tOutputClass) {
				set tSC = $$$ERROR($$$GeneralError, "Output class does not exist: '"_tOutputClass_"'")
				quit
			}
			if '$classmethod(tOutputClass, "%IsA", "%iKnow.TextTransformation.Output") {
				set tSC = $$$ERROR($$$GeneralError, "Output class does not inherit from %iKnow.TextTransformation.Output")
				quit
			}
		}
		do %code.WriteLine("	quit "_$$$QUOTE(tOutputClass))
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// this is the last generated method, so clean up
	kill %ttmodel
	
	quit tSC
}

Method %OnNew() As %Status [ Internal, ServerOnly = 1 ]
{
	quit ..%LoadKeysAndHeaders()
}

///  Returns the TT model definition specified in <xdata>Transformation</xdata> as a <class>%iKnow.TextTransformation.Model.Model</class> object. 
ClassMethod %GetDefinition(pClassName As %String, Output pDefinition As %iKnow.TextTransformation.conf.Model) As %Status [ Internal ]
{
	set tSC = $$$OK, pDefinition=""
	try {
		set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
		quit:tClassDef=""
		quit:tClassDef.Abstract
		
		set tXDataDef = ##class(%Dictionary.XDataDefinition).%OpenId(pClassName_"||Transformation")
		if (tXDataDef="") || (tXDataDef.Data="") {
			set tSC = $$$ERROR($$$GeneralError, "No Transformation XData block defined")
			quit
		}
		
		set tReader = ##class(%XML.Reader).%New()
		set tSC = tReader.OpenStream(tXDataDef.Data)
		quit:$$$ISERR(tSC)
		
		do tReader.Correlate("Model", "%iKnow.TextTransformation.Model.Model")
		
		if 'tReader.Next(.pDefinition, .tSC) {
			set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError, "Transformation definition does not contain a valid model")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  Loads the key and header sets from the locations specified in <xdata>Transformation</xdata>. 
Method %LoadKeysAndHeaders() As %Status [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = %ApplyInternal, Internal ]
{
	set tSC = $$$OK
	try {
		quit:%class.Abstract
		set tModel = $g(%ttmodel)
		quit:'$isobject(tModel)
		
		#dim tModel as %iKnow.TextTransformation.Model.Model
		
		#define WriteLine(%c) do %code.WriteLine($c(9)_%c)
		$$$WriteLine("set tSC = $$$OK")
		$$$WriteLine("try {")
		
		// TODO: load keys & headers to some local property array so they can be used by operations,
		// rather than having to fetch them from ^IRIS.headers! --> will require changes to consuming 
		// operation code
		
		// key set
		if $isobject(tModel.KeySet) {
			if (tModel.KeySet.type="set") {
				$$$WriteLine("	set tSC = ##class(%iKnow.TextTransformation.HK).ImportKeysFromSet("_$$$QUOTE(tModel.KeySet.name)_")")
				$$$WriteLine("	quit:$$$ISERR(tSC)")
			//} elseif (tModel.KeySet.type="xdata") {
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unimplemented set reference type: '"_tModel.KeySet.type_"'")
				quit
			}
		}
		
		// header set
		if $isobject(tModel.HeaderSet) {
			if (tModel.HeaderSet.type="set") {
				$$$WriteLine("	set tSC = ##class(%iKnow.TextTransformation.HK).ImportHeadersFromSet("_$$$QUOTE(tModel.HeaderSet.name)_")")
				$$$WriteLine("	quit:$$$ISERR(tSC)")
			//} elseif (tModel.HeaderSet.type="xdata") {
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unimplemented set reference type: '"_tModel.HeaderSet.type_"'")
				quit
			}
		}
		
		$$$WriteLine("	quit:$$$ISERR(tSC)")
		
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
