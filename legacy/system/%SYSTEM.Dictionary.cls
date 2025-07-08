/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Dictionary Extends Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

ClassMethod defClassDefined(%class) As %String [ CodeMode = expression ]
{
$$$defClassDefined(%class)
}

ClassMethod defClassKeyDefined(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$defClassKeyDefined(%class,%ckey)
}

ClassMethod defClassArrayDefined(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$defClassArrayDefined(%class,%ckey,%member)
}

ClassMethod defMemberDefined(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$defMemberDefined(%class,%ckey,%member)
}

ClassMethod defMemberKeyDefined(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$defMemberKeyDefined(%class,%ckey,%member,%mkey)
}

ClassMethod defSubMemberDefined(%class, %ckey, %member, %mkey, %submember) As %String [ CodeMode = expression ]
{
$$$defSubMemberDefined(%class,%ckey,%member,%mkey,%submember)
}

ClassMethod defSubMemberKeyDefined(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$defSubMemberKeyDefined(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod defClassKeyGet(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$defClassKeyGet(%class,%ckey)
}

ClassMethod defClassArrayGet(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$defClassArrayGet(%class,%ckey,%member)
}

ClassMethod defMemberKeyGet(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$defMemberKeyGet(%class,%ckey,%member,%mkey)
}

ClassMethod defMemberArrayGet(%class, %ckey, %member, %mkey, %msub) As %String [ CodeMode = expression ]
{
$$$defMemberArrayGet(%class,%ckey,%member,%mkey,%msub)
}

ClassMethod defSubMemberKeyGet(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$defSubMemberKeyGet(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod defSubMemberArrayGet(%class, %ckey, %member, %mkey, %submember, %skey, %ssub) As %String [ CodeMode = expression ]
{
$$$defSubMemberArrayGet(%class,%ckey,%member,%mkey,%submember,%skey,%ssub)
}

ClassMethod defClassKill(%class)
{
 $$$defClassKill(%class) Do RebuildItemIndex^%R(%class,"CLS")
 Quit
}

ClassMethod defClassKeyKill(%class, %ckey)
{
 $$$defClassKeyKill(%class,%ckey)
 Quit
}

ClassMethod defClassArrayKill(%class, %ckey, %member)
{
 $$$defClassArrayKill(%class,%ckey,%member)
 Quit
}

ClassMethod defMemberKill(%class, %ckey, %member)
{
 $$$defMemberKill(%class,%ckey,%member)
 Quit
}

ClassMethod defMemberKeyKill(%class, %ckey, %member, %mkey)
{
 $$$defMemberKeyKill(%class,%ckey,%member,%mkey)
 Quit
}

ClassMethod defSubMemberKill(%class, %ckey, %member, %mkey, %submember)
{
 $$$defSubMemberKill(%class,%ckey,%member,%mkey,%submember)
 Quit
}

ClassMethod defSubMemberKeyKill(%class, %ckey, %member, %mkey, %submember, %skey)
{
 $$$defSubMemberKeyKill(%class,%ckey,%member,%mkey,%submember,%skey)
 Quit
}

ClassMethod defClassNext(%class) As %String [ CodeMode = expression ]
{
$$$defClassNext(%class)
}

ClassMethod defClassKeyNext(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$defClassKeyNext(%class,%ckey)
}

ClassMethod defClassArrayNext(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$defClassArrayNext(%class,%ckey,%member)
}

ClassMethod defMemberNext(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$defMemberNext(%class,%ckey,%member)
}

ClassMethod defMemberKeyNext(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$defMemberKeyNext(%class,%ckey,%member,%mkey)
}

ClassMethod defSubMemberNext(%class, %ckey, %member, %mkey, %submember) As %String [ CodeMode = expression ]
{
$$$defSubMemberNext(%class,%ckey,%member,%mkey,%submember)
}

ClassMethod defSubMemberKeyNext(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$defSubMemberKeyNext(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod defClassSet(%class, %value)
{
 $$$defClassSet(%class,%value)
 Quit
}

ClassMethod defClassKeySet(%class, %ckey, %value)
{
 $$$defClassKeySet(%class,%ckey,%value)
 Quit
}

ClassMethod defClassArraySet(%class, %ckey, %member, %value)
{
 $$$defClassArraySet(%class,%ckey,%member,%value)
 Quit
}

ClassMethod defMemberSet(%class, %ckey, %member, %value)
{
 $$$defMemberSet(%class,%ckey,%member,%value)
 Quit
}

ClassMethod defMemberKeySet(%class, %ckey, %member, %mkey, %value)
{
 $$$defMemberKeySet(%class,%ckey,%member,%mkey,%value)
 Quit
}

ClassMethod defMemberArraySet(%class, %ckey, %member, %mkey, %msub, %value)
{
 $$$defMemberArraySet(%class,%ckey,%member,%mkey,%msub,%value)
 Quit
}

ClassMethod defSubMemberSet(%class, %ckey, %member, %mkey, %submember, %value)
{
 $$$defSubMemberSet(%class,%ckey,%member,%mkey,%submember,%value)
 Quit
}

ClassMethod defSubMemberKeySet(%class, %ckey, %member, %mkey, %submember, %skey, %value)
{
 $$$defSubMemberKeySet(%class,%ckey,%member,%mkey,%submember,%skey,%value)
 Quit
}

ClassMethod defSubMemberArraySet(%class, %ckey, %member, %mkey, %submember, %skey, %ssub, %value)
{
 $$$defSubMemberArraySet(%class,%ckey,%member,%mkey,%submember,%skey,%ssub,%value)
 Quit
}

ClassMethod comClassDefined(%class) As %String [ CodeMode = expression ]
{
$$$comClassDefined(%class)
}

ClassMethod comClassKeyDefined(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$comClassKeyDefined(%class,%ckey)
}

ClassMethod comClassArrayDefined(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$comClassArrayDefined(%class,%ckey,%member)
}

ClassMethod comMemberDefined(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$comMemberDefined(%class,%ckey,%member)
}

ClassMethod comMemberKeyDefined(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$comMemberKeyDefined(%class,%ckey,%member,%mkey)
}

ClassMethod comSubMemberDefined(%class, %ckey, %member, %mkey, %submember) As %String [ CodeMode = expression ]
{
$$$comSubMemberDefined(%class,%ckey,%member,%mkey,%submember)
}

ClassMethod comSubMemberKeyDefined(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$comSubMemberKeyDefined(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod comClassKeyGet(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$comClassKeyGet(%class,%ckey)
}

ClassMethod comClassArrayGet(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$comClassArrayGet(%class,%ckey,%member)
}

ClassMethod comMemberKeyGet(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$comMemberKeyGet(%class,%ckey,%member,%mkey)
}

ClassMethod comMemberArrayGet(%class, %ckey, %member, %mkey, %msub) As %String [ CodeMode = expression ]
{
$$$comMemberArrayGet(%class,%ckey,%member,%mkey,%msub)
}

ClassMethod comSubMemberKeyGet(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$comSubMemberKeyGet(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod comSubMemberArrayGet(%class, %ckey, %member, %mkey, %submember, %skey, %ssub) As %String [ CodeMode = expression ]
{
$$$comSubMemberArrayGet(%class,%ckey,%member,%mkey,%submember,%skey,%ssub)
}

ClassMethod comClassKeyGetLvar(%lvar, %class, %ckey)
{
 $$$comClassKeyGetLvar(%lvar,%class,%ckey)
 Quit
}

ClassMethod comClassArrayGetLvar(%lvar, %class, %ckey, %member)
{
 $$$comClassArrayGetLvar(%lvar,%class,%ckey,%member)
 Quit
}

ClassMethod comMemberKeyGetLvar(%lvar, %class, %ckey, %member, %mkey)
{
 $$$comMemberKeyGetLvar(%lvar,%class,%ckey,%member,%mkey)
 Quit
}

ClassMethod comMemberArrayGetLvar(%lvar, %class, %ckey, %member, %mkey, %msub)
{
 $$$comMemberArrayGetLvar(%lvar,%class,%ckey,%member,%mkey,%msub)
 Quit
}

ClassMethod comSubMemberKeyGetLvar(%lvar, %class, %ckey, %member, %mkey, %submember, %skey)
{
 $$$comSubMemberKeyGetLvar(%lvar,%class,%ckey,%member,%mkey,%submember,%skey)
 Quit
}

ClassMethod comSubMemberArrayGetLvar(%lvar, %class, %ckey, %member, %mkey, %submember, %skey, %ssub)
{
 $$$comSubMemberArrayGetLvar(%lvar,%class,%ckey,%member,%mkey,%submember,%skey,%ssub)
 Quit
}

ClassMethod comClassKill(%class)
{
 $$$comClassKill(%class)
 Quit
}

ClassMethod comClassKeyKill(%class, %ckey)
{
 $$$comClassKeyKill(%class,%ckey)
 Quit
}

ClassMethod comClassArrayKill(%class, %ckey, %member)
{
 $$$comClassArrayKill(%class,%ckey,%member)
 Quit
}

ClassMethod comMemberKill(%class, %ckey, %member)
{
 $$$comMemberKill(%class,%ckey,%member)
 Quit
}

ClassMethod comMemberKeyKill(%class, %ckey, %member, %mkey)
{
 $$$comMemberKeyKill(%class,%ckey,%member,%mkey)
 Quit
}

ClassMethod comSubMemberKill(%class, %ckey, %member, %mkey, %submember)
{
 $$$comSubMemberKill(%class,%ckey,%member,%mkey,%submember)
 Quit
}

ClassMethod comSubMemberKeyKill(%class, %ckey, %member, %mkey, %submember, %skey)
{
 $$$comSubMemberKeyKill(%class,%ckey,%member,%mkey,%submember,%skey)
 Quit
}

ClassMethod comClassNext(%class) As %String [ CodeMode = expression ]
{
$$$comClassNext(%class)
}

ClassMethod comClassKeyNext(%class, %ckey) As %String [ CodeMode = expression ]
{
$$$comClassKeyNext(%class,%ckey)
}

ClassMethod comClassArrayNext(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$comClassArrayNext(%class,%ckey,%member)
}

ClassMethod comMemberNext(%class, %ckey, %member) As %String [ CodeMode = expression ]
{
$$$comMemberNext(%class,%ckey,%member)
}

ClassMethod comMemberKeyNext(%class, %ckey, %member, %mkey) As %String [ CodeMode = expression ]
{
$$$comMemberKeyNext(%class,%ckey,%member,%mkey)
}

ClassMethod comSubMemberNext(%class, %ckey, %member, %mkey, %submember) As %String [ CodeMode = expression ]
{
$$$comSubMemberNext(%class,%ckey,%member,%mkey,%submember)
}

ClassMethod comSubMemberKeyNext(%class, %ckey, %member, %mkey, %submember, %skey) As %String [ CodeMode = expression ]
{
$$$comSubMemberKeyNext(%class,%ckey,%member,%mkey,%submember,%skey)
}

ClassMethod comClassSet(%class, %value)
{
 $$$comClassSet(%class,%value)
 Quit
}

ClassMethod comClassKeySet(%class, %ckey, %value)
{
 $$$comClassKeySet(%class,%ckey,%value)
 Quit
}

ClassMethod comClassArraySet(%class, %ckey, %member, %value)
{
 $$$comClassArraySet(%class,%ckey,%member,%value)
 Quit
}

ClassMethod comMemberSet(%class, %ckey, %member, %value)
{
 $$$comMemberSet(%class,%ckey,%member,%value)
 Quit
}

ClassMethod comMemberKeySet(%class, %ckey, %member, %mkey, %value)
{
 $$$comMemberKeySet(%class,%ckey,%member,%mkey,%value)
 Quit
}

ClassMethod comSubMemberSet(%class, %ckey, %member, %mkey, %submember, %value)
{
 $$$comSubMemberSet(%class,%ckey,%member,%mkey,%submember,%value)
 Quit
}

ClassMethod comSubMemberKeySet(%class, %ckey, %member, %mkey, %submember, %skey, %value)
{
 $$$comSubMemberKeySet(%class,%ckey,%member,%mkey,%submember,%skey,%value)
 Quit
}

ClassMethod defStorageSubMemberDefined(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberDefined(%class,%ck,%m,%mk,%sm)
}

ClassMethod defStorageSubMemberKeyDefined(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod defStorageSubSubMemberDefined(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod defStorageSubSubMemberKeyDefine(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod defStorageSubSubSubMemberDefine(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod defStorageSubSubSubMemberKeyDef(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod defStorageSubMemberGet(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberGet(%class,%ck,%m,%mk,%sm)
}

ClassMethod defStorageSubSubMemberGet(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberGet(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod defStorageSubSubSubMemberGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod defStorageSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod defStorageSubSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod defStorageSubSubSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod defStorageSubMemberKill(%class, %ck, %m, %mk, %sm)
{
 $$$defStorageSubMemberKill(%class,%ck,%m,%mk,%sm)
 Quit
}

ClassMethod defStorageSubMemberKeyKill(%class, %ck, %m, %mk, %sm, %sk)
{
 $$$defStorageSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk)
 Quit
}

ClassMethod defStorageSubSubMemberKill(%class, %ck, %m, %mk, %sm, %sk, %ssm)
{
 $$$defStorageSubSubMemberKill(%class,%ck,%m,%mk,%sm,%sk,%ssm)
 Quit
}

ClassMethod defStorageSubSubMemberKeyKill(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk)
{
 $$$defStorageSubSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
 Quit
}

ClassMethod defStorageSubSubSubMemberKill(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm)
{
 $$$defStorageSubSubSubMemberKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
 Quit
}

ClassMethod defStorageSubSubSubMemberKeyKil(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk)
{
 $$$defStorageSubSubSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
 Quit
}

ClassMethod defStorageSubMemberNext(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberNext(%class,%ck,%m,%mk,%sm)
}

ClassMethod defStorageSubMemberKeyNext(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$defStorageSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod defStorageSubSubMemberNext(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberNext(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod defStorageSubSubMemberKeyNext(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod defStorageSubSubSubMemberNext(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod defStorageSubSubSubMemberKeyNex(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$defStorageSubSubSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod defStorageSubMemberSet(%class, %ck, %m, %mk, %sm, %value)
{
 $$$defStorageSubMemberSet(%class,%ck,%m,%mk,%sm,%value)
 Quit
}

ClassMethod defStorageSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %value)
{
 $$$defStorageSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%value)
 Quit
}

ClassMethod defStorageSubSubMemberSet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %value)
{
 $$$defStorageSubSubMemberSet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%value)
 Quit
}

ClassMethod defStorageSubSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %value)
{
 $$$defStorageSubSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%value)
 Quit
}

ClassMethod defStorageSubSubSubMemberSet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %value)
{
 $$$defStorageSubSubSubMemberSet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%value)
 Quit
}

ClassMethod defStorageSubSubSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk, %value)
{
 $$$defStorageSubSubSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk,%value)
 Quit
}

ClassMethod comStorageSubMemberDefined(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberDefined(%class,%ck,%m,%mk,%sm)
}

ClassMethod comStorageSubMemberKeyDefined(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod comStorageSubSubMemberDefined(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod comStorageSubSubMemberKeyDefine(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod comStorageSubSubSubMemberDefine(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod comStorageSubSubSubMemberKeyDef(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberKeyDefined(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod comStorageSubMemberGet(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberGet(%class,%ck,%m,%mk,%sm)
}

ClassMethod comStorageSubSubMemberGet(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberGet(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod comStorageSubSubSubMemberGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod comStorageSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod comStorageSubSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod comStorageSubSubSubMemberKeyGet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberKeyGet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod comStorageSubMemberKill(%class, %ck, %m, %mk, %sm)
{
 $$$comStorageSubMemberKill(%class,%ck,%m,%mk,%sm)
 Quit
}

ClassMethod comStorageSubMemberKeyKill(%class, %ck, %m, %mk, %sm, %sk)
{
 $$$comStorageSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk)
 Quit
}

ClassMethod comStorageSubSubMemberKill(%class, %ck, %m, %mk, %sm, %sk, %ssm)
{
 $$$comStorageSubSubMemberKill(%class,%ck,%m,%mk,%sm,%sk,%ssm)
 Quit
}

ClassMethod comStorageSubSubMemberKeyKill(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk)
{
 $$$comStorageSubSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
 Quit
}

ClassMethod comStorageSubSubSubMemberKill(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm)
{
 $$$comStorageSubSubSubMemberKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
 Quit
}

ClassMethod comStorageSubSubSubMemberKeyKil(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk)
{
 $$$comStorageSubSubSubMemberKeyKill(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
 Quit
}

ClassMethod comStorageSubMemberNext(%class, %ck, %m, %mk, %sm) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberNext(%class,%ck,%m,%mk,%sm)
}

ClassMethod comStorageSubMemberKeyNext(%class, %ck, %m, %mk, %sm, %sk) As %String [ CodeMode = expression ]
{
$$$comStorageSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk)
}

ClassMethod comStorageSubSubMemberNext(%class, %ck, %m, %mk, %sm, %sk, %ssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberNext(%class,%ck,%m,%mk,%sm,%sk,%ssm)
}

ClassMethod comStorageSubSubMemberKeyNext(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk)
}

ClassMethod comStorageSubSubSubMemberNext(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm)
}

ClassMethod comStorageSubSubSubMemberKeyNex(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk) As %String [ CodeMode = expression ]
{
$$$comStorageSubSubSubMemberKeyNext(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk)
}

ClassMethod comStorageSubMemberSet(%class, %ck, %m, %mk, %sm, %value)
{
 $$$comStorageSubMemberSet(%class,%ck,%m,%mk,%sm,%value)
 Quit
}

ClassMethod comStorageSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %value)
{
 $$$comStorageSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%value)
 Quit
}

ClassMethod comStorageSubSubMemberSet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %value)
{
 $$$comStorageSubSubMemberSet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%value)
 Quit
}

ClassMethod comStorageSubSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %value)
{
 $$$comStorageSubSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%value)
 Quit
}

ClassMethod comStorageSubSubSubMemberSet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %value)
{
 $$$comStorageSubSubSubMemberSet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%value)
 Quit
}

ClassMethod comStorageSubSubSubMemberKeySet(%class, %ck, %m, %mk, %sm, %sk, %ssm, %ssk, %sssm, %sssk, %value)
{
 $$$comStorageSubSubSubMemberKeySet(%class,%ck,%m,%mk,%sm,%sk,%ssm,%ssk,%sssm,%sssk,%value)
 Quit
}

}
