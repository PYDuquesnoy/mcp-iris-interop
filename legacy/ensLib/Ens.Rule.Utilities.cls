/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %Integration.Context)

IncludeGenerator %systemInclude

/// Utility methods used by the Rules editor and compiler.
Class Ens.Rule.Utilities [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Return the list of functions (methods) based on compiled classes. <br>
/// If cache is found in context class, use it, otherwise, build it. <br>
/// This list is returned in funcset. <br>
/// The list is of the form: list(NAME) = $LB(class,name,specparsed). <br>
ClassMethod GetFunctionSet(Output funcset) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	Try {

		Kill funcset
		Set tSC = $SYSTEM.Context.InterOpFunctions().GetFunctionSet(.funcset)

		#; Do not return date time stamp top node
		ZKill funcset

	} Catch e {

		Set tSC=e.AsStatus()

	}

	Quit tSC
}

/// If function is found in the FunctionSet, return the ClassName, MethodName and ParsedSpec
/// Otherwise, return error
ClassMethod ResolveFunction(pFuncName As %String, Output pClassName As %String, Output pMethodName As %String, Output pParsedSpec As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tValue As %String

	Try {

		Set tValue = $SYSTEM.Context.InterOpFunctions().GetFunctionDetails(pFuncName,.tSC)

		If $$$ISOK(tSC) {

			If tValue = "" {

				Set tSC=$$$ERROR($$$EnsErrUnknownFunction,pFuncName)

			} Else {

				Set pClassName=$li(tValue,1)
				Set pMethodName=$li(tValue,2)
				Set pParsedSpec=$li(tValue,3)

			}
		}

	} Catch e {

		Set tSC=e.AsStatus()

	}

	Quit tSC
}

ClassMethod buildFunctionSet(Output pFunctionSet) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	Try {
		Kill pFunctionSet

		Set tSC = ..buildFunctionSetOneClass("Ens.Rule.FunctionSet",.pFunctionSet)
		If $$$ISERR(tSC) Quit

		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		#; Pass in "%YZ" to limit % searching to %Z and after
		Set tSC = tRS.Execute("Ens.Rule.FunctionSet",$$$EnsSubClassOfInit("Ens.Rule.FunctionSet")) quit:$$$ISERR(tSC)
		While ( tRS.Next(.tSC) ) {
			Quit:$$$ISERR(tSC)
			Set tSC = ..buildFunctionSetOneClass($g(tRS.Data("Name")),.pFunctionSet)
			If $$$ISERR(tSC) Quit
		}
	} Catch e {
		Set tSC=e.AsStatus()
	}

	Quit tSC
}

ClassMethod buildFunctionSetOneClass(pClass As %String, ByRef pFunctionSet) As %Status [ Internal ]
{
	set tSC=$$$OK
	set compiled=0,method="" for { set method=$$$comMemberNext(pClass,$$$cCLASSmethod,method)  quit:""=method
		set compiled=1
		if '$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHclassmethod) continue
		if $d(pFunctionSet($ZCVT(method,"u")))#2 continue
		set pFunctionSet($ZCVT(method,"u"))=$lb(pClass,method,$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHformalspecparsed))
	}
	#; Look through definition if not compiled and create parsed list of specification as provided by compiled storage.
	if 'compiled {
		set method="" for { set method=$$$defMemberNext(pClass,$$$cCLASSmethod,method)  quit:""=method
			if '$$$defMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHclassmethod) continue
			if $d(pFunctionSet($ZCVT(method,"u")))#2 continue
			try {
				set tSC=$$serializeFormal^%occName(pClass,"method",pClass,$$$defMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHformalspec),.parsedspec)
				if tSC set pFunctionSet($ZCVT(method,"u"))=$lb(pClass,method,parsedspec)
			} catch e {
				set tSC=e.AsStatus()
			}
			if $$$ISERR(tSC) quit
		}
	}
	quit tSC
}

}
