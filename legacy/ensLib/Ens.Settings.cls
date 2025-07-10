/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator (%occInclude, EnsUtil)

Class Ens.Settings [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// List of properties can be set as settings in the configuration file
/// format is a comma separated list of property names
Parameter SETTINGS;

Method AssignOneSetting(pProperty As %String, pValue As %String, pName As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If '$IsValidNum(pValue) {
			Set $property($this,pProperty)=""_pValue
		} Else {
			Set tPropId=$$$CurrentClass_"||"_pProperty
			&sql(SELECT RuntimeType INTO :tType FROM %Dictionary.CompiledProperty Where %ID=:tPropId)
			IF SQLCODE { Set tType="%Library.String" }
			ElseIf "Ens.DataType."=$E(tType,1,$L("Ens.DataType.")) {
				&sql(SELECT Super INTO :tSuper FROM %Dictionary.CompiledClass Where %ID=:tType)
				Set tType=$S('SQLCODE:tSuper, 1:"%Library.String")
			}
			If (tType="%Library.Float")||(tType="%Library.Double") {
				Set $property($this,pProperty)=$Double(pValue)
			} ElseIf tType'="%Library.String" {
				Set $property($this,pProperty)=$Decimal(pValue)
			} Else {
				Set $property($this,pProperty)=""_pValue
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROPERTY DOES NOT EXIST>" Set tSC=$$$EnsError($$$EnsErrProductionSettingInvalid,pName,pProperty) Goto Exit
	Set tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod GetSettings(Output pSettings) As %String [ CodeMode = objectgenerator ]
{
	Set tSC=$$$OK, tSettingsList="", tStack=1, tStack(tStack)=%class.Name
	While 0'=tStack {
		Set tClassList=tStack(tStack)
		Set tClass=$P(tClassList,","), tStack(tStack)=$P(tClassList,",",2,$L(tClassList,","))
		If $Case(tClass,"":0, "Ens.Settings":0, "%Library.RegisteredObject":0, :1) { 
			Set tSettings=$$$comMemberKeyGet(tClass,$$$cCLASSparameter,"SETTINGS",$$$cPARAMdefault)
			#; Loop over all the elements of the SETTINGS parameter from the current class level
			Set url="",depth=0  For i=1:1:$L(tSettings,",") { Set one=$P(tSettings,",",i)
				If ""'=url {
					Set depth=$$bracesDepth(one,.depth)
					Set url=url_one
				} Else {
					Set name=$P(one,":"), attrs=$E(one,2+$L(name),*), name=$ZStrip(name,"<>W")
					Set cat=$P(attrs,":"), url=$E(attrs,2+$L(cat),*), cat=$ZStrip(cat,"<>W"), url=$ZStrip(url,"<>W")
					If ""=name {
						Continue:cat_url=""
						Set tSC=$$$ERROR($$$GeneralError,"Empty setting name at position "_i_" in SETTINGS parameter "_tSettings)
						Quit
					}
					If $TR(name,"""")'=name Set tSC=$$$ERROR($$$GeneralError,"Setting "_name_" contains invalid characters at position "_i_" in SETTINGS parameter "_tSettings)  Quit
					If $TR(cat,"""")'=cat Set tSC=$$$ERROR($$$GeneralError,"Category "_cat_" for Setting "_name_" contains invalid characters at position "_i_" in SETTINGS parameter "_tSettings)  Quit
					Set depth=$$bracesDepth(url,.depth)
				}
				If depth<0 Set tSC=$$$ERROR($$$GeneralError,"Setting "_name_" has excess close braces in its url at position "_i_" in SETTINGS parameter "_tSettings)  Quit
				Continue:depth
				If "-"=$E(name) Set:'$D(tExists($E(name,2,*))) tExists($E(name,2,*))=":"  Continue
				Set:'$D(tExists(name)) tSettingsList=tSettingsList_name_",", tExists(name)=cat, tExists(name,"url")=url
				Set (name,cat,url)=""
			} Quit:$$$ISERR(tSC)
			Set tClassList=$$$comClassKeyGet(tClass,$$$cCLASSsuper)
		} Else { Set tClassList="" }
		If ""'=tClassList Set tStack($I(tStack))=tClassList
		Else  Set:""=tStack(tStack) tStack=tStack-1
	} Quit:$$$ISERR(tSC) tSC
	Kill %EnsSettingsGen
	Set n="" For { Set cat="", n=$O(tExists(n),1,cat)  Quit:""=n  Set:""=cat cat="Additional"
		If ":"=cat {
			Do %code.WriteLine(" Set pSettings("":"",""-"_n_""")=""""")
		} Else {
			If '$D(tCats(cat)) {
				Set tCatLoc = $$$GetLocalizedName(cat)
				Do %code.WriteLine(" Set pSettings("":localizedCategory"","""_cat_""")="""_tCatLoc_"""")
			}
			If $G(tExists(n,"url"))="" {
				Set tPropType = $$$comMemberKeyGet(%class.Name, $$$cCLASSproperty, n, $$$cPROPtype)
				Set tEditor = $case(tPropType, "Ens.DataType.ConfigName": "selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}", :"")
				If tEditor '= "" Set tExists(n,"url")=tEditor
			}
			Set tSettLoc = $$$GetLocalizedName(n)
			Do %code.WriteLine(" Set pSettings("":"","""_n_""")="""_cat_""", pSettings("""_cat_""","""_n_""")="""_$replace($G(tExists(n,"url")),"""","""""")_""", pSettings("""_cat_""","""_n_""",""loc"")="""_tSettLoc_"""")
			Set tCats(cat)=""
			If '$data(%EnsSettingsGen(n)) {
				Set %EnsSettingsGen(n) = ""
				Set %EnsSettingsGen(n,"cat") = cat
				Set %EnsSettingsGen(n,"loc") = tSettLoc
				Set %EnsSettingsGen(n,"url") = $get(tExists(n,"url"))
			}
		}
	}
	Do %code.WriteLine(" Quit """_$E(tSettingsList,1,*-1)_"""")
	Quit $$$OK
bracesDepth(str,d)
	set d1=d+$L(str)-$L($TR(str,"{"))
	set d1=d1-($L(str)-$L($TR(str,"}")))
	Quit d1
}

/// Generated helper method to get the data for setting <var>pSettingName</var> in <var>pSourceClass</var> without referencing ^oddCOM.
/// For backwards compatibility reasons, the code will fall back on calling <method>GetDynamicSettingRow</method>()
/// to perform a lookup in ^oddCOM if the specific subclass hasn't yet had the method regenerated.
ClassMethod GetSettingRow(pSettingName As %String = "", pSourceClass As %String = "") As %List [ CodeMode = objectgenerator, GenerateAfter = GetSettings, Private ]
{
	Merge tSettings = %EnsSettingsGen
	Kill %EnsSettingsGen
	Do %code.WriteLine($char(9) _ "Set tRow = """"")
	Do %code.WriteLine($char(9) _ "// Check if the class has been compiled with the new generator")
	Do %code.WriteLine($char(9) _ "If (pSourceClass = """ _ %compiledclass.Name _ """) {")
	Do %code.WriteLine($char(9,9) _ "Set tRow = $case(pSettingName,")
	#dim tProp As %Dictionary.CompiledProperty
	For i=%compiledclass.Properties.Count():-1:1 {
		Set tProp = %compiledclass.Properties.GetAt(i)
		If $data(tSettings(tProp.Name)) {
			Set tGenSettings(tProp.Name,1) = $$$quote(tProp.Name)
			Set tGenSettings(tProp.Name,2) = $replace($translate($$$quote(tProp.Description),$c(13),""),$c(10),"""_$char(13,10)_""")
			Set tGenSettings(tProp.Name,3) = $$$quote(tProp.Type)
			Set tGenSettings(tProp.Name,4) = tProp.InitialExpression
			Set tCount = 5
			For tParm = "MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST" {
				Set tParmVal = tProp.Parameters.GetAt(tParm)
				Set tGenSettings(tProp.Name,tCount) = $$$quote(tParmVal)
				Set tCount = tCount + 1
			}
			Set tGenSettings(tProp.Name,10) = +tProp.Required
			Set tGenSettings(tProp.Name,11) = $$$quote($get(tSettings(tProp.Name,"loc")))
			Set tCategory = $get(tSettings(tProp.Name,"cat"))
			Set tLocCategory = $select(tCategory = "": "", 1: $$$GetLocalizedName(tCategory))
			Set tGenSettings(tProp.Name,12) = $$$quote(tCategory)
			Set tGenSettings(tProp.Name,13) = $$$quote(tLocCategory)
			Set tGenSettings(tProp.Name,14) = $$$quote($get(tSettings(tProp.Name,"url")))
			Set tGenSettings(tProp.Name) = 14
		}
	}
	Set tName = ""
	For {
		Set tName = $order(tGenSettings(tName),1,tSettingCount)
		Quit:(tName = "")
		Continue:(tSettingCount '= 14)
		Do %code.Write($char(9,9,9) _ $$$quote(tName) _ ": $LB(")
		For i=1:1:14 {
			Do %code.Write($get(tGenSettings(tName,i)) _ $select(i = 14: ")", 1: ","))
		}
		Do %code.WriteLine(",")
	}
	Do %code.WriteLine($char(9,9,9) _ ": """")")
	Do %code.WriteLine($char(9) _ "}")
	Do %code.WriteLine($char(9) _ "Else { // Fall back on getting the data dynamically ")
	Do %code.WriteLine($char(9,9) _ "Set tRow = ..GetDynamicSettingRow(pSettingName,pSourceClass)")
	Do %code.WriteLine($char(9) _ "}")
	Do %code.WriteLine($char(9) _ "Quit tRow")
	Quit $$$OK
}

/// Helper method to get the data for setting <var>pSettingName</var> in <var>pSourceClass</var> that 
/// dynamically looks the data up in ^oddCOM. This method should only be invoked when 
/// <method>GetSettingRow</method>() recognises that it hasn't been regenerated in <var>pSourceClass</var>.
ClassMethod GetDynamicSettingRow(pSettingName As %String = "", pSourceClass As %String = "") As %List [ Private ]
{
	Set tRow = ""
	If (pSettingName '= "") && (pSourceClass '= "") {
		Set tRow = $LB(pSettingName)
		Set tRow = tRow _ $LB($$$comMemberKeyGet(pSourceClass,$$$cCLASSproperty,pSettingName,$$$cPROPdescription))
		Set tRow = tRow _ $LB($$$comMemberKeyGet(pSourceClass,$$$cCLASSproperty,pSettingName,$$$cPROPtype))
		Set tRow = tRow _ $LB(..EvalInitialExpression(pSettingName))
		For tPropParam = "MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST" {
			Set tRow = tRow _ $LB($$$comMemberArrayGet(pSourceClass,$$$cCLASSproperty,pSettingName,$$$cPROPparameter,tPropParam))
		}
		Set tRow = tRow _ $LB($$$comMemberKeyGet(pSourceClass,$$$cCLASSproperty,pSettingName,$$$cPROPrequired))
		Set tCategory = $get(%EnsEnumSettings(":",pSettingName))
		Set tRow = tRow _ $LB(%EnsEnumSettings(tCategory,pSettingName,"loc"))
		Set tRow = tRow _ $LB(tCategory)
		Set tRow = tRow _ $LB(%EnsEnumSettings(":localizedCategory",tCategory))
		Set tRow = tRow _ $LB(%EnsEnumSettings(tCategory,pSettingName))
	}
	Quit tRow
}

Query EnumerateSettings() As %Query(ROWSPEC = "Name,Description,Type,Default,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext")
{
}

ClassMethod EnumerateSettingsExecute(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle,%EnsEnumSettings Set qHandle="", %EnsEnumSettings=..GetSettings(.%EnsEnumSettings) ; EnumerateSettings will not be called recursively in-process
	Quit $$$OK
}

ClassMethod EnumerateSettingsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateSettingsExecute ]
{
 	Kill qHandle, %EnsEnumSettings
	Quit $$$OK
}

ClassMethod EnumerateSettingsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateSettingsExecute ]
{
	Set settings=$G(%EnsEnumSettings)
	Set size=$S(""=settings:0,1:$L(settings,","))
	Set qHandle=$G(qHandle)+1
	If qHandle>size Set Row="",AtEnd=1,qHandle=qHandle-1 Quit $$$OK
	#;
	Set name=$P(settings,",",qHandle)
	Set Row = ..GetSettingRow(name,$classname($this))
	Set AtEnd=qHandle=size
	Quit $$$OK
}

ClassMethod EvalInitialExpression(pPropName As %String) As %String [ CodeMode = objectgenerator, Internal, PublicList = tValue ]
{
	Do %code.WriteLine("	Set $ZT=""Trap""")
	Do %code.WriteLine("    Set tValue=$Case(pPropName,")
	for i=1:1:%compiledclass.Properties.Count() {
		set property=%compiledclass.Properties.GetAt(i)
		Do %code.WriteLine("                     "_$$$quote(property.Name)_":"_property.InitialExpression_",")
	}
	Do %code.WriteLine("                     :"""")")
	Do %code.WriteLine("Exit")
	Do %code.WriteLine("	Quit tValue")
	Do %code.WriteLine("Trap")
	Do %code.WriteLine(" 	Set $ZT="""",tValue=""""")
	Do %code.WriteLine("	Goto Exit")
	Quit $$$OK
}

}
