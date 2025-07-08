/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

Class %DeepSee.PMML.Definition.PMML Extends node [ System = 4 ]
{

Property version As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:string") [ Required ];

Property Header As Header(XMLPROJECTION = "ELEMENT");

Property MiningBuildTask As list Of MiningBuildTask(XMLPROJECTION = "ELEMENT");

Property DataDictionary As DataDictionary(XMLPROJECTION = "ELEMENT") [ Required ];

Property TransformationDictionary As TransformationDictionary(XMLPROJECTION = "ELEMENT");

Property Models As list Of %DeepSee.PMML.Definition.Models.AbstractModel(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		// BDB839 - track transformation dictionary
		set %PMMLTransformations = ..TransformationDictionary
		
		// validate field names used in this PMML definition, starting with reserved names
		kill tNames
		do ##class(%DeepSee.PMML.Definition.Util.Functions).AddToDictionary(.tNames)
		
		if '$isobject(..DataDictionary) {
			set tSC = $$$ERROR($$$GeneralError, "<DataDictionary> is a required element")
			quit
		}
		
		// first build basic dictionary based on ..DataDictionary
		set tSC = ..DataDictionary.%GetDictionary(.tNames)
		quit:$$$ISERR(tSC)
		
		// then validate and append using ..TransformationDictionary
		if $isobject(..TransformationDictionary) {
			set tSC = ..TransformationDictionary.%ValidateNames(.tNames)
			quit:$$$ISERR(tSC)
		}
		
		// now validate model by model
		for i = 1:1:..Models.Count() {
			set tSC = ..Models.GetAt(i).%ValidateNames(.tNames)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %Create(pVersion As %String, pDescription As %String = "", pApplication As %String = "") As PMML
{
	set pmml = ..%New()
	set pmml.version = pVersion
	set pmml.Header = ##class(%DeepSee.PMML.Definition.Header).%New()
	set pmml.Header.description = pDescription
	set pmml.Header.Timestamp = ##class(%DeepSee.PMML.Definition.HeaderTimestamp).%New()
	set pmml.Header.Timestamp.value = $zdt($h)
	if (pApplication'="") {
		set pmml.Header.Application = ##class(%DeepSee.PMML.Definition.HeaderApplication).%New()
		set pmml.Header.Application.name = pApplication
	}
	set pmml.DataDictionary = ##class(%DeepSee.PMML.Definition.DataDictionary).%New()
	set pmml.TransformationDictionary = ##class(%DeepSee.PMML.Definition.TransformationDictionary).%New()
	quit pmml
}

Method %ToString(Output pString As %String, pFormatted As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		
		set tSC = ..XMLExportToString(.pString)
		quit:$$$ISERR(tSC)
		
		set:pFormatted pString = ..FormatXML(pString)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %FromString(Output pModel As %DeepSee.PMML.Definition.PMML, pString As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tReader = ##class(%XML.Reader).%New()
		set tReader.SAXFlags = $$$SAXNOVALIDATION // BDB738
		set tSC = tReader.OpenString(pString)
		quit:$$$ISERR(tSC)
		
		do tReader.Correlate("PMML", "%DeepSee.PMML.Definition.PMML")
		
		if 'tReader.Next(.pModel, .tSC) && $$$ISOK(tSC) {
			set tSC = $$$ERROR($$$GeneralError, "No PMML element in string")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %SaveToClass(pClassName As %String, pOverwriteExisting As %Boolean = 1, pVerbose As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		// delete any existing class
		if $$$defClassDefined(pClassName) {
			if 'pOverwriteExisting {
				set tSC = $$$ERROR($$$ClassNameExists, pClassName)
				quit
			}
		    set tSC = $$Delete^%apiOBJ(pClassName,"-d")
		    quit:$$$ISERR(tSC)
		}
	    
	    set tClass = ##class(%Dictionary.ClassDefinition).%New()
	    set tClass.Name = pClassName
	    set tClass.Super = "%DeepSee.PMML.Definition"
	    set tClass.ProcedureBlock = 1
	    
	    set tXData = ##class(%Dictionary.XDataDefinition).%New()
	    set tXData.Name = "PMML"
	    set tXData.XMLNamespace = "http://www.intersystems.com/deepsee/pmml"
	    do tClass.XDatas.Insert(tXData)
	    
		set tSC = ..%ToString(.tString)
		quit:$$$ISERR(tSC)
		set tSC = tXData.Data.Write(tString)
		quit:$$$ISERR(tSC)
	    
	    set tSC = tClass.%Save()
	    quit:$$$ISERR(tSC)
	    set tClass="", tXData=""
	    
	    set tSC = $system.OBJ.Compile(pClassName, $s(pVerbose:"ckd", 1:"ck-d"))
	    quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Some basic XML formatting
/// Note: this expects nicely formatted attribute content and no surprises in CDATA !
ClassMethod FormatXML(pString As %String) As %String [ Internal, Private ]
{
	set tString = "", tPrevPos=0
	for {
		set tPos = $find(pString,"<",tPrevPos)
		if 'tPos {
			set tString = tString _ $e(pString,tPrevPos,*)
			quit
		}
				
		// first add tag content, if any
		if tPrevPos && (tPrevPos<tPos-2) {
			set tString = tString_$e(pString,tPrevPos,tPos-2)
		}
		
		// catch CDATA
		if ($e(pString,tPos,tPos+6)="!CDATA[") {
			set tEndPos = $find(pString,"]]>",tPos)
			set tString = tString_$e(pString,tPos-1,tEndPos-1)
			set tPrevPos = tEndPos
			set tLastOpenTag = ""
			continue
		}
		
		// process normal tags
		set tFirstSpace = $find(pString," ",tPos), tFirstClose = $find(pString,">",tPos)
		set tTag = $e(pString,tPos,$s(tFirstSpace&&(tFirstSpace<tFirstClose):tFirstSpace, 1:tFirstClose)-2)
		
		// check if we can immediately close the tag
		set tClosing = $e(pString,tFirstClose,tFirstClose+$l(tTag)+2)
		if (tClosing = ("</"_tTag_">")) || (tClosing = ("</"_tTag_" ")) {
			set tString = tString _ $e(pString,tPos-1,tFirstClose-2) _ " />"_$c(13,10)
			set tPrevPos = $find(pString,">",tFirstClose)
		} else {
			// just append tag
			set tString = tString _ $e(pString,tPos-1,tFirstClose-1)
			set tPrevPos = tFirstClose
			
			if ($e(pString,tFirstClose)="<") && ($e(pString,tFirstClose,tFirstClose+7)'="<!CDATA[") {
				set tString = tString _ $c(13,10)
			}
		}
	}
	quit tString
}

}
