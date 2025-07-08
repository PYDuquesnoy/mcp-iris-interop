/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a measure within a DeepSee cube.<br/>
/// At query processing time, a measure is treated as if it were a 
/// member of a special dimension called "Measures".
Class %DeepSee.Model.measure Extends (%DeepSee.Model.node, %DeepSee.Model.source) [ Inheritance = right, System = 3 ]
{

/// Cube that this measure belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = measures ];

/// Default aggregate function applied to this measure.<br/>
/// If not specified, the default aggregate for numeric measures is SUM and COUNT for
/// all other types.
Property aggregate As %DeepSee.Datatype.string(VALUELIST = ",COUNT,SUM,MIN,MAX,AVG", XMLPROJECTION = "attribute");

/// This indicates the type of this measure.<br/>
/// The type specifies how this measure is used within MDX processing. The type
/// can be one of the following:
/// <ul>
/// <li>"integer" - the measure contains an integer value that can be aggregated
/// within an MDX query.
/// If no aggregate is specified, then SUM is used.</li>
/// <li>"number" - the measure contains a numeric value that can be aggregated
/// within an MDX query.
/// If no aggregate is specified, then SUM is used.</li>
/// <li>"boolean" - the measure contains a boolean value that can be aggregated
/// within an MDX query.
/// If no aggregate is specified, then COUNT is used (which is equivalent to SUM).</li>
/// <li>"date" - the measure contains a date value (in +$H format). The only aggregates that 
/// can be used with a date measure are MIN, MAX, and AVG.
/// If no aggregate is specified, then MAX is used.</li>
/// <li>"age" - the measure contains an age value (in days). The only aggregates that 
/// can be used with an age measure are MIN, MAX, and AVG.
/// If no aggregate is specified, then AVG is used.</li>
/// <li>"string" - the measure contains a string value. The only aggregate that 
/// can be used with a string measure is COUNT.</li>
/// A string measure can be used as a way to add arbitrary data to a cube's
/// fact table. String measures are not indexed.</li>
/// <li>"text" - similar to a "string" measure, except that it is indexed using a text index.</li>
/// <li>"iKnow" - a text value that is processed and indexed using the iKnow Smart Indexing API.</li>
/// </ul>
/// If not specified then the type will match the source property, as best as possible
/// or be set to "number".<br/>
Property type As %DeepSee.Datatype.string(VALUELIST = ",integer,number,boolean,string,date,age,text,iKnow", XMLPROJECTION = "attribute");

/// The scale value (number of digits following the decimal point) used
/// for numeric measures. If not specified, then the scale of the source property
/// is used, if possible.
Property scale As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// If true, this measure is hidden. That is, it will not be listed among the
/// cube's members within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, this measure can be used to filter results.<br/>
/// Setting this true may result in additional indices being defined for this measure.
Property searchable As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Optional. Units applied to this measure.<br/>
/// This is not currently used.
Property units As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// If this is an "iKnow" measure, then this indicates the type of the source text for this
/// measure:<br/>
/// "string" -- source is a string property or expression,<br/>
/// "stream" -- source is a character stream property,<br/>
/// "file" -- source is a string containing a file name.<br/>
/// "domain" -- source is a string containing the external ID of a text already indexed in
/// a domain identified by the iKnowDomain attribute.<br/>
/// For other measure types, this attribute is ignored.
Property iKnowSource As %DeepSee.Datatype.string(VALUELIST = ",string,stream,file,domain", XMLPROJECTION = "attribute");

/// If this is an "iKnow" measure and iKnowSource="domain", this attribute indicates
/// which domain the text corresponding to this fact is stored in.
Property iKnowDomain As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// If this is an "iKnow" measure, this property can be used to supply additional domain
/// parameters for the corresponding iKnow domain. This should be a semicolon-delimited list
/// of double-colon-delimited parameter-name / parameter-value pairs.
/// For example: "DefaultConfig::Spanish;Mat:DefaultProfile::-1" will force this domain
/// to use the Configuration named "Spanish" and default Matching Profile -1.
/// NOTE: this attribute cannot be used for iKnow-managed domains
Property iKnowParameters As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// If this is an "iKnow" measure, use this property to identify which Term Lists should
/// be loaded as dictionaries for iKnow to match the iKnow measures text contents against.
/// This attribute should contain a comma-separated list of existing Term List names.
/// NOTE: this attribute cannot be used for iKnow-managed domains
Property iKnowDictionaries As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

Property listingFilterValue As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

Property listingFilterOperator As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Define a stable fact number for this measure
Property factNumber As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Test if this measure's definition is valid.
/// As a side-effect, set the aggregate function if not specified.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	Try {
		if ($f(..iKnowDomain,":")) {
			set tSC = $$$ERROR($$$GeneralError, "iKnowDomain cannot contain colon characters")
			quit
		}
		
		if (..type="iKnow") && (..iKnowSource="") {
			set tSC = $$$ERROR($$$GeneralError, "iKnowSource is mandatory for an iKnow measure")
			quit
		}
		
		if (..iKnowParameters'="") && (..iKnowSource="domain") {
			set tSC = $$$ERROR($$$GeneralError, "iKnowParameters can not be set for an iKnow-managed domain (iKnowSource=""domain"")")
			quit
		}
		
		if (..iKnowDictionaries'="") && (..iKnowSource="domain") {
			set tSC = $$$ERROR($$$GeneralError, "iKnowDictionaries can not be set for an iKnow-managed domain (iKnowSource=""domain"")")
			quit
		}
		
		if (..iKnowDomain="") && (..iKnowSource="domain") {
			set tSC = $$$ERROR($$$GeneralError, "iKnowDomain is mandatory for an iKnow-managed domain (iKnowSource=""domain"")")
			quit
		}
		
		
		// n.b. remaining validation and establishing of default value is done
		// at code generation time in %DeepSee.Generator
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tMeasureObj = {}
	
	Try {
		// Perform a series of checks to see if this is AtScale-compatible
		If (..sourceProperty="") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Measure cannot be exported without a sourceProperty:")_..name,$$$msgInfo))
			Set tMeasureObj = ""
			Quit
		}
		If ..disabled {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Measure is disabled and will not be exported:")_..name,$$$msgInfo))
			Set tMeasureObj = ""
			Quit
		}
		
		// Provided format example:
		//  "name": "m_salesamount_sum",
	    //  "displayName": "Sales amount sum",
	    //  "datasetName": "factinternetsales",
	    //  "columnName": "salesamount",
	    //  "aggregation": "SUM",
	    //  "visible": true,
	    //  "description": "Sales amount sum measure description"
		
		Set tMeasureObj.name = "m_"_..name_ $S((..aggregate'=""):"_"_$$$LOWER(..aggregate),1:"")
		Set tMeasureObj.displayName = $S(..displayName'="":..displayName,1:..name)
		Set tMeasureObj.description = ..description
		Set tMeasureObj.datasetName = pAuxiliaryIndex.primaryDataset
		Set tMeasureObj.columnName = ..sourceProperty
		Set tMeasureObj.aggregation = ..%AtScaleConvertAggregate(..aggregate,..type,.tSC)
		If $$$ISERR(tSC) Quit
		
		Do tMeasureObj.%Set("visible",'..hidden,"boolean")		// DP-405037
		Set:(..scale'="") tMeasureObj.precision = ..scale		// DP-406089
		Set:(..formatString'="") tMeasureObj.customFormat = ..formatString		// DP-406089
		
		Set pStatus = ..%AtScaleProcessSourceRef(..sourceProperty,.pAuxiliaryIndex)
		If $$$ISERR(pStatus) Quit
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tMeasureObj=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tMeasureObj
}

}
