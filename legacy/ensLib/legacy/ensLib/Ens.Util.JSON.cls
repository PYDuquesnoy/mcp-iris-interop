/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.JSON [ Abstract, System = 4 ]
{

/// This method calls the legacy <class>%ZEN.Auxiliary.jsonProvider</class>
/// method %ParseJSON. The JSON parsing correlates the first JSON string to
/// correlate to the object returned. It does require the stream to begin with either a
/// [ or {. It does not error if there is other text in the stream after the first identified JSON string.
/// It will return a null object and no error if the {} or [] cannot be parsed e.g. an = is used instead of a :
/// It also tolerates, for example, JSON properties that are not enclosed in double quotes.
ClassMethod JSONStreamToObject(pStream, Output pObject As %RegisteredObject, pClass As %String, pIgnoreUnknownProps As %Boolean) As %Status
{
	Set tSC=##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(pStream,.pClass,.pObject,,,,.pIgnoreUnknownProps)
	Quit:$$$IsdefObject(pObject) tSC
	Set:$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"No object found in JSON stream "_pStream.Read(200+pStream.Rewind()))
	Quit tSC
}

/// This method calls the legacy <class>%ZEN.Auxiliary.jsonProvider</class>
/// method %ParseJSON. The JSON parsing correlates the first JSON string to
/// the object returned. It does require the stream to begin with either a
/// [ or {. It does not error if there is other text in the stream after the first identified JSON string.
/// It will return a null object and no error if the {} or [] cannot be parsed e.g. an = is used instead of a :
/// It also tolerates, for example, JSON properties that are not enclosed in double quotes.
ClassMethod JSONStreamToObjectArray(pStream, Output pArray, pClass As %String, pIgnoreUnknownProps As %Boolean) As %Status
{
	Kill pArray
	Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(.pStream,.pClass,.tObjectList,,,,.pIgnoreUnknownProps)
	If $$$ISERR(tSC) Quit tSC
	Set pArray = tObjectList.Count()
	For i=1:1:pArray {
		Set pArray(i) = tObjectList.GetAt(i)
	}
	Quit tSC
}

/// This method calls the <class>%ZEN.Auxiliary.altJSONProvider</class>
/// method %ParseJSON. Notes include: this method assumes well-formed JSON notation for a single JSON string
/// representation and uses the system level dynamic objects parsing code. It also requires, for example, properties
/// to be enclosed in double quotes. 
/// It does not perform complete error checking.
ClassMethod altJSONStreamToObject(pStream, Output pObject As %RegisteredObject, pClass As %String, pIgnoreUnknownProps As %Boolean) As %Status
{
	Set tSC=##class(%ZEN.Auxiliary.altJSONProvider).%ParseJSON(pStream,.pClass,.pObject,,,,.pIgnoreUnknownProps)
	Quit:$$$IsdefObject(pObject) tSC
	Set:$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"No object found in JSON stream "_pStream.Read(200+pStream.Rewind()))
	Quit tSC
}

/// This method calls the <class>%ZEN.Auxiliary.altJSONProvider</class>
/// method %ParseJSON. Notes include: this method assumes well-formed JSON notation for a single JSON string
/// representation and uses the system level dynamic objects parsing code. It also requires, for example, properties
/// to be enclosed in double quotes. 
/// It does not perform complete error checking.
ClassMethod altJSONStreamToObjectArray(pStream, Output pArray, pClass As %String, pIgnoreUnknownProps As %Boolean) As %Status
{
	Kill pArray
	Set tSC = ##class(%ZEN.Auxiliary.altJSONProvider).%ParseJSON(.pStream,.pClass,.tObjectList,,,,.pIgnoreUnknownProps)
	If $$$ISERR(tSC) Quit tSC
	Set pArray = tObjectList.Count()
	For i=1:1:pArray {
		Set pArray(i) = tObjectList.GetAt(i)
	}
	Quit tSC
}

/// This method calls the legacy %ZEN.Auxiliary.jsonProvider::%WriteJSONStreamFromObject in order
/// to support formatting options such as "iw"
ClassMethod ObjectToJSONStream(pObject As %RegisteredObject, ByRef pStream, pFormat As %String = "iw") As %Status [ CodeMode = expression ]
{
##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.pStream,.pObject,,,,pFormat)
}

}
