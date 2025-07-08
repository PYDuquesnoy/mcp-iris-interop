/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.NaiveBayes Extends (%RegisteredObject, Base) [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.NaiveBayes;

Property tableConfig As %DeepSee.extensions.modelling.conf.Table;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.NaiveBayes) As %Status
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
	
	#dim g As %String
	
	Try {
		set sc = ..getNaiveBayesModel()
		Quit:$$$ISERR(sc)
		
		w "Training Set Confusion Matrix:", !
		set sc = ..printConfusionMatrix()
		Quit:$$$ISERR(sc)
		
		w "Test Set Confusion Matrix:", !
		set sc = ..printConfusionMatrix("Test Set")
		Quit:$$$ISERR(sc)

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getNaiveBayesModel() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim pmmlClassName As %String
	
	Try {
		set pmmlClassName = ..pmmlClassName()
		if ('(##class(%Dictionary.CompiledClass).%ExistsId(pmmlClassName))) {
			set sc = ..generatePMML()
			Quit:$$$ISERR(sc)
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method delete() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim pmmlClassName As %String
	
	Try {
		set pmmlClassName = ..pmmlClassName()
		if ((##class(%Dictionary.CompiledClass).%ExistsId(pmmlClassName))) {
			w "Deleting: ", pmmlClassName, !
			set sc = $system.OBJ.Delete(pmmlClassName)
			Quit:$$$ISERR(sc)
		}

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method generatePMML() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim pmmlClassName, sql, baseSQL As %String
	#dim tFields
	#dim tDataset As %DeepSee.PMML.Dataset.SQL
	
	Try {
		set pmmlClassName = ..pmmlClassName()
		
		set sc = ..SQL4NaiveBayes(.tFields, .baseSQL)
		Quit:$$$ISERR(sc)
		set sql = baseSQL_" where ("_..config.TrainingSetPredicate_")"
		if (..config.verbose) {
			w sql, !
		}
		
		w "Creating NaiveBayes model: ", pmmlClassName, !
		set tFields($i(tFields)) = $lb(..tableConfig.OutcomeColumn, ..tableConfig.OutcomeColumn, "string", "categorical")
		set tDataset = ##class(%DeepSee.PMML.Dataset.SQL).%Create(pmmlClassName, sql, .tFields,,"Instance", .sc)
		Quit:$$$ISERR(sc)
		
		set tDataset.Name = "Training Set"
		
		set tBuilder = ##class(%DeepSee.PMML.Builder.NaiveBayes).%New()
		set tBuilder.Dataset = tDataset
		set tBuilder.ModelName = $p(pmmlClassName,".",$l(pmmlClassName,"."))
		set tBuilder.FunctionName = "classification"
		set tBuilder.Threshold = 0.0001
		set tBuilder.TargetField = ..tableConfig.OutcomeColumn
		set tBuilder.OutputProbability = 1

		if (..config.TestSetPredicate '= "") {
			set sql= baseSQL_" where ("_..config.TestSetPredicate_")"
		} else {
			set sql= baseSQL_" where (not ("_..config.TrainingSetPredicate_"))"
		}
		set tDataSource = ##class(%DeepSee.PMML.Definition.Extension.SQLDataSource).%New()
		set tDataSource.name = "Test Set"
		set tDataSource.SQL = sql
		set sc = tBuilder.DataSources.Insert(tDataSource)
		quit:$$$ISERR(sc)
		
		set sc = tBuilder.GeneratePMMLClass(pmmlClassName)
		quit:$$$ISERR(sc)


		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method SQL4NaiveBayes(Output pFields, Output sql As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim values, tableName, prop, className, outcomeColumn As %String
	#dim i, n As %Integer
	
	Try {
		set className = ..config.ClassifierClass
		set tableName = $$TableFromClass^%occClass(className)
			
		set outcomeColumn = ..tableConfig.OutcomeColumn

		set values = ..config.Values

		set sql = "select "
		k pFields
		
		if (..config.DimReduction = "none") {
			set n = $parameter(className,"Dim")
		
			for i = 1:1:n {
				set prop = ..ClassifierPropName(i)
				if (..config.Truncate '= "") {
					set sql = sql_" ROUND("_prop_",1) as "_prop_", "
				} else {
					set sql = sql_prop_", "
				}
				set pFields($i(pFields)) = $lb(prop, prop, "double", "continuous")
			}
		} else {
			if (..config.EffectiveDim > 0) {
				set n = ..config.EffectiveDim
			} else {
				set n = ..tableConfig.MaxPC
			}
			
			for i = 1:1:n {
				set prop = ..ClassifierPCName(i)
				if (..config.Truncate '= "") {
					set sql = sql_" ROUND("_prop_",1) as "_prop_", "
				} else {
					set sql = sql_prop_", "
				}
				set pFields($i(pFields)) = $lb(prop, prop, "double", "continuous")
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
        	set sql = sql_" NVL("_outcomeColumn_",0) as "_outcomeColumn_" "
		}
    	set sql = sql_", Instance from "_tableName_" as c "
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method printConfusionMatrix(dsName As %String = "", Output s1 As %Double, Output s2 As %Double) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, y, n, len, testId As %Integer
	#dim confusion
	#dim ss As %Double
	#dim g
	#dim rs As %IResultSet
	#dim v As %String
	
	#dim sql, pmmlClass As %String
	
	Try {
		set pmmlClass = ..pmmlClassName()
		w "Testing Model: "_pmmlClass, !

		set sc = ##class(%DeepSee.PMML.Utils).%RunModel(.testId, pmmlClass, , .dsName)
		Quit:$$$ISERR(sc)
	
		w "Tested: "_dsName
		w "; Test Id: "_testId, !

		set stmt = ##class(%SQL.Statement).%New()
		
		set sql = "SELECT ActualValue, count(*) from %DeepSee_PMML_Utils.TempResult WHERE TestId = ? GROUP BY ActualValue"
		set sc = stmt.%Prepare(sql)
		Quit:$$$ISERR(sc)
		
		set rs = stmt.%Execute(testId)
		k g		
		While (rs.%Next()) {
			set v = rs.%GetData(1)
			set g(v) = rs.%GetData(2)
		}
		d rs.%Close()
		
		m confusion = g
		k g

		set sql = "SELECT PredictedValue, count(*) from %DeepSee_PMML_Utils.TempResult WHERE TestId = ? GROUP BY PredictedValue"
		set sc = stmt.%Prepare(sql)
		Quit:$$$ISERR(sc)
		
		set rs = stmt.%Execute(testId)
		set len = 0
		While (rs.%Next()) {
			set v = rs.%GetData(1)
			set g(v) = rs.%GetData(2)
			if ($l(v) > len) {
				set len = $l(v)
			}
		}
		d rs.%Close()

		set sql = "SELECT ActualValue, PredictedValue, count(*) from %DeepSee_PMML_Utils.TempResult "
		set sql = sql_" WHERE TestId = ? GROUP BY ActualValue, PredictedValue"
		
		set sc = stmt.%Prepare(sql)
		Quit:$$$ISERR(sc)
		
		set rs = stmt.%Execute(testId)
		While (rs.%Next()) {
			set v = rs.%GetData(1)
			set y = rs.%GetData(2)
			set confusion(v,y) = rs.%GetData(3)
		}
		d rs.%Close()
		
		set len = len + 2
		w $j("",len)
		set y = $o(g(""))
		While (y '= "") {
			w $j(y,len)
			set y = $o(g(y))
		}
		w !
				
		set v = $o(confusion(""))
		While (v '= "") {
			w $j(v_": ",len)
			set y = $o(g(""))
			While (y '= "") {
				w $j($g(confusion(v,y),0),len)
				set y = $o(g(y))
			}
			w !
			set v = $o(confusion(v))
		}

		set s1 = 1
		set s2 = 1
		set v = $o(confusion(""))
		w $j("Group ",len)_$c(32,9)_$j("Sensitivity",14)_$c(32,9)_$j("Specificity",14), !
		While (v '= "") {
			set ss = $g(confusion(v,v),0) / confusion(v) 
			set s1 = s1 * ss
			w $j(v_": ",len)_$c(32,9)_$j($fn(ss,"",5),14)
			
			set ss = ..getSpecificity(v, .sc, .confusion)
			Quit:$$$ISERR(sc)

			set s2 = s2 * ss
			w $c(32,9)_$j($fn(ss,"",5),14)
			
			set v = $o(confusion(v))
			w !
		}
		Quit:$$$ISERR(sc)
		
		set y = $o(g(""))
		While (y '= "") {
			if ($d(confusion(y)) > 0) {
				set y = $o(g(y))
				Continue
			}
			w $j(y_": ",len)_$c(32,9)_$j("",14)
			
			set ss = ..getSpecificity(y, .sc, .confusion)
			Quit:$$$ISERR(sc)

			set s2 = s2 * ss
			w $c(32,9)_$j($fn(ss,"",5),14)
			
			set y = $o(g(y))
			w !
		}
		Quit:$$$ISERR(sc)
		
		w "Overall Sensitivity :"_s1, !
		w "Overall Specificity :"_s2, !
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

ClassMethod getSpecificity(g, Output sc As %Status, ByRef confusion) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim y1, y2 As %String
	#dim s As %Double = ""
	#dim trueNeg, falsePos As %Integer
	
	Set sc  = $$$OK

	Try {
		set trueNeg = 0
		set falsePos = 0
		set y1 = $o(confusion(""))
		While (y1 '= "") {
			set y2 = $o(confusion(""))
			While (y2 '= "") {
				if ((y1 '= g)) {
					if (y2 '= g) {
						set trueNeg = trueNeg + $g(confusion(y1,y2))
					} else {
						set falsePos = falsePos + $g(confusion(y1,y2))
					}
				} 
				set y2 = $o(confusion(y2))
			}
			set y1 = $o(confusion(y1))
		}
		
		set s = (trueNeg) / ( trueNeg + falsePos)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit s
}

Method pmmlClassName() As %String
{
	#dim  dim As %Integer
	#dim type, p, name As %String
	#dim l As %Integer
	
	if (..config.PMMLClassName '= "") {
		Quit ..config.PMMLClassName
	}
	
	set l = $l(..config.ClassifierClass,".")
	if ($p(..config.ClassifierClass,".",l-2,l-1) = "classifiers") {
		set p = $p(..config.ClassifierClass,".",1,l-2)
	} else {
		set p = $p(..config.ClassifierClass,".",1,l-1) 
	}
	if (..config.name '= "") {
		set name = ..config.name
	} else {
		set type = ..config.DimReduction
	
		set dim = $parameter(..config.ClassifierClass,"Dim")
		set name = $p(..config.ClassifierClass,".",l)_"||"_type_":"_dim
	}
	
	Quit p_".pmml."_name
}

}
