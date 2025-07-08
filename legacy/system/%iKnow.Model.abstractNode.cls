/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Model.abstractNode Extends %DeepSee.Model.abstractNode [ Deprecated, System = 3 ]
{

/// Generate code needed to recreate this instance.
Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, pCollection As %String, pLevel As %Integer = 1, pKey As %String = "", pParentVar As %String = "unknown") [ CodeMode = objectgenerator, GenerateAfter = (%OnBeforeApplyParams, %OnAfterApplyParams), Internal ]
{
	#; Note: this method *generates* a code generator!

	#; Create a local varname based on our class name
	If (%class.Name = "%DeepSee.Model.cube") {
		#; for root, we always want to call our variable "tCube"
		Do %code.WriteLine(" Set tVar = ""tCube""_pLevel")
	}
	Else {
		Do %code.WriteLine(" Set tVar = """_$TR($P(%class.Name,".",$L(%class.Name,".")),"aeiou","")_"""_pLevel")
	}

	#; note: the order of actions is important:
	#; 1) create instances
	#; 2) fill in properties
	#; 3) add to parent
	#; 4) create children

	#; create instance
	Do %code.WriteLine(" Do pCode.WriteLine("" Set ""_tVar_"" = ##class("_%class.Name_").%New()"")")
	
	do %code.WriteLine(" do ..%OnBeforeApplyParams(pCode,tVar,##this)")
 
	#; list of special properties that we skip in code generation
	#; Set tIgnore("name")=""

	#; flag to indicate that there are children to process
	#; we want to defer these til later
	Set tHasChildren = 0

	#; get list of properties and set their values
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)

		#; filter out properties we do not care about
		#; namely: do not process items in tIgnore list or non-XML enabled % properties
		Set tSkip = 0
		If $D(tIgnore(tProp.Name)) {
			Set tSkip = 1
		}
		ElseIf ($E(tProp.Name,1,1)="%") {
			#; if someone sets XMLNAME for %prop then they must need it!
			If (tProp.Parameters.GetAt("XMLNAME")="") {
				Set tSkip = 1
			}
		}
		ElseIf (+tProp.Calculated) {
			#; The client-object model does not include calculated properties.
			Set tSkip = 1
		}

		If ('tSkip) {
			#; use InitialExpression to get default value
			Set tDefVal = tProp.InitialExpression
			
			#; make note of link properties
			If (tProp.Type = "%ZEN.Datatype.uri") {
				Do %code.WriteLine(" Set:(.."_tProp.Name_"'="""") pURIList(.."_tProp.Name_")= """"")
			}

			If (tProp.Collection = "list") {
				#; recurse over list
				Do %code.WriteLine(" For n=1:1:.."_tProp.Name_".Count() {")
				Do %code.WriteLine("  If ##class("_tProp.Type_").%IsA(""%DeepSee.Model.abstractNode"") {")
				Do %code.WriteLine("   Do .."_tProp.Name_".GetAt(n).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,,tVar)")
				Do %code.WriteLine("  } else {")
				Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_tVar_""."_tProp.Name_".SetAt(""_$$$QUOTE(.."_tProp.Name_".GetAt(n))_"", ""_n_"")"")")
				Do %code.WriteLine("  }")
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "array") {
				#; recurse over array
				Do %code.WriteLine(" Set key=.."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key'="""") {")
				Do %code.WriteLine("  If ##class("_tProp.Type_").%IsA(""%DeepSee.Model.abstractNode"") {")
				Do %code.WriteLine("   Do .."_tProp.Name_".GetAt(key).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,key,tVar)")
				Do %code.WriteLine("  } else {")
				Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_tVar_""."_tProp.Name_".SetAt(""_$$$QUOTE(.."_tProp.Name_".GetAt(key))_"", ""_$$$QUOTE(key)_"")"")")
				Do %code.WriteLine("  }")
				Do %code.WriteLine("  Set key=.."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
			}
			ElseIf ($$$comClassKeyGet(tProp.Type,$$$cCLASSclasstype)="") {
				#; simple (non-persistent, non-serial) object-valued property
				#; in this case, pCollection is the name of the container property
				#; and we use $C(0) as a key value to indicate this
				Do:(tProp.Inverse="") %code.WriteLine(" Do:($IsObject(.."_tProp.Name_")&&(##class("_tProp.Type_").%IsA(""%DeepSee.Model.abstractNode""))) .."_tProp.Name_".%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,$C(0),tVar)")
			}
			Else {
				#; this line generates a generator to get values for *normal* properties
				#; test if this value needs to be localized
				Set ZENLOCALIZE = tProp.Parameters.GetAt("ZENLOCALIZE")

				If (ZENLOCALIZE) {
					Do %code.WriteLine(" If (pLocalize) {")
					Do %code.WriteLine(" Do:(.."_tProp.Name_"'=("_tDefVal_")) pCode.WriteLine("" "_"Set ""_tVar_""."_tProp.Name_"=""_..%QuoteValueL10N(.."_tProp.Name_")_"""")")
					Do %code.WriteLine(" } Else {")
				}
				Do %code.WriteLine(" Do:(.."_tProp.Name_"'=("_tDefVal_")) pCode.WriteLine("" "_"Set ""_tVar_""."_tProp.Name_"=""_..%QuoteValue(.."_tProp.Name_"))")

				If (ZENLOCALIZE) { // close else
					Do %code.WriteLine(" }")
				}
			}
		}
	}

	#; insert in parent list (unless we are at the top)
	#; (less than ideal, but good enough)
	Do %code.WriteLine(" If (pLevel>1) {")
	Do %code.WriteLine("  If (pKey=$c(0)) {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Set ""_pParentVar_"".""_pCollection_"" = ""_tVar)")
	Do %code.WriteLine("  } else {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".Insert(""_tVar_"")"")")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")
	
	do %code.WriteLine(" do ..%OnAfterApplyParams(pCode,tVar,##this)")
	
	Quit $$$OK
}

ClassMethod %OnBeforeApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ Internal ]
{
}

ClassMethod %OnAfterApplyParams(pCode As %CharacterStream, pVar As %String, pObj) [ Internal ]
{
}

Method %ApplyOverrides(pGLVN As %String) [ Internal ]
{
}

}
