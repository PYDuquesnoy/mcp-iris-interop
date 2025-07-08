/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  Root element for specifying a Text Transformation model. 
/// See also <class>%iKnow.TextTransformation.Definition</class>.
Class %iKnow.TextTransformation.Model.Model Extends node [ Deprecated, System = 3 ]
{

///  Logical name for this model 
Property name As %String(XMLPROJECTION = "ATTRIBUTE");

///  Name of the output class to be populated when executing this model. 
/// This class should inherit from <class>%iKnow.TextTransformation.Output</class> and, the model is
/// to be applied in batch, also from <class>%Persistent</class>. 
Property outputClass As %String(XMLPROJECTION = "ATTRIBUTE");

///  Ordered list of atomic annotate and transform operations that make up this model. 
Property Operations As list Of Operation(XMLITEMNAME = "Operation", XMLPROJECTION = "WRAPPED");

///  Reference to a set of candidate key strings for identifying key-value pairs. 
Property KeySet As SetReference;

///  Reference to a set of candidate header strings for identifying sections. 
Property HeaderSet As SetReference;

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
	    set tClass.Super = "%iKnow.TextTransformation.Definition"
	    set tClass.ProcedureBlock = 1
	    
	    set tXData = ##class(%Dictionary.XDataDefinition).%New()
	    set tXData.Name = "Transformation"
	    set tXData.XMLNamespace = "http://www.intersystems.com/iknow/transformation"
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
