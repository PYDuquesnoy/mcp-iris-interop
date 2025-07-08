/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %PMML

IncludeGenerator %PMML

/// This class represents a PMML model as defined in the PMML XData block of a <class>%DeepSee.PMML.Definition</class> class.
Class %DeepSee.PMML.Model.AbstractModel Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// The name of the <class>%DeepSee.PMML.Definition</class> class defining this PMML model.
Parameter DEFINITIONCLASS As CLASSNAME [ Internal ];

/// The name of the root <class>%DeepSee.PMML.Data</class> class for this model's PMML definition
Parameter DATACLASS As CLASSNAME;

/// The name of the <class>%DeepSee.PMML.ModelInput</class> class for this model
Parameter INPUTCLASS As CLASSNAME;

/// The name of the <class>%DeepSee.PMML.ModelOutput</class> class for this model
Parameter OUTPUTCLASS As CLASSNAME;

/// The name of this model as defined in the PMML definition
Parameter MODELNAME As STRING;

/// The field in <parameter>DATACLASS</parameter> predicted by this model.
Parameter PREDICTEDFIELD As STRING;

/// How the weighting info in this models trace output needs to be interpreted.
/// Either of:
/// <ul>
/// 	<li>"none": only rank info available</li>
/// 	<li>"tree": trace info is a sequence of tree nodes leading to the prediction</li>
/// 	<li>"add": additive contributions (total score might be a function of this sum)</li>
/// 	<li>"multiply": multiplicative contributions (total score might be a function of this product)</li>
/// </ul>
Parameter TRACEWEIGHTTYPE As STRING [ Internal ] = "none";

/// This parameter defines whether the model type implementation supports "simple mode",
/// with simple array data structures rather than objects used to pass around observation data.
/// This parameter is for internal use only.
Parameter SUPPORTSSIMPLEMODE As BOOLEAN [ Internal ] = 0;

/// Whether or not to use simple arrays to pass observation data around internally.
/// While faster, data dictionaries with derived fields or requiring specific treatment of 
/// certain values, as well as certain model types, cannot use simple mode. In these cases
/// the <parameter>SUPPORTSSIMPLEMODE</parameter> is set to 0. 
Property SimpleMode As %Boolean [ InitialExpression = {..#SUPPORTSSIMPLEMODE}, Internal ];

/// Whether or not to generate trace information in the output object.
Property Tracing As %Boolean [ InitialExpression = 0 ];

/// For classification models only.
/// If set to 1, the probabilities of each class will be available from the output object,
/// regardless of the OutputField settings in the definition.
Property KeepAllClassProbabilities As %Boolean [ InitialExpression = 0, Internal ];

/// <p>This method is called as part of compiling a <class>%DeepSee.PMML.Definition</class> Model node and
/// adds the appropriate properties, methods and other constructs to the model class
/// <var>pClass</var>. Subclasses are free to forward (parts of) this activity as they see fit and
/// can even change the superclass of <var>pClass</var>, as long as it remains a subclass of
/// this class.</p>
/// <p>The following class parameters are already defined in <var>pClass</var>:
/// <ul>
///  <li>DATACLASS</li>
///  <li>INPUTCLASS</li>
///  <li>OUTPUTCLASS</li>
///  <li>MODELNAME</li>
/// </ul>
ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	quit $$$OK
}

/// Returns the name of this model (similar to <parameter>MODELNAME</parameter>)
ClassMethod %GetName() As %String [ CodeMode = expression, Final, ForceGenerate ]
{
..#MODELNAME
}

ClassMethod %GetDataClassName() As %String [ CodeMode = expression, Final, ForceGenerate ]
{
..#DATACLASS
}

ClassMethod %GetInputClassName() As %String [ CodeMode = expression, Final, ForceGenerate ]
{
..#INPUTCLASS
}

ClassMethod %GetOutputClassName() As %String [ CodeMode = expression, Final, ForceGenerate ]
{
..#OUTPUTCLASS
}

ClassMethod %GetPredictedField() As %String [ CodeMode = expression, Final, ForceGenerate ]
{
..#PREDICTEDFIELD
}

/// Builds a <class>%DeepSee.PMML.ModelInput</class> object based on the root <class>%DeepSee.PMML.Data</class>
/// for this PMML definition.
ClassMethod %GetInputObject(pData As %DeepSee.PMML.Data) As %DeepSee.PMML.ModelInput [ CodeMode = objectgenerator, Final ]
{
	if (%class.Abstract) {
		do %code.WriteLine("	quit """"")
	} else {
		do %code.WriteLine("	quit ##class(" _ %parameter("INPUTCLASS")_").%New(pData)")
	}
}

/// To be implemented by subclasses
Method %ExecuteModelInternal(ByRef pInput As %DeepSee.PMML.ModelInput, Output pOutput As %DeepSee.PMML.ModelOutput) As %Status [ Abstract, Private ]
{
	quit $$$OK
}

/// This method runs the model against a fact from the DeepSee fact table of a cube for which
/// an &lt;X-DeepSeeDataSource&gt; element defines a mapping from the cube's measures and
/// dimensions to the Data Fields in the PMML definition. If <var>pDataSource</var> is null, 
/// the first DataSource of the model definition is expected to contain this DeepSee-to-PMML mapping.</p>
Method %ExecuteModelDeepSee(pFactId As %Integer, Output pOutput As %DeepSee.PMML.ModelOutput, pDataSource As %String = "") As %Status [ Final ]
{
	set tSC = $$$OK, pOutput = ""
	try {
		
		set tSC = $classmethod(..#DATACLASS, "%CreateFromDeepSee", pFactId, .tObservation, pDataSource)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%ExecuteModel(.tObservation, .pOutput)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Executes this model for a given <class>%DeepSee.PMML.Data</class> data object.
/// As an alternative to providing the actual Data Class (or model input class) for this model, it
/// is also possible to supply a simple array containing the data field values indexed by field name.</p>
/// <p>See also <class>%DeepSee.PMML.Utils</class> for details about running a model against a
/// whole set of records at once, writing the corresponding results to a table.</p>
Method %ExecuteModel(ByRef pData As %DeepSee.PMML.Data, Output pOutput As %DeepSee.PMML.ModelOutput) As %Status [ Final ]
{
	set tSC = $$$OK, pOutput = ""
	try {
		
		if '$d(pData) {
			set tSC = $$$ERROR($$$GeneralError, "supplied data object is empty")
			quit
		}
		
		// BDB731 - check if we can use "simple mode"
		if 'i%SimpleMode {
			
			// if the data comes in as an array, try to turn it into a data class
			if $d(pData)>1 {
				set tData = $classmethod(..#INPUTCLASS, "%CreateFromArray", .pData, .tSC)
				quit:$$$ISERR(tSC)
			}
			
			// check if this is the right data class
			elseif '$isobject(pData) {
				
				set tSC = $$$ERROR($$$GeneralError, "supplied variable is not an object or array")
				quit
				
			} elseif 'pData.%Extends(..#DATACLASS) {
				
				// BDB717 - leverage %GetAsArray code if possible
				if pData.%Extends("%DeepSee.PMML.Data") {
					set tSC = pData.%GetAsArray(.tArray)
					quit:$$$ISERR(tSC)
					set tData = $classmethod(..#INPUTCLASS, "%CreateFromArray", .tArray, .tSC)
					quit:$$$ISERR(tSC)
				} else {
					set tData = $classmethod(..#INPUTCLASS, "%CreateFromObject", pData, .tSC)
					quit:$$$ISERR(tSC)
				}
				
			} 
			
			// if pData is not a model-specific data class, convert it
			elseif 'pData.%Extends(..#INPUTCLASS) {
				set tData = ..%GetInputObject(pData)
				if (tData="") { set tSC = %objlasterror  quit }
			}
			
		} else {
			
			// BDB731 - check if this is already an array
			if $d(pData) > 1 {
				
				// BDB850 - append & validate
				set tSC = $classmethod(..#INPUTCLASS, "%BuildData", .pData, .tCleanData)
				quit:$$$ISERR(tSC)
				
				set tSC = ..%ExecuteModelInternal(.tCleanData, .pOutput)
				quit
				
			// BDB731 - if not, convert to simple array
			} elseif '$isobject(pData) {
				set tSC = $$$ERROR($$$GeneralError, "supplied variable is not an object or array")
				quit
			} elseif pData.%Extends("%DeepSee.PMML.Data") {
				set tSC = pData.%GetAsArray(.tData)
				quit:$$$ISERR(tSC)
			} else {
				// if an unknown object, convert to input object and then extract array
				set tObjData = $classmethod(..#INPUTCLASS, "%CreateFromObject", pData, .tSC)
				quit:$$$ISERR(tSC)
				set tSC = tObjData.%GetAsArray(.tData)
				quit:$$$ISERR(tSC)
				set tSC = $$$ERROR($$$GeneralError, "unsupported input object for this model")
				quit
			}
		}
			
		// now forward to the real execution method
		set tSC = ..%ExecuteModelInternal(.tData, .pOutput)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the name of the field whose value is predicted by this model. To be overridden/refined
/// by subclasses
ClassMethod %GetPredictedFieldFromDef(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %String [ Internal ]
{
	do ..%GetPredictedFieldsFromDef(pDefinition, .tFields)
	quit $g(tFields(1))
}

ClassMethod %GetPredictedFieldsFromDef(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, Output pAllFields) As %Status [ Internal ]
{
	kill pAllFields
	for i = 1:1:pDefinition.MiningSchema.MiningFields.Count() {
		set tField = pDefinition.MiningSchema.MiningFields.GetAt(i)
		if $$$PMMLusageTypeIsTarget(tField.usageType) {
			set pAllFields($i(pAllFields)) = tField.name
		}
	}
	if '$d(pAllFields) && $isobject(pDefinition.Output.OutputFields) {
		for i = 1:1:pDefinition.Output.OutputFields.Count() {
			set tOutputField = pDefinition.Output.OutputFields.GetAt(i)
			if (tOutputField.feature="predictedValue") {
				set pAllFields($i(pAllFields)) = $s(tOutputField.targetField="":tOutputField.name, 1:tOutputField.targetField)
			}
		}
	}
	
	// BDB827: predicted fields might be inherited from parent model
	if '$d(pAllFields) && $d(%PMML("CurrentModel"),tCurrentModel) { // tap into compile-time context
		set tCurrentModelName = %PMML("CurrentModel",tCurrentModel)
		if $d(%PMML("Models",$$$UPPER(tCurrentModelName),"parent"),tParentModelName) {
			merge tParentTargets = %PMML("Classes",$$$UPPER(%PMML("Models",$$$UPPER(tParentModelName))),"targetFields")
			set tFieldName = ""
			for {
				set tFieldName = $order(tParentTargets(tFieldName))
				quit:tFieldName=""
				set pAllFields($i(pAllFields)) = tFieldName
			}
		}
	}
	
	quit $$$OK
}

ClassMethod %AppendImplicitOutputFields(ByRef pPredictedFields) As %Status [ Internal ]
{
	quit $$$OK
}

/// Returns basic info about the data field predicted by this model.
ClassMethod %GetPredictedFieldInfo(Output pFieldName As %String, Output pDataType As %String, Output pOpType As %String) As %Status
{
	quit $$$OK
}

ClassMethod %PopulateOutputObject(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pMethod As %Stream.Object, pPredictedValueVar As %String = "tPredictedValue") As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set tSC = $$$OK
	try {
		$$$WriteLine("")
		$$$WriteLine("set pOutput = $classmethod(..#OUTPUTCLASS, ""%New"")")
		
		set tPredictedField = ..%GetPredictedFieldFromDef(pDefinition)
		if $isobject(pDefinition.Output) {
			for i = 1:1:pDefinition.Output.OutputFields.Count() {
				#dim tOutputField As %DeepSee.PMML.Definition.OutputField = pDefinition.Output.OutputFields.GetAt(i)
				continue:tOutputField.segmentId'=""
				
				set tTargetField = tOutputField.targetField
				if (tTargetField'="") {
					if (tTargetField'=tPredictedField) {
						set tSC = $$$ERROR($$$GeneralError, "OutputField has a targetField that does not correspond to this model's target field")
						quit
					}
				} else {
					set tTargetField = tPredictedField
				}
				
				if (tOutputField.feature = "predictedValue") {
					
					set tFeatureValueVar = pPredictedValueVar
					
				} elseif (tOutputField.feature = "transformedValue") {
					
					set tExprCode = tOutputField.Expression.%GetComputeCode(.tInline, pPredictedValueVar)
					if (tInline) {
						set tFeatureValueVar = tExprCode
					} else {
						$$$WriteLine("")
						$$$WriteLine("// compute code for expression")
						$$$WriteLine("set tValue = "_pPredictedValueVar_", tStatus = $s("_pPredictedValueVar_"="""":""missing"", 1:""valid"")")
						do pMethod.WriteLine(tExprCode)
						$$$WriteLine("")
						set tFeatureValueVar = "tValue"
					}
						
				} else {
					
					set tFeatureValueVar = "tFeatureValue"
					set tSC = ..%OnGetOutputFeature(pMethod, pDefinition, tOutputField, .tFeatureValueVar, .tSupported)
					quit:$$$ISERR(tSC)
					
					// feature is not supported!
					if 'tSupported {
						
						// some fallback options for select features
						if (tOutputField.feature = "predictedDisplayValue") {
							$$$WriteLine("set "_tFeatureValueVar_" = pOutput.%GetDisplayValue("_$$$QUOTE(tPredictedField)_", "_pPredictedValueVar_")")
						} else {
							set tSC = $$$ERROR($$$GeneralError, "Output field '"_tOutputField.name_"' with feature '"_tOutputField.feature_"' not supported for model type '"_$piece($classname(pDefinition),".",*)_"'")
							quit
						}
					}
					
				}
				$$$WriteLine("set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tFeatureValueVar)
				
			}
			quit:$$$ISERR(tSC)
		} else {
			$$$WriteLine("set pOutput."_$$$PROPERTYNAME(tPredictedField)_" = "_pPredictedValueVar)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Write code to compute a nontrivial feature for <var>pOutputField</var> to <var>pMethod</var>,
/// setting the value to a variable named <var>pFeatureValue</var> (can be updated). The features
/// "predictedValue" and x are already taken care of.
ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	set pSupported = 0
	quit $$$OK
}

ClassMethod %IsOutputFieldSupported(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, Output pSC As %Status) As %Boolean [ Internal ]
{
	set pSC = $$$OK
	set pSC = ..%OnGetOutputFeature(##class(%Stream.TmpCharacter).%New(), pDefinition, pOutputField, "dummy", .tSupported)
	quit tSupported
}

ClassMethod %GetDefinition(Output pModel As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
		#dim tPMML As %DeepSee.PMML.Definition.PMML
		set tSC = $classmethod(..#DEFINITIONCLASS, "%GetDefinition", .tPMML)
		quit:$$$ISERR(tSC)
		
		for i = 1:1:tPMML.Models.Count() {
			if (tPMML.Models.GetAt(i).modelName = ..#MODELNAME) {
				set pModel = tPMML.Models.GetAt(i)
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %PopulateTrace(ByRef pOutput As %DeepSee.PMML.ModelOutput, ByRef pWeights) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		set tWeight = ""
		for {
			set tWeight = $order(pWeights(tWeight))
			quit:tWeight=""
			
			set i = ""
			for {
				set i = $order(pWeights(tWeight, i), 1, tInfo)
				quit:i=""
				
				set pOutput.%Trace($i(pOutput.%Trace)) = $li(tInfo,1,2) _ $lb($i(tRank)) _ $li(tInfo,3,4)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Prints the trace information for this model type in user-friendly HTML.
/// To be refined by subclasses based on the information available for that model type.
Method %DrawTraceInfo(pOutput As %DeepSee.PMML.ModelOutput) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		quit:$g(pOutput)=""
        quit:$$$ISERR(pOutput.%GetTracingInfo(.tTrace))
        
        if (..#TRACEWEIGHTTYPE'="none") {
	        set tMaxWeight = "", tMinWeight = ""
	        set tHasPos = 0, tHasNeg = 0
	        for i = 1:1:tTrace {
		        set tWeight = $lg(tTrace(i),4)
		        continue:'tWeight
		        if (tWeight > 0) {
			        set tHasPos = 1
		        } else {
			        set tHasNeg = 1
		        }
		        set tWeights(tWeight) = ""
		        set tWeight = $zabs(tWeight)
		        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
		        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
	        }
        	
	        set tMaxBarWidth = 100, tMinBarWidth = 5
	        if tHasPos && tHasNeg {
		        set tMax = $o(tWeights(""),-1), tMin = $o(tWeights(""))
		        set tMaxPosBarWidth = (tMaxBarWidth * tMax / (tMax + $zabs(tMin))) \ 1
		        set tMaxNegBarWidth = (tMaxBarWidth * $zabs(tMin) / (tMax + $zabs(tMin))) \ 1
	        }
        }
        
        &html<<table width="100%">>
        if (..#TRACEWEIGHTTYPE = "tree") {
	        set tSpacerWidth = 0
        } elseif (..#TRACEWEIGHTTYPE = "none") {
		    &html<<tr><th>Rank</th><th>Info</th></tr>>
        } else {
		    &html<<tr><th>Info</th><th>Contribution</th></tr>>
        }
	    for i = 1:1:tTrace {
	        set tFields = $lts($lg(tTrace(i),1))
	        set tValues = $lts($lg(tTrace(i),2))
	        set tRank = $lg(tTrace(i),3)
	        set tWeight = $normalize($lg(tTrace(i),4),4)
	        set tInfo = $lg(tTrace(i),5)
	        
	        set tInfo = $s(tInfo="":tFields, 1:tInfo)
	        if tWeight && (..#TRACEWEIGHTTYPE'="none") && (..#TRACEWEIGHTTYPE'="tree") {
		        
		        if (tHasPos && tHasNeg) {
			        
			        if tWeight>0 {
				        set tWidth = tMaxPosBarWidth * tWeight / tMax
				        set tWeight = "<td width="""_(tMaxNegBarWidth+tMinBarWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_((tWidth+tMinBarWidth)\1)_""" title="""_tWeight_""" style=""background-color: #9cfa7d; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth-(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
			        } else {
				        set tWidth = tMaxNegBarWidth * tWeight / $zabs(tMin)
				        set tWeight = "<td width="""_(tMaxNegBarWidth-$zabs(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_($zabs(tWidth\1)+tMinBarWidth)_""" title="""_tWeight_""" style=""background-color: #eea17d; border-right:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth+tMinBarWidth)_""" ><img src=""images/spacer.gif"" border=""0"" /></td>"
			        }
			        
		        } else {
			        set tWidth = (tMaxBarWidth * tWeight / (tMaxWeight-tMinWeight)) \ 1
			        set tWeight = "<td width="""_($zabs(tWidth)+tMinBarWidth)_""" title="""_tWeight_""" style=""background-color: "_$s(tWidth>0:"#9cfa7d;", 1:"#eea17d;")_"; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxBarWidth-tWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
		        }
		        
		        set tWeight = "<table height=""15""><tr>"_tWeight_"</tr></table>"
		        
	        } else {
		        set tWeight=""
	        }
	        
	        if (..#TRACEWEIGHTTYPE = "tree") {
		        &html<<tr><td><img src="images/spacer.gif" width="#(tSpacerWidth)#" height="1" /><img src="images/line-ne.gif" style="vertical-align:text-top;" /> #(tInfo)#</td></tr>>
		        set tSpacerWidth = $i(tSpacerWidth,30)
	        } elseif (..#TRACEWEIGHTTYPE = "none") {
		        &html<<tr><td>#(tRank)#</td><td>#(tInfo)#</td></tr>>
	        } else {
		        &html<<tr><td>#(tInfo)#</td><td>#(tWeight)#</td></tr>>
	        }
        }
        &html<</table>>
        
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method SimpleModeSet(pValue As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	if (pValue && '..#SUPPORTSSIMPLEMODE) {
		quit $$$ERROR($$$GeneralError, "This model does not support simple mode")
	}
	set i%SimpleMode = pValue
	quit $$$OK
}

}
