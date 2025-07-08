/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used by CMQL and other MV engines to
/// determine the make up of a class that describes metadata
/// for any particular file that is projected in to the
/// file space.
/// 
Class %MV.EnumClass Extends %RegisteredObject [ Final, ServerOnly = 1, System = 4 ]
{

/// Returns all information regarding the indexes described by a particuler MV class in a string serialized form that is usable by the CMQL parser
/// 
ClassMethod Indexes(className As %String, includeNamespace As %Boolean) As %String
{
	
#define escapedquote(%string) $$escapedquote^%SYS.MVQ(%string)
	
	Set $ZT ="trapme"
	#; First we need to see if the class is compiled, if it
	#; is not, then we are just going to return an empty string
	#; which will ignore indexes for the class. Later we may decide
	#; that this is an error.
	#; 
	set classDef = ##class(%Dictionary.CompiledClass).%OpenId(className)
	if '$isobject(classDef) {
		Quit ""
	}
	#; Looks like the class is defined so let's iterate the indexes
	#; 
	Set eol         = $c(13)_$c(10)
	Set indices     = classDef.Indices
	Set properties  = classDef.Properties
	Set indexesCode = ""
	#;
	#; ---- Make properties easier to find (must be a better way than this, but no time to look)
	#; 
	Set x = ""
	For {
		Set x=properties.Next(x)
		Quit:x=""
		Set p=properties.GetAt(x)
		Set pxref(p.Name)=x
	}
	#;
	#;
	Set ind = "", indexCount=0
	#;
	Set tabinfo = $Get($$$EXTsqlinfo($$$rEXT,className))
	Set extentsize = $$$SQLLocTableExtentSize(tabinfo)
	Set mastermapname = $$$SQLLocTableMasterMap(tabinfo)
	Set mastermap = $G($$$EXTSQLMAPsqlinfo($$$rEXT,className,mastermapname))
	Set masterpages=$$$SQLLocMapNumberOfBlocksAlone(mastermap)
	set address = $Order($$$EXTADDR($$$pEXT,className,""))
	while address '= "" {
		s mapinfo=$G($$$EXTSQLMAPsqlinfo($$$rEXT,className,address))
		s pages=$$$SQLLocMapNumberOfBlocksAlone(mapinfo)
		set index = $Get($$$EXTADDRindex($$$pEXT,className,address))
		if index '= "" {
			Set indexCount = indexCount + 1
			#;
			#; We have found another index, build up the description
			#; 
			Set indexCode = "index {"_eol
			Set indexCode = indexCode_"    name = """_index_""";"_eol
			Set indexCode = indexCode_"    type = "
			#;
			set indexType = $Get($$$EXTIDXtype($$$pEXT,className,index))
			set storageIndexLocation = $Get($$$EXTADDRbasereference($$$pEXT,className,address))
			if includeNamespace {
				Set:$E(storageIndexLocation,2)'="|" storageIndexLocation = "^|"""_$namespace_"""|"_$E(storageIndexLocation,2,*)
			} else {
				Set:$P($P(storageIndexLocation,"|",2),"""",2)=$namespace storageIndexLocation = "^"_$P(storageIndexLocation,"|",3)
			}
			if (indexType = "") {
				#;
				Set indexCode = indexCode_"index"
				#;
			} Else {
				#;
				Set indexCode = indexCode_indexType
			}
			Set indexCode = indexCode_";"_eol
			Set indexCode = indexCode_" storage = """_$$$escapedquote(storageIndexLocation)_""";"_eol
			Set indexCode = indexCode_"  blocks = """_pages_""";"_eol
			#;
			#; We now iterate all the elements that make up the index
			#; by inspecting the properties that define the index
			#; Before doing so, we garner the class description using an internal utility
			#; as this gives us inormation that is otherwise very diffuclt to construct. We
			#; use this infomration when an MV specific parameter is not present, but we can infer
			#; it's value only by using this additional information. We ignore errors in favor
			#; of just doing nothing if we cannot garner the info.
			#; 
			Set datanodes = ""
			Set status  = $$NodeMetadata^%ocsCacheUtil(className,.datanodes)
			Set max = $LISTLENGTH(datanodes)
			For i = 1:1:max {
				Set mapElement = $LIST(datanodes, i)
				if (mapElement '= "") {
					#;
					Set pxref(mapElement, "SLOT") = i
				}
			}
			#; Index elements
			#;
        	Set pCount = $$$comMemberKeyGet(className,$$$cCLASSindex,index,$$$cINDEXproperty)
			For i = 1:1:pCount {
			   #;
			   #; Describe this property
			   #;
			   $$$comSubMemberKeyGetLvar(pname,className,$$$cCLASSindex,index,$$$cINDEXproperty,i,$$$cINDEXPROPproperty)
			   #;
			   #; The special case of %%ID is known about because this is a multivalue index
			   #; We also exclude the KEYS of a multivalue index, because the SQL interface assumes this 
			   #; structure.
			   #; 
			   Set elements = $ZConvert($piece($piece(pname,"(",2),")",1),"U")
			   if ((pname '= "%%ID") && (pname '= "ItemId") && (elements '= "KEYS")) {
			   	Set prop = pxref($Piece($Piece(pname,"(",1),":",1))
			   	Set prop=properties.GetAt(prop)
			   	#;
			   	Set propDesc = "element {"_eol
			   	#;
			   	#; -------------------------------------------------------
				Set propDesc = propDesc_"          name = """_pname_""";"_eol
			   	#; -------------------------------------------------------
			   	#; Indexes on collections do not seem to be supported anywhere at
			   	#; the moment. We need an MV index type.
			   	#; 
			   	If elements = "ELEMENTS" {
			   		Set propDesc    = propDesc_"            mv = ""M"";"_eol
			   	} Else {
					Set propDesc    = propDesc_"            mv = ""S"";"_eol
			   	}
			   	#; -------------------------------------------------------
			   	Set pval = prop.Parameters.GetAt("MVATTRIBUTE")
			   	If (pval="") {
				   #; 
				   #; Need to work out where the compiler allocated it
				   #;
				  Set pval = $G(pxref(pname, "SLOT"))
				  Set:pval="" pval=0
			   	}
			   	#;
			   	#;
			   	Set propDesc = propDesc_"        attrno = """_pval_""";"_eol
			   	#; -------------------------------------------------------
			   	Set pval = prop.Type
			   	If (pval '= "") {
			      Set propDesc = propDesc_"      datatype = """_pval_""";"_eol
			   	}
			   	#; -------------------------------------------------------
			   	Set pval = prop.Parameters.GetAt("MVTOLOGICAL")
			   	If (pval '= "") {
			      Set propDesc = propDesc_"         attr8 = """_$$$escapedquote(pval)_""";"_eol
			   	}
			   	#; -------------------------------------------------------
			   	Set pval = prop.Parameters.GetAt("MVTODISPLAY")
			   	If (pval'="") {
			      Set propDesc = propDesc_"          conv = """_$$$escapedquote(pval)_""";"_eol
			   	}
			   	#; -------------------------------------------------------
				Set coll = prop.Parameters.GetAt("COLLATION")
				Set propDesc = propDesc_"     collation = """_$ZCVT(coll,"U")_""";"_eol
			   	#; -------------------------------------------------------
			   	Set pval = prop.Parameters.GetAt("MVFORMAT")
			   	If (pval'="") {
			      Set propDesc = propDesc_"        format = """_$$$escapedquote(pval)_""";"_eol
			   	}
			   	#; -------------------------------------------------------
			   	Set pval = prop.Parameters.GetAt("MVITYPE")
			   	If (pval'="") {
			      Set propDesc = propDesc_"   itypeSource = """_$$$escapedquote(pval)_""";"_eol
			   	}
			   	#; -------------------------------------------------------
			   	#; 
			   	#; Now we must see if there is a SQL column defined. There should be
			   	#; but if there is not then we have to work this out from the storage
			   	#; definition as it is the column position in the index. 
			   	#; 
			   	If (prop.SqlColumnNumber  '= "") {
				  #;
			      Set pval = prop.SqlColumnNumber
			   	} Else {
				  #;
				  #; See if we can determine the column number from storage then
				  #;
				  Set pval = $$$EXTPROPsqlcolumnnumber($$$pEXT,className,prop.Name)
			   	}
			   	Set propDesc = propDesc_"         colno = """_pval_""";"_eol

				Set selectivity = $lg($$GetFieldTuneStats^%qarTune(className,prop.Name,.msg))
				#; If selectivity is not empty then convert the Object expression to an SQL understandable expression.
				Set:$Length(selectivity) selectivity=$$ConvertSelectivity^%ocsExtent(selectivity,extentsize)
			   	Set propDesc = propDesc_"   selectivity = """_selectivity_""";"_eol
			   	#;
			   	#; IndexData element is fully described.
			   	#; 
			   	Set propDesc = propDesc_"}"_eol
			   	#;
			   	Set indexCode = indexCode_propDesc
			   }
			}
			#; Data node elements
			#;
       		Set data = $$$comMemberKeyGet(className,$$$cCLASSindex,index,$$$cINDEXdata)
       		If data '= "" {
	       	    Do ParseDelimitedString^%occStorageUtil(data,",",.pCount)
				For i = 1:1:pCount {
				   #;
				   #; Describe this property
				   #;
				   Set pname=pCount(i)
				   #;
				   #; The special case of %%ID is known about because this is a multivalue index
				   #; We also exclude the KEYS of a multivalue index, because the SQL interface assumes this 
				   #; structure.
				   #; 
				   Set elements = $ZConvert($piece($piece(pname,"(",2),")",1),"U")
				   if ((pname '= "%%ID") && (elements '= "KEYS")) {
				   	Set prop = pxref($Piece($Piece(pname,"(",1),":",1))
				   	Set prop=properties.GetAt(prop)
				   	#;
				   	Set propDesc = "node {"_eol
				   	#;
				   	#; -------------------------------------------------------
					Set propDesc = propDesc_"          name = """_pname_""";"_eol
				   	#; -------------------------------------------------------
				   	#; Indexes on collections do not seem to be supported anywhere at
				   	#; the moment. We need an MV index type.
				   	#; 
				   	If elements = "ELEMENTS" {
				   		Set propDesc    = propDesc_"            mv = ""M"";"_eol
				   	} Else {
						Set propDesc    = propDesc_"            mv = ""S"";"_eol
				   	}
				   	#; -------------------------------------------------------
				   	Set pval = prop.Parameters.GetAt("MVATTRIBUTE")
				   	If (pval="") {
					   #; 
					   #; Need to work out where the compiler allocated it
					   #;
					  Set pval = $G(pxref(pname, "SLOT"))
					  Set:pval="" pval=0
				   	}
				   	#;
				   	#;
				   	Set propDesc = propDesc_"        attrno = """_pval_""";"_eol
				   	#; -------------------------------------------------------
				   	Set pval = prop.Type
				   	If (pval '= "") {
				      Set propDesc = propDesc_"      datatype = """_pval_""";"_eol
				   	}
				   	#; -------------------------------------------------------
				   	Set pval = prop.Parameters.GetAt("MVTOLOGICAL")
				   	If (pval '= "") {
				      Set propDesc = propDesc_"         attr8 = """_$$$escapedquote(pval)_""";"_eol
				   	}
				   	#; -------------------------------------------------------
				   	Set pval = prop.Parameters.GetAt("MVTODISPLAY")
				   	If (pval'="") {
				      Set propDesc = propDesc_"          conv = """_$$$escapedquote(pval)_""";"_eol
				   	}
				   	#; -------------------------------------------------------
					Set coll = prop.Parameters.GetAt("COLLATION")
					Set propDesc = propDesc_"     collation = """_$ZCVT(coll,"U")_""";"_eol
				   	#; -------------------------------------------------------
				   	Set pval = prop.Parameters.GetAt("MVFORMAT")
				   	If (pval'="") {
				      Set propDesc = propDesc_"        format = """_$$$escapedquote(pval)_""";"_eol
				   	}
				   	#; -------------------------------------------------------
				   	Set pval = prop.Parameters.GetAt("MVITYPE")
				   	If (pval'="") {
				      Set propDesc = propDesc_"   itypeSource = """_$$$escapedquote(pval)_""";"_eol
				   	}
				   	#; -------------------------------------------------------
				   	#; 
				   	#; Now we must see if there is a SQL column defined. There should be
				   	#; but if there is not then we have to work this out from the storage
				   	#; definition as it is the column position in the index. 
				   	#; 
				   	If (prop.SqlColumnNumber  '= "") {
					  #;
				      Set pval = prop.SqlColumnNumber
				   	} Else {
					  #;
					  #; See if we can determine the column number from storage then
					  #;
					  Set pval = $$$EXTPROPsqlcolumnnumber($$$pEXT,className,prop.Name)
				   	}
				   	Set propDesc = propDesc_"         colno = """_pval_""";"_eol
				   	#;
				   	#; IndexData element is fully described.
				   	#; 
				   	Set propDesc = propDesc_"}"_eol
				   	#;
				   	Set indexCode = indexCode_propDesc
				   }
				}
			}
			#;
			Set indexCode = indexCode_"}"_eol
			Set indexesCode = indexesCode_indexCode_eol
		}
		set address = $Order($$$EXTADDR($$$pEXT,className,address))
	}
	Set result = "extentsize = """_extentsize_""";"_eol_"blocks = """_masterpages_""";"_eol
	if (indexCount) {
	   Set result = result_"indexes {"_eol_indexesCode_eol_"}"_eol
	} else {
	   Set result = ""
	}
	Quit result
	#;
trapme 
	W "Error enumerating index class '",className,"'",!
	W $ZERROR,!
    Quit ""   ; Just assume no indexes if an error happens
}

}
