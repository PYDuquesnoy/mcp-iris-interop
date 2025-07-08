/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a helper class that is used by the various %SYSTEM classes to 
/// provide a Help method.
Class %SYSTEM.Help [ Abstract, System = 3 ]
{

/// Write out a list of the methods of this object to the console.
/// Pass the method name as an argument to see the full description for
/// this item.
ClassMethod Help(method As %String = "") As %String
{
	If method="" {
		Set class=##class(%Dictionary.CompiledClass).%OpenId($classname())
		If class=$$$NULLOREF Write "Internal error",! Quit
		
		Write "'Do "_$replace($classname(),"%SYSTEM.","$system.")_".Help(method)' "_$$$GetSimpleMessage("%Compiler","OBJHelp"),!!
		Write $$$GetSimpleMessage("%Compiler","OBJMethodList")_$classname(),!
		For index=1:1:class.Methods.Count() {
			Set method=class.Methods.GetAt(index)
			If $extract(method.Name)="%" Continue
			Set description=method.Description
			If description'="",method.Private'=1,'method.Internal {
				Set spec=method.FormalSpec
				Set s=""
				For a=1:1:$L(spec,",")  Set s=s_$S(s="":"",1:",")_$P($P(spec,",",a),":")
				Write !,method.Name,"(",s,")",!
				Write ?5,$zconvert($piece(description,$char(13)),"I","HTML"),!
			}
		}
	} Else {
		Write $$$GetSimpleMessage("%Compiler","OBJMethodDesc")_method_":"_$classname(),!
		Set obj=##class(%Dictionary.CompiledMethod).%OpenId($classname()_"||"_method)
		If obj=$$$NULLOREF||(obj.Internal) {
			Write !,"'"_method_"'"_$$$GetSimpleMessage("%Compiler","OBJMethodNotExist"),!
		} Else {
			Write !,method,"(",obj.FormalSpec,")",!
			Write $zconvert(obj.Description,"I","HTML"),!
		}
	}
}

}
