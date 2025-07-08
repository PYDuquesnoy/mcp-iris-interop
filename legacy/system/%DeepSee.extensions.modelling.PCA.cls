/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.PCA Extends (%RegisteredObject, Base) [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.PCA;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.PCA) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..config = conf
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method apply() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim pca As %DeepSee.extensions.components.PCA
	
	Try {
		set sc = ..PCAAnalysis(.pca)
		quit:$$$ISERR(sc)
		
		// BDB473 - append derived fields based on PCA transformation matrix
		set sc = pca.GetTransformationMatrix(.W)
		quit:$$$ISERR(sc)
		set tInCount = $ll(pca.InputColumnList)
		set tOutCount = $ll(pca.OutputColumnList)
		for j = 1:1:tOutCount {
			set tDerivedField = ##class(%DeepSee.PMML.Definition.DerivedField).%New()
			set tDerivedField.name = ..ClassifierPCName(j)
			set tDerivedField.optype = "continuous"
			set tDerivedField.dataType = "double"
			
			set tSum = ##class(%DeepSee.PMML.Definition.Util.Apply).%New()
			set tSum.function = "sum"
			set tDerivedField.Expression = tSum
			
			for i = 1:1:tInCount {
				set tCoefficient = $g(W(i,j))
				continue:'tCoefficient
				set tFactor = ##class(%DeepSee.PMML.Definition.Util.Apply).%New()
				set tFactor.function = "*"
				set tConstant = ##class(%DeepSee.PMML.Definition.Util.Constant).%New()
				set tConstant.value = tCoefficient
				do tFactor.Expressions.Insert(tConstant)
				set tDiff = ##class(%DeepSee.PMML.Definition.Util.Apply).%New()
				set tDiff.function = "-"
				set tMean = ##class(%DeepSee.PMML.Definition.Util.Constant).%New()
				set tMean.value = pca.Mean(i)
				do tDiff.Expressions.Insert(tMean)
				set tFieldRef = ##class(%DeepSee.PMML.Definition.Util.FieldRef).%New()
				set tFieldRef.field = ..ClassifierPropName(i)
				do tDiff.Expressions.Insert(tFieldRef)
				do tFactor.Expressions.Insert(tDiff)
				do tSum.Expressions.Insert(tFactor)
			}
			do ..PMML.TransformationDictionary.DerivedFields.Insert(tDerivedField)
		}
		
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method print() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tableName, className As %String
	
	Try {
		set className = ..config.ClassifierClass
		if (className = "") {
			set sc = $$$ERROR($$$GeneralError,"Classifier Class is undefined")
			Quit
		}
		
		set tableName = $$TableFromClass^%occClass(className)
		
		set pca = ##class(%DeepSee.extensions.components.PCA).%OpenId(tableName,-1, .sc)
		Quit:$$$ISERR(sc)
		
		set sc = pca.print()
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method PCAAnalysis(Output pca As %DeepSee.extensions.components.PCA) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim d1, d2, i As %Integer
	#dim margin As %Double
	#dim tableName, className As %String

	Try {
		set margin = ..config.DimReductionMargin
		set className = ..config.ClassifierClass
		if (className = "") {
			set sc = $$$ERROR($$$GeneralError,"Classifier Class is undefined")
			Quit
		}
		
		set tableName = $$TableFromClass^%occClass(className)
		
		if (##class(%DeepSee.extensions.components.PCA).%ExistsId(tableName)) {
			set pca = ##class(%DeepSee.extensions.components.PCA).%OpenId(tableName,-1, .sc)
			Quit:$$$ISERR(sc)

			set d1 = pca.GetEffectiveDimensionality(margin, .sc)
			Quit:$$$ISERR(sc)
			set d2 = pca.GetModifiedEffectiveDimensionality(margin,$parameter(className,"Dim"),.sc)
			Quit:$$$ISERR(sc)
		} else {
			set sc = ..ClassifierPCA(0, .d1, .d2, .pca)
			Quit:$$$ISERR(sc)
		}
			
		w "For margin "_margin_" diminsionality: "_d1, !
		w "Modified diminsionality: "_d2_"; Eigenvalues:", !
		
		for i=1:1:(d2+5) {
			Quit:i>20
			w i_": "_pca.OutputStdDev(i), !
		}
		
		if (d2 > ..config.NumberOfPC) {
			if (..config.ErrorOnMaxPC) {
				set sc = $$$ERROR($$$GeneralError,"Too few principle components: "_..config.NumberOfPC_" is defined, "_d2_" are required")
			} else {
				w "WARNING: "_"Too few principle components: "_..config.NumberOfPC_" is defined, "_d2_" are required", !
			}
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method ClassifierPCA(verbose As %Boolean = 1, Output d1 As %Integer, Output d2 As %Integer, Output pca As %DeepSee.extensions.components.PCA) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim input, output, prop, cz As %String
	#dim i, n, nPC As %Integer
	#dim margin As %Double
	#dim czExists As %Boolean
	#dim tableName, className As %String
	
	Try {
		set className = ..config.ClassifierClass
		set sc = ##class(%iKnow.Objects.dd.Builder).TableName(className, .tableName)
		Quit:$$$ISERR(sc)
		set input = ""
		set n = $parameter(className,"Dim")
		for i=1:1:n {
			set:input'="" input = input_","
			set prop = ..ClassifierPropName(i)
			set input = input_prop
		}
		
		set sc = ..GetNPC(.nPC)
		Quit:$$$ISERR(sc)
		
		set output = ..ClassifierPCName(1)
		for i=2:1:nPC {
			set cz = ..ClassifierPCName(i)
			set czExists = ##class(%Dictionary.CompiledProperty).%ExistsId(className_"||"_cz)
			if ('czExists) {
				set sc = $$$ERROR($$$GeneralError,"Principal Component "_cz_" is not defined in class "_className)
				Quit
			}
			set output = output_","_cz
		}
		Quit:$$$ISERR(sc)
		
		set margin = ..config.DimReductionMargin
		w "Doing PCA:", !
		set sc = ..PCA(tableName, input, output, 0, margin, .d1, .d2, .pca)
		Quit:$$$ISERR(sc)
		
		set sc = pca.%Save()
		Quit:$$$ISERR(sc)
		
		if (verbose) {
			w "For margin "_margin_" diminsionality: "_d1, !
			Quit:$$$ISERR(sc)
			w "Modified diminsionality: "_d2_"; Eigenvalues:", !
			for i=1:1:d2 {
				w i_": "_pca.OutputStdDev(i), !
			}
		
			if (d2 > nPC) {
				set sc = $$$ERROR($$$GeneralError,"Too few principle components: "_nPC_" is defined, "_d2_" are required")
			}
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetNPC(Output n As %Integer) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tableConfig As %DeepSee.extensions.modelling.conf.Table
	
	Try {
		set n = ..config.NumberOfPC
		if ((n '= "") && (n > 0)) {
			Quit
		}
		
		set sc = ##class(Processor).readConfig(..config.ClassifierClass, "Table", "Table", .tableConfig)
		if ($$$ISERR(sc)) {
			set sc = $$$ERROR($$$GeneralError,"Can not determine configuration for table: "_$system.Status.GetErrorText(sc))
			Quit
		}
		
		set n = tableConfig.MaxPC
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod PCA(table As %String, input As %String, out As %String, print As %Boolean = 1, margin As %Double = "", Output d1 As %Integer, Output d2 As %Integer, Output pca As %DeepSee.extensions.components.PCA) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		w:print "Doing PCA on "_table_"; input = "_input_", output = "_out, !
		set sc = ##class(%DeepSee.extensions.components.PCA).process(table, input, out, .pca, 1, print)
		Quit:$$$ISERR(sc)
		//w "PCA Done", !
		
		if (print) {
			set sc = pca.print()
			Quit:$$$ISERR(sc)
		}
		if (margin '= "") {
			set d1 = pca.GetEffectiveDimensionality(margin, .sc)
			Quit:$$$ISERR(sc)
			set d2 = pca.GetModifiedEffectiveDimensionality(margin,$l(input,","),.sc)
			Quit:$$$ISERR(sc)
		}

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

}
