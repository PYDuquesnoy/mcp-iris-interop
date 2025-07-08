/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class contains various methods needed by 
/// method generators within the ZEN framework.<br>
/// This is an internal class. Applications should not make direct use
/// of the methods within this class.
Class %ZEN.Generator Extends %RegisteredObject [ Deprecated, System = 2 ]
{

/// Generates code for the %ApplyURLParms method.
ClassMethod %GenerateApplyURLParms() As %Status
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

    #; find all properties with ZENURL parameter defined
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" If $IsObject($G(%request)) {")

	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tParm = tProp.Parameters.GetAt("ZENURL")
		If (tParm'="") {
			Do %code.WriteLine("  Set .."_tProp.Name_" = $G(%request.Data("""_tParm_""",1),.."_tProp.Name_")")
			Do %code.WriteLine("  If (.."_tProp.Name_" '= """") {")
			Do %code.WriteLine("   Set tSC1 = .."_tProp.Name_"IsValid(.."_tProp.Name_")")
			Do %code.WriteLine("   If $$$ISERR(tSC1) { Set tSC1 = $$$ERROR($$$GeneralError,""Invalid URL parameter: "_tParm_""") Set tSC = $$$ADDSC(tSC,tSC1) }")
			Do %code.WriteLine("  }")
		}
	}
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Called in the context of a method generator.
/// Tests if the given XData block exists and has some content in it.
/// pLocalOnly restricts the check to XDatas that originate in the current class.
ClassMethod %DoesXDataExist(pXDataName As %String, pLocalOnly As %Boolean = 0) As %Boolean
{
	If '##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||"_pXDataName) Quit 0
	Set tExists = 0

	#; find XDATA block
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||"_pXDataName)

	If (tIndex '= "") {
		Set tXData = %compiledclass.XDatas.GetAt(tIndex)
		#; Ensure we don't use an inherited XData block if pLocalOnly is true
		If pLocalOnly && (tXData.Origin '= %class.Name) {
			Set tExists = 0
		}
		Else {
			#; get XDATA as stream
			Set tStream = tXData.Data
			If (tStream.Size > 0) {
				Set tExists = 1
			}
		}
	}
	Quit tExists
}

/// Generates code for the given XData block that
/// will write out the contents of the XData block as a Style Sheet
/// Used for Style sheets.
/// This method assumes it is being called in the context of
/// a method generator.
ClassMethod %GenerateStyleSheet(pXDataName As %String) As %Status
{

	#; marker to indicate where style comes from
	#; (and makes sure method has *some* code)
	Do %code.WriteLine(" &html<<!-- "_pXDataName_": #($classname())# -->>")
	If '##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||"_pXDataName) Quit $$$OK

	#; find XDATA block
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||"_pXDataName)
	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		#; generate code to write out contents of XDATA block
		If (tStream.Size > 0) {
			// JMD1187 &html< does not handle ">" well; use the WRITE command
			While ('tStream.AtEnd) {
				Set tLine = tStream.ReadLine()
				Set tLine = $ZSTRIP(tLine,"<>W")
				If (tLine'="") {
					// check for #()#
					If ((tLine["#(")&&(tLine[")#")) {
						Do %code.Write(" Write ")
						Set p1 = 1
						Set p2 = $Find(tLine,"#(")
						While (p2) {
							Do:p1>1 %code.Write(",")
							Do %code.Write($$$quote($E(tLine,p1,p2-3)))

							// )#
							Set p1 = p2
							Set p2 = $Find(tLine,")#",p2)
							If (p2) {
								Do %code.Write(","_$E(tLine,p1,p2-3))

								// next #()#
								Set p1 = p2
								Set p2 = $Find(tLine,"#(",p2)
							}
						}
						If ((p1>1) && (p1<$L(tLine))) {
							Do %code.Write(","_$$$quote($E(tLine,p1,*)))
						}
						Do %code.WriteLine(",!")
					}
					Else {
						Do %code.WriteLine(" Write "_$$$quote(tLine)_",!")
					}
				}
			}
		}
	}
	Quit $$$OK
}

/// Draw JavaScript needed to define client-side class for this component.<br>
/// This is the logic of the %DrawClassDefinition method generator
/// of %ZEN.Component.object.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present.<br>
/// It is also assumed that this is called *before* server
/// serialization methods are generated, as this creates serialization
/// metadata as a side effect.
ClassMethod %DrawClassDefinition() As %Status
{
	#; Convert a server class name to a JavaScript class name.
#define MakeJSClassName(%cls) ($TR(%cls,"%.","__"))
	
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; build list of our super classes (we can't rely on %IsA in a generator)
		Set ancestors="~"
		Set super=%compiledclass.Name
		For  Set ancestors=ancestors_super_"~" Set super=$piece($$$comClassKeyGet(super,$$$cCLASSsuper),",") Quit:super=""

		#; find all JavaScript methods
		#; these are client-side methods
		Set tCount = %compiledclass.Methods.Count()
		For n = 1:1:tCount {
			Set tMethod = %compiledclass.Methods.GetAt(n)
			If tMethod=$$$NULLOREF Return $$$EMBEDERROR($get(%objlasterror,$$$OK),$$$GeneralError,"Class "_%compiledclass.Name_" method "_n)
			If ((tMethod.ClientMethod) && (tMethod.Language = "javascript") && ('tMethod.Abstract)){
				Set tMethods(tMethod.Name) = tMethod
			}
		}

        #; get list of server methods callable from client
        #; use ZenMethod keyword
		#; from 2013.1 onward only ZenMethod is allowed
		For n = 1:1:%compiledclass.Methods.Count() {
			Set tMethod = %compiledclass.Methods.GetAt(n)
			If (tMethod.ZenMethod) {
				Set tSvrMethods(tMethod.Name) = tMethod
			}
		}

        #; get list of client properties
		For n = 1:1:%compiledclass.Properties.Count() {
			Set tProp = %compiledclass.Properties.GetAt(n)
			Set tProperties(tProp.Name) = tProp
		}

		#; test for javascript reserved words
		For tWord = "class" {
			If ($D(tProperties(tWord))) {
				Set tSC = $$$ERROR($$$GeneralError,"JavaScript reserved word cannot be used as a property name: "_tWord)
				Quit
			}
		}

		Do %code.WriteLine(" Write !")
		// Do %code.WriteLine(" Write ""// "_$TR($J(" ",80)," ","=")_""",!") // separator line

		#; normalize class name
		Set tCls = $$$MakeJSClassName(%compiledclass.Name)

		#; add this class to client index of short names to JavaScript names

		#; find xml namespace of component
		#; for library components, we use "" for NS within the index
		Set tNS = ""
		If ($G(%parameter("NAMESPACE"))'="") {
			Set tNS = %parameter("NAMESPACE")
			Set:tNS="http://www.intersystems.com/zen" tNS = ""
		}

		#; If there is an XMLNAME, use it for the component name
		If ((%class.Name'="%ZEN.Component.abstractPage")&&($G(%parameter("XMLNAME"))'="")) {
			Set tElementName = %parameter("XMLNAME")
		}
		Else { 
			Set tElementName = $P(%class.Name,".",$L(%class.Name,"."))
		}
		Set tIdx = $S(tNS="":tElementName,1:tNS_"/"_tElementName)
		Do %code.WriteLine(" Write ""self._zenClassIdx['"_tIdx_"'] = '"_tCls_"';"",!")

		#; write out client object constructor
		Do %code.WriteLine(" Write ""self."_tCls_" = function(index,id) {"",!")
		Do %code.WriteLine(" Write $C(9),""if (index>=0) {"_tCls_"__init(this,index,id);}"",!")
		Do %code.WriteLine(" Write ""}"",!")

		#; write out _init function: this does the actual construction
		Do %code.WriteLine(" Write !")
		Do %code.WriteLine(" Write ""self."_tCls_"__init = function(o,index,id) {"",!")

		#; note that we use javascript prototypes to assign methods to classes

		#; initialize properties for this class (special cases first)
		#; this code only gets placed in constructor for base object;
		#; other components will dispatch to this
		#; (N.B. special case for svgPage)
		If ((%compiledclass.Name = "%ZEN.Component.object")||(%compiledclass.Name = "%ZEN.SVGComponent.svgPage")) {
			Do %code.WriteLine(" Write $C(9),""o.index = index;"",!")
			Do %code.WriteLine(" Write $C(9),""o.id = id;"",!")
			Do %code.WriteLine(" Write $C(9),""o.name = '';"",!")
			Do %code.WriteLine(" Write $C(9),""o.parent = null;"",!")
			Do %code.WriteLine(" Write $C(9),""o.composite = null;"",!")
			Set tSuper = ""
		}
		Else {
			#; generate call to super class init function
			Set tSuper = $P(%compiledclass.Super,",",1)
			If (tSuper '= "") {
				Set tSuperCls = $$$MakeJSClassName(tSuper)
				#; test if super is in another frame
				Do %code.WriteLine(" Write $C(9),""('undefined' == typeof "_tSuperCls_"__init) ?""")
				Do %code.WriteLine(" Write ""zenMaster."_tSuperCls_"__init(o,index,id)""")
				Do %code.WriteLine(" Write "":""")
				Do %code.WriteLine(" Write """_tSuperCls_"__init(o,index,id);"",!")
			}
		}
		#; build list of client properties to use for client serialization
		#; 
		#; N[umber],O[ref],P[arent],B[oolean],A[rray],L[ist],E[ncrypted],S[tring],Z[ieceList]
		#; AO,LO (object collection), P[arent]
		#; index # must be first

		#; names of serialized properties
		Set tSerialProps = "index!id!name!parent!composite"
		#; types
		Set tSerialTypes = "N!S!S!P!O"
		
		#; is this property a "setting"? If so put its name here
		If (%class.Name '= "%ZEN.Component.object") {
			Set tSettings = "!!name!!"
		}
		Else {
			Set tSettings = "!id!name!!"
		}
		#; what type of setting: default is "string"
		Set tSettingTypes = "!!!!"

		Set tSkip("id") = ""
		Set tSkip("name") = ""
		Set tSkip("index") = ""
		Set tSkip("parent") = ""
		Set tSkip("composite") = ""

		Set tName = $O(tProperties(""))
		While (tName '= "") {
			#; get non-% properties, skip items in tSkip
			If ('$D(tSkip(tName)) && ($E(tName,1,1)'="%") && '+tProperties(tName).MultiDimensional) {

				Set tType = ..GetPropertyType(tProperties(tName))
				Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)

				#; see if this is an inherited property
				Set tOrigin = tProperties(tName).Origin
				Set tInherit = (tOrigin '= %class.Name)&&(tOrigin'="")

				#; if property is inherited from a secondary class
				#; that is not a component
				#; then do not treat it as inherited
				If (tInherit) {
					Set tInherit = $$$comClassKeyGet(tOrigin,$$$cCLASSprimarysuper)["~%ZEN.Component.object~"
				}

				Set ZENCLIENTONLY = +tProperties(tName).Parameters.GetAt("ZENCLIENTONLY")
				Set ZENENCRYPT = +tProperties(tName).Parameters.GetAt("ZENENCRYPT")
				Set ZENSETTING = +tProperties(tName).Parameters.GetAt("ZENSETTING")
				Set tSettingType=""

				If (('tInherit)&&ZENSETTING) {
					#; what type of setting to report
					#; use ZEN datatype name
					If (($P(tType,".",1,2)="%ZEN.Datatype")) {
						Set t = $P(tType,".",$L(tType,"."))
						Set:t'="string" tSettingType = t
						#; we may need to add some decoration to the type
						If (t = "classMember") {
							#; special case for class members
							Set MEMBERTYPE = tProperties(tName).Parameters.GetAt("MEMBERTYPE")
							If (MEMBERTYPE'="") {
								Set tSettingType = tSettingType_":"_MEMBERTYPE
							}
						}
						ElseIf (t = "className") {
							#; special case for class names
							Set SUBCLASSOF = tProperties(tName).Parameters.GetAt("SUBCLASSOF")
							If (SUBCLASSOF'="") {
								Set tSettingType = tSettingType_":"_SUBCLASSOF
							}
						}
						Else {
							#; test for enums (assume they start with ","
							Set VALUELIST = tProperties(tName).Parameters.GetAt("VALUELIST")
							If (VALUELIST'="") {
								Set VALUELIST = $E(VALUELIST,2,*)
								Set tSettingType = "enum:"_VALUELIST
								Set DISPLAYLIST = tProperties(tName).Parameters.GetAt("DISPLAYLIST")
								If (DISPLAYLIST'="") {
									Set DISPLAYLIST = $E(DISPLAYLIST,2,*)
									Set tSettingType = tSettingType_":"_DISPLAYLIST
								}
							}
						}
					}
				}
				#; write out initializer for property
				#; add property to serialize list
				If (tProperties(tName).Collection = "list") {
					#; list collection
					Do:'tInherit %code.WriteLine(" Write $C(9),""o."_tName_" = new Array();"",!")
					Set tTypeCode = $S($$$classIsDataType(tType):"L",1:"LO")
				}
				ElseIf (tProperties(tName).Collection = "array") {
					#; array collection: use Object and add special marker
					Do:'tInherit %code.WriteLine(" Write $C(9),""o."_tName_" = new Object();"",!")
					Set tTypeCode = $S($$$classIsDataType(tType):"A",1:"AO")
				}
				ElseIf (tProperties(tName).Collection = "") {
					#; normal property: initial value is ''
					#; use InitialExpression to get default value
					Set tDefVal = tProperties(tName).InitialExpression
					Set tInitProp = ('tInherit||(tDefVal'=""""""))

					If (tInherit && tInitProp && (tSuper'="")) {
						#; see if the default value for inherited properties
						#; is different than the parent class

						#; see if def val is a literal
						If ((tDefVal = +tDefVal) || (($E(tDefVal,1)="""")&&($E(tDefVal,$L(tDefVal))="""")&&($E(tDefVal,2,$L(tDefVal)-1)'[""""))) {
							Set tSuperDefVal = $$$comMemberKeyGet(tSuper,$$$cCLASSproperty,tName,$$$cPROPinitialexpression)
							If (tDefVal=tSuperDefVal) {
								Set tInitProp = 0
							}
						}
						ElseIf($E(tDefVal,1,3)="..#") {
							#; assume this is a parameter
							Set tSuperDefVal = $$$comMemberKeyGet(tSuper,$$$cCLASSproperty,tName,$$$cPROPinitialexpression)
							If (tSuperDefVal = tDefVal) {
								Set tPm = $E(tDefVal,4,$L(tDefVal))
								Set tPVal = $$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSparameter,tPm,$$$cPARAMdefault)
								Set tSuperPVal = $$$comMemberKeyGet(tSuper,$$$cCLASSparameter,tPm,$$$cPARAMdefault)
								If (tPVal = tSuperPVal) {
									Set tInitProp = 0
								}
							}
						}
					}

					If (ZENCLIENTONLY) {
						#; initialize to null
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = null;"",!")
					}
					ElseIf (ZENENCRYPT) {
						#; never place encrypted values into the constructor
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = ''; // encrypted"",!")
					}
					ElseIf (tClientType = "BOOLEAN") {
						#; convert to true/false
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = "",$S(+("_tDefVal_"):""true"",1:""false""),"";"",!")
					}
					ElseIf (tType="%ZEN.Datatype.list") {
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = new Array();"",!")
					}
					ElseIf ('$$$classIsDataType(tType)) {
						#; object property
						#; note: if not a ZEN.component, this property is set to null and then ignored
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = null;"",!")
					}
					Else {
						#; JMD1242: make sure def val is escaped!
						Do:tInitProp %code.WriteLine(" Write $C(9),""o."_tName_" = '""_$ZCVT("_tDefVal_",""O"",""JS"")_""';"",!")
					}

					#; find best serial type using client type
					If ('$$$classIsDataType(tType)) {
						Set tTypeCode = "O" // oref
					}
					ElseIf (ZENENCRYPT) {
						Set tTypeCode = "E"
					}
					ElseIf (tType="%ZEN.Datatype.list") {
						Set tTypeCode = "Z" // piece list
					}
					Else {
						Set tTypeCode = $Case(tClientType,"BOOLEAN":"B","INTEGER":"N","NUMERIC":"N","DOUBLE":"N",:"S")
					}
				}

				#; add property to serialize list "!"-delimited
				If ('ZENCLIENTONLY) {
					Set tSerialTypes = tSerialTypes _ $S(tSerialTypes="":"",1:"!") _ tTypeCode
					Set tSerialProps = tSerialProps _ $S(tSerialProps="":"",1:"!") _ tName
					If (('tInherit)&&ZENSETTING) {
						Set tSettings = tSettings _ $S(tSettings="":"",1:"!") _ tName
						Set tSettingTypes = tSettingTypes _ $S(tSettingTypes="":"",1:"!") _ tSettingType
					}
				}
			}
			#; next property
			Set tName = $O(tProperties(tName))
		}

		#; calculate CRC of serialProps; this serves as the "signature" for 
		#; an object; we use this to test if a serial state from a client
		#; matches the server code
		Set tCRC = $ZCRC(tSerialProps,7)

		#; cache serialization data
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Ancestors") = ancestors
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialProps") = tSerialProps
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialTypes") = tSerialTypes
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Settings") = tSettings
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SettingTypes") = tSettingTypes
		Set ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"CRC") = tCRC

		#; if present, invoke onCreate callback
		If ($D(tMethods("onCreate"))) {
			Do %code.WriteLine(" Write $C(9),""o.onCreate();"",!")
		}

		#; end of init function
		Do %code.WriteLine(" Write ""}"",!")

		#; call method to draw client serialization method
		Do %code.WriteLine(" Set tSC=..%DrawJSSerialize()")
		Do %code.WriteLine(" Quit:$$$ISERR(tSC) tSC")

		#; call method to draw client getSetting method
		Do %code.WriteLine(" Set tSC=..%DrawJSGetSettings()")
		Do %code.WriteLine(" Quit:$$$ISERR(tSC) tSC")

		#; write out client method implementations
		#; gather list of methods in tProtoList so we can later
		#; build the classLoader code
		Set tName = $O(tMethods(""))
		While (tName '= "") {
			Set tMethod = tMethods(tName)

			#; see if we can inherit this method
			Set tInherit = (tMethod.Origin '= %class.Name)

			#; if method is inherited from a secondary class
			#; that is not a component
			#; then do not treat it as inherited
			If (tInherit) {
				Set tInherit = $$$comClassKeyGet(tMethod.Origin,$$$cCLASSprimarysuper)["~%ZEN.Component.object~"
			}

			#; we do not need to worry about inherited methods
			If ('tInherit) {
				#; point prototype to actual method implementation
				Set tOrigin = $$$MakeJSClassName(tMethod.Origin)

				#; build clean list of args (no types)
				Set tArgList = tMethod.FormalSpecParsed
				Set tArgs = ""
				For n = 1:1:$LL(tArgList) {
					Set tArgs = tArgs _ $S(tArgs="":"",1:",") _ $LG($LG(tArgList,n),1)
				}

				#; check for localized strings in js method code
				Set DOMAIN = $G(%parameter("DOMAIN"))
				Set tSC = ..%FindLocalizedText(tMethod,DOMAIN,.tTextList)
				If $$$ISERR(tSC) Quit

				#; use helper tag to write out client method
				Do %code.WriteLine(" Do JSClientMethod("""_tName_""","""_tArgs_""")")
				Set tProtoList(tName) = ""
			}

			#; next method
			Set tName = $O(tMethods(tName))
		}

		#; cache list of localized strings
		Merge ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"TextList") = tTextList

		#; write out implementation of client-side wrappers for server methods
		Set tName = $O(tSvrMethods(""))
		While (tName '= "") {
			Set tMethod = tSvrMethods(tName) // method object

			#; build client-side arg list
			Set tArgList = tMethod.FormalSpecParsed
			Set tArgs = ""
			Set tSpec = ""
			For n = 1:1:$LL(tArgList) {
				Set tArgs = tArgs _ $S(tArgs="":"",1:",") _ $LG($LG(tArgList,n),1)

				Set tArgType = $LG($LG(tArgList,n),2)
				Set tArgClassType = $$$comClassKeyGet(tArgType,$$$cCLASSclasstype)

				#; determine if each argument is L(iteral), B(oolean) or O(bject)
				If (tArgClassType="datatype") {
					Set tArgClientType = $$$comClassKeyGet(tArgType,$$$cCLASSclientdatatype)
					If (tArgClientType = "BOOLEAN") {
						Set tArgCode = "B" // boolean
					}
					Else {
						Set tArgCode = "L" // literal
					}
				}
				Else {
					#; special case for list and arrays:
					If (tArgType = "%Library.ArrayOfDataTypes") {
						Set tArgCode = "A" // array
					}
					ElseIf (tArgType = "%Library.ListOfDataTypes") {
						Set tArgCode = "LI" // list
					}
					Else {
						Set tArgCode = "O" // object
					}
				}

				Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tArgCode
			}

			#; get client-type of returnType
			Set tRetType = tMethod.ReturnType
			#; special case for list and arrays:
			If (tRetType = "%Library.ArrayOfDataTypes") {
				Set tRetType = "ARRAYDT" // array
			}
			ElseIf (tRetType = "%Library.ListOfDataTypes") {
				Set tRetType = "LISTDT" // list
			}
			Else {
				Set:tRetType'="" tRetType = $$$comClassKeyGet(tRetType,$$$cCLASSclientdatatype)
			}

			#; use helper tag to write out server method stubs
			Do %code.WriteLine(" Do JSSvrMethod("_+tMethod.ClassMethod_","""_tRetType_""","""_tName_""","""_tArgs_""","""_tSpec_""")")

			Set tProtoList(tName) = ""

			#; next method
			Set tName = $O(tSvrMethods(tName))
		}

		#; create classLoader
		Do %code.WriteLine(" Write ""self."_tCls_"__Loader = function() {"",!")

		#; define local var to cut down on code size
		Do %code.WriteLine(" Set tCls = """_tCls_"""")

		#; prototype properties
		#; see if we have a superclass
		Set tSuperCls = ""
		If ((%class.Name '= "%ZEN.Component.object")&&(%class.Name'="%ZEN.SVGComponent.svgPage")) {
			Set tSuper = $P(%compiledclass.Super,",",1)
			If (tSuper '= "") {
				Set tSuperCls = $$$MakeJSClassName(tSuper)
			}
		}

		#; deal with inheritance
		If (tSuperCls '= "") {
			#; first make sure our super class is loaded
			Do %code.WriteLine(" Write $C(9),""zenLoadClass('"_tSuperCls_"');"",!")
			
			#; force our prototype to be an instance of our
			#; superclass to inherit its methods
			#; use zenCreate to make sure correct context is determined
			Do %code.WriteLine(" Write $C(9),tCls,"".prototype = zenCreate('"_tSuperCls_"',-1);"",!")
		}

		#; set local var to object prototype to save space
		Do %code.WriteLine(" Write $C(9),""var p = "",tCls,"".prototype;"",!")
		Do %code.WriteLine(" Write $C(9),""if (null==p) {return;}"",!")

		#; make sure our constructor function is set up
		#; this.superClass points to our superclass prototype
		#; this makes this.superClass.method syntax work
		#; get primary super class and normalize
		#; n.b. "super" is a js reserved word, so we use superClass
		If (tSuperCls '= "") {
			Do %code.WriteLine(" Write $C(9),""p.constructor = "",tCls,"";"",!")
			Do %code.WriteLine(" Write $C(9),""p.superClass = ('undefined' == typeof "_tSuperCls_") ? zenMaster."_tSuperCls_".prototype:"_tSuperCls_".prototype;"",!")
		}

		#; set flag to indicate this is a ZENcomponent
		Do %code.WriteLine(" Write $C(9),""p.__ZENcomponent = true;"",!")

		#; set client (prototype) property with server class name
		Do %code.WriteLine(" Write $C(9),""p._serverClass = '""_$ZCVT("""_%class.Name_""",""O"",""JS"")_""';"",!")

		#; set client (prototype) property with component type
		Set tCompType = $P(%class.Name,".",$L(%class.Name,"."))
		Do %code.WriteLine(" Write $C(9),""p._type = '""_"""_tCompType_"""_""';"",!")

		#; client serialization methods
		Do %code.WriteLine(" Write $C(9),""p.serialize = "",tCls,""_serialize;"",!")

		#; client getSetting method
		Do %code.WriteLine(" Write $C(9),""p.getSettings = "",tCls,""_getSettings;"",!")

		#; set up pointers to our methods
		Set tName = $O(tProtoList(""))
		While (tName '= "") {
			Do %code.WriteLine(" Write $C(9),""p."_tName_" = "",tCls,""_"_tName_";"",!")
			Set tName = $O(tProtoList(tName))
		}
		Do %code.WriteLine(" Write ""}"",!")

		Do %code.WriteLine(" Quit $$$OK")

		#; post-script: define some useful code snippets as local
		#; tags to cut down on code size

		#; JSClientMethod
		#; Writes out client-side method definition
		#; method is method name, args is spec

		#; n.b. rather than generate a series of Write statements to
		#; render client-side method bodies, we will instead get the
		#; method directly from oddCOM at run-time; this cuts down on
		#; code size and avoids potential method-too-big problems.
		#; Downside is that you cannot use "deployed" mode on this class
		#; (though if you pre-generate .js file, this should be possible!)
		
		#; NOTE: If we switch namespaces via $NAMESPACE, then JSClientMethod *must*
		#;       be called in the namespace in which the class was actually compiled
		#;       unless the class is mapped everywhere.

		Do %code.WriteLine("JSClientMethod(method,args)")
		Do %code.WriteLine(" Write !,""self."","""_tCls_""",""_"",method,"" = function("",args,"") {"",!")
		Do %code.WriteLine(" For line=1:1:$$$comMemberKeyGet("""_%class.Name_""",$$$cCLASSmethod,method,$$$cMETHimplementation) {")
		Do %code.WriteLine("  If +$G(%zenStripJS) {")
		Do %code.WriteLine("   Set tLine = $ZSTRIP($$$comMemberArrayGet("""_%class.Name_""",$$$cCLASSmethod,method,$$$cMETHimplementation,line),""<>W"")")
		Do %code.WriteLine("   If (tLine[""&"") {")
		// escape common characters that XHTML does not support
		Do %code.WriteLine("    Set tLine = $Replace(tLine,""&nbsp;"",""&#160;"")")
		Do %code.WriteLine("    Set tLine = $Replace(tLine,""&raquo;"",""&#187;"")")
		Do %code.WriteLine("    Set tLine = $Replace(tLine,""&laquo;"",""&#171;"")")
		Do %code.WriteLine("   }")
		Do %code.WriteLine("   Write:(($L(tLine)>0)&&($E(tLine,1,2)'=""//"")) tLine,!")
		Do %code.WriteLine("  } Else {")
		Do %code.WriteLine("   Write $$$comMemberArrayGet("""_%class.Name_""",$$$cCLASSmethod,method,$$$cMETHimplementation,line),!")
		Do %code.WriteLine("  }")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Write ""}"",!") // end of method
		Do %code.WriteLine(" Quit")

		#; JSSvrMethod
		#; Writes out client-side method definition for server methods
		#; cm is 1 for class method

		Do %code.WriteLine("JSSvrMethod(cm,retType,method,args,spec)")
		Do %code.WriteLine(" Write !,""self."","""_tCls_""",""_"",method,"" = function("",args,"") {"",!")
		Do %code.WriteLine(" Write $C(9),$S(retType="""":"""",1:""return ""),$S(cm:""zenClassMethod"",1:""zenInstanceMethod""),""(this,'"",method,""','"",spec,""','"",retType,""',arguments);"",!")
		Do %code.WriteLine(" Write ""}"",!") // end of method

		Do %code.WriteLine(" Quit")

	} While(0)

Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Draw JavaScript needed to initialize properties for client side of this object<br>
/// This is the logic of the %DrawObjectProperties method generator
/// of %ZEN.Component.object.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present. 
ClassMethod %DrawObjectProperties() As %Status
{
	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnDrawObjectProperties",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Do ..%OnDrawObjectProperties()")
	}

	#; initial property values

	#; get list of client properties
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)

		Set tType = tProp.Type
		Set tInitialExpression = tProp.InitialExpression

		#; figure out the classtype for the property
		#; first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			#; assume this type belongs to our package
			Set tType = $P(tProp.parent.Name,".",1,$L(tProp.parent.Name,".")-1) _ "." _ tType
		}

		Set ZENENCRYPT = +tProp.Parameters.GetAt("ZENENCRYPT")

		Set tType = $$$NormalizeClassname(tType)
		Set clsType = $$$getClassType(tType)
		Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)
		Set mask = ","_tClientType_","
		#; BIGINT,BINARY
		#; BOOLEAN,CURRENCY,CHARACTERSTREAM,
		#; DATE,DOUBLE,HANDLE,INTEGER,LIST,LONGVARCHAR
		#; NUMERIC,STATUS,TIME,TIMESTAMP,VARCHAR
		#; FDATE,FTIMESTAMP

		If ((tProp.Name '= "index") && ($E(tProp.Name,1,1)'="%")) {

			If (+tProp.Calculated) {
				#; ignore calculated properties
			}
			ElseIf (+tProp.MultiDimensional) {
				#; ignore multidimensional properties
			}
			ElseIf (tProp.Collection = "list") {
				#; initialize list collection
				#; note that client collection is 0-based

				Do %code.WriteLine(" For i=1:1:.."_tProp.Name_".Count() {")
				If (clsType = "datatype") {
					#; literal collection
					Do %code.WriteLine("  Write ""o."_tProp.Name_"["",i-1,""] = '"",$ZCVT(.."_tProp.Name_".GetAt(i),""O"",""JS""),""';"",!")
				}
				Else {
					#; object collection: look up instance in index
					#; make sure this is a collection of components
					Do %code.WriteLine("  If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("   Set idx = +.."_tProp.Name_".GetAt(i).index")
					Do %code.WriteLine("   Write:'idx ""throw new Error('Collection element is not part of the page model.\nClass: "_%compiledclass.Name_"\nProperty: "_tProp.Name_"\nElement Type:"_tType_"\nKey: "",i,""');"",!")
					Do %code.WriteLine("   Write ""o."_tProp.Name_"["",i-1,""] = _zenIndex["",idx,""];"",!")
					Do %code.WriteLine("  }")
				}
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "array") {
				#; initialize array collection (use associative array on client)
				Do %code.WriteLine(" Set key = .."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key '= """") {")
				If (clsType = "datatype") {
					#; literal collection
					Do %code.WriteLine("  Write ""o."_tProp.Name_"['"",key,""'] = '"",$ZCVT(.."_tProp.Name_".GetAt(key),""O"",""JS""),""';"",!")
				}
				Else {
					#; object collection: look up instance in index
					#; make sure this is a collection of components
					Do %code.WriteLine("  If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("   Set idx = +.."_tProp.Name_".GetAt(key).index")
					Do %code.WriteLine("   Write:'idx ""throw new Error('Collection element is not part of the page model.\nClass: "_%compiledclass.Name_"\nProperty: "_tProp.Name_"\nElement Type:"_tType_"\nKey: "",key,""');"",!")
					Do %code.WriteLine("   Write ""o."_tProp.Name_"['"",key,""'] = _zenIndex["",idx,""];"",!")
					Do %code.WriteLine("  }")
				}
				Do %code.WriteLine(" Set key = .."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "") {
				#; single-valued property
				If (clsType = "datatype") {
					#; datatype: only set if not "" (unless encrypted)
					If (ZENENCRYPT) {
						Do %code.Write(" Write")
					}
					Else {
						Do %code.Write(" Write:(.."_tProp.Name_"'="_tInitialExpression_")")
					}

					#; use client type to figure out best way to init value
					If (ZENENCRYPT) {
						Do %code.WriteLine(" ""o."_tProp.Name_" = '"",$ZCVT($$$cspEncode(%session.Key,$ZCVT(.."_tProp.Name_",""O"",""UTF8"")),""O"",""JS""),""';"",!")
					}
					ElseIf (",BIGINT,CURRENCY,DOUBLE,INTEGER,NUMERIC," [ mask) {
						#; convert to JS number
						Do %code.WriteLine(" ""o."_tProp.Name_" = "",$S($IsValidNum(.."_tProp.Name_"):.."_tProp.Name_",1:""''""),"";"",!")
					}
					ElseIf (",BOOLEAN," [ mask) {
						#; convert to JS bool
						Do %code.WriteLine(" ""o."_tProp.Name_" = "",$S(+.."_tProp.Name_":""true"",1:""false""),"";"",!")
					}
					ElseIf (tType="%ZEN.Datatype.list") { // piece list
						Set tDelim = tProp.Parameters.GetAt("DELIMITER")
						Set:tDelim="" tDelim="\x05"
						Do %code.WriteLine(" ""o."_tProp.Name_" = zenListToArray('"",##class(%ZEN.Controller).%EscapeJS($ZCVT(.."_tProp.Name_",""O"",""JS"")),""','"_tDelim_"');"",!")
					}
					Else {	// string
						Do %code.WriteLine(" ""o."_tProp.Name_" = '"",$ZCVT(.."_tProp.Name_",""O"",""JS""),""';"",!")
					}
				}
				ElseIf (clsType = "") {
					#; registered object: set up code to stitch reference back together on client
					#; make sure this is a reference to a component
					#; do this check at run-time
					#; (it would be better to do this at compile time, but that introduces
					#; compile dependencies)
					Do %code.WriteLine("  If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("  Write:$IsObject(.."_tProp.Name_") ""o."_tProp.Name_" = _zenIndex["",(+.."_tProp.Name_".index),""]"","";"",!")
					Do %code.WriteLine(" }")
				}
			}
		}
	}

	#; as far as client is concerned we are not *modified* at this
	#; point; clear mod bits.
	Do %code.WriteLine(" Do $System.CLS.SetSModified($this,0)")
	Quit $$$OK
}

/// This is the logic of the %ObjectSync method generator
/// of %ZEN.Component.object.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present. 
ClassMethod %ObjectSynch() As %Status
{
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Set $ZT=""Trap""")

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnObjectSynch",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Set tSC = ..%OnObjectSynch()")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")
	}

	#; use local var to cut down on size of code
	Do %code.WriteLine(" Set osp =  ""o.setProperty""")

	#; find changed properties

	#; first find all % properties and clear their mod bits
	#; (there might not be any client changes!)
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		If ($E(tProp.Name,1,1)="%") {
			Set tCalculated=+$$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSproperty,tProp.Name,$$$cPROPcalculated)
			// clear shadow bit
			Do:'tCalculated %code.WriteLine(" Set s%"_$$$QN(tProp.Name)_"=0")
		}
	}	

	#; test if we are still modified (shadow bits)
	Do %code.WriteLine(" Quit:'$system.CLS.GetSModified($this) tSC")

	#; now get list of client properties
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tType = tProp.Type
		Set tInitialExpression = tProp.InitialExpression
	
		#; figure out the classtype for the property
		#; first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			#; assume this type belongs to our package
			Set tType = $P(tProp.parent.Name,".",1,$L(tProp.parent.Name,".")-1) _ "." _ tType
		}

		Set ZENENCRYPT = +tProp.Parameters.GetAt("ZENENCRYPT")
		Set ZENSETTING = +tProp.Parameters.GetAt("ZENSETTING")
		Set ZENCLIENTONLY = +tProp.Parameters.GetAt("ZENCLIENTONLY")

		Set tType = $$$NormalizeClassname(tType)
		Set clsType = $$$getClassType(tType)
		Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)
		Set mask = ","_tClientType_","
		#; BIGINT,BINARY
		#; BOOLEAN,CURRENCY,CHARACTERSTREAM,
		#; DATE,DOUBLE,HANDLE,INTEGER,LIST,LONGVARCHAR
		#; NUMERIC,STATUS,TIME,TIMESTAMP,VARCHAR
		#; FDATE,FTIMESTAMP

		If ('ZENCLIENTONLY && (tProp.Name '= "index") && ($E(tProp.Name,1,1)'="%")) {
			// shadow mod bit
			Set tModBit="s%"_$$$QN(tProp.Name)

			If (tProp.Collection = "list") {
				#; set contents of list collection
				#; if modified, set the whole thing
				#; note that client collection is 0-based
				#; if this is the children collection AND the %partial
				#; flag is set, do not sync
				If (tProp.Name = "children") {
					Do %code.WriteLine(" If (('..%partial)&&"_tModBit_") {")
				}
				Else {
					Do %code.WriteLine(" If ("_tModBit_") {")
				}

				#; clear out client collection
				Do %code.WriteLine(" Write ""o."_tProp.Name_".length = 0;"",!")

				Do %code.WriteLine(" For i=1:1:.."_tProp.Name_".Count() {")
				If (clsType = "datatype") {
					#; literal collection
					Do %code.WriteLine("  Write ""o."_tProp.Name_"["",i-1,""] = '"",$ZCVT(.."_tProp.Name_".GetAt(i),""O"",""JS""),""';"",!")
				}
				Else {
					#; object collection: look up instance in index
					#; make sure this is a collection of components
					Do %code.WriteLine("  If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("   Set idx = +.."_tProp.Name_".GetAt(i).index")
					Do %code.WriteLine("   Write:'idx ""throw new Error('Collection element is not part of the page model.\nClass: "_%compiledclass.Name_"\nProperty: "_tProp.Name_"\nElement Type:"_tType_"\nKey: "",i,""');"",!")
					Do %code.WriteLine("   Write ""o."_tProp.Name_"["",i-1,""] = _zenIndex["",idx,""];"",!")
					Do %code.WriteLine("  }")
				}
				Do %code.WriteLine(" }")
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "array") {
				#; if mod, set array collection (use associative array on client)
				Do %code.WriteLine(" If ("_tModBit_") {")

				#; clear out client array
				Do %code.WriteLine(" Write ""o."_tProp.Name_" = new Object();"",!")

				Do %code.WriteLine(" Set key = .."_tProp.Name_".Next("""")")
				Do %code.WriteLine(" While (key '= """") {")
				If (clsType = "datatype") {
					#; literal collection
					Do %code.WriteLine("  Write ""o."_tProp.Name_"['"",key,""'] = '"",$ZCVT(.."_tProp.Name_".GetAt(key),""O"",""JS""),""';"",!")
				}
				Else {
					#; object collection: look up instance in index
					#; make sure this is a collection of components
					Do %code.WriteLine("   If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("   Set idx = +.."_tProp.Name_".GetAt(key).index")
					Do %code.WriteLine("   Write:'idx ""throw new Error('Collection element is not part of the page model.\nClass: "_%compiledclass.Name_"\nProperty: "_tProp.Name_"\nElement Type:"_tType_"\nKey: "",key,""');"",!")
					Do %code.WriteLine("   Write ""o."_tProp.Name_"['"",key,""'] = _zenIndex["",idx,""];"",!")
					Do %code.WriteLine("  }")
				}
				Do %code.WriteLine(" Set key = .."_tProp.Name_".Next(key)")
				Do %code.WriteLine(" }")
				Do %code.WriteLine(" }")
			}
			ElseIf (tProp.Collection = "") {
				#; single-valued property
				If (clsType = "datatype") {
					#; datatype: only set if modified (don't test calculated props)
					Set tCalculated=+$$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSproperty,tProp.Name,$$$cPROPcalculated)
					If (tCalculated) {
						Do %code.Write(" Write")
					}
					Else {
						Do %code.Write(" Write:"_tModBit)
					}
					#; use client type to figure out best way to set value
					If (ZENSETTING) {
						#; use setProperty
						If (ZENENCRYPT) {
							Do %code.WriteLine(" osp,""('"_tProp.Name_"','"",$ZCVT($$$cspEncode(%session.Key,$ZCVT(.."_tProp.Name_",""O"",""UTF8"")),""O"",""JS""),""');"",!")
						}
						ElseIf (",BIGINT,CURRENCY,DOUBLE,INTEGER,NUMERIC," [ mask) {
							#; convert to JS number
							Do %code.WriteLine(" osp,""('"_tProp.Name_"',"",$S($IsValidNum(.."_tProp.Name_"):.."_tProp.Name_",1:""''""),"");"",!")
						}
						ElseIf (",BOOLEAN," [ mask) {
							#; convert to JS bool
							Do %code.WriteLine(" osp,""('"_tProp.Name_"',"",$S(+.."_tProp.Name_":""true"",1:""false""),"");"",!")
						}
						Else {	// string
							Do %code.WriteLine(" osp,""('"_tProp.Name_"','"",$ZCVT(.."_tProp.Name_",""O"",""JS""),""');"",!")
						}
					}
					Else {
						#; set directly
						If (ZENENCRYPT) {
							Do %code.Write(" ""o."_tProp.Name_" = '"",$ZCVT($$$cspEncode(%session.Key,$ZCVT(.."_tProp.Name_",""O"",""UTF8"")),""O"",""JS""),""';"",!")
						}
						ElseIf (",BIGINT,CURRENCY,DOUBLE,INTEGER,NUMERIC," [ mask) {
							#; convert to JS number
							Do %code.Write(" ""o."_tProp.Name_" = "",$S($IsValidNum(.."_tProp.Name_"):.."_tProp.Name_",1:""''""),"";"",!")
						}
						ElseIf (",BOOLEAN," [ mask) {
							#; convert to JS bool
							Do %code.Write(" ""o."_tProp.Name_" = "",$S(+.."_tProp.Name_":""true"",1:""false""),"";"",!")
						}
						ElseIf (tType="%ZEN.Datatype.list") { // piece list
							Set tDelim = tProp.Parameters.GetAt("DELIMITER")
							Set:tDelim="" tDelim="\x05"
							Do %code.Write(" ""o."_tProp.Name_" = zenListToArray('"",##class(%ZEN.Controller).%EscapeJS($ZCVT(.."_tProp.Name_",""O"",""JS"")),""','"_tDelim_"');"",!")
						}
						Else {	// string
							Do %code.Write(" ""o."_tProp.Name_" = '"",$ZCVT(.."_tProp.Name_",""O"",""JS""),""';"",!")
						}

						If (tProp.Name = "renderFlag") {
							#; additional special code for renderFlag
							Do %code.Write(",""zenRenderContents(o);"",!")
						}
						Do %code.WriteLine("")
					}
				}
				ElseIf (clsType = "") {
					#; registered object: set up code to stitch reference back together on client
					#; make sure this is a reference to a component
					#; do this check at run-time

					Do %code.WriteLine(" If "_tModBit_" {")
					Do %code.WriteLine(" If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("  Write ""o."_tProp.Name_" = "",$S($IsObject(.."_tProp.Name_"):""_zenIndex[""_(+.."_tProp.Name_".index)_""]"",1:""null""),"";"",!")
					Do %code.WriteLine(" }")
					Do %code.WriteLine(" }")
				}
			}
		}
	}

	#; clear mod bits.
	Do %code.WriteLine(" Do $System.CLS.SetSModified($this,0)")
	Do %code.WriteLine(" Quit tSC")

	#; error trap
	Do %code.WriteLine("Trap")
	Do %code.WriteLine(" Set $ZT=""""")
	Do %code.WriteLine(" Set tSC = $$$ERROR($$$ObjectScriptError,"""_%compiledclass.Name_":ObjectSynch: ""_$ZE)")
	Do %code.WriteLine(" Quit tSC")

	Quit $$$OK
}

/// Generate %ZENDeserialize method.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present. 
ClassMethod %ZENDeserialize() As %Status
{
	#; get cached meta data
	Set tAncestors = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Ancestors"))
	Set tSerialProps = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialProps"))
	Set tSerialTypes = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialTypes"))

	Do %code.WriteLine(" Set tSC=$$$OK")
	Do %code.WriteLine(" If (..%GetClassCRC()'=$P(pState,$C(1),1)) { Quit $$$ERROR($$$GeneralError,""Server version of object does not match version sent from the client: ""_..%ClassName(1)) } ")

	#; first part of serial state is CRC of object signature
	#; test to see if this matches

	Set tCount = $L(tSerialTypes,"!")
	Set tCode = ""
	For n = 1:1:tCount {
		Set tProp = $P(tSerialProps,"!",n)
		Set tType = $P(tSerialTypes,"!",n)
		Set tExpr = ""
		Set tValExpr = "$P(pState,$C(1),"_(n+1)_")"

		#; check for readonly & calculated properties
		Set tRO = $$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSproperty,tProp,$$$cPROPreadonly)
		Set tCalculated=+$$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSproperty,tProp,$$$cPROPcalculated)
		If (tRO) {
			Set tExpr = " // Readonly: "_tProp
		}
		ElseIf (tCalculated) {
			Set tExpr = " // Calculated: "_tProp
		}
		Else {
			If (tType = "N") {
				#; number
				Set tExpr = " Set .."_tProp_"="_tValExpr
			}
			ElseIf (tType = "P") {
				#; parent:
				#; test if we are a visual component or not
				If ((tAncestors [ "~%ZEN.Component.component~")||
					(tAncestors [ "~%ZEN.SVGComponent.svgComponent~")) {
					Set tExpr = " Set parent=$S("_tValExpr_"="""":"""",1:$G(pObjSet("_tValExpr_"))) Do:$IsObject(parent) parent.%AddChild(##this)"
				}
				Else {
					#; non-visual component
					Set tExpr = " Set parent=$S("_tValExpr_"="""":"""",1:$G(pObjSet("_tValExpr_")))"
				}
			}
			ElseIf (tType = "O") {
				#; find oref in pObjSet
				Set tExpr = " Set .."_tProp_"=$S("_tValExpr_"="""":"""",1:$G(pObjSet("_tValExpr_")))"
			}
			ElseIf (tType = "B") {
				#; boolean
				Set tExpr = " Set .."_tProp_"=''"_tValExpr
			}
			ElseIf (tType = "A") {
				#; array of dt
				Set tExpr = " Set val="_tValExpr_" For i=1:1:$L(val,$C(2)) {Do .."_tProp_".SetAt($P($P(val,$C(2),i),$C(3),2),$P($P(val,$C(2),i),$C(3),1))}"
			}
			ElseIf (tType = "L") {
				#; list of dt
				Set tExpr = " Set val="_tValExpr_" If (val'="""") {For i=1:1:$L(val,$C(2)) {Do .."_tProp_".Insert($P(val,$C(2),i))}}"
			}
			ElseIf (tType = "AO") {
				#; array of objects
				Set tExpr = " Set val="_tValExpr_" If (val'="""") {For i=1:1:$L(val,$C(2)) {Set item=$P(val,$C(2),i) Do .."_tProp_".SetAt($S($P(item,$C(3),2)="""":"""",1:$G(pObjSet($P(item,$C(3),2)))),$P(item,$C(3),1))}}"
			}
			ElseIf (tType = "LO") {
				#; list of objects
				#; special case: neglect children
				If (tProp '= "children") {
					Set tExpr = " Set val="_tValExpr_" If (val'="""") {For i=1:1:$L(val,$C(2)) {Set item=$P(val,$C(2),i) Do .."_tProp_".Insert($S(item="""":"""",1:$G(pObjSet(item))))}}"
				}
				Else {
					#; but, check for partially serialized objects
					#; these have a serial state of -1
					Set tExpr = " Set:(("_tValExpr_")=-1) ..%partial=1"
				}
			}
			ElseIf (tType = "E") {
				#; decode encrpyted value
				Set tExpr = " Set:(("_tValExpr_")'="""") .."_tProp_"=$ZCVT($$$cspDecode(%session.Key,"_tValExpr_"),""I"",""UTF8"")"
			}
			Else {
				#; string
				Set tExpr = " Set .."_tProp_"="_tValExpr
			}
		}
		
		Do:tExpr'="" %code.WriteLine(tExpr)
	}

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnZENDeserialize",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Set tSC=..%OnZENDeserialize()")
	}

	#; clear mod bits
	Do %code.WriteLine(" Do $System.CLS.SetSModified($this,0)")
	Do %code.WriteLine(" Quit tSC")

	Quit $$$OK
}

/// Generate client JSSerialize method.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present. 
ClassMethod %JSSerialize() As %Status
{
#define MakeJSClassName(%cls) ($TR(%cls,"%.","__"))

	#; get cached meta data
	Set tSerialProps = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialProps"))
	Set tSerialTypes = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialTypes"))
	#; Set tSerialInherit = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SerialInherit"))

	#; normalize class name
	Set tCls = $$$MakeJSClassName(%class.Name)

	#; serialize function: set is SerialState object; s is array to place items in
	Do %code.WriteLine(" Write ""function "_tCls_"_serialize(set,s)"",!")
	Do %code.WriteLine(" Write ""{"",!")

	Do %code.WriteLine(" Write $C(9)")

	#; alias for *this*
	Do %code.WriteLine(" Write ""var o = this;""")

	#; first part of serial structure is CRC of object signature
	Do %code.WriteLine(" Write ""s[0]='""_$ZCVT(..%GetClassCRC(),""O"",""JS"")_""';""")

	Set tCount = $L(tSerialTypes,"!")
	Set tCode = ""
	For n = 1:1:tCount {
		Set tProp = $P(tSerialProps,"!",n)
		Set tType = $P(tSerialTypes,"!",n)
		#; Set tInherit = $P(tSerialInherit,"!",n)
		Set tExpr = """"""
		If ((tType = "O")||(tType = "P")) {
			#; add obj to serial set; add index to serial state
			Set tExpr = "set.addObject(o."_tProp_",'"_tProp_"')"
		}
		ElseIf (tType = "B") {
			Set tExpr = "(o."_tProp_"?1:0)"
		}
		ElseIf ((tType = "A")||(tType = "AO")) {
			#; serialize array
			Set flag = $S(tType="A":"false",1:"true")
			Set tExpr = "set.serializeArray(o,o."_tProp_","_flag_",'"_tProp_"')"
		}
		ElseIf ((tType = "L")||(tType = "LO")) {
			#; serialize list
			Set flag = $S(tType="L":"false",1:"true")
			Set tExpr = "set.serializeList(o,o."_tProp_","_flag_",'"_tProp_"')"
		}
		ElseIf (tType = "Z") {
			#; convert client array to delimited list.
			Set tDelim = $$$comMemberArrayGet(%class.Name,$$$cCLASSproperty,tProp,$$$cPROPparameter,"DELIMITER")
			Set:tDelim="" tDelim="\x05"
			Set tExpr = "zenArrayToList(o."_tProp_",'"_tDelim_"')"
		}
		ElseIf (tProp = "value") {
			#; special case for values, make sure boolean are cast
			Set tExpr = "('boolean'==typeof o."_tProp_"?(o."_tProp_"?1:0):o."_tProp_")"
		}
		Else {
			Set tExpr = "o."_tProp
		}

		#; keep this code terse, put everything on one line
		Do %code.WriteLine(" Write ""s["_(n)_"]="_tExpr_";""")
	}
	Do %code.WriteLine(" Write !,""}"",!")
	Do %code.WriteLine(" Quit $$$OK")

	Quit $$$OK
}

/// Generate client getSettings method.<br>
/// It is assumed that this is called during method generation
/// time and that %code and other compiler objects are present. 
ClassMethod %JSGetSettings() As %Status
{
#define MakeJSClassName(%cls) ($TR(%cls,"%.","__"))

	#; get cached meta data
	Set tSettings = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Settings"))
	Set tSettingTypes = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"SettingTypes"))

	#; normalize class name
	Set tCls = $$$MakeJSClassName(%class.Name)

	#; getSettings function: fill in array with settings info
	Do %code.WriteLine(" Write ""function "_tCls_"_getSettings(s)"",!")
	Do %code.WriteLine(" Write ""{"",!")

	Set tCount = $L(tSettings,"!")
	Set tCode = ""
	For n = 1:1:tCount {
		Set tProp = $P(tSettings,"!",n)
		If (tProp '= "") {
			Set tType = $P(tSettingTypes,"!",n)
			Set:tType="" tType = "string" // default
	
			Do %code.WriteLine(" Write $C(9),""s['"_tProp_"'] = '"_tType_"';"",!")
		}
	}
	#; dispatch
	If (%class.Name '= "%ZEN.Component.object") {
		Do %code.WriteLine(" Write $C(9),""this.invokeSuper('getSettings',arguments);"",!")
	}
	Do %code.WriteLine(" Write ""}"",!")
	Do %code.WriteLine(" Quit $$$OK")

	Quit $$$OK
}

/// Get normalized type (class name) of given property definition.
/// This is a duplicate of the same method in %ZEN.FormGenerator.
ClassMethod GetPropertyType(pdef As %Dictionary.CompiledProperty) As %String
{
	Set tType = pdef.Type

	#; figure out the classtype for the property
	#; first normalize the type name
	If ((tType '[ ".") && (tType '[ "%")) {
		#; assume this type belongs to our package
		Set tType = $P(pdef.parent.Name,".",1,$L(pdef.parent.Name,".")-1) _ "." _ tType
	}

	Quit $$$NormalizeClassname(tType)
}

/// Build a list of super classes (indexed by number) starting from (and including) <var>pClass</var>.
/// Stop when any of the classes in the list <var>pSkip</var> are reached.
/// Skip any classes in any of the packages in the list <var>pSkipPackage</var> are reached.
ClassMethod GetSuperClassList(pClass As %String, ByRef pList As %String, ByRef pSkip As %String, ByRef pSkipPackage As %String) As %Status
{
	Set tSC = $$$OK
	Quit:pClass="" tSC

	#; skip this package?
	Set tPkg = $P(pClass,".",1,$L(pClass,".")-1)
	If ((tPkg'="")&&$D(pSkipPackage(tPkg))) {
		Quit tSC
	}

	Set pSkip(pClass) = "" // prevent duplicates

	Set tSupers = $$$comClassKeyGet(pClass,$$$cCLASSsuper)
	For p = $L(tSupers,","):-1:1 {
		Set tSuper = $P(tSupers,",",p)
		If ((tSuper '= "") && ('$D(pSkip(tSuper)))) {
			Set tSC = ..GetSuperClassList(tSuper,.pList,.pSkip,.pSkipPackage)
			If $$$ISERR(tSC) Quit
		}
	}

	#; add current class to the list
	Set pList($I(pList)) = pClass
	Quit tSC
}

/// Build a list of properties in sequence order, including inherited properties.<br>
/// On return, <var>pList</var> is a list of properties names (subscripted by order number).
/// Stop when any of the classes in the list <var>pSkip</var> are reached.<br>
/// Skip any classes in any of the packages in the list <var>pSkipPackage</var> are reached.<br>
/// Private properties are skipped.
ClassMethod GetOrderedProps(pClassDef As %Dictionary.CompiledClass, ByRef pList As %String, ByRef pSkip As %String, ByRef pSkipPackage As %String) As %Status
{
	Set tSC = $$$OK

	Set tSC = ..GetSuperClassList(pClassDef.Name, .tClassList, .pSkip, .pSkipPackage)
	If $$$ISERR(tSC) Quit tSC
	Quit:'$D(tClassList) tSC

	// now build list of properties in sequence order
	Set tNext = 1

	Set tClassNo = $O(tClassList(""))
	While (tClassNo'="") {
		Set cdef = ##class(%Dictionary.ClassDefinition).%OpenId(tClassList(tClassNo))
		If ($IsObject(cdef)) {
			#; first make list of this class' properties using its order
			Set n = 0 // used for props with no seq no
			Kill t
			set key = "", pdef = cdef.Properties.GetNext(.key)
			while key '= "" {
				If ('+pdef.Private) {
					Set seq = +pdef.SequenceNumber
					If (seq = 0) {
						#; missing seq no!
						Set n = n - 1
						Set seq = n
					}
					If $g(b(pdef.Name))="" {
						Set t(seq) = pdef.Name
					}
					Set b(pdef.Name)=seq
				}
				set pdef = cdef.Properties.GetNext(.key)
			}

			#; now add these to the end of the main list
			Set key = $O(t(""))
			While (key '= "") {
				Set pList(tNext) = t(key)
				Set tNext = tNext + 1
				Set key = $O(t(key))
			}
		}
		Set tClassNo = $O(tClassList(tClassNo))
	}

	Quit tSC
}

/// Find all occurences of $$$Text() localized strings within the given JavaScript method.<br/>
/// <var>pDomain</var> is the default DOMAIN of of the class containing the method.
/// Any strings without an explicit domain used the default. If the default is missing, then the string is ignored.</br>
/// On return, <var>pTextList</var> contains a list of all localized strings in the form:<br/>
/// pTextList(domain,string) = ""<br/>
ClassMethod %FindLocalizedText(pMethod As %Dictionary.MethodDefinition, pDomain As %String, ByRef pTextList As %String) As %Status [ Internal ]
{
	#; JMD611
	#; JMD1018 add debug mode and \ escaping
	Set tSC = $$$OK
	Try {
		Set tLineNo = 0
		If $IsObject(pMethod) {
			Do pMethod.Implementation.Rewind()
		}

		// Read each line of code
		While ($S($IsObject(pMethod):'pMethod.Implementation.AtEnd,1:1)) {
			If $IsObject(pMethod) {
				Set tLine = pMethod.Implementation.ReadLine()
			}
			Else {
				// for testing
				Set tLine = pMethod
			}
			Set tLineNo = tLineNo + 1
			If (tLine'["$$$Text") {
				// nothing to do; skip line
			}
			Else {
				// parse line
				Set p = 1
				Set tState = 0
				Set tText = ""
				Set tDomain = ""

				// use simple FSM to find $$$Text 
				While (p<=$L(tLine)) {
					Set ch = $E(tLine,p)
					If (tState=0) {
						If (ch="$") {
							If ($E(tLine,p,p+7)="$$$Text(") {
								Set tText = ""
								Set tDomain = ""
								Set tState = 1
								Set p = p + 7
							}
						}
					}
					ElseIf (tState=1) {
						// start of text
						If (ch="""") {
							Set tQuote = """"
							Set tState = 2
						}
						ElseIf (ch="'") {
							Set tQuote = "'"
							Set tState = 2
						}
						// else swallow white-space
					}
					ElseIf (tState=2) {
						// accumulate until end of string
						If (ch="\") {
							// JMD1018
							Set peek = $E(tLine,p+1)
							If (peek=tQuote) {
								Set p = p + 1
								Set tText = tText _ peek
							}
							Else {
								Set tText = tText _ ch
							}
						}
						ElseIf (ch=tQuote) {
							Set tState = 3
						}
						Else {
							Set tText = tText _ ch
						}
					}
					ElseIf (tState=3) {
						// look for ) or ,
						If (ch=")") {
							If (tText'="") {
								// add text to list
								Set tDomain = $S(tDomain="":pDomain,1:tDomain)
								If (tDomain'="") {
									Set tKey = tDomain_"/"_tText
									Set pTextList(tKey) = ""
								}
							}
							Set tState = 0
						}
						ElseIf (ch=",") {
							Set tState = 4
						}
					}
					ElseIf (tState=4) {
						// get domain name
						If (ch="""") {
							Set tQuote = """"
							Set tState = 5
						}
						ElseIf (ch="'") {
							Set tQuote = "'"
							Set tState = 5
						}
					}
					ElseIf (tState=5) {
						If (ch=tQuote) {
							// go back to find closing ")"
							Set tState = 3
						}
						Else {
							Set tDomain = tDomain_ch
						}
					}
					Set p = p + 1
				}
			}
			Quit:'$IsObject(pMethod)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
