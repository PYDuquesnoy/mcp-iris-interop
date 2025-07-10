/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %systemInclude)

/// This class contains a number of utility methods used
/// by the DTL engine and editor.
Class Ens.DTL.Utils Extends %RegisteredObject [ ClassType = "", Owner = {_PUBLIC}, ProcedureBlock, System = 3 ]
{

/// Deprecated; use Ens.VDoc.Utils).EnumerateDocContents()
Query EnumerateDocContents(Class As %String, Mode As %String = "source", DocType As %String = "", Level As %Integer = 0) As %Query(CONTAINID = 0, ROWSPEC = "Property:%String:Specification of the path to a property in the object,Type:%String:Datatype of the property") [ SqlProc ]
{
}

/// Note: extra args to EnumerateDocContentsExecute because Studio seems to send them
ClassMethod EnumerateDocContentsExecute(ByRef qHandle As %Binary, Class As %String, Mode As %String, DocType As %String, Level As %Integer, p6, p7, p8, p9) As %Status [ CodeMode = expression ]
{
##class(Ens.VDoc.Utils).EnumerateDocContentsExecute(.qHandle,.Class,.Mode,.DocType,.Level)
}

ClassMethod EnumerateDocContentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocContentsExecute ]
{
##class(Ens.VDoc.Utils).EnumerateDocContentsFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod EnumerateDocContentsClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocContentsExecute ]
{
##class(Ens.VDoc.Utils).EnumerateDocContentsClose(.qHandle)
}

/// Deprecated; use Ens.VDoc.Utils).EnumerateDocTypes()
Query EnumerateDocTypes(Class As %String, Category As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Type:%String") [ SqlProc ]
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Class As %String, Category As %String = "") As %Status [ CodeMode = expression ]
{
##class(Ens.VDoc.Utils).EnumerateDocTypesExecute(.qHandle,.Class,.Category)
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocTypesExecute ]
{
##class(Ens.VDoc.Utils).EnumerateDocTypesFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocTypesExecute ]
{
##class(Ens.VDoc.Utils).EnumerateDocTypesClose(.qHandle)
}

}
