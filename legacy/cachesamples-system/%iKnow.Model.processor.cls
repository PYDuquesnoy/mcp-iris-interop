/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a specific <class>%iKnow.Source.Processor</class> to use when loading
/// the contents of a <class>%iKnow.Model.list</class>. 
Class %iKnow.Model.processor Extends %iKnow.Model.nodeWithParameters [ Deprecated, System = 3 ]
{

/// The class of the Processor to use, which should extend <class>%iKnow.Source.Processor</class>.
/// The actual Processor class dictates the contents of the <property>parameters</property> property
/// for this element.
Property processorClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..processorClass="") {
			// this is fine, we'll just use the default for this Lister
		} else {
			if '##class(%Dictionary.CompiledClass).%ExistsId(..processorClass) ||
				'$$IsDerivedFrom^%occLibrary(..processorClass,"%iKnow.Source.Processor") {
				set tSC = $$$ERROR($$$IKInvalidProcessor, ..processorClass)
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
