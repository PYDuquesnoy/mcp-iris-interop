/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Notification by identity request
Class EnsLib.PushNotifications.NotificationInfo Extends %XML.Adaptor [ System = 4 ]
{

/// Collapse key (if supported)
Property CollapseKey As %String(MAXLEN = 512);

/// Timestamp that indicates when the notification expires.  If the notification is not delivered to the device by this time, the server will not send it to the device.
Property ExpiresUTC As %TimeStamp;

/// String that identifies a sound to be played on the device.
Property SoundNotification As %String(MAXLEN = 2048);

/// String to be displayed to the user as a notification.
Property AlertNotification As %String(MAXLEN = 2048);

/// Integer that is diplayed to the user in an icon.  For example, this can be used to indicate the number of unread messages.
Property BadgeNotification As %Integer;

/// String containing name-value pairs in JSON form.  Data contains the names and values that are used by the notification handling code in the mobile app.
Property Data As array Of %String;

/// Alert-URL notification
Property UrlNotification As %String(MAXLEN = 2048);

ClassMethod CopyFrom(pSrc As %RegisteredObject, pTarget As %RegisteredObject) As %Status [ CodeMode = generator ]
{
	#dim tProperty As %String
	#dim tRuntimeType As %String
	
    $$$GENERATE("   If '$IsObject($GET(pTarget)) || 'pTarget.%Extends("""_%class_""") {")
    $$$GENERATE("   	Quit $$$ERROR($$$ObjectInstanceRequired)")
    $$$GENERATE("   }")
    $$$GENERATE("   Set tType = pSrc.%ClassName(1)")
    
    Set tProperty = ""
    For {
        Set tProperty = $$$comMemberNext(%class,$$$cCLASSproperty,tProperty)
        Quit:tProperty=""
        
        Continue:+$$$comMemberKeyGet(%class,$$$cCLASSproperty,tProperty,$$$cPROPsqlcomputed)            
        Continue:+$$$comMemberKeyGet(%class,$$$cCLASSproperty,tProperty,$$$cPROPcalculated)             
        Continue:+$$$comMemberKeyGet(%class,$$$cCLASSproperty,tProperty,$$$cPROPreadonly)
                        
        $$$comMemberKeyGetLvar(tRuntimeType,%class,$$$cCLASSproperty,tProperty,$$$cPROPruntimetype)
        
        If ($$$getClassType(tRuntimeType)=$$$cCLASSCLASSTYPEDATATYPE) && ($E(tProperty,1)'="%") {
            // Copy this property (if it exists in the src object)
            $$$GENERATE("   Set:$$$comMemberDefined(tType,"""_$$$cCLASSproperty_""","""_tProperty_""") pTarget."_tProperty_" = pSrc."_tProperty)
        }
        ElseIf (tRuntimeType="%Collection.ListOfObj" && ($E(tProperty,1)'="%")) {
			$$$GENERATE("   If $$$comMemberDefined(tType,"""_$$$cCLASSproperty_""","""_tProperty_""")&&($c(0)'[pSrc."_tProperty_") { Do pTarget."_tProperty_".Clear() For tItem=1:1:pSrc."_tProperty_".Count() Do pTarget."_tProperty_".Insert(pSrc."_tProperty_".GetAt(tItem)) }")
        }
        ElseIf (tRuntimeType="%Collection.ArrayOfDT" && ($E(tProperty,1)'="%"))
        {
	        $$$GENERATE("   If $$$comMemberDefined(tType,"""_$$$cCLASSproperty_""","""_tProperty_""")&&($c(0)'[pSrc."_tProperty_") { Do pTarget."_tProperty_".Clear() Set tKey="""" For  { Do pSrc."_tProperty_".GetNext(.tKey) Quit:tKey=""""  Do pTarget."_tProperty_".SetAt(tKey, pSrc."_tProperty_".GetAt(tKey)) }}")
        }    
        /*      
        Else
        {       $$$GENERATE("   ; runtime type of "_tProperty_" is "_tRuntimeType_", class type of runtime type is "_$$$getClassType(tRuntimeType)) }
        */
        
    }
    
    $$$GENERATE("   Quit $$$OK")

    Quit $$$OK
}

}
