/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// Utility class used by the <class>%ZEN.DataModel.DataModel</class>
/// classes.
Class %ZEN.DataModelUtils Extends %RegisteredObject [ Deprecated, System = 2 ]
{

/// Generate code needed for the GetPropertyInfo method of a DataModel.
/// Given the definition of a property within a DataModel.
ClassMethod GeneratePropInfoCode(pName As %String, pClass As %String, pProperty As %String, pCode As %CharacterStream, pLocalize As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK

	#; get array describing what kind of control to create
	Set tSC = ..GetControlForProperty(pClass,pProperty,.tInfo)
	If $$$ISERR(tSC) Quit tSC

	#; generate code based on tInfo
	Set tControlType = $G(tInfo("%type"))

	Do:(tControlType '= "") pCode.WriteLine("  Set pInfo(tProp,""%type"") = """_tControlType_"""")
	Do:($G(tInfo("size")) '= "") pCode.WriteLine("  Set pInfo(tProp,""size"") = "_+$G(tInfo("size")))
	Do:(+$G(tInfo("required"))) pCode.WriteLine("  Set pInfo(tProp,""required"") = 1")

	If (pLocalize) {
		#; generate localization for these
		Do:($D(tInfo("title"))) pCode.WriteLine("  Set pInfo(tProp,""title"") = $$$Text(" _ $$$quote($G(tInfo("title")))_")")
		Do:($D(tInfo("caption"))) pCode.WriteLine("  Set pInfo(tProp,""caption"") = $$$Text(" _ $$$quote($G(tInfo("caption")))_")")

		#; special handling for valueList and displayList
		If ($D(tInfo("valueList")) && '$D(tInfo("displayList"))) {
			Do pCode.WriteLine("  Set pInfo(tProp,""displayList"") = $$$Text(" _ $$$quote($G(tInfo("valueList")))_")")
		}

		#; for label, localize default if not provided
		If ($D(tInfo("label"))) {
			Do pCode.WriteLine("  Set pInfo(tProp,""label"") = $$$Text(" _ $$$quote($G(tInfo("label")))_")")
		}
		Else {
			Do pCode.WriteLine("  Set pInfo(tProp,""label"") = $$$Text(" _ $$$quote($TR(pProperty,"."," "))_")")
		}
	}
	Else {
		Do:($D(tInfo("title"))) pCode.WriteLine("  Set pInfo(tProp,""title"") = " _ $$$quote($G(tInfo("title"))))
		Do:($D(tInfo("caption"))) pCode.WriteLine("  Set pInfo(tProp,""caption"") = " _ $$$quote($G(tInfo("caption"))))
		Do:($D(tInfo("label"))) pCode.WriteLine("  Set pInfo(tProp,""label"") = " _ $$$quote($G(tInfo("label"))))
	}

	Do:($G(tInfo("%group")) '= "") pCode.WriteLine("  Set pInfo(tProp,""%group"") = " _ $$$quote($G(tInfo("%group"))))

	#; remove the items we have already processed
	Kill tInfo("title"),tInfo("caption"),tInfo("label")
	Kill tInfo("size"),tInfo("required"),tInfo("%type"),tInfo("%group")

	#; pick up remaining attributes
	#; assume we are given a control of the correct type
	Set tKey = $O(tInfo(""))
	While (tKey '= "") {
		Do pCode.WriteLine("  Set pInfo(tProp,"_$$$quote(tKey)_") = " _ $$$quote($G(tInfo(tKey))))
		Set tKey = $O(tInfo(tKey))
	}

	Quit $$$OK
}

/// Given a class and property name, fill in an array of information that
/// can be used to create a ZEN control to display the property.<br>
/// This is used both by code generators and run-time code to create forms
/// on the "fly".
ClassMethod GetControlForProperty(pClass As %String, pProperty As %String, Output pInfo As %String) As %Status
{
	Kill pInfo
	If '$$$comMemberDefined(pClass,$$$cCLASSproperty,pProperty) {
		Quit $$$ERROR($$$GeneralError, "Property not found: " _ pClass _ ":" _ pProperty)
	}

	#; local macro to get parameter values for the current property
#define PARAM(%name) 	$$$comMemberArrayGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPparameter,%name)

	Set tName = pProperty
	Set tPropName = pProperty
	Set tLabel = pProperty
	Set tControlName = pProperty
	Set tHint = ""

	Set tControlType = ""
	Set tControlSize = ""
	Set tControlMaxLength = ""
	Set tValueList = ""
	Set tDisplayList = ""
	Set tCaption = ""
	Set tCached = 0

	#; get property parameters
	Set ZENCONTROL = $$$PARAM("ZENCONTROL")
	Set ZENSIZE = $$$PARAM("ZENSIZE")
	Set ZENTITLE = $$$PARAM("ZENTITLE")
	Set ZENGROUP = $$$PARAM("ZENGROUP")
	Set ZENSQL = $$$PARAM("ZENSQL")
	Set ZENSQLLOOKUP = $$$PARAM("ZENSQLLOOKUP")
	Set ZENREADONLY = $$$PARAM("ZENREADONLY")
	Set ZENHIDDEN = $$$PARAM("ZENHIDDEN")
	Set ZENLABEL = $$$PARAM("ZENLABEL")
	Set ZENHINT = $$$PARAM("ZENHINT")
	Set CAPTION = $$$PARAM("CAPTION") // support CAPTION as well
	
	#; holder for additional attributes: this has the form
	#; name:val|name:val
	Set ZENATTRS = $$$PARAM("ZENATTRS")

	Set tLookup = 0
	Set tRequired = +$$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPrequired)
	Set tDesc = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPdescription)
	Set tControlTitle = $P(tDesc,$C(13),1) // first line of description is default popup-title

	Set tReadOnly = ZENREADONLY || (+$$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPreadonly))

	Set tType = ..GetNormalizedPropertyType(pClass,pProperty)

	#; use client datatype to guess what type of control to use
	Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)

	If (ZENHIDDEN) {
		#; this has precedence
		Set tControlType = "hidden"
	}
	Else {
		#; handle different property types differently
		Set tCollection = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPcollection)
		If (tCollection = "") {
			#; non-collection
			If ($$$classIsDataType(tType)) {
				#; datatype property
	
				#; note that MVC ships display values to the client
				#; so the control for VALUELIST properties will
				#; have a valueList that is the *display* values of the server property
			
				Set DISPLAYLIST = $$$PARAM("DISPLAYLIST")
				Set VALUELIST = $$$PARAM("VALUELIST")
				If (DISPLAYLIST = "") {
					Set DISPLAYLIST = VALUELIST
				}
		
				#; find best type (and possibly size) for the property
				#; based on its client type; possibilities are:
				#; BIGINT,BINARY
				#; BOOLEAN,CURRENCY,CHARACTERSTREAM,
				#; DATE,DOUBLE,HANDLE,INTEGER,LIST,LONGVARCHAR
				#; NUMERIC,STATUS,TIME,TIMESTAMP,VARCHAR
				#; FDATE,FTIMESTAMP
	
				Set tControlSize = ZENSIZE
				Set mask = ","_tClientType_","
	
				If (ZENSQL '= "") {
					#; there is a lookup query; use dataCombo (control will find query to use???)
					Set tControlType = "dataCombo"
					Set tCached = 1
				}
				ElseIf ((DISPLAYLIST '= "")&&($E(DISPLAYLIST,1)=",")) {
					#; we only deal with display lists that are csv
					#; this is an enum; use a combobox OR radioSet
					#; choose control based on number of items in the list
					#; if not required, always use a combobox as it is easier
					#; for the user to set the value to ""
					If (($L(DISPLAYLIST,",") > 4)) {
						Set tControlType = "combobox"
					}
					Else {
						Set tControlType = "radioSet"
					}
	
					#; if not required, leave the "" at the start of choices
					If ('tRequired) {
						Set tValueList = DISPLAYLIST // see note above
					}
					Else {
						Set tValueList = $E(DISPLAYLIST,2,99999)
					}
				}
				ElseIf (",BIGINT,CURRENCY,DOUBLE,INTEGER,NUMERIC," [ mask) {
					#; numeric
					Set tControlType = "text"
					
					#; guess at size of control
					Set MAXVAL = $ZABS($$$PARAM("MAXVAL"))
					Set MINVAL = $ZABS($$$PARAM("MINVAL"))
					Set tMax = $Case(MAXVAL>MINVAL,1:MAXVAL,:MINVAL)
					If (tMax > 0) {
						Set tControlSize = ($ZLOG(tMax)+3)\1
					}
					Else {
						Set tControlSize = 6
					}
				}
				ElseIf (",TIME," [ mask) {
					#; time
					Set tControlType = "text"
					Set tControlSize = 8
				}
				ElseIf (",DATE," [ mask) {
					#; date
					#; if display format is YYYY-MM-DD, then we can use dateText
					#; otherwise use dateSelect
					If ($$$PARAM("FORMAT")=3) {
						Set tControlType = "dateText"
					}
					Else {
						Set tControlType = "dateSelect"
					}
				}
				ElseIf (",TIMESTAMP," [ mask) {
					#; time
					Set tControlType = "text"
					Set tControlSize = 24
				}
				ElseIf (",BOOLEAN," [ mask) {
					#; boolean
					Set tControlType = "checkbox"
					Set tCaption = $S(ZENLABEL'="":ZENLABEL,1:tLabel)
					Set tLabel = ""
				}
				ElseIf (",STATUS," [ mask) {
					#; status code
					Set tControlType = "text"
				}
				Else {
					#; string
					Set tControlType = "text"
					
					#; guess at size/type based on MAXLEN
					Set MAXLEN = $$$PARAM("MAXLEN")
					Set tControlMaxLength = MAXLEN
					If (MAXLEN > 250) {
						#; textarea
						Set tControlType = "textarea"
						Set tControlSize = "5,60"
						Set tControlMaxLength = ""
					}
					ElseIf ((MAXLEN = "") || (MAXLEN > 30)) {
						Set tControlSize = 30
					}
					ElseIf (MAXLEN < 2) {
						Set tControlSize = 2
					}
					Else {
						Set tControlSize = MAXLEN
					}
				}
			} // datatype
			Else {
				#; object
				Set ctype = $$$getClassType(tType)
				If (ctype = $$$cCLASSCLASSTYPESTREAM) {
					$$$comClassKeyGetLvar(odbctype,tType,$$$cCLASSodbctype)
					If (odbctype = "LONGVARCHAR") {
						#; character stream
						Set tControlType = "textarea"
					}
					Else {
						#; binary stream
						Set tControlType = "image"
					}
				}
				Else {
					#; object (use a dataCombo)
					Set tControlType = "dataCombo"
					Set tCached = 1
					#; the lookup queries are determined by the
					#; %ZEN.DataModel.ObjectDataModel:%GetLookupSQL method
				}
	
			}
		} // collection?
		Else {
			#; allow override by collection
			Set:ZENCONTROL'="" tControlType = ZENCONTROL
		}
	}

	If (tControlType '= "") {
		#; apply overrides
		Set:ZENCONTROL'="" tControlType = ZENCONTROL
		Set:ZENSIZE'="" tControlSize = ZENSIZE
		Set:ZENTITLE'="" tControlTitle = ZENTITLE
		Set:CAPTION'="" tLabel = CAPTION
		Set:ZENLABEL'="" tLabel = ZENLABEL // this has precedence
		Set:ZENHINT'="" tHint = ZENHINT

		#; fill in pInfo array
		Set pInfo("%type") = tControlType
		Set:(tControlSize '= "") pInfo("size") = +tControlSize
		Set:(tControlMaxLength '= "") pInfo("maxlength") = +tControlMaxLength
		Set:(tLabel '= tName) pInfo("label") = tLabel
		Set:(tControlTitle '= "") pInfo("title") = tControlTitle
		Set:(tCaption '= "") pInfo("caption") = tCaption
		Set:(tHint '= "") pInfo("hint") = tHint
		Set:(tRequired) pInfo("required") = 1
		Set:(tReadOnly) pInfo("readOnly") = 1
		Set:(tCached) pInfo("cached") = 1

		#; special case for checkbox
		If ((tControlType="checkbox")&&('$D(pInfo("label")))) {
			Set pInfo("label") = ""
		}

		Set:(tDisplayList '= "") pInfo("displayList") = tDisplayList
		Set:(tValueList '= "") pInfo("valueList") = tValueList
		Set:(ZENGROUP '= "") pInfo("%group") = ZENGROUP
		Set:($G(pInfo("label"))=" ") pInfo("label") = "" // " " will turn of label

		#; process additional attrs
		#; user is responsible for making sure the control has these properties!
		For n = 1:1:$L(ZENATTRS,"|") {
			Set tAttr = $ZSTRIP($P(ZENATTRS,"|",n),"<>W")
			If ((tAttr'="")&&(tAttr[":")) {
				Set tXProp = $ZSTRIP($P(tAttr,":",1),"<>W")
				Set tXVal = $P(tAttr,":",2,999)
				Set:tXProp'="" pInfo(tXProp) = tXVal
			}
		}
	}

	Quit $$$OK
}

/// Generate and return a default SQL search query for a given
/// object reference property.
ClassMethod GetSQLForProperty(pClass As %String, pProperty As %String) As %String [ Internal ]
{
	Set tSQL = ""
	Set tType = ..GetNormalizedPropertyType(pClass, pProperty)
	Set tTable = ..GetSQLTableName(tType)
	Set ZENDISPLAYCOLUMN = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPparameter,"ZENDISPLAYCOLUMN")
	If (ZENDISPLAYCOLUMN'="") {
		Set dlist = "," _ ZENDISPLAYCOLUMN
		Set where = " WHERE "_ZENDISPLAYCOLUMN_" %STARTSWITH ?"
		Set orderby = " ORDER BY " _ ZENDISPLAYCOLUMN
	}
	Else {
		Set dlist = ""
		Set where = ""
		Set orderby = ""
	}

	Set tSQL = "SELECT %ID"_dlist_" FROM " _ tTable _ where _ orderby
	Quit tSQL
}

/// Generate and return a default SQL lookup query for a given
/// object reference property.
ClassMethod GetSQLLookupForProperty(pClass As %String, pProperty As %String) As %String [ Internal ]
{
	Set tSQL = ""
	Set tType = ..GetNormalizedPropertyType(pClass, pProperty)
	Set tTable = ..GetSQLTableName(tType)
	Set ZENDISPLAYCOLUMN = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPparameter,"ZENDISPLAYCOLUMN")
	If (ZENDISPLAYCOLUMN'="") {
		Set dlist = ZENDISPLAYCOLUMN
	}
	Else {
		Set dlist = "%ID"
	}

	Set tSQL = "SELECT "_dlist_" FROM " _ tTable _ " WHERE %ID = ?"
	Quit tSQL
}

/// Return the SQL table name for the given class name.
ClassMethod GetSQLTableName(pClass As %String) As %String
{
	Quit $$$comClassKeyGet(pClass,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(pClass,$$$cCLASSsqltablename)
}

/// Get normalized type (class name) of given property definition
/// This is a duplicate of the same method in %ZEN.Generator.
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

/// Get normalized type (class name) of the given property.
ClassMethod GetNormalizedPropertyType(pClass As %String, pProperty As %String) As %String
{
	Set tType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPtype)
	Quit:tType="" ""

	#; figure out the classtype for the property
	#; first normalize the type name
	If ((tType '[ ".") && (tType '[ "%")) {
		#; assume this type belongs to its class' package
		Set tType = $P(pClass,".",1,$L(pClass,".")-1) _ "." _ tType
	}

	Quit $$$NormalizeClassname(tType)
}

}
