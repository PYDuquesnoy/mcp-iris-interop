/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Container class for MFT items
Class Ens.MFT.StreamContainer Extends Ens.StreamContainer [ System = 4 ]
{

Parameter XMLTYPE = "MFTMessage";

Parameter XMLNAME = "MFTMessage";

/// MFT Item Info
Property ItemInfo As %MFT.ItemInfo;

/// MFT Modified By Username
Property ModifiedByUsername As %String;

/*	Overriding properties to control XML projection order in message viewer */
Property OriginalFilename As %String(MAXLEN = "");

/// This property can be used to store a filename to be used on output<br>
/// Used for example in the EnsLib.MFT.Operation.Passthrough <br>
Property OutputFilename As %String(MAXLEN = "");

/// This property can be used to store a folder identifier to be used on output.<br>
/// Used for example in the EnsLib.MFT.Operation.Passthrough <br>
Property OutputFolder As %String(MAXLEN = "");

/// MFT file object 
Property Stream As %Stream.Object [ Calculated, Transient ];

Property DetailsObject As %DynamicObject(XMLPROJECTION = "NONE") [ Transient ];

Method DetailsObjectGet() As %DynamicObject
{
	#dim tDetailsObject = $$$NULLOREF

	Try {

		If $IsObject(..ItemInfo) && (..ItemInfo.Details '= "") {

			Set tDetailsObject = [].%FromJSON(..ItemInfo.Details)

		}

	} Catch {}

	Quit tDetailsObject
}

/// Clean up MFTItemInfo
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Try {
		#dim tMFTItemInfo = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"ItemInfo")
		If $IsObject(tMFTItemInfo),(tMFTItemInfo.%Id()'="") {
			#dim tMFTItemInfoId = tMFTItemInfo.%Id()
			#dim tMFTItemInfoClass = $classname(tMFTItemInfo)
			Set tMFTItemInfo = ""
			Do $CLASSMETHOD(tMFTItemInfoClass,"%DeleteId",tMFTItemInfoId)
		}
	} Catch {}
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID  Set %tID={%%ID}
	Try {
		#dim tMFTItemInfo = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"ItemInfo")
		If $IsObject(tMFTItemInfo),(tMFTItemInfo.%Id()'="") {
			#dim tMFTItemInfoId = tMFTItemInfo.%Id()
			#dim tMFTItemInfoClass = $classname(tMFTItemInfo)
			Set tMFTItemInfo = ""
			Do $CLASSMETHOD(tMFTItemInfoClass,"%DeleteId",tMFTItemInfoId)
		}
	} Catch {}

	Quit
}

Storage Default
{
<Data name="StreamContainerDefaultData1">
<Subscript>"StreamContainer"</Subscript>
<Value name="1">
<Value>ItemInfo</Value>
</Value>
<Value name="2">
<Value>ModifiedByUsername</Value>
</Value>
</Data>
<DefaultData>StreamContainerDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
