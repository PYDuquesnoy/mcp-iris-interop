/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.LDA Extends (%RegisteredObject, Base) [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.LDA;

Property tableConfig As %DeepSee.extensions.modelling.conf.Table;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.LDA) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tableConfig As %DeepSee.extensions.modelling.conf.Table
	
	Try {
		set ..config = conf

		set sc = ##class(Processor).readConfig(..config.ClassifierClass, "Table", "Table", .tableConfig)
		if ($$$ISERR(sc)) {
			set sc = $$$ERROR($$$GeneralError,"Can not determine outcome column: "_$system.Status.GetErrorText(sc))
			Quit
		}
		
		set ..tableConfig = tableConfig
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method apply() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim lda As %DeepSee.extensions.utils.LDA
	#dim g As %String
	
	Try {
		set sc = ..getLDAModel(.lda)
		Quit:$$$ISERR(sc)
		
		w "Training Set Confusion Matrix:", !
		set sc = lda.printConfusionMatrix()
		Quit:$$$ISERR(sc)
		
		set g = ..config.TargetValue
		w "Overall Sensetivity: "_(lda.getSensitivity(g) * lda.getSpecificity(g)), !

		w "Test Set Confusion Matrix:", !
		set sc = ..printTestSetConfusionMatrix()
		Quit:$$$ISERR(sc)

		if (..config.verbose) {
			//set sc = ..printCovectors()
			Quit:$$$ISERR(sc)
		}
		
		
		// BDB473 
		// TODO: this code might need to go into a %DeepSee.PMML.Builder.LDA class
		set tModel = ##class(%DeepSee.PMML.Definition.Models.RegressionModel).%New()
		set tModel.modelName = $s(..config.name="":"LDA", 1:..config.name)
		set tModel.functionName = "classification"
		set tModel.algorithmName = "LDA"
		set tModel.modelType = "linearRegression"
		set tModel.targetFieldName = ..tableConfig.OutcomeColumn
		
		// build MiningSchema
		set tModel.MiningSchema = ##class(%DeepSee.PMML.Definition.MiningSchema).%New()
		if (..config.DimReduction="none") {
			set tDim = $parameter(..config.ClassifierClass, "Dim")
			for i = 1:1:tDim {
				set tFieldNames(i) = ..ClassifierPropName(i)
			}
		} else {
			set tDim = ..config.EffectiveDim
			for i = 1:1:tDim {
				set tFieldNames(i) = ..ClassifierPCName(i)
			}
		}
		for i = 1:1:tDim {
			set tMiningField = ##class(%DeepSee.PMML.Definition.MiningField).%New()
			set tMiningField.name = tFieldNames(i)
			set tMiningField.usageType = "active"
			do tModel.MiningSchema.MiningFields.Insert(tMiningField)
		}
		set tMiningField = ##class(%DeepSee.PMML.Definition.MiningField).%New()
		set tMiningField.name = "Outcome"
		set tMiningField.usageType = "predicted"
		do tModel.MiningSchema.MiningFields.Insert(tMiningField)
		
		merge tPIC = lda.PooledInverseCovariance
		set tGroup = ""
		for {
			set tGroup = $order(lda.Groups(tGroup), 1, tCount)
			quit:tGroup=""
			
			set tRegTable = ##class(%DeepSee.PMML.Definition.Models.Regression.RegressionTable).%New()
			set tRegTable.targetCategory = tGroup
			
			if (lda.UseMahalanobisDistance) {
				
				set tIntercept = 0
				for i = 1:1:tDim {
					set tPredictor = ##class(%DeepSee.PMML.Definition.Models.Regression.NumericPredictor).%New()
					set tPredictor.coefficient = -tPIC(i,i)
					set tPredictor.exponent = 2
					set tPredictor.name = tFieldNames(i)
					do tRegTable.NumericPredictors.Insert(tPredictor)
					
					set tCoeff = 0
					for j = 1:1:tDim {
						set tCoeff = tCoeff - (lda.GroupMean(tGroup,j) * (tPIC(i,j)+tPIC(j,i)))
						set tIntercept = tIntercept + (lda.GroupMean(tGroup,j) * lda.GroupMean(tGroup,i) * tPIC(i,j))
					}
					set tPredictor = ##class(%DeepSee.PMML.Definition.Models.Regression.NumericPredictor).%New()
					set tPredictor.coefficient = -tCoeff
					set tPredictor.exponent = 1
					set tPredictor.name = tFieldNames(i)
					do tRegTable.NumericPredictors.Insert(tPredictor)
					
					for j = 1:1:i-1 {
						set tPredictorTerm = ##class(%DeepSee.PMML.Definition.Models.Regression.PredictorTerm).%New()
						set tPredictorTerm.coefficient = -(tPIC(i,j)+tPIC(j,i))
						set tFieldRef = ##class(%DeepSee.PMML.Definition.Util.FieldRef).%New()
						set tFieldRef.field = tFieldNames(i)
						do tPredictorTerm.FieldRefs.Insert(tFieldRef)
						set tFieldRef = ##class(%DeepSee.PMML.Definition.Util.FieldRef).%New()
						set tFieldRef.field = tFieldNames(j)
						do tPredictorTerm.FieldRefs.Insert(tFieldRef)
						do tRegTable.PredictorTerms.Insert(tPredictorTerm)
					}
				}
				set tRegTable.intercept = -tIntercept
				
				/*
				

dist1 = x1 - gmean1
dist2 = x2 - gmean2
dist3 = x3 - gmean3


tmp1 = dist1 * pic11 + dist2 * pic21 + d3 * pic31
tmp2 = dist1 * pic12 + dist2 * pic22 + d3 * pic32
tmp3 = dist1 * pic13 + dist2 * pic23 + d3 * pic33


v1 = tmp1 * dist1 + tmp2 * dist2 + tmp3 * d3
   = ((x1 - gmean1) * pic11 + (x2 - gmean2) * pic21 + (x3-gm3)*pic31) * (x1 - gmean1)
	 + ((x1 - gm1) * pic12 + (x2 - gmean2) * pic22 + (x3-gm3)*pic32) * (x2 - gmean2)
	 + ((x1 - gm1) * pic13 + (x2 - gmean2) * pic23 + (x3-gm3)*pic33) * (x3 - gm3) 
   = (x1*pic11 - gmean1*pic11 + x2*pic21 - gmean2*pic21 + x3*pic31 - gm3*pic31) * (x1 - gm1)
	 + (x1*pic12 - gm1*pic12 + x2*pic22 - gm2*pic22 + x3*pic32 - gm3*pic32) * (x2 - gm2)
	 + (x1*pic13 - gm1*pic13 + x2*pic23 - gm2*pic23 + x3*pic33 - gm3*pic33) * (x3 - gm3)

   = 	x1*x1*pic11 + x2*x2*pic22 + x3*x3*pic33
	(- 2*gm1*pic11  - gm2*pic21 - gm2*pic12 - gm3*pic31 - gm3*pic13)*x1 + 
	(-pic21*gm1 - gm1*pic12 - 2*gm2*pic22 - gm3*pic32 - gm3*pic23)*x2 + 
	(-pic31*gm1 - gm1*pic13 - 2*gm3*pic33 - gm2*pic32 - gm2*pic23)*x3 + 
	(pic21 + pic12)*x1*x2 + (pic31 + pic13)*x1*x3 + (pic23 + pic32)*x2*x3
	gm1*gm1*pic11 + gm1*gm2*pic21 + gm1*gm2*pic12 + gm2*gm2*pic22 + gm1*gm3*pic31 + gm2*gm3*pic32 + gm3*gm3*pic33 + gm1*gm3*pic13 + gm2*gm3*pic23


*/
			} else {
				kill tMean, tProduct, tCoefficients
				merge tMean = lda.GroupMean(tGroup)
				set tMean(0,1) = tDim
				set tMean(1,0) = 1
				set tSC = ##class(%DeepSee.extensions.utils.MatrixArithmetics).mult(.tMean, .tPIC, .tCoefficients)
				quit:$$$ISERR(tSC)
				
				for i = 1:1:tDim {
					set tCoefficient = $g(tCoefficients(i))
					continue:'tCoefficient
					
					set tPredictor = ##class(%DeepSee.PMML.Definition.Models.Regression.NumericPredictor).%New()
					set tPredictor.name = tFieldNames(i)
					set tPredictor.coefficient = tCoefficient
					do tRegTable.NumericPredictors.Insert(tPredictor)
				}
				
				set tMean(0,1) = 1
				set tMean(1,0) = tDim
				set tSC = ##class(%DeepSee.extensions.utils.MatrixArithmetics).mult(.tCoefficients, .tMean, .tProduct)
				quit:$$$ISERR(tSC)
				set tRegTable.intercept = -0.5*tProduct(1) + $zln(lda.Probability(tGroup))
			}
			do tModel.RegressionTables.Insert(tRegTable)
		}
		do ..PMML.Models.Insert(tModel)
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getLDAModel(Output lda As %DeepSee.extensions.utils.LDA) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim ldaName As %String
	
	Try {
		set ldaName = ..ldaName()
		if ('(##class(%DeepSee.extensions.utils.LDA).NameIdxExists(ldaName))) {
			set sc = ..LDA()
			Quit:$$$ISERR(sc)
		}

		set lda = ##class(%DeepSee.extensions.utils.LDA).NameIdxOpen(ldaName, -1, .sc)
		Quit:$$$ISERR(sc)
		
		set lda.UseMahalanobisDistance = ..config.UseMahalanobisDistance
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method delete() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim ldaName As %String
	
	Try {
		set ldaName = ..ldaName()
		if ((##class(%DeepSee.extensions.utils.LDA).NameIdxExists(ldaName))) {
			w "Deleting: ", ldaName, !
			set sc = ##class(%DeepSee.extensions.utils.LDA).NameIdxDelete(ldaName)
			Quit:$$$ISERR(sc)
		}

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method LDA() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim ldaName, sql As %String
	#dim i, j, n As %Integer
	#dim d, g
	#dim dim As %Integer
	#dim md, p As %Boolean
	
	Try {
		set p = '(..config.EqualProbabilities)
		set md = ..config.UseMahalanobisDistance
		set dim = $parameter(..config.ClassifierClass,"Dim")
		
		set sc = ..SQL4LDA(.sql, .n)
		Quit:$$$ISERR(sc)
		set sql = sql_" where ("_..config.TrainingSetPredicate_")"
		if (..config.verbose) {
			w sql, !
		}
		
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare(sql)
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)

		set i = 0
		While (rs.%Next()) {
			set i = $i(i)
			for j=1:1:n {
				set d(i,j) = rs.%GetData(j)
			}
			set g(i) = rs.%GetData(n+1)
		}
		
		d rs.%Close()
		
		set ldaName = ..ldaName()
		set lda = ##class(%DeepSee.extensions.utils.LDA).%New(ldaName)
		set lda.UseMahalanobisDistance = md
		
		w "Creating LDA: ", ldaName, !
		set sc = lda.Create(i, n, .d, .g, p)
		Quit:$$$ISERR(sc)
			
		set sc = lda.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method SQL4LDA(Output sql As %String, Output n As %Integer) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim values, tableName, prop, className, outcomeColumn As %String
	#dim i As %Integer
	
	Try {
		set className = ..config.ClassifierClass
		set tableName = $$TableFromClass^%occClass(className)
			
		set outcomeColumn = ..tableConfig.OutcomeColumn

		set values = ..config.Values

		set sql = "select "
		
		if (..config.DimReduction = "none") {
			set n = $parameter(className,"Dim")
		
			for i = 1:1:n {
				set prop = ..ClassifierPropName(i)
				set sql = sql_prop_", "
			}
		} else {
			if (..config.EffectiveDim > 0) {
				set n = ..config.EffectiveDim
			} else {
				set n = ..tableConfig.MaxPC
			}
			
			for i = 1:1:n {
				set prop = ..ClassifierPCName(i)
				set sql = sql_prop_", "
			}
		}
		
		if (values '= "") {
			#dim k, M, tv
			set sql = sql_" decode("_outcomeColumn_", "
			set M = $l(values,",")
			for k=1:1:M {
				set tv = $p(values,",",k)
				if (($e(tv) = "!") || ($e(tv) = "'")) {
					Continue
				}
				set sql = sql_"'"_tv_"','"_tv_"',"
			}
			set sql = sql_"0)"
		} else {
        	set sql = sql_" NVL("_outcomeColumn_",0) "
		}
    	set sql = sql_"from "_tableName_" as c "
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method printTestSetConfusionMatrix(Output s As %Double) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, y As %Integer
	#dim confusion, x
	#dim r, ss As %Double
	#dim g
	
	#dim sql As %String
	
	#dim lda As %DeepSee.extensions.utils.LDA

	Try {
		set sc = ..SQL4LDA(.sql)
		Quit:$$$ISERR(sc)
		set sql = sql_" where ( NOT ("_..config.TrainingSetPredicate_"))"
		if (..config.verbose) {
			w sql, !
		}
		
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare(sql)
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)
		
		set sc = ..getLDAModel(.lda)
		Quit:$$$ISERR(sc)

		set sc = lda.getConfusionMatrixForTestSet(rs, 1, lda.Dim, .confusion, .r)
		Quit:$$$ISERR(sc)
		
		set sc = lda.printConfusionMatrix(.confusion)
		Quit:$$$ISERR(sc)

		w "R = "_r, !
		
		set s = 1
		set r = 1
		set g = $o(confusion(""))
		While (g '= "") {
			set ss = lda.getSensitivity(g, .sc, .confusion)
			Quit:$$$ISERR(sc)
			set s = s * ss
			
			set ss = lda.getSpecificity(g, .sc, .confusion)
			Quit:$$$ISERR(sc)
			set r = r * ss
			
			set g = $o(confusion(g))
		}
		
		w "Overall Sensitivity :"_s, !
		w "Overall Specificity :"_r, !
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

Method printCovectors() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim lda As %DeepSee.extensions.utils.LDA
	#dim sql As %String

	#dim f, v, cov, covv
	#dim x, g, y As %String
	#dim i, j As %Integer
	#dim group
	
	Try {
		set sc = ..SQL4LDA(.sql)
		Quit:$$$ISERR(sc)
		// set sql = sql_" where ( NOT ("_..config.TrainingSetPredicate_"))"
		if (..config.verbose) {
			w sql, !
		}
		
		set sc = ..getLDAModel(.lda)
		Quit:$$$ISERR(sc)

		set g = $o(lda.Groups(""))
		set j = 1
		While(g '= "") {
			set group(j) = g
			set g = $o(lda.Groups(g))
			set j = $i(j)
		}
		set group = j - 1

		for j = 1:1:group {
			k cov
			set sc = lda.getCovector(group(j), .cov)
			Quit:$$$ISERR(sc)
			
			m covv(group(j)) = cov
		}
		Quit:$$$ISERR(sc)
			
			
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare(sql)
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)
		
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)
			
		While (rs.%Next()) {
			k x
			set x(1,0) = lda.Dim
			set x(0,1) = 1
			for i=1:1:lda.Dim {
				set x(i) = rs.%GetData(i)
			}
			set g = rs.%GetData(lda.Dim + 1)

			set y = lda.predict(.x, .sc)
			Quit:$$$ISERR(sc)
				
			set sc = lda.GetDF(.x, .f, 0)
			Quit:$$$ISERR(sc)
				
			w g_$c(9)_y
			for j = 1:1:group {
				k cov
				s g = group(j)
				m cov = covv(g)
				set sc = ##class(%DeepSee.extensions.utils.MatrixArithmetics).mult(.cov, .x, .v)
				Quit:$$$ISERR(sc)
				
				w $j($fn(f(g),"",5),12)_$j($fn(v(1),"",5),12)_$j($fn((v(1) - f(g)),"",2),9)
			}				
			Quit:$$$ISERR(sc)
			w !
		}
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}

	Quit sc
}

Method ldaName() As %String
{
	#dim  dim As %Integer
	#dim type As %String
	
	if (..config.name '= "") {
		Quit ..config.name
	}
	
	set type = ..config.DimReduction
	
	set dim = $parameter(..config.ClassifierClass,"Dim")
	Quit ..config.ClassifierClass_"||"_type_":"_dim
}

}
