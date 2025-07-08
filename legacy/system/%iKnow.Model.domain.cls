/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// Model representation of an iKnow domain object. See also <class>%iKnow.Domain</class>
Class %iKnow.Model.domain Extends nodeWithParameters [ Deprecated, System = 3 ]
{

/// The name of the domain, which should be unique within the namespace
Property name As %String(MAXLEN = 150, XMLPROJECTION = "attribute");

/// If set to 0, no domain is generated for this definition, nor is the contents of
/// this &gt;domain&lt; element validated.
Property disabled As %Boolean(XMLPROJECTION = "attribute");

/// If nonempty, objects will be generated representing the various elements in iKnow indexing
/// results in the package named in this attribute. Existing objects will be replaced.
Property objectsPackage As %String(MAXLEN = 150, XMLPROJECTION = "attribute");

/// Wrapper object for all source data locations that should be loaded into this domain.
Property data As %iKnow.Model.data(XMLPROJECTION = "element");

/// Wrapper object for all dictionary data that should be loaded into this domain.
Property matching As %iKnow.Model.matching(XMLPROJECTION = "element");

/// Metadata info for this domain
Property metadata As %iKnow.Model.metadata(XMLPROJECTION = "element");

/// Metrics for this domain
Property metrics As %iKnow.Model.metrics(XMLPROJECTION = "element");

/// The configurations used by this domain
Relationship configurations As %iKnow.Model.configuration(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = domain ];

/// Whether or not to allow custom code to manually create domain objects, add sources, etc,
/// outside of any updates applied by this Domain Definition itself.
/// If set to false (default), only select operations remain available for custom code, such as
/// setting individual metadata values and building metrics.
Property allowCustomUpdates As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Expression elements for use in this domain definition
Relationship expressions As %iKnow.Model.expression(XMLELEMENTREF = 1, XMLNAME = "expression", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = domain ];

/// User Dictionaries for use in any configuration objects declared in this definition
Relationship userDictionaries As list Of %iKnow.Model.userDictionary(XMLELEMENTREF = 1, XMLNAME = "userDictionary", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = domain ];

/// Skiplists for use in this domain
Relationship skiplists As list Of %iKnow.Model.skiplist(XMLELEMENTREF = 1, XMLNAME = "skiplist", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = domain ];

/// Build flags to use for this domain. For advanced use only.
/// This should be a sequence of single-digit numbers representing the build flag values for
/// each flag position. A 0 means never build this index; a 9 means always build this index.
Property buildFlags As %String(MAXLEN = 300, XMLPROJECTION = "attribute") [ Internal ];

/// Validates the domain name and its primary parameters, essential to the creation of the domain.
/// <method>%ValidateContent</method> will be called after the domain is instantiated to perform
/// further validation on &lt;domain&gt; contents, being passed the domains ID
Method %Validate() As %Status
{
	set tSC = $$$OK
	try {
		
		// validate domain name
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "Domain name is a required attribute")
			quit
		}
		
		// validate domain parameters
		kill tNames
		for i = 1:1:..parameters.Count() {
			set tParam = ..parameters.GetAt(i)
			
			if (tParam.name="") {
				set tSC = $$$ERROR($$$GeneralError, "Domain parameter name is required")
				quit
			} else {
				if ($e(tParam.name,1,3)="$$$") {
					set tParamName = $system.iKnow.GetDomainParameterName(tParam.name)
					if (tParamName="") {
						set tSC = $$$ERROR($$$GeneralError, "Unknown domain parameter name: "_tParam.name)
						quit
					}
				} else {
					set tParamName = tParam.name
				}
				
				// BDB679
				if $i(tNames(tParamName))>1 {
					set tSC = $$$ERROR($$$GeneralError, "Domain parameter '"_tParam.name_"' can only be set once")
					quit
				}	
				
				if '$$$IKALLOWUSERSET(tParamName) {
					set tSC = $$$ERROR($$$IKIllegalDomainParameter, tParamName)
					quit
				}
				
				// BDB544
				if tParamName=$$$IKPMATDEFAULTPROFILE {
					set tSC = $$$ERROR($$$GeneralError, "Domain parameter $$$IKPMATDEFAULTPROFILE is not supported for domain definitions, use the defaultProfile attribute in the <matching> element instead")
					quit
				}
			}
			
			if (tParam.value="") {
				set tSC = $$$ERROR($$$GeneralError, "Domain parameter value is required")
				quit
			} else {
				// value is checked when assigning, after %Validate() returns
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// This method validates all static elements of the domain, such as metadata field definitions, 
/// metrics and any configuration and/or user dictionary objects embedded in this domain definition.
Method %ValidateStatic(pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		// validate user dictionaries
		kill tNames
		for i = 1:1:..userDictionaries.Count() {
			set tUD = ..userDictionaries.GetAt(i)
			set tSC = tUD.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
			if $i(tNames(tUD.name))>1 {
				set tSC = $$$ERROR($$$GeneralError, "User dictionary name not unique: '"_tUD.name_"'")
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// validate configurations
		kill tNames
		for i = 1:1:..configurations.Count() {
			set tCFG = ..configurations.GetAt(i)
			set tSC = tCFG.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
			if $i(tNames(tCFG.name))>1 {
				set tSC = $$$ERROR($$$GeneralError, "Configuration name not unique: '"_tCFG.name_"'")
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// validate objectsPackage
		if (..objectsPackage'="") && '$zname(..objectsPackage_".Source",4) {
			set tSC = $$$ERROR($$$GeneralError, "objectsPackage value is not a valid package name")
			quit:$$$ISERR(tSC)
		}
		
		// validate <metadata>
		if $isobject(..metadata) {
			set tSC = ..metadata.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
		}
		
		// validate <metrics>
		if $isobject(..metrics) {
			set tSC = ..metrics.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
		}
		
		// validate <skiplist>
		kill tNames
		for i = 1:1:..skiplists.Count() {
			set tBL = ..skiplists.GetAt(i)
			set tSC = tBL.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
			if $i(tNames(tBL.name))>1 {
				set tSC = $$$ERROR($$$GeneralError, "Skiplist name not unique: '"_tBL.name_"'")
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Valiates the child elements of this domain, including &lt;list&gt; and its descendants. 
/// This method gets passed in the domain ID of the domain being validated, which could be 
/// required for some (nested) checks.
Method %ValidateContent(pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		// validate <data>
		if $isobject(..data) {
			set tSC = ..data.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
		}
		
		// validate <matching>
		if $isobject(..matching) {
			set tSC = ..matching.%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
		}
		
		// validate <expression> elements
		for i = 1:1:..expressions.Count() {
			set tSC = ..expressions.GetAt(i).%Validate(pDomainId, $this)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Outputs this Domain Definition as a %String
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

/// Saves this Domain Definition to a class
Method %SaveToClass(pClassName As %String, pOverwriteExisting As %Boolean = 1, pVerbose As %Boolean = 0, pCompile As %Boolean = 1, pSuper As %String = "%iKnow.DomainDefinition") As %Status
{
	set tSC = $$$OK
	try {
		set tClass = ""
		if $$$defClassDefined(pClassName)
		{
			if 'pOverwriteExisting 
			{
				set tClass = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName,-1,.sc)
				if sc '= $$$OK set tSC = $$$ERROR("Open DomainDefintion Failed") quit
				Set tIndex = tClass.XDatas.FindObjectId(pClassName_"||Domain")
				If tIndex'="" Do tClass.XDatas.RemoveAt(tIndex)
			}
			else
			{
		   		set tSC = $$Delete^%apiOBJ(pClassName,"-d")
		    	quit:$$$ISERR(tSC)
			}
		}
		if tClass = ""
		{
			set tClass = ##class(%Dictionary.ClassDefinition).%New()
	    	set tClass.Name = pClassName
	    	set tClass.Super = pSuper
	    	set tClass.ProcedureBlock = 1
		}
		set tXData = ##class(%Dictionary.XDataDefinition).%New()
	    set tXData.Name = "Domain"
	    set tXData.XMLNamespace = "http://www.intersystems.com/iknow"
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
