/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Various class queries used by DeepSee utilities.
Class %DeepSee.ClassQueries Extends %RegisteredObject [ System = 4 ]
{

/// Returns a list of available DeepSee cubes.
/// The list contains the cube's logical name, (base) class name, and type.
Query EnumerateCubes() As %Query(ROWSPEC = "Name:%String,ClassName:%String,Type:%String")
{
}

ClassMethod EnumerateCubesExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = qHandle.%Execute("%DeepSee.CubeDefinition")
	Quit tSC
}

ClassMethod EnumerateCubesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	#; return only non-abstract classes
	Set done = 0
	While ('done) {
		If (qHandle.%Next()) {
			Set tClass = qHandle.Data("Name")

			#; only return compiled classes
			If ($$$comClassDefined(tClass)) {
				Set tAbstract = +$$$comClassKeyGet(tClass,$$$cCLASSabstract)
				If ('tAbstract) {
					Set tType = "cube"
					Set tCubeName = $zobjclassmethod(tClass,"%GetCubeName")
					Set Row = $LB(tCubeName,tClass,tType)
					Set AtEnd = 0
					Set done = 1
				}
			}
		}
		Else {
			Set Row = ""
			Set AtEnd = 1
			Set done = 1
		}
	}

	Quit $$$OK
}

ClassMethod EnumerateCubesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

}
