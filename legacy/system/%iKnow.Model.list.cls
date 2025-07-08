/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a given "location" where data to be loaded can be found. The structure
/// of these list objects adheres to what's required to configure and run
/// <class>%iKnow.Source.Lister</class> objects.
Class %iKnow.Model.list Extends %iKnow.Model.nodeWithParameters [ Deprecated, System = 3 ]
{

Property listname As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// The data wrapper this list belongs to
Relationship data As %iKnow.Model.data(XMLPROJECTION = "none") [ Cardinality = one, Inverse = lists ];

/// The Lister class to use for loading data defined in this list element. This class should
/// extend <class>%iKnow.Source.Lister</class>. The Lister class defined here dictates the contents
/// of the <property>parameters</property> property.
Property listerClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// Whether or not to load the data in this list in batch mode.
Property batchMode As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// The name of the <class>%iKnow.Configuration</class> object to use when loading data from this
/// list. This can be a configuration that's registered in the configurations property of the 
/// domain definition this list belongs to, or another configuration that exists on the system.
/// If left empty, the default configuration is used.
Property configuration As %String(MAXLEN = 150, XMLPROJECTION = "attribute");

/// The processor to be used when loading data from this list. If not set, the default for this
/// lister class is used.
Property processor As %iKnow.Model.processor(XMLPROJECTION = "element");

/// The converter to be used when loading data from this list. If not set, no conversions are applied.
Property converter As %iKnow.Model.converter(XMLPROJECTION = "element");

/// If set to 1, this list is not included in the %Build() method.
Property disabled As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Any fixed metadata values to register for each source in the following list definitons
Relationship metadataValues As %iKnow.Model.metadataValue(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = list ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		quit:..disabled
		
		if (..listerClass="") {
			
			set tSC = $$$ERROR($$$GeneralError, "listerClass is a required attribute")
			quit
			
		} else {
			if '##class(%Dictionary.CompiledClass).%ExistsId(..listerClass) ||
				 '$$IsDerivedFrom^%occLibrary(..listerClass,"%iKnow.Source.Lister") {
				set tSC = $$$ERROR($$$IKUnknownLister, ..listerClass)
				quit
			}
		}
		
		// validate parameters
		kill tParams
		set tListerObj = $classmethod(..listerClass,"%New", pDomainId)
		if '$isobject(tListerObj) {
			set tSC = $$$ERROR($$$GeneralError, "Failed to instantiate Lister of class "_..listerClass_$s($g(%objlasterror)'="":": "_$system.Status.GetErrorText(%objlasterror), 1:""))
			quit
		}
		set tHasExpressions = 0
		for i=1:1:..parameters.Count() {
			set tParam = ..parameters.GetAt(i)
			if $isobject(tParam) {
				set tParams($i(tParams)) = tParam.GetValue(.tIsExpression)
				set:tIsExpression tHasExpressions = 1
			} else {
				set x = $i(tParams)
			}
		}
		// BDB393 - only test params if not containing any expressions, as these might well
		// have changed by the time these parameters are actually run anyway
		set:'tHasExpressions tSC = tListerObj.TestParams(tParams...)
		quit:$$$ISERR(tSC)
		
		
		// validate converter and processor
		if $isobject(..processor) {
			set tSC = ..processor.%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		if $isobject(..converter) {
			set tSC = ..converter.%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		
		// validate fixed metadata fiels
		for i=1:1:..metadataValues.Count() {
			set tSC = ..metadataValues.GetAt(i).%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		
		// validate configuration
		if (..configuration'="") && '..%IsExpression(..configuration) && '##class(%iKnow.Configuration).Exists(..configuration) {
			set tFound = 0
			for i = 1:1:pDomainDefinition.configurations.Count() {
				set tFound = (..configuration=pDomainDefinition.configurations.GetAt(i).name)
				quit:tFound
			}
			if 'tFound {
				set tSC = $$$ERROR($$$IKConfigurationNotFound, ..configuration)
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
