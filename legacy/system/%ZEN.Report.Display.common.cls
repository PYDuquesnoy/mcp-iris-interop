/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.common Extends (%RegisteredObject, %XML.Adaptor) [ Deprecated, Inheritance = right, PropertyClass = %ZEN.Report.Display.displayParameters, System = 4 ]
{

/// XML namespace used for Zen Report display definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display";

/// If XMLFORMAT="Literal", then only support for literal format import and export is generated.<br>
Parameter XMLFORMAT = "Literal";

/// This is a unique identifier that is used to distinguish this object
/// from other objects within the same Zen Report Display.<br/>
/// You can find an object with a given id value using the node object's
/// <method>getComponentById</method> method.<br>
Property id As %ZEN.Datatype.string;

Property parent As %ZEN.Report.Display.node(XMLPROJECTION = "NONE") [ Internal ];

/// For components that are created as part of a composite(template component,
/// this is a link to the composite that contains this object.
/// Applications should not set this property.
Property composite As composite(XMLPROJECTION = "none") [ Final ];

/// Generate code needed to recreate this instance.
Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, pCollection As %String, pLevel As %Integer = 1, pKey As %String = "", pParentVar As %String = "unknown", pReturnInParent As %Boolean = 0, pMode As %String = "report") [ CodeMode = objectgenerator, Internal ]
{
	#; Note: this method *generates* a code generator!
	#; Do %code.WriteLine(" Do pCode.WriteLine("" // "_%class.Name_""")")

	Set tSC=$$$OK
	#; Create a local varname based on our class name
	If (%class.Name = "%ZEN.Report.Display.report") {
		#; for root, we always want to call our variable "report"
		Do %code.WriteLine(" Set tVar = ""report""_pLevel")
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
	Do %code.WriteLine(" If (pLevel>1) {")
	Do %code.WriteLine("  Do pCode.WriteLine("" New ""_tVar)")
	Do %code.WriteLine("  Do pCode.WriteLine("" Set ""_tVar_"" = ##class("_%class.Name_").%New()"")")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("   If (pMode = ""composite"") {")
	Do %code.WriteLine("    Do pCode.WriteLine("" New ""_tVar)")
	Do %code.WriteLine("    Do pCode.WriteLine("" Set ""_tVar_"" = ##this"")")
	Do %code.WriteLine("   } Else {")
	Do %code.WriteLine("     Do pCode.WriteLine("" New ""_tVar)")
	Do %code.WriteLine("     Do pCode.WriteLine("" Set ""_tVar_"" = ##class("_%class.Name_").%New()"")")
	#; set %report *here* as user code may reference it
    Do %code.WriteLine("   	 Do pCode.WriteLine("" New %display Set %display = ""_tVar_"""")")
	Do %code.WriteLine("   }")
	Do %code.WriteLine(" }")
	
	
	#; list of special properties that we skip in code generation
	#; Set tIgnore("name")=""
	Set tIgnore("composite")=""
	Do %code.WriteLine("  Do:$IsObject($g(%composite)) pCode.WriteLine("" Set:$IsObject($g(%composite)) ""_tVar_"".composite = %composite"")")
	#;Set tName="composite"
	#; Do %code.WriteLine(" Do:(.."_tName_"'="""") pCode.WriteLine("" "_"Set ""_tVar_""."_tName_"=""_..%QuoteValue(.."_tName_"))")

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
				If tProp.Name = "children" {
					#; defer child processing
					Set tHasChildren = 1
				}
				Else {
					#; recurse over list
					Do %code.WriteLine(" For n=1:1:.."_tProp.Name_".Count() {")
					Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(n).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,,tVar,pMode)")
					Do %code.WriteLine(" }")
				}
			}
			ElseIf (tProp.Collection = "array") {
				#; recurse over array
				Do %code.WriteLine(" Set key=.."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key'="""") {")
				Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(key).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,key,tVar,pMode)")
				Do %code.WriteLine("  Set key=.."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
			}
			ElseIf ($$$comClassKeyGet(tProp.Type,$$$cCLASSclasstype)="") {
				#; simple (non-persistent, non-serial) object-valued property
				#; in this case, pCollection is the name of the container property
				#; and we use $C(0) as a key value to indicate this
				Do:tProp.Name'="parent" %code.WriteLine(" Do:($IsObject(.."_tProp.Name_")&&(.."_tProp.Name_".%IsA(""%ZEN.Report.Display.common""))) .."_tProp.Name_".%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,$C(0),tVar,pMode)")
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
				Do %code.WriteLine(" Do:(.."_tProp.Name_"'=("_tDefVal_")) pCode.WriteLine("" "_"Set ""_tVar_""."_tProp.Name_"=""_..%QuoteValueEmbedded(.."_tProp.Name_"))")

				If (ZENLOCALIZE) { // close else
					Do %code.WriteLine(" }")
				}
			}
		}
	}

	#; insert in parent list (unless we are at the top)
	#; There is a special case for "children" of groups
	#; In ZenUI such children are *registered* with the page (by %AddChild)
	#; or explicitly added to the page with a call %AddToPage. For Reports
	#; we just need to cover template/composite objects - instead of calling
	#; %AddChild, we'll just use insert and manually set the composite property
	#; this has to be done right after creating the component
	Do %code.WriteLine(" If (pLevel>1) {")
	Do %code.WriteLine("  If (pKey="""") {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".Insert(""_tVar_"")"")")
	Do %code.WriteLine("  }")
	Do %code.WriteLine("  ElseIf (pKey=$C(0)) {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Set ""_pParentVar_"".""_pCollection_"" = ""_tVar)")
	Do %code.WriteLine("   Do pCode.WriteLine("" Set ""_tVar_"".parent = ""_pParentVar)")
	Do %code.WriteLine("  }")
	Do %code.WriteLine("  Else {")
	Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".SetAt(""_tVar_"",""""""_pKey_"""""")"")")
	Do %code.WriteLine("   Do pCode.WriteLine("" Set ""_tVar_"".parent = ""_pParentVar)")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" ElseIf (pReturnInParent) {")
	Do %code.WriteLine("  Do pCode.WriteLine("" Set ""_pParentVar_"" = ""_tVar)")
	Do %code.WriteLine(" }")
	
	set tIsComposite=%compiledclass.PrimarySuper["~%ZEN.Report.Display.composite~"
	Set tName="children"
	If tHasChildren {
		Do:tIsComposite %code.WriteLine(" If pMode'=""composite"" {")
		Do:tIsComposite %code.WriteLine("   Do pCode.WriteLine("" d ""_tVar_"".%CreateComposite()"")")
		Do:tIsComposite %code.WriteLine("  }")
		Do:tIsComposite %code.WriteLine(" Else {")	
					#; recurse over list
					Do %code.WriteLine("   For n=1:1:.."_tName_".Count() {")
					Do %code.WriteLine("      Do .."_tName_".GetAt(n).%GenerateCode(pCode,pLocalize,"""_tName_""",pLevel+1,,tVar,pMode)")
					Do %code.WriteLine("   }")
		Do:tIsComposite %code.WriteLine(" }")
	}

	#; add report diplay node id to index of id values
	#; we assume that id value is set *before* component is added to its
	#; parent group
	Do %code.WriteLine(" Do pCode.WriteLine("" If (""_tVar_"".id'="""""""") {"")")
		;Do %code.WriteLine(" Do pCode.WriteL Set:$D(..%ComponentIds(tVar.id)) tSC=$$$ERROR($$$GeneralError,""More than one component with id: '"" _ tVar.id _""'."")")
		Do %code.WriteLine(" Do pCode.WriteLine("" Set %ComponentIds(""_tVar_"".id) = ""_tVar)")
	Do %code.WriteLine(" Do pCode.WriteLine("" }"")")
	Quit tSC
}

ClassMethod %QuoteValueEmbedded(pValue As %String)
{
	Set expr=""
	Set position=1
	while (position'=0) {
		Set oldposition=position
		Set position=$find(pValue,"#(",position)
		if position'=0 {
			Set position1=$find(pValue,")#",position)
			if position1'=0 {
				Set expr1=""
				if (position>3) Set expr1=..%QuoteValue($e(pValue,oldposition,position-3))
				Set expr2=..%QuoteValue($e(pValue,position-2,position1-1))
				Set expr3=""
				Set position2=$find(pValue,"#(",position)
				if (position2=0) {
					Set position3=$L(pValue)
					Set position=0
				}
				else {
					Set position3=position2-3
					Set position=position2-2
				}
				if position3>=position1 Set expr3=..%QuoteValue($e(pValue,position1,position3))
				Set expr=$s(expr'="":expr_"_",1:"")_$s(expr1'="":expr1_"_",1:"")_expr2_$s(expr3'="":"_"_expr3,1:"")
				
			} else {
				Set expr=$s(expr'="":expr_"_",1:"")_..%QuoteValue($e(pValue,oldposition,$L(pValue)))
				Set position=0
			}
		} else {
			Set expr=$s(expr'="":expr_"_",1:"")_..%QuoteValue($e(pValue,oldposition,$L(pValue)))
			Set position=0
		}
	}
	Quit expr
}

/// Take a value string and return a quoted string.
ClassMethod %QuoteValue(pValue As %String) [ CodeMode = expression ]
{
$S((pValue=$c(0)):"""""",$E(pValue,1,2)'="#("&&($E(pValue,$L(pValue)-1,$L(pValue))'=")#"):$TR($zu(144,1,pValue),$C(10),""),1:$TR($E(pValue,3,*-2),$C(10),""))
}

/// Take a value string and return a quoted string wrapped within a
/// $$$Text macro.<br>
/// If value starts and ends with #( )#, then return an expression
ClassMethod %QuoteValueL10N(pValue As %String)
{
	Quit:$E(pValue,1,2)'="#(" "$$$Text("_..%QuoteValue(pValue)_")"
	Quit:$E(pValue,$L(pValue)-1,$L(pValue))'=")#" "$$$Text("_..%QuoteValue(pValue)_")"

	#; return run-time expression
	Quit ..%QuoteValue(pValue)
}

}
