/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.SchemaXML Extends %XML.SAX.ContentHandler [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Flag to only check the category defined in the schema xml file
Property CatOnly As %Boolean;

/// slot for remembering categories encountered in schema xml file
Property lastFileCategory As %String;

/// slot for remembering forced category name
Property forceCategory As %String;

/// Error encountered inside xml import handler
Property Error As %Status [ InitialExpression = {$$$OK} ];

/// Filename for use in constructing xml handler error messages
Property Filename As %String;

/// Array for disambiguation of names
Property %propNames As %String [ MultiDimensional ];

ClassMethod Import(pFile As %String, Output pCategoryImported As %String, pForceCategory As %String) As %Status
{
	Set handler=..%New(), handler.forceCategory=$G(pForceCategory), pCategoryImported=""
	If '$IsObject(pFile) {
		Set handler.Filename=pFile
		Quit:'##class(%File).Exists(pFile) $$$ERROR($$$FileDoesNotExist,pFile)
		Set sc=##class(%XML.SAX.Parser).ParseFile(pFile,handler)  quit:$$$ISERR(sc) sc
	} Else {
		Set handler.Filename=$S(""'=pForceCategory:pForceCategory_".X12", ""'=$G(pCategoryImported):pCategoryImported_".X12", 1:pFile)
		Set sc=##class(%XML.SAX.Parser).ParseStream(pFile,handler)  quit:$$$ISERR(sc) sc
	}
	Set pCategoryImported=handler.lastFileCategory
	Quit handler.Error
}

ClassMethod GetImportCategory(pFilename As %String) As %String
{
	set handler=..%New()  Set handler.CatOnly=1
	set sc=##class(%XML.SAX.Parser).ParseFile(pFilename,handler)
	quit handler.lastFileCategory
}

ClassMethod Export(pCategory As %String, pFile As %String) As %Status
{
	Quit:'$D($$$vaSchemaGbl(pCategory)) $$$ERROR($$$ObjectScriptError,"X12 Schema Category <"_pCategory_"> does not exist in namespace "_$ZNSpace)
	If '$IsObject(pFile) {
		set tFilename=pFile
		set pFile=##class(%FileCharacterStream).%New()
		//set tSC=pFile.LinkToFile(tFilename)  Quit:$$$ISERR(tSC) tSC
		set pFile.Filename = tFilename
		set pFile.TranslateTable="UTF8"
		Set tEncoding="UTF-8"
	} Else {
		Set tEncoding=$S(pFile.%Extends("%IO.IParts.CharacterIO"):pFile.CharEncoding,
						pFile.%Extends("%FileCharacterStream"):$$MapExtCharset^%NLS(pFile.TranslateTable),
						1:"")
	}
#define escape(%text) $ZCVT(%text,"O","XML")

	Do pFile.WriteLine("<?xml version=""1.0"""_$S(""=tEncoding:"",1:" encoding="""_tEncoding_"""")_"?>")
	Do pFile.WriteLine("")
	Do pFile.Write("<Category name="""_pCategory_"""")
	set desc=$g($$$vaSchemaDescGbl(pCategory))
	if desc'="" Do pFile.Write(" description="""_desc_"""")
	set base=$g($$$vaSchemaGbl(pCategory,"base"))
	if base'="" Do pFile.Write(" base="""_base_"""")
	if +$g($$$vaSchemaDescGbl(pCategory,"std")) Do pFile.Write(" std=""1""")
	Do pFile.WriteLine(">")

	#; document structure
	if $d($$$vaSchemaGbl(pCategory,"DS")) Do pFile.WriteLine("")
	k tSorted  set k="" for { set k=$o($$$vaSchemaGbl(pCategory,"DS",k))  Quit:""=k  Set tSorted(" "_$zcvt(k,"U"))=k }
	set next="",ds="" for { set next=$o(tSorted(next),1,ds) quit:next=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DS",ds))
		set description=$g($$$vaSchemaDescGbl(pCategory,"DS",ds))
		Do pFile.Write("<DocumentStructure name='"_ds_"'")
		Do pFile.Write(" definition='"_$$$escape(..stripDefCategory(definition,pCategory,base))_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		set altdesc=$g($$$vaSchemaDescGbl(pCategory,"DS",ds,"alt"))
		if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
		set purpose=$g($$$vaSchemaDescGbl(pCategory,"DS",ds,"purpose"))
		if purpose'="" Do pFile.Write(" purpose='"_$$$escape(purpose)_"'")
		Do pFile.WriteLine("/>")
	}
	k tSorted
	
	#; segment structure
	if $d($$$vaSchemaGbl(pCategory,"SS")) Do pFile.WriteLine("")
	set k="" for { set k=$o($$$vaSchemaGbl(pCategory,"SS",k))  Quit:""=k  Set tSorted($zcvt(k,"U"))=k }
	set next="",ss="" for { set next=$o(tSorted(next),1,ss) quit:next=""
		set definition=$g($$$vaSchemaGbl(pCategory,"SS",ss))
		set description=$g($$$vaSchemaDescGbl(pCategory,"SS",ss))
		Do pFile.Write("<SegmentStructure name='"_ss_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		for i=1:1:$LL(definition) { continue:'$LD(definition,i)
			Do pFile.Write("    <SegmentSubStructure piece='"_i_"'")
			Do pFile.Write(" description='"_$$$escape($g($$$vaSchemaDescGbl(pCategory,"SS",ss,i)))_"'")
			if $lg($li(definition,i),1)'="" Do pFile.Write(" datatype='"_..stripDefCategory($lg($li(definition,i),1),pCategory,base)_"'")
			if +$lg($li(definition,i),2) Do pFile.Write(" minlength='"_$$$escape($lg($li(definition,i),2))_"'")
			if $lg($li(definition,i),4)'="" Do pFile.Write(" maxlength='"_$lg($li(definition,i),4)_"'")
			if $lg($li(definition,i),3)'="" Do pFile.Write(" repeatcount='"_$lg($li(definition,i),3)_"'")
			Do pFile.Write(" required='"_$$$escape($lg($li(definition,i),5,"O"))_"'")
			if +$lg($li(definition,i),6) Do pFile.Write(" elemid='"_$lg($li(definition,i),6)_"'")
			set codetable=$g($$$vaSchemaGbl(pCategory,"SS",ss,"tables",i))
			if codetable'="" Do pFile.Write(" codetable='"_..stripDefCategory(codetable,pCategory,base)_"'")
			set altdesc=$g($$$vaSchemaDescGbl(pCategory,"SS",ss,i,"alt"))
			if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</SegmentStructure>")
	}
	k tSorted
	
	#; composite structure
	if $d($$$vaSchemaGbl(pCategory,"CS")) Do pFile.WriteLine("")
	set cs="" for { set cs=$o($$$vaSchemaGbl(pCategory,"CS",cs)) quit:cs=""
		set definition=$g($$$vaSchemaGbl(pCategory,"CS",cs))
		set description=$g($$$vaSchemaDescGbl(pCategory,"CS",cs))
		Do pFile.Write("<CompositeStructure name='"_cs_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		for i=1:1:$LL(definition)  {
			Do pFile.Write("    <CompositeSubStructure piece='"_i_"'")
			Do pFile.Write(" description='"_$$$escape($g($$$vaSchemaDescGbl(pCategory,"CS",cs,i)))_"'")
			//tType,tMinLen,tMaxUse,tMaxLen,tStdReq,tEleID,tActReq
			if $lg($li(definition,i),1)'="" Do pFile.Write(" datatype='"_..stripDefCategory($lg($li(definition,i),1),pCategory,base)_"'")
			if +$lg($li(definition,i),2) Do pFile.Write(" minlength='"_$$$escape($lg($li(definition,i),2))_"'")
			if $lg($li(definition,i),4)'="" Do pFile.Write(" maxlength='"_$lg($li(definition,i),4)_"'")
			if $lg($li(definition,i),3)'="" Do pFile.Write(" repeatcount='"_$lg($li(definition,i),3)_"'")
			Do pFile.Write(" required='"_$$$escape($lg($li(definition,i),5,"O"))_"'")
			if +$lg($li(definition,i),6) Do pFile.Write(" elemid='"_$lg($li(definition,i),6)_"'")
			set codetable=$g($$$vaSchemaGbl(pCategory,"CS",cs,"tables",i))
			if codetable'="" Do pFile.Write(" codetable='"_..stripDefCategory(codetable,pCategory,base)_"'")
			set altdesc=$g($$$vaSchemaDescGbl(pCategory,"CS",cs,i,"alt"))
			if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</CompositeStructure>")
	}
	#; code table
	if $d($$$vaSchemaGbl(pCategory,"CT")) Do pFile.WriteLine("")
	set ct="" for { set ct=$o($$$vaSchemaGbl(pCategory,"CT",ct)) quit:ct=""
		set definition=$g($$$vaSchemaGbl(pCategory,"CT",ct))
		set description=$g($$$vaSchemaDescGbl(pCategory,"CT",ct))
		Do pFile.Write("<CodeTable name='"_ct_"'")
		Do pFile.Write(" tabletype='"_definition_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		kill indexed
		set one="" For  { set one=$o($$$vaSchemaGbl(pCategory,"CT",ct,one)) Quit:one=""
			set indexed($$$vaSchemaGbl(pCategory,"CT",ct,one))=one
		}
		set i="" For  { set i=$o(indexed(i)) Quit:i=""
			Set description=$g($$$vaSchemaDescGbl(pCategory,"CT",ct,indexed(i)))
			Do pFile.Write("   <Enumerate")
			Do pFile.Write(" position='"_i_"'")
			Set tVal=indexed(i)  Set:$C(0)=tVal tVal=""
			Do pFile.Write(" value='"_$$$escape(tVal)_"'")
			If description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</CodeTable>")
	}
	#; relational conditions
	if $d($$$vaSchemaGbl(pCategory,"RC")) Do pFile.WriteLine("")
	set location="" for { set location=$o($$$vaSchemaGbl(pCategory,"RC",location)) quit:location=""
		Do pFile.Write("<RelationalCondition location='"_location_"'")
		Do pFile.WriteLine(">")
		set one="",i=0
		For  {
			Set one=$o($$$vaSchemaGbl(pCategory,"RC",location,one)) Quit:one=""
			Do pFile.Write("   <Enumerate")
			Do pFile.Write(" position='"_$I(i)_"'")
			Do pFile.Write(" rule='"_one_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</RelationalCondition>")
	}

	Do pFile.WriteLine("")
	Do pFile.WriteLine("</Category>")
	Do:pFile.%Extends("%Library.FileStreamAdaptor") pFile.SaveStream()
	Quit $$$OK
}

Property category;

Property base;

Property elementtype;

Property elementname;

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List) [ Internal ]
{
	for i=0:1:$LL(attrs)\5-1 set attribs($li(attrs,i*5+2))=$li(attrs,i*5+5)
	if localname="Category" {
		If ..CatOnly Set ..lastFileCategory=attribs("name")  ZTrap "GCAT"
		set ..category=$S(""'=..forceCategory:..forceCategory, 1:attribs("name")), ..forceCategory=""
		set ..base=$g(attribs("base"))
		set desc=$g(attribs("description"))
		set std=$g(attribs("std"))
		kill $$$vaSchemaGbl(..category), $$$vaSchemaDescGbl(..category)
		if ..base'="" set $$$vaSchemaGbl(..category,"base")=..base
		if desc'="" set $$$vaSchemaDescGbl(..category)=desc
		if $Case($ZCVT(std,"L"),"":0,0:0,"false":0,:1) set $$$vaSchemaDescGbl(..category,"std")=1
	} elseif localname="DocumentStructure" {
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"DS",attribs("name"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"DS",attribs("name"),"alt")=attribs("altdesc")
		if $g(attribs("purpose"))'=""	  set $$$vaSchemaDescGbl(..category,"DS",attribs("name"),"purpose")=attribs("purpose")
		set $$$vaSchemaGbl(..category,"DS",attribs("name"))=$g(attribs("definition"))
	} elseif localname="SegmentStructure" {
		set ..elementtype="SS"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"SS",..elementname)=attribs("description")
		set $$$vaSchemaGbl(..category,"SS",..elementname)=""
		Kill ..%propNames
	} elseif localname="SegmentSubStructure" {
		if ..elementtype'="SS" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"SS",..elementname,attribs("piece"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"SS",..elementname,attribs("piece"),"alt")=attribs("altdesc")
		if $g(attribs("codetable"))'=""   set $$$vaSchemaGbl(..category,"SS",..elementname,"tables",attribs("piece"))=attribs("codetable")
		set definition=$lb($g(attribs("datatype")),+$g(attribs("minlength"),0),$g(attribs("repeatcount")),$g(attribs("maxlength")),$g(attribs("required"),"O"),$g(attribs("elemid")))
		set $li($$$vaSchemaGbl(..category,"SS",..elementname),attribs("piece"))=definition
		set propname=..fieldDescToName(attribs("description"),..elementname,attribs("piece"))
		Set:$I(..%propNames(propname))>1 propname=propname_..%propNames(propname)
		set $$$vaSchemaGbl(..category,"SS",..elementname,"names",propname)=attribs("piece")
	} elseif localname="CompositeStructure" {
		set ..elementtype="CS"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"CS",attribs("name"))=attribs("description")
		set $$$vaSchemaGbl(..category,"CS",attribs("name"))=""
		Kill ..%propNames
	} elseif localname="CompositeSubStructure" {
		if ..elementtype'="CS" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"CS",..elementname,attribs("piece"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"CS",..elementname,attribs("piece"),"alt")=attribs("altdesc")
		if $g(attribs("codetable"))'="" set $$$vaSchemaGbl(..category,"CS",..elementname,"tables",attribs("piece"))=attribs("codetable")
		set definition=$lb($g(attribs("datatype")),+$g(attribs("minlength"),0),$g(attribs("repeatcount")),$g(attribs("maxlength")),$g(attribs("required"),"O"),$g(attribs("elemid")))
		set $li($$$vaSchemaGbl(..category,"CS",..elementname),attribs("piece"))=definition
		set propname=..compositeDescToName(attribs("description"),..elementname,attribs("piece"))
		Set:$I(..%propNames(propname))>1 propname=propname_..%propNames(propname)
		set $$$vaSchemaGbl(..category,"CS",..elementname,"names",propname)=attribs("piece")
	} elseif localname="CodeTable" {
		set ..elementtype="CT"
		set ..elementname=attribs("name")
		set:""'=$g(attribs("description")) $$$vaSchemaDescGbl(..category,"CT",..elementname)=attribs("description")
		set:""'=$g(attribs("tabletype")) $$$vaSchemaGbl(..category,"CT",..elementname)=attribs("tabletype")
	} elseif localname="RelationalCondition" {
		set ..elementtype="RC"
		set ..elementname=attribs("location")
	} elseif localname="Enumerate" {
		if ..elementtype="CT" {
			set tVal=attribs("value")  Set:""=tVal tVal=$C(0)
			if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"CT",..elementname,tVal)=attribs("description")
			set $$$vaSchemaGbl(..category,"CT",..elementname,tVal)=attribs("position")
		} elseif ..elementtype="RC" {
			set tRule=attribs("rule")
			set $$$vaSchemaGbl(..category,"RC",..elementname,tRule)=""
		} else {
			quit
		}
	} elseif ..category_..lastFileCategory'="" {
		Set ..Error=$$$ERROR($$$ObjectScriptError,"unrecognized tag <"_localname_"> in load of schema "_..Filename)
	}
	quit
}

ClassMethod fieldDescToName(desc, elem, piece) As %String
{
	Quit ##class(EnsLib.EDI.SEF.Compiler).CreateShortName(desc) ;$ZStrip($ZCVT($TR(desc,"/'"_$C(8217)," "),"W"),"*P")
}

ClassMethod compositeDescToName(desc, elem, piece) As %String
{
	Quit ##class(EnsLib.EDI.SEF.Compiler).CreateShortName(desc) ; $ZStrip($ZCVT($TR(desc,"/'"_$C(8217)," "),"W"),"*P")
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String) [ Internal ]
{
	if localname="Category" {
		if $$$ISOK(..Error) {
			set ..Error=..addDefaultCategories(..category,..Filename)
			do ##class(EnsLib.EDI.X12.Schema).BuildCategoryMaps(..category)
		}
		set $$$vaSchemaGbl(..category,"time")=$ZTS
		set ..lastFileCategory=..category
		set ..category=""
	} elseif localname="SegmentStructure" {
		set ..elementtype=""
		set ..elementname=""
	} elseif localname="CompositeStructure" {
		set ..elementtype=""
		set ..elementname=""
	} elseif localname="CodeTable" {
		set ..elementtype=""
		set ..elementname=""
	}
	quit
}

ClassMethod addDefaultCategories(pCategory As %String, pFilename As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	#; document structure
	set ds="" for { set ds=$o($$$vaSchemaGbl(pCategory,"DS",ds)) quit:ds=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DS",ds))
		set:""'=definition $$$vaSchemaGbl(pCategory,"DS",ds)=..addDefaultCategory(definition,pCategory,"SS",.sc,pFilename)
	}
	#; segment structure
	set ss="" for { set ss=$o($$$vaSchemaGbl(pCategory,"SS",ss)) quit:ss=""
		set definition=$g($$$vaSchemaGbl(pCategory,"SS",ss))
		set did=0  for i=1:1:$LL(definition) { continue:'$LD(definition,i)
			set info=$li(definition,i)
			set compositestruct=$lg(info,1)
			set:"("'=$E(compositestruct) $li(info,1)=..addDefaultCategory(compositestruct,pCategory,"CS",.sc,pFilename), $li(definition,i)=info, did=1
			set codetable=$g($$$vaSchemaGbl(pCategory,"SS",ss,"tables",i))
			set:""'=codetable $$$vaSchemaGbl(pCategory,"SS",ss,"tables",i)=..addDefaultCategory(codetable,pCategory,"CT",.sc,pFilename)
		}
		set:did $$$vaSchemaGbl(pCategory,"SS",ss)=definition
	}
	#; composite structure
	set cs="" for { set cs=$o($$$vaSchemaGbl(pCategory,"CS",cs)) quit:cs=""
		set definition=$g($$$vaSchemaGbl(pCategory,"CS",cs))
		set did=0  for i=1:1:$LL(definition)  {
			set codetable=$g($$$vaSchemaGbl(pCategory,"CS",cs,"tables",i))
			set:""'=codetable $$$vaSchemaGbl(pCategory,"CS",cs,"tables",i)=..addDefaultCategory(codetable,pCategory,"CT",.sc,pFilename)
		}
		set:did $$$vaSchemaGbl(pCategory,"CS",cs)=definition
	}
	quit:+$g($$$vaSchemaDescGbl(pCategory,"std")) $$$OK  ; don't report unresolved references in standard schema categories
	quit sc
}

/// Add categories to xml definitions for precise schema global definitions
ClassMethod addDefaultCategory(pValue As %String, pCategory As %String, pElementType As %String, ByRef pSC As %Status = {$$$OK}, pFilename As %String) As %String [ Internal ]
{
	for i=1:1:$L(pValue,"~") { set one=$P(pValue,"~",i)  continue:""=one
		continue:one?1(1"{".E,1"[".E,1"(".E,1P)
		set:":"=$E(one) $E(one)="" ; strip leading ':'
		set:".:"=$E(one,1,2) $E(one,1,2)="" ; strip leading '.:'
		set:"base:"=$E(one,1,$L("base:")) $E(one,1,$L("base:"))="" ; strip leading 'base:'
		if one'[":" {
			kill base  set base=pCategory, base(base)=1, tElemType=pElementType
			while ""'=base
				 && '$D($$$vaSchemaGbl(base,tElemType,$P(one,"!")))
				 && '("SS"=tElemType && ("DocsRef"=$e(one,*-$L("DocsRef")+1,*))) {
				set base=$G($$$vaSchemaGbl(base,"base"))
				#; prevent circular references
				if ""=base||$d(base(base)) set base=""  quit
				set base(base)=1
			}
			set:""=base base="."
			set $P(pValue,"~",i)=base_":"_one
			set:"."=base&&$$$ISOK(pSC) pSC=$$$ERROR($$$ObjectScriptError,"Unresolved "_tElemType_" reference '"_one_"' in category "_pCategory_" in load of schema "_pFilename)
		}
	}
	quit pValue
}

/// Strip schema global definition categories for concise xml format
ClassMethod stripDefCategory(pValue As %String, pDefCategory As %String, pBase As %String) As %String [ Internal ]
{
	for i=1:1:$L(pValue,"~") { set one=$P(pValue,"~",i)  continue:""=one
		continue:one?1P.NA
		set:":"=$E(one) $E(one)="" ; strip leading ':'
		if one[":" {
			set oneCat=$P(one,":"),oneDoc=$P(one,":",2)
			if oneCat=pDefCategory { set $P(pValue,"~",i)=oneDoc }
			elseif oneCat=pBase { set $P(pValue,"~",i)="base:"_oneDoc }
		}
	}
	quit pValue
}

}
