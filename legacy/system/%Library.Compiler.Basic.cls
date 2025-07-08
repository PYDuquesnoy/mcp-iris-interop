/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Interface to the Basic Compiler
Class %Library.Compiler.Basic Extends %Library.RegisteredObject [ Not ProcedureBlock, System = 2 ]
{

/// Given a resolved class name, return the class flags for the named class
/// Bit 1 = On if the class is a datatype class
ClassMethod ClassFlags(ClassName As %Library.String) As %Library.List [ Final ]
{
	Quit $ListBuild($$$getClassType(ClassName)=$$$cCLASSCLASSTYPEDATATYPE)
}

/// Returns a List containing an encoded description of the class members for use during the
/// Cache Basic compilation process
/// Each member is a $list(), consists of name, membertype, and one or several values
/// For methods,    the format is: name, 1, classmethod, quitwithvalue,arglist
/// arglist contains a list of argument names and a flag indicating whether the argument is
/// passed byref or not (0 = byvalue, 1 = byref)
/// For parameters, the format is: name, 2, defaultvalue
/// For properties, the format is: name, 3, multidim, datatype, calculated, slot, element
/// (please note that slot and element numbers only make sense for datatype and non-calculated properties)
/// At the end of of the list, there is a end-of-data marker, which is $lb("").  If there is no
/// end-of-data marker at the end, that means there is more data to come.  The caller should call
/// back to ClassInfo again, passing the last member element as its second input value.
ClassMethod ClassInfo(ClassName As %Library.String, cursor As %Library.Binary) As %Library.List [ Final ]
{
 #define kindMETHOD      1
 #define kindPARAMETER   2
 #define kindPROPERTY    3
 #define kindLAST        3
 #define ENDOFDATAMARKER $lb("")
 #define MAXVALUESIZE    30000
 #;
 n class,kind,name,value,onevalue,quit,stub,kd,pq,mn,clsm,qval,mdim,dtyp,calc,slot,elem,modbit,isdtyp,rttype,prtype
 s class=$$$NormalizeClassname(ClassName)
 s name=$lg($g(cursor),1,""),kind=$lg($g(cursor),2,1)
 s value="",quit=0
 f  d  q:quit  s kind=kind+1 q:kind>$$$kindLAST
 . i kind=$$$kindMETHOD f  s name=$$$comMemberNext(class,$$$cCLASSmethod,name) q:name=""  d  q:quit
 . . s stub=$$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHstub)
 . . i stub'="" s pq=$p(stub,".",1),mn=$p(stub,".",2),kd=$p(stub,".",3)
 . . i  s clsm=$$$comSubMemberKeyGet(class,kd,pq,$$$cCLASSmethod,mn,$$$cMETHclassmethod)
 . . e  s clsm=$$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHclassmethod)
 . . i  s qval=($$$comSubMemberKeyGet(class,kd,pq,$$$cCLASSmethod,mn,$$$cMETHreturntype)'="")
 . . e  s qval=($$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHreturntype)'="")
 #;
 #; Get the method arguments
 . . New tArgs Set tArgs=$$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHformalspec)
 #;
 #; Strip leading/trailing parens (cdl compiler lets extraneous ones through)
 . . For  Quit:$extract(tArgs,1)'="("  Set $Extract(tArgs)=""
 . . For  Quit:$extract(tArgs,$Length(tArgs))'=")"  Set $Extract(tArgs,$Length(tArgs))=""
 #;
 #; Parse the args and create the list of arg descriptors
 . . New tC,tI,tList,tName,tByRef Set tList=""
 . . If tArgs]"" For tI=1:1:$Length(tArgs,",") Do
 . . . Set tName=$Piece($Piece($Piece(tArgs,",",tI),":"),"=")
 . . . Set tC=$Extract(tName) If tC="*"!(tC="&")!(tC=".") Set tByRef=1,$Extract(tName)=""
 . . . Else  Set tByRef=0
 . . . Set tList=tList_$ListBuild(tName,tByRef)
 . . s onevalue=$lb($lb(name,kind,+clsm,qval,tList))
 . . i $l(value)+$l(onevalue)>$$$MAXVALUESIZE s quit=1 q
 . . s value=value_onevalue
 . i kind=$$$kindPARAMETER f  s name=$$$comMemberNext(class,$$$cCLASSparameter,name) q:name=""  d  q:quit
 . . s onevalue=$lb($lb(name,kind,$$$comMemberKeyGet(class,$$$cCLASSparameter,name,$$$cPARAMdefault)))
 . . i $l(value)+$l(onevalue)>$$$MAXVALUESIZE s quit=1 q
 . . s value=value_onevalue
 . i kind=$$$kindPROPERTY f  s name=$$$comMemberNext(class,$$$cCLASSproperty,name) q:name=""  d  q:quit
 . . s mdim=$$$comMemberKeyGet(class,$$$cCLASSproperty,name,$$$cPROPmultidimensional)
 . . s rttype=$$$comMemberKeyGet(class,$$$cCLASSproperty,name,$$$cPROPruntimetype)
 . . s prtype=$$$comMemberKeyGet(class,$$$cCLASSproperty,name,$$$cPROPtype)
 . . s isdtyp=$$$classIsDataType(rttype)
 . . s calc=$$$comMemberKeyGet(class,$$$cCLASSproperty,name,$$$cPROPcalculated)
 . . s slot=""  ; Previous call to GetPropNumber^%occDescriptor never worked
 . . s onevalue=$lb($lb(name,kind,+mdim,+isdtyp,+calc,+slot,0,0,1,+slot,prtype,rttype))
 . . i $l(value)+$l(onevalue)>$$$MAXVALUESIZE s quit=1 q
 . . s value=value_onevalue
 i quit=0 s value=value_$$$ENDOFDATAMARKER
 q value
}

ClassMethod GetSource(VarName, Line)
{
#;
#; GetSource - retrieve a chunk of source - minimal implementation
 New list Set list="" For Line=Line:1 Quit:'$Data(@VarName@(Line))  Set list=list_$LB(@VarName@(Line))
 Quit list
}

ClassMethod PutSuperTokens(VarName, Index, Tokens)
{
#;
#; Save returned supertokens - minimal implementation
 Set @VarName@(Index)=Tokens
 Quit 1
}

/// Given an abbreviated class name and an import list, resolve the full class name
ClassMethod ResolveClassName(ClassName As %Library.String, ImportList As %Library.String) As %Library.List [ Final ]
{
 If $Extract(ImportList,$Length(ImportList))="," Set $Extract(ImportList,$Length(ImportList))=""
 New class,list,%sc,i
 Set list="" If ImportList'="" For i=1:1:$Length(ImportList,",") Set list=list_$ListBuild($Piece(ImportList,",",i))
 Set %sc=$$NormalizeClassnameByImports^%occName(.class,ClassName,list)
 If $$$ISERR(%sc) Set class=ClassName
 Quit $ListBuild(class)
}

}
