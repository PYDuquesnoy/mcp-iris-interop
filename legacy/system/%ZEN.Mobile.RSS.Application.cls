/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Mobile.RSS.Application Extends %Persistent [ Deprecated, System = 3 ]
{

Parameter DEFAULTGLOBAL = "^ZEN.Mobile.RSS.Application";

/// Together with the NameIndex, this property defines the primary key of this class
/// enabling reference by name
Property Name As %String(MAXLEN = 75);

Index NameIndex On Name [ IdKey ];

/// This contains a short description of the application
Property Description As %String(MAXLEN = 250) [ Required ];

/// The application manages a collection of Feeds
Relationship Feeds As Feed [ Cardinality = children, Inverse = Application ];

/// This retreives a subscription by URL
Method GetSubscription(pURL As %String) As Feed
{
    #dim tIndex As %Integer
    #dim tFeed As Feed = $$$NULLOREF
    For tIndex=1:1:..Feeds.Count() {
        Set tFeed=..Feeds.GetAt(tIndex) If tFeed.URL=pURL Quit
        Set tFeed=""
    }
    Quit tFeed
}

/// Check to see if the application is already subscribed
Method IsSubscribed(pURL As %String) As %Boolean [ CodeMode = expression ]
{
(..GetSubscription(pURL)'=$$$NULLOREF)
}

/// Subscribe to a feed. Feed URL is required, an optional tag can be added which can be used to categorize the feed
Method Subscribe(pURL As %String, pTag As %String = "", pTimeout As %Integer = -1, pHttpRequest As %Net.HttpRequest = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tApp As Application
    #dim tFeed As Feed
    Try {
        
        #; If we are not already subscribed
        If '..IsSubscribed(pURL) {
            
            #; Create a new instance of a feed
            Set tFeed=##class(%ZEN.Mobile.RSS.Feed).%New(pURL,pTag,pTimeout,pHttpRequest)
            If '$IsObject(tFeed) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%ZEN.Mobile.RSS.Feed")) Quit
           
            #; Add it to the feeds collection
            Set tSC=..Feeds.Insert(tFeed)
            If $$$ISERR(tSC) Quit
            
            #; Save it
            Set tSC=tFeed.%Save()
            If $$$ISERR(tSC) Quit
        }
      
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// UnSubscribe from a feed
Method UnSubscribe(pURL As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tIndex As %Integer
    #dim tFeed As Feed = $$$NULLOREF

    Try {
  
        For tIndex=1:1:..Feeds.Count() {
            Set tFeed=..Feeds.GetAt(tIndex) 
            If tFeed.URL=pURL {
                Do ..Feeds.RemoveAt(tIndex)
                Set tSC=..%Save()
                Quit
            }
        }
      
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Returns a list of subscriptions
Method ListSubscriptions(Output pURLs As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tFeed As Feed
    #dim tIndex As %Integer
    Try {
        
        #; Walk the existing Feeds and update their names
        For tIndex=1:1:..Feeds.Count() {
            Set pURLs($Increment(pURLs))=..Feeds.GetAt(tIndex).URL
        }
        
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Update One Subscription. Given a URL defining a feed, fetch the current items for the feed.
/// If the pPurgeCurrent flag is set to true, then the previously stored contents of the feed will be purged.
/// You can also pass an output parameter to receive the time taken to perform the operation, an output parameter
/// to receive the number of items updated. For advanced usages a timeout and pre-configured HttpRequest object can
/// be passed ( for example for https access, a HttpObject preconfigured with credentials is required )
Method UpdateOneSubscription(pURL As %String, pPurgeCurrent As %Boolean = 0, Output pTimeTaken, Output pItemsUpdated, pTimeout As %Integer = -1) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    #dim tZH As %String = $ZH
    #dim tFeed As %ZEN.Mobile.RSS.Feed
    Try {
        #; Initialize Items Update
        Set pItemsUpdated=0
        
        #; Ask it to refresh
        Set tFeed=..GetSubscription(pURL)
        If tFeed'="" {
            Set tSC=tFeed.Refresh(.pItemsUpdated,pPurgeCurrent)
        }
       
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Set pTimeTaken=$ZH-tZH
    Quit tSC
}

/// Update All Subscriptions. This method will update all the subscriptions owned by this application by fetching
/// the latest list of items and merging them into the database. If a timeout is supplied and exceeded the update
/// will not fail, but report a TimedOut via the pTimedOut parameter. The total number of items updated is reported by
/// the pItemsUpdated parameter
Method UpdateAllSubscriptions(Output pItemsUpdated As %Integer, Output pTimedOut As %Boolean = 0, pTimeout As %Integer = -1) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tSubNames,tKey,tName As %String
    #dim tTimeTaken,tTotalTimeTaken As %Double = 0
    #dim tItemsUpdated As %Integer
    Try {
        Set pItemsUpdated=0
        Set tSC=..ListSubscriptions(.tSubNames)
        If $$$ISERR(tSC) Quit
        
        Set tKey="" For {
            
            Set tKey=$Order(tSubNames(tKey),1,tName) If tKey="" Quit
            
            #; Don't purge during update
            Set tSC=..UpdateOneSubscription(tName,0,.tTimeTaken,.tItemsUpdated,pTimeout)
            If $$$ISERR(tSC) Quit
            
            #; Update the count
            Set pItemsUpdated=pItemsUpdated+tItemsUpdated
            
            If pTimeout'=-1 {
                Set tTotalTimeTaken=tTotalTimeTaken+tTimeTaken
                If tTotalTimeTaken>pTimeout {
                    Set pTimedOut=1
                    Quit
                }
            }
        }
        
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Assing the name and decription to the application
Method %OnNew(pName As %String = "", pDescription As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
    Set i%Name=pName,i%Description=pDescription
    Quit $$$OK
}

Storage Default
{
<Data name="ApplicationDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^ZEN.Mobile.RSS.ApplicationD</DataLocation>
<DefaultData>ApplicationDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ZEN.Mobile.RSS.ApplicationD</IdLocation>
<IndexLocation>^ZEN.Mobile.RSS.ApplicationI</IndexLocation>
<StreamLocation>^ZEN.Mobile.RSS.ApplicationS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
