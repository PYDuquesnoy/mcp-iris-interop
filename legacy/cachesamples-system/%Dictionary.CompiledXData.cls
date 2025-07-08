/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledXData Extends (%Persistent, %Dictionary.CompiledXDataQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = XDatas ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// The data stream.
Property Data As %Stream.TmpCharacter;

/// True if this XDATA is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the XData.
Property Description As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Mime type of XData block.
Property MimeType As %RawString;

/// The name of the xData block.
Property Name As %Dictionary.Identifier [ Required ];

/// Origin
Property Origin As %RawString;

/// The schema definition of the data.
Property SchemaSpec As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// The default XML NameSpace for the XDATA.
Property XMLNamespace As %RawString;

Index IDKEY On Name [ IdKey ];

Parameter SQLENABLED = 1;

Trigger OnInsertUpdate [ Event = INSERT/UPDATE ]
{
 set %ok=0
 set %msg="Insert/Update operations not supported on this table."
}

Trigger OnDelete [ Event = DELETE ]
{
 set %ok=0
 set %msg="Delete operation not supported on this table."
}

Method %OnNew(name As %String) As %Status [ Private ]
{
 q $$$ERROR($$$CanNotNewCompiledDictionaryClasses)
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
 i $$$comMemberDefined(name1,$$$cCLASSxdata,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSxdata,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAdescription)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAkeywordmodified)
 . s i%MimeType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype),i%%isDefined("MimeType")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAmimetype)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAorigin)
 . s i%SchemaSpec=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec),i%%isDefined("SchemaSpec")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAschemaspec)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAsequencenumber)
 . s i%XMLNamespace=$$$comMemberKeyGetO(origin,name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace),i%%isDefined("XMLNamespace")=$$$comMemberKeyDefined(name1,$$$cCLASSxdata,name2,$$$cXDATAxmlnamespace)
 . s i%Data=""
 . f ptr=1:1:$$$comMemberKeyGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata) d
 . . d ..Data.WriteLine($$$comMemberArrayGet(name1,$$$cCLASSxdata,name2,$$$cXDATAdata,ptr))
 . d ..Data.Rewind()
exit i i%%Concurrency=2||(i%%Concurrency=1) d ..%UnlockId(id,1,1)
 q sc
trap s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g exit
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 q $$$ERROR($$$CanNotSaveCompiledDictionaryClasses)
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
	Quit $$$ERROR($$$CanNotDeleteCompiledDictionaryClasses)
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
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"x",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"x",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"x",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"x",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"x",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"x",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"x",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"x",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"x",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"x",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="MimeType">
<RetrievalCode> s {MimeType}=$s($d(^oddCOM({L1},"x",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"x",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},24))#2:^(24),1:"text/xml"))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"x",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"x",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="SchemaSpec">
<RetrievalCode> s {SchemaSpec}=$s($d(^oddCOM({L1},"x",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"x",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"x",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"x",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="XMLNamespace">
<RetrievalCode> s {XMLNamespace}=$s($d(^oddCOM({L1},"x",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"x",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"x",{L3},2),{L1}),"x",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"x"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledXData.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledXDataS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
