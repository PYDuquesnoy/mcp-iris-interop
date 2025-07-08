/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.XDataDefinition Extends (%Persistent, %Dictionary.XDataDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = XDatas ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// The data stream.
Property Data As %Stream.TmpCharacter;

/// True if this XDATA is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the XData.
Property Description As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// Mime type of XData block.
Property MimeType As %RawString [ InitialExpression = "text/xml" ];

/// The name of the xData block.
Property Name As %Dictionary.Identifier [ Required ];

/// The schema definition of the data.
Property SchemaSpec As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// The default XML NameSpace for the XDATA.
Property XMLNamespace As %RawString;

Index IDKEY On Name [ IdKey ];

Parameter SQLENABLED = 1;

Trigger OnInsertUpdate [ Event = INSERT/UPDATE ]
{
 set %ok=0
 set %msg="Insert/Update operations not supported on this table."
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
 $$$defClassKeySet($p({parent},"||",1),$$$cCLASStimechanged,$zutil(188))
 do RebuildItemIndex^%R($p({parent},"||",1),"CLS")
}

Method %OnNew(name As %String) As %Status [ Private ]
{
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("MimeType")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("SchemaSpec")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("XMLNamespace")=0
 i $g(name)="" q $$$OK
 s i%parent=$$$NormalizeClassname($p(name,":",1))
 s i%Name=$p(name,":",2)
 q $$$OK
}

/// The object representation of this XData block after correlating the XML and importing it
Property Object As %RegisteredObject [ Calculated ];

Method ObjectGet() As %RegisteredObject
{
 q ##class(%Studio.SASchemaUtil).returnCorrelated($this)
}

ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 i (name1="")||(name2="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$defMemberDefined(name1,$$$cCLASSxdata,name2) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSxdata,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal)
 . s i%MimeType=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype),i%%isDefined("MimeType")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype)
 . s i%SchemaSpec=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec),i%%isDefined("SchemaSpec")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber)
 . s i%XMLNamespace=$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace),i%%isDefined("XMLNamespace")=$$$defMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace)
 . s i%Data=""
 . f ptr=1:1:$$$defMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata) d
 . . d ..Data.WriteLine($$$defMemberArrayGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,ptr))
 . d ..Data.Rewind()
exit i i%%Concurrency=2||(i%%Concurrency=1) d ..%UnlockId(id,1,1)
 q sc
trap s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g exit
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 $$$IsClassDefVersionMatched(ismatched) i ismatched=0 q $$$ERROR($$$ClassDictionaryVersionMismatch)
 s sc=$$$OK,id=$$$idCurrent i id'="" s insert=0,idassigned=1
 e  s insert=1,idassigned=0
 s lock=0
 i i%parent'="",'##class(%Dictionary.ClassDefinition).%ExistsId(i%parent) q $$$ERROR($$$ReferencedObjectDoesNotExist,"ClassName")
 i 'insert DO
 . i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i '($$$defMemberDefined(name1,$$$cCLASSxdata,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSxdata,name2,"")
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription,i%Description) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal,i%Internal) }
 . i 'i%%isDefined("MimeType") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype,i%MimeType) }
 . i 'i%%isDefined("SchemaSpec") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec,i%SchemaSpec) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("XMLNamespace") { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace,i%XMLNamespace) }
 . $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAdata)
 . d ..Data.Rewind() s ..Data.LineTerminator=$c(10)
 . f line=1:1 q:..Data.AtEnd  d
 . . s linetext=..Data.ReadLine($$$MaxLocalLength) i $e(linetext,*)=$c(13) s linetext=$e(linetext,1,*-1)
 . . $$$defMemberArraySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,line,linetext)
 . $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,line-1)
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSxdata,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.XDataDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSxdata,name2,"")
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription,i%Description) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal,i%Internal) }
 . i i%MimeType="text/xml" { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype,i%MimeType) }
 . i i%SchemaSpec="" { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec,i%SchemaSpec) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber,i%SequenceNumber) }
 . i i%XMLNamespace="" { $$$defMemberKeyKill(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace) } else { $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace,i%XMLNamespace) }
 . d ..Data.Rewind() s ..Data.LineTerminator=$c(10)
 . f line=1:1 q:..Data.AtEnd  d
 . . s linetext=..Data.ReadLine($$$MaxLocalLength) i $e(linetext,*)=$c(13) s linetext=$e(linetext,1,*-1)
 . . $$$defMemberArraySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,line,linetext)
 . $$$defMemberKeySet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,line-1)
 . i i%%Concurrency=3 s sc=..%LockId(id,1)
 . s:i%%Concurrency=4 lock=0
 i $$$ISERR(sc) d:lock ..%UnlockId(id) QUIT sc
 d:lock ..%UnlockId(id)
 If $$$ISOK(sc) Set %objTX(9,"Do UpdClsDef^%occLibrary("""_name1_""")")=""
 QUIT sc
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
 Quit:id="" $$$ERROR($$$NullId)
 Set sc=$$$OK
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 If concurrency Set sc=..%LockId(id) If $$$ISERR(sc) Quit sc
 If '($$$defMemberDefined(name1,$$$cCLASSxdata,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSxdata,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
}

Method DeprecatedSet(value As %String = "") As %Status
{
 set i%Deprecated=value,i%%isDefined("Deprecated")=1 quit $$$OK
}

Method DeprecatedReset()
{
 set i%Deprecated=0 set i%%isDefined("Deprecated")=0 quit
}

Method DeprecatedIsDefined() As %Boolean
{
 quit ''i%%isDefined("Deprecated")
}

Method DescriptionSet(value As %String = "") As %Status
{
 set i%Description=value,i%%isDefined("Description")=1 quit $$$OK
}

Method DescriptionReset()
{
 set i%Description="" set i%%isDefined("Description")=0 quit
}

Method DescriptionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Description")
}

Method InternalSet(value As %String = "") As %Status
{
 set i%Internal=value,i%%isDefined("Internal")=1 quit $$$OK
}

Method InternalReset()
{
 set i%Internal=0 set i%%isDefined("Internal")=0 quit
}

Method InternalIsDefined() As %Boolean
{
 quit ''i%%isDefined("Internal")
}

Method MimeTypeSet(value As %String = "") As %Status
{
 set i%MimeType=value,i%%isDefined("MimeType")=1 quit $$$OK
}

Method MimeTypeReset()
{
 set i%MimeType="text/xml" set i%%isDefined("MimeType")=0 quit
}

Method MimeTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("MimeType")
}

Method NameSet(value As %String = "") As %Status
{
 set i%Name=value,i%%isDefined("Name")=1 quit $$$OK
}

Method NameReset()
{
 set i%Name="" set i%%isDefined("Name")=0 quit
}

Method NameIsDefined() As %Boolean
{
 quit ''i%%isDefined("Name")
}

Method SchemaSpecSet(value As %String = "") As %Status
{
 set i%SchemaSpec=value,i%%isDefined("SchemaSpec")=1 quit $$$OK
}

Method SchemaSpecReset()
{
 set i%SchemaSpec="" set i%%isDefined("SchemaSpec")=0 quit
}

Method SchemaSpecIsDefined() As %Boolean
{
 quit ''i%%isDefined("SchemaSpec")
}

Method SequenceNumberSet(value As %String = "") As %Status
{
 set i%SequenceNumber=value,i%%isDefined("SequenceNumber")=1 quit $$$OK
}

Method SequenceNumberReset()
{
 set i%SequenceNumber=0 set i%%isDefined("SequenceNumber")=0 quit
}

Method SequenceNumberIsDefined() As %Boolean
{
 quit ''i%%isDefined("SequenceNumber")
}

Method XMLNamespaceSet(value As %String = "") As %Status
{
 set i%XMLNamespace=value,i%%isDefined("XMLNamespace")=1 quit $$$OK
}

Method XMLNamespaceReset()
{
 set i%XMLNamespace="" set i%%isDefined("XMLNamespace")=0 quit
}

Method XMLNamespaceIsDefined() As %Boolean
{
 quit ''i%%isDefined("XMLNamespace")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Data">
<RetrievalCode> s {Data}=""
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"x",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"x",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"x",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="MimeType">
<RetrievalCode> s {MimeType}=$s($d(^oddDEF({L1},"x",{L3},24))#2:^(24),1:"text/xml")
</RetrievalCode>
</Data>
<Data name="SchemaSpec">
<RetrievalCode> s {SchemaSpec}=$s($d(^oddDEF({L1},"x",{L3},22))#2:^(22),1:"")
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"x",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="XMLNamespace">
<RetrievalCode> s {XMLNamespace}=$s($d(^oddDEF({L1},"x",{L3},23))#2:^(23),1:"")
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"x"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.XDataDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.XDataDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
