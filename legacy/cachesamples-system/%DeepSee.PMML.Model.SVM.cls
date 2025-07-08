/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.SVM Extends AbstractModel [ Abstract, System = 4 ]
{

Parameter SUPPORTSSIMPLEMODE As BOOLEAN [ Internal ] = 1;

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.SupportVectorMachineModel = pDefinition
	
	set tSC = $$$OK
	try {
		
		/// Build %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		do tExecute.Implementation.WriteLine("	set tSC = $$$OK, tSM = i%SimpleMode")
		do tExecute.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9,9)_%c)
		
		set tOneAgainstAll = (tDefinition.classificationMethod = "OneAgainstAll")
		set tCoefficientsOnly = (tDefinition.svmRepresentation = "Coefficients")
		
		$$$WriteLine("// build input vector x")
		set tFieldCount = tDefinition.VectorDictionary.Fields.FieldRefs.Count()
		for i = 1:1:tFieldCount {
			set tFieldRef = tDefinition.VectorDictionary.Fields.FieldRefs.GetAt(i)
			$$$WriteLine("set x("_i_") = "_$$$PropValue("pObservation", tFieldRef.field))	
		}
				
		if 'tCoefficientsOnly {
			$$$WriteLine("")
			$$$WriteLine("// build kernels")
			set tVectorCount = tDefinition.VectorDictionary.numberOfVectors
			/// For PMML models that the numberOfVectors field is not explicitly specified in the Definition
			if (tDefinition.VectorDictionary.numberOfVectors = ""){
				set tVectorCount = tDefinition.VectorDictionary.Instances.Count()
			}
			for i = 1:1:tVectorCount {
				set tVector = tDefinition.VectorDictionary.Instances.GetAt(i)
				set tSC = tDefinition.KernelType.%GetKernelFormula(tVector, .tFormula)
				quit:$$$ISERR(tSC)
				$$$WriteLine("set tKernels("_$$$QUOTE(tVector.id)_") = "_tFormula)
			}
			quit:$$$ISERR(tSC)
		}
		
		
		$$$WriteLine("")
		#dim tSVM As %DeepSee.PMML.Definition.Models.SVM.SupportVectorMachine
		for i = 1:1:tDefinition.SVMs.Count() {
			set tSVM = tDefinition.SVMs.GetAt(i)
			$$$WriteLine("")
			$$$WriteLine("// SVM "_i_": "_tSVM.targetCategory_ $s('tOneAgainstAll:" vs "_tSVM.alternateTargetCategory, 1:""))
			
			set tFormula = ""
			for j = 1:1:tSVM.Coefficients.Coefficients.Count() {
				set tKernel = $s(tCoefficientsOnly:"x("_j_")", 1:"tKernels("_$$$QUOTE(tSVM.SupportVectors.Vectors.GetAt(j).vectorId)_")")
				set tFormula = tFormula _ " + (" _ tSVM.Coefficients.Coefficients.GetAt(j).value _ "*"_tKernel_")"
			}
			$$$WriteLine("set tScore = "_+tSVM.Coefficients.absoluteValue_tFormula)
				
			if tOneAgainstAll {
				$$$WriteLine("set tScores=$g(tScores)+1, tScores(tScore, tScores) = "_$$$QUOTE(tSVM.targetCategory))
			} else {
				set tThreshold = +$s(tSVM.threshold="":tDefinition.threshold, 1:tSVM.threshold)
				$$$WriteLine("set tPredictedClass = $s(tScore<"_+tThreshold_":"_$$$QUOTE(tSVM.targetCategory)_", 1:"_$$$QUOTE(tSVM.alternateTargetCategory)_")")
				$$$WriteLine("set tVotes(tPredictedClass) = $g(tVotes(tPredictedClass))+1, tVotes = tVotes(tPredictedClass), tScores = $g(tScores)+1, tScores(-tVotes, tScores) = tPredictedClass")
			}
		}
		quit:$$$ISERR(tSC)
		
		$$$WriteLine("")
		$$$WriteLine("")
		$$$WriteLine("// resolve scores")
		$$$WriteLine("set tBestScore = $order(tScores(""""))")
		$$$WriteLine("set x = $order(tScores(tBestScore, """"), 1, tBestCategory)")
		
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tBestCategory")
		quit:$$$ISERR(tSC)
		
		
		do tExecute.Implementation.WriteLine("	} catch (ex) {")
		do tExecute.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tExecute.Implementation.WriteLine("	}")
		do tExecute.Implementation.WriteLine("	quit tSC")
		do pClass.Methods.Insert(tExecute)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

}
