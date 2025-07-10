/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsEDIXML, %xmlDOM)

Class EnsLib.EDI.XML.NamespaceHelper Extends %RegisteredObject [ System = 4 ]
{

Property Namespaces As %String [ MultiDimensional ];

Property NamespaceIdx As %String [ MultiDimensional ];

Property BackIdx As %String [ MultiDimensional ];

Property NsIdx As %Integer [ InitialExpression = 0 ];

Method addNamespace(pAttrName As %String, pValue As %String)
{
		if $D(..Namespaces(pAttrName)) {
			Set i=..BackIdx(pAttrName)
		} else {
			Set ..NsIdx=..NsIdx+1
			Set i=..NsIdx
		}
		Set ..NamespaceIdx(i)=pAttrName
		Set ..Namespaces(pAttrName)=pValue
		Set ..BackIdx(pAttrName)=i
}

Method getString(ByRef pPrefixes, pLimitByPrefixArray As %Boolean = 1)
{
	Set tNamespaces=""
	For i=1:1:..NsIdx {
		Set tAttrName= ..NamespaceIdx(i)
		Set setflag=1
		If ($find(tAttrName,":")&&(pLimitByPrefixArray&&'$D(pPrefixes($P(tAttrName,":",2))))) Set setflag=0
		Set:setflag tNamespaces=tNamespaces_" "_tAttrName_"="_..Namespaces(tAttrName)
	}
	quit tNamespaces
}

Method Copy(pNamespaceHelper As NamespaceHelper)
{
	for i=1:1:pNamespaceHelper.NsIdx {
		Set tAttrName= pNamespaceHelper.NamespaceIdx(i)
		do ..addNamespace(tAttrName,pNamespaceHelper.Namespaces(tAttrName))
	}
}

ClassMethod getPrefixes(pContentRef, pContentSubs, ByRef pPrefixes)
{
	if pContentSubs'="",pContentSubs'=-1,$$$xmlGetNodeType(pContentRef,pContentSubs)=$$$xmlELEMENTNODE {
		$$$xmlaGetChildList(pContentRef,pContentSubs,tChildList,tDescriptor)
	} else {
		Set tChildList=""
	}
	if (tChildList'="") {
		$$$xmlaForEachAttribute(pContentRef,tChildList,o,attribute)

			// look at attribute that is a namespace xmlns:prefix or xmnlns namespace declarer
			Set qName=$$$domGetAttributeQName(pContentRef,pContentSubs,attribute)
			if $find(qName,":") {
				Set prefix=$P(qName,":",1)
			} else {
				Set prefix=""
			}
			if (prefix="xmlns") {
				Set pPrefixes($P(qName,":",2))=""
			}	
		$$$xmlaEndForEachAttribute(pContentRef,tChildList,o,attribute)
	}
}

}
