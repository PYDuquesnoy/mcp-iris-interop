/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.ClassificationMethod Extends node [ Deprecated, System = 3 ]
{

/// This is the method the classifier will use to match the document vector against the different
/// Categories. Depending on this method, the weights in the CategoryTermWeights vectors will
/// represent different metrics.
Property method As %String(VALUELIST = ",cosineSimilarity,euclideanDistance,naiveBayes,linearRegression,pmml,rules", XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// The local term weight metric to use to build the Document Vector. The default setting (binary)
/// means simple 0s and 1s will be used to identify if the term occurred in the document or not.
/// Some values for <property>method</property> impose restrictions on this property.
Property localTermWeights As %String(VALUELIST = ",linear,binary,logarithmic", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "binary", Required ];

/// The normalization function to apply to the Document Vector.
/// Some values for <property>method</property> impose restrictions on this property.
Property normalization As %String(VALUELIST = ",none,cosine", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "none", Required ];

/// Any global term weights for the terms in the TermDictionary, based on their corpus-wide
/// relevance. Used to weigh the Document Vector.
/// This property cannot be used when <property>method</property> = "naiveBayes".
Property GlobalTermWeights As %DeepSee.PMML.Definition.Util.Array;

/// This matrix contains the term weights within the specific categories of this classifier when
/// <property>method</property> is "cosineSimilarity", "euclideanDistance", "naiveBayes" or "linearRegression".
/// Rows correspond positionally to the categories in the Categories element and columns to
/// the terms in the TermDictionary, appended with any MetadataProperty elements. 
/// The meaning of the "weight" value is dependent on the classification method and might
/// correspond to an actual weight (vector space), a probability (naiveBayes) or coefficient (regression)
Property CategoryTermWeights As %DeepSee.PMML.Definition.Util.Matrix;

/// When <property>method</property>="naiveBayes", this array contains any a-priori probabilities of the
/// categories, used to weigh the per-category term-based probabilities.
Property CategoryWeights As %DeepSee.PMML.Definition.Util.Array;

/// If <property>method</property>="pmml", this element contains the PMML model to be used for categorization
Property PMML As %DeepSee.PMML.Definition.PMML;

/// If <property>method</property>="rules", this element contains the actual decision rules for deriving the category from the text input
Property ClassificationRules As ClassificationRules;

Method %Validate(ByRef pInfo) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..method="pmml") {
			
			if '$isobject(..PMML) {
				set tSC = $$$ERROR($$$GeneralError, "ClassificationMethod needs to contain a PMML element if method='PMML'")
				quit
			}
			set tSC = ..PMML.%ValidatePMML()
			quit:$$$ISERR(tSC)
			
		} elseif (..method="rules") {
			
			if '$isobject(..ClassificationRules) {
				set tSC = $$$ERROR($$$GeneralError, "ClassificationMethod needs to contain a ClassificationRules element if method='rules'")
				quit
			}
			set tSC = ..ClassificationRules.%Validate(.pInfo)
			quit:$$$ISERR(tSC)
			
		} else {
			
			if '$isobject(..CategoryTermWeights) {
				set tSC = $$$ERROR($$$GeneralError, "ClassificationMethod needs to contain a CategoryTermWeights element if method='"_..method_"'")
				quit
			}
			
			if (..method="naiveBayes") && '$isobject(..CategoryWeights) {
				set tSC = $$$ERROR($$$GeneralError, "ClassificationMethod needs to contain a CategoryWeights element if method='naiveBayes'")
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
