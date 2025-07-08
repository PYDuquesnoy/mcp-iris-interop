/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.Classname Extends %DataType [ System = 2 ]
{

ClassMethod IsValid(%val As %RawString) As %Status
{
 If $length(%val)>220 Quit $$$ERROR($$$DatatypeValidationError,"%Dictionary.Classname",%val)
 Set v=1
 For i=1:1:$l(%val,".") Set p=$p(%val,".",i),v=$select(i=1:$zname(p),1:$extract(p)'="%"&$zname(p)) Quit:v=0
 Quit $select(v:$$$OK,1:$$$ERROR($$$DatatypeValidationError,"%Dictionary.Classname",%val))
}

}
