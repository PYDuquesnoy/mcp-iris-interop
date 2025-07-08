/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.Classifier Extends node [ Deprecated, System = 3 ]
{

/// An optional description for this Classifier
Property description As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE");

/// The name of the <class>%iKnow.Classification.Builder</class> class used to create this
/// classifier. (optional)
Property builderClass As %String(XMLPROJECTION = "ATTRIBUTE");

/// The list of categories this classifier will choose from.
Property Categories As list Of Category(XMLPROJECTION = "WRAPPED") [ Required ];

/// A descriptor of the terms to consider for classification.
Property TermDictionary As TermDictionary [ Required ];

/// A wrapper for all the information needed to match the document vector built based on TermDictionary
/// to the different categories this classifier is identifying.
Property ClassificationMethod As ClassificationMethod [ Required ];

/// Optional list of parameters from the Builder instance creating this definition,
/// so it can be used to restore a Builder instance from this definition to further optimize
/// or otherwise refine it.
Property BuilderParameters As list Of BuilderParameter(XMLNAME = "BuilderParameter", XMLPROJECTION = "ELEMENT");

Method %Validate() As %Status
{
	set tSC = $$$OK
	try {
		
		set tCatCount = ..Categories.Count()
		if 'tCatCount {
			set tSC = $$$ERROR($$$GeneralError, "Classification model needs at least one category definition")
			quit
		}
		for i = 1:1:tCatCount {
			set tCatName = ..Categories.GetAt(i).name
			if (tCatName = "") {
				set tSC = $$$ERROR($$$GeneralError, "Category needs to have a name")
				quit
			} elseif $d(tCategories($$$UPPER(tCatName))) {
				set tSC = $$$ERROR($$$GeneralError, "Duplicate category name: '"_tCatName_"'")
				quit
			}
			set tCategories($$$UPPER(tCatName)) = ""
		}
		quit:$$$ISERR(tSC)
		
		merge tInfo("categories") = tCategories
		set tSC = ..ClassificationMethod.%Validate(.tInfo)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GetFromDefinition(pDefinitionClass As %String, Output pModel As %iKnow.Classification.Definition.Classifier, pValidate As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tXData = ##class(%Dictionary.XDataDefinition).%OpenId(pDefinitionClass_"||Classifier")
		if '$isobject(tXData) {
			set tSC = $$$ERROR($$$GeneralError, "No classifier definition found in class '"_pDefinitionClass_"'")
			quit
		}
		
		do tXData.Data.Rewind()
		set tReader = ##class(%XML.Reader).%New()
		set tSC = tReader.OpenStream(tXData.Data)
		quit:$$$ISERR(tSC)
		
		do tReader.Correlate("Classifier","%iKnow.Classification.Definition.Classifier")
		
		kill pModel
		do tReader.Next(.pModel,.tSC)
		quit:$$$ISERR(tSC)
		
		if (pModel="""") {
			set tSC = $$$ERROR($$$GeneralError, "No classifier definition found in class '"_pDefinitionClass_"'")
			quit
		}
		
		if (pValidate) {
			set tSC = pModel.%Validate()
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
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

Method %SaveToClass(pClassName As %String, pOverwriteExisting As %Boolean = 1, pVerbose As %Boolean = 0, pCompile As %Boolean = 1) As %Status
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
	    set tClass.Super = "%iKnow.Classification.Classifier"
	    set tClass.ProcedureBlock = 1
	    
	    set tXData = ##class(%Dictionary.XDataDefinition).%New()
	    set tXData.Name = "Classifier"
	    set tXData.XMLNamespace = "http://www.intersystems.com/iknow/classification"
	    do tClass.XDatas.Insert(tXData)
	    
		set tSC = ..%ToString(.tString)
		quit:$$$ISERR(tSC)
		set tSC = tXData.Data.Write(tString)
		quit:$$$ISERR(tSC)
	    
	    set tSC = tClass.%Save()
	    quit:$$$ISERR(tSC)
	    set tClass="", tXData=""
	    
	    if (pCompile) {
			set tSC = $$CompileRecurse^%apiOBJ(pClassName,$s(pVerbose:"ckd", 1:"ck-d")_" /multicompile=0")
		    quit:$$$ISERR(tSC)
	    }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
