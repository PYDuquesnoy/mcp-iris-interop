/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

Class EnsLib.EDI.XML.SchemaXSD Extends %RegisteredObject [ System = 4 ]
{

ClassMethod generateXSDFromClass(pClassname As %String, pStreamOut As %Stream.Object = {$$$NULLOREF}) As %Status [ Internal ]
{
	If ""=$G(pClassname)||'$$$comClassDefined(pClassname)||'$classmethod(pClassname,"%Extends","%XML.Adaptor") Quit $$$ERROR($$$GeneralError,"invalid class "_pClassname)
	
	Set writer=##class(%XML.Writer).%New()
	Set writer.Indent=1
	Set tNeedCopy=$$$NULLOREF
	If '$IsObject(pStreamOut) {
		If ""=pStreamOut { Set tSC=writer.OutputToDevice() }
		Else { Set tSC=writer.OutputToFile(pStreamOut) }
	} Else {
		If pStreamOut.%Extends("%FileBinaryStream") {
			Set tSC=writer.OutputToStream(pStreamOut)
		} Else {
			Set tNeedCopy=pStreamOut
			Set tSC=writer.OutputToStream(.pStreamOut)
		}
	} Quit:$$$ISERR(tSC)
	Set xsd=##class(%XML.Schema).%New()
	Set tSC=xsd.AddSchemaType(pClassname)  Quit:$$$ISERR(tSC) tSC
	Set node=xsd.GetSchema("")

	Set tSC=writer.DocumentNode(node)  Quit:$$$ISERR(tSC) tSC
	
	If $IsObject(tNeedCopy) {
		Set tSC=tNeedCopy.CopyFrom(pStreamOut)
		Set:tSC=0 tSC=$$$ERROR($$$GeneralError,"Stream copy failed from "_pStreamOut_"("_pStreamOut.Size_") to "_tNeedCopy)
		Set pStreamOut=tNeedCopy
	}
	Quit tSC
}

ClassMethod GetImportCategory(location As %String) As %String [ Internal ]
{
	Set path=$S($IsObject(location):location.Name,1:location)
	Quit:location'["://"&&'$IsObject(location)&&'##class(%File).Exists(##class(%File).NormalizeFilename(path)) ""
	If $$$isVMS && (path["[") Set path = $P(path,"]",$L(path,"]"))
	Set path=$replace(path,"\","/")
	Set:"/"=$E(path,*) path=$E(path,1,*-1)
	Set path=$P(path,"/",$L(path,"/"))
	Set:$Case($ZCVT($P(path,".",$L(path,".")),"L"),"xsd":1,"xml":1,:0) path=$P(path,".",1,$L(path,".")-1)
	Set path=$replace(path,",","_")
	Quit path
}

ClassMethod ImportFiles(pFilePath As %String, pNSCategories As %String) As %Status
{
	Set tResultSet=##class(%ResultSet).%New("%File:FileSet")
	Kill tResultSet.Data
	Set tSC=tResultSet.Execute(##class(%File).GetDirectory(pFilePath),##class(%File).GetFilename(pFilePath),"DateModified",0)  Quit:$$$ISERR(tSC) tSC
	While 1 {
		If 0=tResultSet.Next() {
			#; Done with this ResultSet now
			Do tResultSet.Close()
			Quit
		}
		Continue:"D"=tResultSet.Data("Type") ; skip directories
		Set tOneFilename = tResultSet.Data("Name"), tModified = tResultSet.Data("DateModified")
		w !,"Processing file "_tOneFilename_" : "
		w $$$StatusDisplayString(tSC)
		Set tSC=..Import(tOneFilename,,,.pNSCategories)  Quit:$$$ISERR(tSC)
	}
	w !
	Quit tSC
}

/// User needs %Ens_EDISchema WRITE privilege which
/// is enforced via calling SMP page EnsPortal.EDI.XML.SchemaMain 
/// and the schema global creation API.
ClassMethod Import(location As %String, Output pCategoryImported As %String, pForceCategory As %String = "", pNSCategories As %String = "", pVerbose As %String = "") As %Status
{
	Set reader = ##class(%XML.Utils.SchemaReader).%New()
	Set:'$IsObject(location)&&(location'["https://")&&'$$$isVMS reader.SSLConfiguration = $P($P(location,"[",2),"]"), location=$P(location,"[")
	Set reader.Debug=+$P(pVerbose,"r",2), doVerbose=+pVerbose

	Set tCat=..GetImportCategory(location)
	Quit:""=tCat $$$ERROR($$$FileDoesNotExist,location)

	Set tSC = reader.PreParseLocation(##class(%XML.Utils.SchemaHandler).GetFullPath("",location))  Quit:$$$ISERR(tSC) tSC

	// Save the top-level objects (children of the root node) into the schema global
	Set:""'=pForceCategory tCat=pForceCategory
	try {
		/* Create the global entry with standard collation
			OK if transaction will be rolled back and left with
			empty schema global */
		If '$D($$$vaSchemaGbl) { // JSL5241
			Set tSC = ##class(%SYS.Ensemble).CreateXMLSchemaGlobal()
			Quit:$$$ISERR(tSC)
		}
		TStart
		Kill $$$vaSchemaGbl(tCat)
		Merge $$$vaSchemaGbl(tCat,"ns","list")=reader.NSInfo
		Merge $$$vaSchemaGbl(tCat,"ns","index")=reader.NSIndex
		Set $$$vaSchemaGbl(tCat,"ns","targ")=reader.TargetNS
		Set elno="" For { Set elno = $O(^IRIS.Temp(reader.Tree,1,0,"ch",elno))  Quit:""=elno
			Set tLocalType=$G(^IRIS.Temp(reader.Tree,1,elno,"local"))
			Set tElem=$Case(tLocalType, "element":"DS", "complexType":"CT", "attributeGroup":"CG", "group":"CG", "simpleType":"ST", "attribute":"ST", :"")
			If ""'=tElem {
				Set tStruct=$G(^IRIS.Temp(reader.Tree,1,elno,"attrs","name"),"."), tStructNS=$P(tStruct,"^"), tStruct=$P(tStruct,"^",2)
		//!!!TBD make sure in a schema that has the same name in no-namespace and namespace that the no-namespace one is the one with no $namespace suffix.
				Set:$D($$$vaSchemaGbl(tCat,tElem,tStruct))&&(tStructNS'=$G($$$vaSchemaGbl(tCat,tElem,tStruct,"ns"))) tStruct=tStruct_"$"_tStructNS ; disambiguate same Elem type/name in different namespaces
				//$$$ASSERTNOLOG('$D($$$vaSchemaGbl(tCat,tElem,tStruct)))
				Set $$$vaSchemaGbl(tCat,tElem,tStruct)=elno
				Set:""'=tStructNS $$$vaSchemaGbl(tCat,tElem,tStruct,"ns")=tStructNS
				Set tEl=$G($$$vaSchemaGbl(tCat,"<types>",tStruct)), $$$vaSchemaGbl(tCat,"<types>",tStruct)=$S(""=tEl:"",1:tEl_",")_elno ; multiple Elem types per name allowed
				Set $$$vaSchemaGbl(tCat,"<types>",tStruct,elno)=tElem
			}
			ElseIf $Case(tLocalType,"annotation":1,"documentation":1,:0) {
				Set tDesc="",sub=elno  For {
					If "documentation"=tLocalType&&(""'=$TR($G(^IRIS.Temp(reader.Tree,1,sub,"chars")),$C(13,10,32,9))) {
						Set tDesc=tDesc_","_sub
					}
					Set sub=$O(^IRIS.Temp(reader.Tree,1,sub,"ch",""))  Quit:""=sub
					Set tLocalType=$G(^IRIS.Temp(reader.Tree,1,sub,"local"))
				}
				Set $$$vaSchemaGbl(tCat,"desc")=$G($$$vaSchemaGbl(tCat,"desc"))_","_tDesc
			}
			Else {
				$$$ASSERTNOLOG(0_"unrecognized local type "_tLocalType)
			}
		}
		#; Make another pass promoting CT types to DS's if no DS types are defined in the schema
		If '$D($$$vaSchemaGbl(tCat,"DS")) {
			Set tStruct="" For { Set tStruct=$O($$$vaSchemaGbl(tCat,"CT",tStruct),1,elno)  Quit:""=tStruct
				Merge $$$vaSchemaGbl(tCat,"DS",tStruct)=$$$vaSchemaGbl(tCat,"CT",tStruct)
				Kill $$$vaSchemaGbl(tCat,"CT",tStruct)
				Set $$$vaSchemaGbl(tCat,"<types>",tStruct,elno)="DS"
			}
		}
		#; Set up the description for the whole xsd category
		Set tDesc=$G($$$vaSchemaGbl(tCat,"desc"))  Kill $$$vaSchemaGbl(tCat,"desc")
		If $D($$$vaSchemaGbl(tCat)) {
			Merge $$$vaSchemaGbl(tCat)=^IRIS.Temp(reader.Tree,1)
			Set $$$vaSchemaGbl(tCat,"src")=reader.ElementSrc
			For i=1:1:+$get(reader.ElementSrc) {
				Set $$$vaSchemaGbl(tCat,"src",i)=$replace(reader.ElementSrc(i)," ","%20")
			}
			Set pCategoryImported=tCat
			For i=1:1:$L(tDesc) Set:","=$E(tDesc,i)&&(i=1||(","=$E(tDesc,i+1))) $E(tDesc,i)="",i=i-1 ; remove first comma and double commas
			Set:""'=tDesc $$$vaSchemaGbl(tCat,"desc")=tDesc
		}
		Kill ^IRIS.Temp(reader.Tree)
		Set tSC=##class(EnsLib.EDI.XML.Schema).BuildCategoryMaps(tCat,doVerbose)
	} catch ex {
		Set tSC=$$$SystemErrorType("",ex)
	}
	If $$$ISERR(tSC) { TRollback }
	Else { TCommit }
	Quit tSC
}

/*
ClassMethod getPrimary()
{
		// Find primary Request class
		Kill agentreqsuper,dsnreqsuper
		Set key=""  For {  Set key = $O($$$RdrClassTree(key))  Quit:""=key
			If ('$G($$$RdrClassTree(key,"Removed"))) {
				if 0=$D($$$RdrClassTree(key,"UsedBy")) && '$D(reqclass) {
					Set $$$RdrClassTree(key,"ClassType") = "persistent"
					Set reqclass=$$$RdrClassTree(key,"ClassName")
					Set reqclassshort=$P(reqclass,".",$L(reqclass,"."))
					Set reqpkg=$P(reqclass,".",1,$L(reqclass,".")-1)
					If "iWayDSNdata"=reqclassshort {
						Set reqclass = $P(reqclass,".",1,$L(reqclass,".")-1)
						Set reqxmlname=$$$RdrClassTree(key,"Parameter","XMLNAME"), reqxmlname=$P(reqxmlname,".",1,$L(reqxmlname,".")-1)
						Set $$$RdrClassTree(key,"Parameter","PROCNAME") = reqxmlname
						Set reqxmlname = "data"
						Set $$$RdrClassTree(key,"Parameter","XMLNAME") = reqxmlname
						Set respclass=$G(respclass,"EnsLib.IWay.DSN.Response"), nocreateresp=1
						Set (reqsuper,dsnreqsuper)=reqpkg_".EnsDSNRequest"
						Set dsnreqsupersuper="EnsLib.IWay.DSN.Request"
					} Else {
						Set (reqsuper,agentreqsuper)=reqpkg_".EnsRequest"
						Set agentreqsupersuper="Ens.Request"
						If "PS8"=reqclassshort {
							#; to get classname, strip the filename down to the <path>/[service_]NAME[.xsd] NAME piece
							Set reqclass=$TR(filename,"\","/"), reqclass=$P(reqclass,"/",$L(reqclass,"/")), reqclass=$P(reqclass,".")
							Set:reqclass["service_" reqclass=$P(reqclass,"service_",2)
							Set $$$RdrClassTree(key,"Parameter","PROCNAME") = reqclass
							Set reqclass=reqpkg_"."_reqclass_"Request"
							Set $$$RdrClassTree(key,"Parameter","XMLNAME") = "PS8"
						}
					}
					Set reqclass=$TR(reqclass,"_",".")
					Set $$$RdrClassTree(key,"ClassName") = reqclass
					Set $$$RdrClassTree(key,"Super") = reqsuper
					Set $$$RdrClassTree(key,"Parameter","RESPONSECLASSNAME") = $G(respclass)
				} Else {
					// Set all others %Serial
					If $$$RdrClassTree(key,"ClassType") '= "datatype" {
					 	Set $$$RdrClassTree(key,"Super") = "%SerialObject,%XML.Adaptor"
						Set $$$RdrClassTree(key,"ClassType") = "serial"
						Set $$$RdrClassTree(key,"Parameter","XMLIGNORENULL") = 1
					}
				}
				Set %session.Data("ClassKey",$$$RdrClassTree(key,"ClassName"))=key
			}
		}
}
*/
}
