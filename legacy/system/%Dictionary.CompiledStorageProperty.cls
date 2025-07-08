/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageProperty Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorage [ Cardinality = parent, Inverse = Properties ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// AverageFieldSize
Property AverageFieldSize As %RawString;

/// BiasQueriesAsOutlier
Property BiasQueriesAsOutlier As %RawString;

/// ChildBlockCount
Property ChildBlockCount As %RawString;

/// ChildExtentSize
Property ChildExtentSize As %RawString;

/// Histogram
Property Histogram As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %RawString [ Required ];

/// OutlierSelectivity
Property OutlierSelectivity As %RawString;

/// Selectivity
Property Selectivity As %RawString;

/// StreamLocation
Property StreamLocation As %RawString;

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

ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 i (name1="")||(name2="")||(name3="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||('$$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%AverageFieldSize=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYaveragefieldsize),i%%isDefined("AverageFieldSize")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYaveragefieldsize)
 . s i%BiasQueriesAsOutlier=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYbiasqueriesasoutlier),i%%isDefined("BiasQueriesAsOutlier")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYbiasqueriesasoutlier)
 . s i%ChildBlockCount=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYchildblockcount),i%%isDefined("ChildBlockCount")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYchildblockcount)
 . s i%ChildExtentSize=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYchildextentsize),i%%isDefined("ChildExtentSize")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYchildextentsize)
 . s i%Histogram=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYhistogram),i%%isDefined("Histogram")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYhistogram)
 . s i%KeywordError=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYkeyworderror)
 . s i%KeywordModified=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYkeywordmodified)
 . s i%OutlierSelectivity=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYoutlierselectivity),i%%isDefined("OutlierSelectivity")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYoutlierselectivity)
 . s i%Selectivity=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYselectivity),i%%isDefined("Selectivity")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYselectivity)
 . s i%StreamLocation=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYstreamlocation),i%%isDefined("StreamLocation")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYstreamlocation)
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

Method AverageFieldSizeSet(value As %String = "") As %Status
{
 set i%AverageFieldSize=value,i%%isDefined("AverageFieldSize")=1 quit $$$OK
}

Method AverageFieldSizeReset()
{
 set i%AverageFieldSize="" set i%%isDefined("AverageFieldSize")=0 quit
}

Method AverageFieldSizeIsDefined() As %Boolean
{
 quit ''i%%isDefined("AverageFieldSize")
}

Method BiasQueriesAsOutlierSet(value As %String = "") As %Status
{
 set i%BiasQueriesAsOutlier=value,i%%isDefined("BiasQueriesAsOutlier")=1 quit $$$OK
}

Method BiasQueriesAsOutlierReset()
{
 set i%BiasQueriesAsOutlier="" set i%%isDefined("BiasQueriesAsOutlier")=0 quit
}

Method BiasQueriesAsOutlierIsDefined() As %Boolean
{
 quit ''i%%isDefined("BiasQueriesAsOutlier")
}

Method ChildBlockCountSet(value As %String = "") As %Status
{
 set i%ChildBlockCount=value,i%%isDefined("ChildBlockCount")=1 quit $$$OK
}

Method ChildBlockCountReset()
{
 set i%ChildBlockCount="" set i%%isDefined("ChildBlockCount")=0 quit
}

Method ChildBlockCountIsDefined() As %Boolean
{
 quit ''i%%isDefined("ChildBlockCount")
}

Method ChildExtentSizeSet(value As %String = "") As %Status
{
 set i%ChildExtentSize=value,i%%isDefined("ChildExtentSize")=1 quit $$$OK
}

Method ChildExtentSizeReset()
{
 set i%ChildExtentSize="" set i%%isDefined("ChildExtentSize")=0 quit
}

Method ChildExtentSizeIsDefined() As %Boolean
{
 quit ''i%%isDefined("ChildExtentSize")
}

Method HistogramSet(value As %String = "") As %Status
{
 set i%Histogram=value,i%%isDefined("Histogram")=1 quit $$$OK
}

Method HistogramReset()
{
 set i%Histogram="" set i%%isDefined("Histogram")=0 quit
}

Method HistogramIsDefined() As %Boolean
{
 quit ''i%%isDefined("Histogram")
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

Method OutlierSelectivitySet(value As %String = "") As %Status
{
 set i%OutlierSelectivity=value,i%%isDefined("OutlierSelectivity")=1 quit $$$OK
}

Method OutlierSelectivityReset()
{
 set i%OutlierSelectivity="" set i%%isDefined("OutlierSelectivity")=0 quit
}

Method OutlierSelectivityIsDefined() As %Boolean
{
 quit ''i%%isDefined("OutlierSelectivity")
}

Method SelectivitySet(value As %String = "") As %Status
{
 set i%Selectivity=value,i%%isDefined("Selectivity")=1 quit $$$OK
}

Method SelectivityReset()
{
 set i%Selectivity="" set i%%isDefined("Selectivity")=0 quit
}

Method SelectivityIsDefined() As %Boolean
{
 quit ''i%%isDefined("Selectivity")
}

Method StreamLocationSet(value As %String = "") As %Status
{
 set i%StreamLocation=value,i%%isDefined("StreamLocation")=1 quit $$$OK
}

Method StreamLocationReset()
{
 set i%StreamLocation="" set i%%isDefined("StreamLocation")=0 quit
}

Method StreamLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("StreamLocation")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="AverageFieldSize">
<RetrievalCode> s {AverageFieldSize}=$g(^oddCOM({L1},"s",{L3},"M",{L5},26),$g(^%qObjectKey(1,"M",26)))
</RetrievalCode>
</Data>
<Data name="BiasQueriesAsOutlier">
<RetrievalCode> s {BiasQueriesAsOutlier}=$g(^oddCOM({L1},"s",{L3},"M",{L5},25),$g(^%qObjectKey(1,"M",25)))
</RetrievalCode>
</Data>
<Data name="ChildBlockCount">
<RetrievalCode> s {ChildBlockCount}=$g(^oddCOM({L1},"s",{L3},"M",{L5},27),$g(^%qObjectKey(1,"M",27)))
</RetrievalCode>
</Data>
<Data name="ChildExtentSize">
<RetrievalCode> s {ChildExtentSize}=$g(^oddCOM({L1},"s",{L3},"M",{L5},23),$g(^%qObjectKey(1,"M",23)))
</RetrievalCode>
</Data>
<Data name="Histogram">
<RetrievalCode> s {Histogram}=$g(^oddCOM({L1},"s",{L3},"M",{L5},28),$g(^%qObjectKey(1,"M",28)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"M",{L5},12),$g(^%qObjectKey(1,"M",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"M",{L5},13),$g(^%qObjectKey(1,"M",13)))
</RetrievalCode>
</Data>
<Data name="OutlierSelectivity">
<RetrievalCode> s {OutlierSelectivity}=$g(^oddCOM({L1},"s",{L3},"M",{L5},24),$g(^%qObjectKey(1,"M",24)))
</RetrievalCode>
</Data>
<Data name="Selectivity">
<RetrievalCode> s {Selectivity}=$g(^oddCOM({L1},"s",{L3},"M",{L5},21),$g(^%qObjectKey(1,"M",21)))
</RetrievalCode>
</Data>
<Data name="StreamLocation">
<RetrievalCode> s {StreamLocation}=$g(^oddCOM({L1},"s",{L3},"M",{L5},22),$g(^%qObjectKey(1,"M",22)))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"s"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledStorage.Name}</Expression>
</Subscript>
<Subscript name="4">
<Expression>"M"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledStorageProperty.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledSto4B18S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
