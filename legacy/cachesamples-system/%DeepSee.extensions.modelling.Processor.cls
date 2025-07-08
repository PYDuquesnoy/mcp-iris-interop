/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.Processor Extends %RegisteredObject
{

Parameter CONFPACKAGE = "%DeepSee.extensions.modelling.conf.";

ClassMethod applyModel(class As %String, verbose As %Boolean = 1, Output pmml As %DeepSee.PMML.Definition.PMML, ByRef p1 As %RawString = "", ByRef p2 As %RawString = "", ByRef p3 As %RawString = "", ByRef p4 As %RawString = "", ByRef p5 As %RawString = "", ByRef p6 As %RawString = "", ByRef p7 As %RawString = "", ByRef p8 As %RawString = "") As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim model As %DeepSee.extensions.modelling.conf.Model
	#dim op As %DeepSee.extensions.modelling.conf.Operation
	#dim key, opId As %String
	#dim count As %Integer
	
	Try {
		set count = 0
		set sc = ..readModel(class, .model)
		Quit:$$$ISERR(sc)
		
		// BDB473: initialize PMML element
		set tDescription = "PMML definition for model "_model.name_$s(model.name'=class:" ("_class_")", 1:"")
		set tApplication = "%DeepSee.extensions.modelling.Processor"
		set pmml = ##class(%DeepSee.PMML.Definition.PMML).%Create("4.1", tDescription, tApplication)
		set key = model.Operations.Next("")
		While (key '= "") {
			set op = model.Operations.GetAt(key)
			if (verbose) {
				w "Doing: "_op.name_" [id = "_op.id_"]", !
			}
			
			set opId = op.GetOpId()
			if (opId = "") {
				set sc = $$$ERROR($$$GeneralError, "Undefined operator id for key = "_key)
				Quit
			}
			set sc = ..applyOperation(class, opId, op.GetType(), op.perform, .pmml, op.args,op.control,op.Operations,.p1,.p2,.p3,.p4,.p5,.p6,.p7,.p8)

			Quit:$$$ISERR(sc)
			
			set count = $i(count)
			set key = model.Operations.Next(key)
		}
		Quit:$$$ISERR(sc)
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	if (verbose) {
		if ($$$ISERR(sc)) {
			d $system.OBJ.DisplayError(sc)
		} else {
			w "Model "_model.name_" is successfully applied. "_count_" operations are performed.", !
		}
	}
	
	Quit sc
}

ClassMethod readModel(class As %String, Output model As %XML.Adaptor) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = ..readConfig(class, "Model", "Model", .model)
		Quit:$$$ISERR(sc)
		
		if (model.name = "") {
			set model.name = class
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod readConfig(class As %String, id As %String, type As %String, Output conf As %XML.Adaptor) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim xdata As %String
	Try {
		set xdata = class_"||"_id
		Set tXML=##class(%Dictionary.CompiledXData).%OpenId(xdata).Data
		If '$IsObject(tXML) {
			Set sc=%objlasterror 
			Quit
		}
		
		Set reader = ##class(%XML.Reader).%New()
		Set sc=reader.OpenStream(tXML)
		Quit:$$$ISERR(sc)
		
		if (type[".") {
			Do reader.Correlate($tr(type,"%",""),type)

		} else {
			Do reader.Correlate(type,..#CONFPACKAGE_type)
		}

		if ('reader.Next(.conf,.sc)) {
			if ($$$ISOK(sc)) {
				set sc = $$$ERROR($$$GeneralError,"No "_type_" element in XData: "_xdata)
			}
		}
		Quit:$$$ISERR(sc)
		
		if (conf.%Extends("%DeepSee.extensions.modelling.conf.Operator")) {
			set conf.SourceClass = class
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod applyOperation(class As %String, opId As %String, type As %String, custom As %String, ByRef pmml As %DeepSee.PMML.Definition.PMML, numargs As %Integer = 0, control As %String, operations As %ObjectHandle, ByRef p1 As %RawString = "", ByRef p2 As %RawString = "", ByRef p3 As %RawString = "", ByRef p4 As %RawString = "", ByRef p5 As %RawString = "", ByRef p6 As %RawString = "", ByRef p7 As %RawString = "", ByRef p8 As %RawString = "") As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim op As %DeepSee.extensions.modelling.conf.Operator
	
	#dim implementor, method, setConfig As %String
	#dim operator
	
	Try {
		set sc = ..readConfig(class, opId, type, .op)
		Quit:$$$ISERR(sc)
		
		set implementor = op.GetImplementingClass()
		if (custom '= "") {
			set method = custom
		} else {
			set method = op.GetApplyMethod()
		}
		set setConfig = op.GetSetConfigMethod()
		
		set operator = $classmethod(implementor,"%New")
		set sc = $method(operator,setConfig,op)
		Quit:$$$ISERR(sc)


		if control ="foreach" {
			// There should be methods execute, next and getData, getData will take numargs arguments by reference

			// also operator should have Operations collection

			s sc=$method(operator,"execute")
			Quit:$$$ISERR(sc)


			while (operator.next()) {

				set sc=..execNArgs(operator, "getData", numargs, .p1, .p2, p3, .p4, .p5, .p6, .p7, .p8)
				set key = operations.Next("")

				s count=0
				While (key '= "") {

					set op = operations.GetAt(key)

				

					set opId = op.GetOpId()

					if (opId = "") {

						set sc = $$$ERROR($$$GeneralError, "Undefined operator id for key = "_key)

						Quit

				}

			
			set sc = ..applyOperation(class, opId, op.GetType(), op.perform,.pmml, op.args,op.control,op.Operations,.p1,.p2,.p3,.p4,.p5,.p6,.p7,.p8)

			Quit:$$$ISERR(sc)

			

			set count = $i(count)

			set key = operations.Next(key)

		}



			}

			Quit   

		}

		if operations.Count()>0 {

			s sc=$$$ERROR("Suboperations are defined, but no control directive is present")

			quit

		}
		set operator.PMML = pmml


		if '(numargs) {

			set sc = $method(operator, method)

		}

		else {

			set sc=..execNArgs(operator, method, numargs, .p1, .p2, p3, .p4, .p5, .p6, .p7, .p8)

		}

		Quit:$$$ISERR(sc)
		
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod execNArgs(operator As %ObjectHandle, method As %String, numargs As %Integer = 0, ByRef p1 As %RawString = "", ByRef p2 As %RawString = "", ByRef p3 As %RawString = "", ByRef p4 As %RawString = "", ByRef p5 As %RawString = "", ByRef p6 As %RawString = "", ByRef p7 As %RawString = "", ByRef p8 As %RawString = "") As %Status
{

		if (+numargs=0) {

			set sc = $method(operator, method)



		}

		elseif (numargs=1) {

			set sc = $method(operator, method, .p1)



		}

		elseif (numargs=2) {
			set sc = $method(operator, method, .p1, .p2)



		}

		elseif (numargs=3) {

			set sc = $method(operator, method, .p1, .p2, .p3)



		}

		elseif (numargs=4) {

			set sc = $method(operator, method, .p1, .p2, p3, .p4)

		}

		elseif (numargs=5) {

			set sc = $method(operator, method, .p1, .p2, p3, .p4, .p5)

		}

		elseif (numargs=6) {

			set sc = $method(operator, method, .p1, .p2, p3, .p4, .p5, .p6)

		}

		elseif (numargs=7) {

			set sc = $method(operator, method, .p1, .p2, p3, .p4, .p5, .p6, .p7)

		}

		elseif (numargs=8) {

			set sc = $method(operator, method, .p1, .p2, p3, .p4, .p5, .p6, .p7, .p8)

		}

		else {

			set sc = $$$ERROR("Number of arguments must be an integer between 0 and 8 inclusively")

		}

		quit sc
}

}
