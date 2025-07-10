/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

IncludeGenerator (Ensemble, EnsCompiler)

/// This class provides the framework for defining a data transformation by encoding the 
/// operations in the data transform language (DTL)
Class Ens.DataTransformDTL Extends Ens.DataTransform [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Override this parameter to 1 in your DTL subclass to make it log and return all errors encountered
/// while executing the transform. When this parameter is set to 0 the DTL will silently
/// log them as Trace messages with category 'xform'.
Parameter REPORTERRORS As %Boolean = 0;

/// Override this parameter to 1 in your DTL subclass to make it ignore errors resulting from an attempt
/// to use a value from a source property or virtual property that does not exist in the provided source object
Parameter IGNOREMISSINGSOURCE As %Boolean = 0;

/// Override this parameter to 1 in your DTL subclass to prevent 'for each' loops from being implemented when 
/// the property to iterate over is a repeating field and that field is empty
Parameter TREATEMPTYREPEATINGFIELDASNULL As %Boolean = 0;

/// Override this parameter to 1 in your DTL subclass to allow generation of empty segments in target for source segments and properties
/// that are missing in the source object  
Parameter GENERATEEMPTYSEGMENTS As %Boolean = 0;

ClassMethod GetSourceType() As %String [ CodeMode = objectgenerator ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Don't run this method on the base class
		If %compiledclass.Name="Ens.DataTransformDTL" Quit
		
		#; Find XDATA block named DTL
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||DTL")
		If tIndex="" {
			Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,%class.Name,"DTL")
			Quit
		}
		
		#; Get XDATA as a stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
	
		Set tSC=##class(Ens.DTL.Compiler).ParseStream(.tTransform,tStream)
		If $$$ISERR(tSC) Quit
		
		Set %code.Language=$$$sysLangFromBPL(tTransform.Language)
		
		If tTransform.Language=$$$basic {
			Do %code.WriteLine(" Return """_tTransform.SourceClass_"""")
		} else {
			Do %code.WriteLine(" Quit """_tTransform.SourceClass_"""")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod GetSourceDocType() As %String [ CodeMode = objectgenerator ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Don't run this method on the base class
		If %compiledclass.Name="Ens.DataTransformDTL" Quit
		
		#; Find XDATA block named DTL
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||DTL")
		If tIndex="" {
			Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,%class.Name,"DTL")
			Quit
		}
		
		#; Get XDATA as a stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
	
		Set tSC=##class(Ens.DTL.Compiler).ParseStream(.tTransform,tStream)
		If $$$ISERR(tSC) Quit
		
		Set %code.Language=$$$sysLangFromBPL(tTransform.Language)
		
		If tTransform.Language=$$$basic {
			Do %code.WriteLine(" Return """_tTransform.SourceDocType_"""")
		} else {
			Do %code.WriteLine(" Quit """_tTransform.SourceDocType_"""")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod GetTargetType(Output pCreate As %String) As %String [ CodeMode = objectgenerator ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Don't run this method on the base class
		If %compiledclass.Name="Ens.DataTransformDTL" Quit
		
		#; Find XDATA block named DTL
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||DTL")
		If tIndex="" {
			Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,%class.Name,"DTL")
			Quit
		}
		
		#; Get XDATA as a stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
	
		Set tSC=##class(Ens.DTL.Compiler).ParseStream(.tTransform,tStream)
		If $$$ISERR(tSC) Quit
		
		Set %code.Language=$$$sysLangFromBPL(tTransform.Language)
		
		If $$$objectscriptOrPython(tTransform.Language) {
			Do %code.WriteLine(" Set pCreate="""_tTransform.Create_"""")
			Do %code.WriteLine(" Quit """_tTransform.TargetClass_"""")
		} Else {
			Do %code.WriteLine(" pCreate="""_tTransform.Create_"""")
			Do %code.WriteLine(" Return """_tTransform.TargetClass_"""")
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod GetTargetDocType() As %String [ CodeMode = objectgenerator ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Don't run this method on the base class
		If %compiledclass.Name="Ens.DataTransformDTL" Quit
		
		#; Find XDATA block named DTL
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||DTL")
		If tIndex="" {
			Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,%class.Name,"DTL")
			Quit
		}
		
		#; Get XDATA as a stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
	
		Set tSC=##class(Ens.DTL.Compiler).ParseStream(.tTransform,tStream)
		If $$$ISERR(tSC) Quit
		
		Set %code.Language=$$$sysLangFromBPL(tTransform.Language)
		
		If $$$objectscriptOrPython(tTransform.Language) {
			Do %code.WriteLine(" Quit """_tTransform.TargetDocType_"""")
		} else {
			Do %code.WriteLine(" Return """_tTransform.TargetDocType_"""")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod Transform(source As %RegisteredObject, ByRef target As %RegisteredObject, ByRef aux = "") As %Status [ CodeMode = objectgenerator, PublicList = (process, context) ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Don't run this method on the base class
		If %compiledclass.Name="Ens.DataTransformDTL" Quit
		
		#; Find XDATA block named DTL
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||DTL")
		If tIndex="" {
			Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,"DTL",%class.Name)
			Quit
		}
		
		#; Get XDATA as a stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
	
		Set tSC=##class(Ens.DTL.Compiler).CompileStream(tStream,%class,%code)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
