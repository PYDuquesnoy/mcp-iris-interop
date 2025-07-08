/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

IncludeGenerator %occUtility

/// Abstract base class for various Document meta-data objects.<br/>
Class %Document.Model.Schema.abstractNode Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, System = 3 ]
{

/// Do not include *this* class in the XML groupings.
Parameter XMLINCLUDEINGROUP = 0;

Parameter XMLIGNORENULL = "inputonly";

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// Generate code needed to recreate this instance.
Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, pCollection As %String, pLevel As %Integer = 1, pKey As %String = "", pParentVar As %String = "unknown") [ CodeMode = objectgenerator, Internal ]
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
				Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(n).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,,tVar)")
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "array") {
				#; recurse over array
				Do %code.WriteLine(" Set key=.."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key'="""") {")
				Do %code.WriteLine("  Do .."_tProp.Name_".GetAt(key).%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,key,tVar)")
				Do %code.WriteLine("  Set key=.."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
			}
			ElseIf ($$$comClassKeyGet(tProp.Type,$$$cCLASSclasstype)="") {
				#; simple (non-persistent, non-serial) object-valued property
				#; in this case, pCollection is the name of the container property
				#; and we use $C(0) as a key value to indicate this
				// Do %code.WriteLine(" Do:($IsObject(.."_tProp.Name_")&&(.."_tProp.Name_".%IsA(""%DeepSee.Model.abstractNode""))) .."_tProp.Name_".%GenerateCode(pCode,pLocalize,"""_tProp.Name_""",pLevel+1,$C(0),tVar)")
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
	Do %code.WriteLine("   Do pCode.WriteLine("" Do ""_pParentVar_"".""_pCollection_"".Insert(""_tVar_"")"")")
	Do %code.WriteLine(" }")
	Quit $$$OK
}

/// Take a value string and return a quoted string.
ClassMethod %QuoteValue(pValue As %String) As %String [ CodeMode = expression ]
{
$S($ListValid(pValue):..%QuoteList(pValue),1:$TR($$$quote(pValue),$C(10),""))
}

/// Take a $List value and return an express to construct it.
ClassMethod %QuoteList(pValue As %List) As %String
{
	Set tExpr = "$LB("
	For n = 1:1:$LL(pValue) {
		Set tExpr = tExpr _ $S(n>1:",",1:"") _ ..%QuoteValue($LG(pValue,n))
	}
	Set tExpr = tExpr _ ")"
	Quit tExpr
}

/// Take a value string and return a quoted string wrapped within a
/// $$$Text macro.<br>
/// If value starts and ends with #( )#, then return an expression
ClassMethod %QuoteValueL10N(pValue As %String) As %String
{
	Quit:$E(pValue,1,2)'="#(" "$$$Text("_..%QuoteValue(pValue)_")"
	Quit:$E(pValue,$L(pValue)-1,$L(pValue))'=")#" "$$$Text("_..%QuoteValue(pValue)_")"
	Quit ..%QuoteValue(pValue)
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject
{
	#; not supported
	Quit ""
}

Method %NormalizeObject() As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0, norecurseon As %String = "") As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %RemoveFromSaveSet() As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %BindExport(dev As %String, ByRef Seen As %String, RegisterOref As %Boolean, AllowedDepth As %Integer, AllowedCapacity As %Integer) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

/// Apply local overrides of values for this object.<br/>
/// This looks at the ^DeepSee.Override global and applies values to properties
/// within the model object.
Method %ApplyOverrides(pGLVN As %String) [ CodeMode = objectgenerator, Internal ]
{
	Set tSC= $$$OK
	Try {
		// ignore these properties
		Set tIgnore("name")=""

		#; tGLVN is glvn passed on to child objects
		Do %code.WriteLine(" If (..name'="""") {")
		Do %code.WriteLine("  Set tGLVN = $Name(@pGLVN@($$$UPPER(..name)))")

		#; get list of properties
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
				If (tProp.Collection = "list") {
					#; recurse over list (use prop name as qualifier)
					Do %code.WriteLine("  Set tGLVN2 = $Name(@tGLVN@("_$$$quote($$$UPPER(tProp.Name))_"))")
					Do %code.WriteLine("  For n=1:1:.."_tProp.Name_".Count() {")
					Do %code.WriteLine("   Do .."_tProp.Name_".GetAt(n).%ApplyOverrides(tGLVN2)")
					Do %code.WriteLine("  }")
				}
				ElseIf (tProp.Collection = "array") {
					#; recurse over array (use prop name as qualifier)
					Do %code.WriteLine("  Set tGLVN2 = $Name(@tGLVN@("_$$$quote($$$UPPER(tProp.Name))_"))")
					Do %code.WriteLine("  Set key=.."_tProp.Name_".Next("""")")
					Do %code.WriteLine("  While (key'="""") {")
					Do %code.WriteLine("   Do .."_tProp.Name_".GetAt(key).%ApplyOverrides(tGLVN2)")
					Do %code.WriteLine("   Set key=.."_tProp.Name_".Next(key)")
					Do %code.WriteLine("  }")
				}
				ElseIf ($$$comClassKeyGet(tProp.Type,$$$cCLASSclasstype)="") {
					#; simple (non-persistent, non-serial) object-valued property
					#; in this case, pCollection is the name of the container property
					#; and we use $C(0) as a key value to indicate this
					// Do %code.WriteLine("  Do:($IsObject(.."_tProp.Name_")&&(.."_tProp.Name_".%IsA(""%DeepSee.Model.abstractNode""))) .."_tProp.Name_".%ApplyOverrides(tGLVN)")
				}
				Else {
					Do %code.WriteLine("  If ($D(@tGLVN@("_$$$quote($$$UPPER(tProp.Name))_"))) {")
					Do %code.WriteLine("   Set .."_tProp.Name_" = @tGLVN@("_$$$quote($$$UPPER(tProp.Name))_")")
					Do %code.WriteLine("   Write !,""Applying override to: "","_$$$quote(tProp.Name)_","" = "",$$$quote(.."_tProp.Name_")")
					Do %code.WriteLine("  }")
				}
			}
		}
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Quit $$$OK")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
