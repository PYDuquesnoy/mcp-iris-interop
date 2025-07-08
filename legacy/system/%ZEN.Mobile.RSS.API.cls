/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides the API for the RSS implementation
Class %ZEN.Mobile.RSS.API Extends %RegisteredObject [ Deprecated, System = 3 ]
{

/// Create an application, at minimum a name and description must be supplied
ClassMethod %CreateApplication(pName As %String, pDescription As %String, Output pApplication As Application) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    
    Try {
        #; No point attempting to create if already exists
        If ..%ExistsApplication(pName) {
            Set tSC=$$$ERROR($$$KeyNotUnique,pName) 
            Quit
        }
        Kill %objlasterror
        Set pApplication=##class(Application).%New(pName,pDescription)
        If '$IsObject(pApplication) {
            Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%ZEN.Mobile.RSS.Application")) 
            Quit
        }
        Set tSC=pApplication.%Save()
        
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Test a Feed, URL must be supplied. Optionally supplied a preconfigured HttpRequest. Returns True if an Accessible Feed,
/// Otherwise false. If false examine pStatus for an an explanation of why the feed is not accessible ( if you care )
ClassMethod %TestFeed(pURL As %String, Output pStatus As %Status, pTimeout As %Integer = -1, pHttpRequest As %Net.HttpRequest = "") As %Boolean
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    Try {
        
        Kill %objlasterror
        Set pFeed=##class(%ZEN.Mobile.RSS.Feed).%New(pURL,"SomeTag",pTimeout,pHttpRequest)
        If '$IsObject(pFeed) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%ZEN.Mobile.RSS.Feed")) Quit
        
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Set pStatus=tSC
    Quit '$$$ISERR(tSC)
}

/// Delete a named application
ClassMethod %DeleteApplication(pName As %String) As %Status [ CodeMode = expression ]
{
##class(Application).%DeleteId(pName)
}

/// Test for existence of a named application
ClassMethod %ExistsApplication(pName As %String) As %Boolean [ CodeMode = expression ]
{
##class(Application).%ExistsId(pName)
}

/// Returns a list of defined applications
ClassMethod %ListApplications(Output pNames As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    
    #dim tRS As %ResultSet
    Try {
        Set tRS=##class(%ResultSet).%New("%ZEN.Mobile.RSS.Application:Extent")
        Set tSC=tRS.Execute() If $$$ISERR(tSC) Quit
        While(tRS.Next()) {
             If $Increment(pNames) Set pNames(tRS.Data("ID"))=""
        }
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Open a named application
ClassMethod %OpenApplication(pName As %String, Output pObject As Application) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    Try {
        Kill %objlasterror
        Set pObject=##class(Application).%OpenId(pName)
        If '$IsObject(pObject) {
            Set tSC=$Get(%objlasterror,$$$ERROR($$$LoadObjectNotFound,"%ZEN.Mobile.RSS.Application",pName))
        }
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Exercise the API
ClassMethod %Exercise(pFeedURL As %String = "feed://www.npr.org/rss/rss.php?id=1001")
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tAppNames,tKey,tSubURLs As %String
    #dim tI,tItemsUpdated,tTimeTaken As %Integer
    #dim tApp As %ZEN.Mobile.RSS.Application
    #dim tFeed As %ZEN.Mobile.RSS.Feed
    #dim tItem As %ZEN.Mobile.RSS.Item
    
    Try {

        #; First Kill the extent of the Application
        Set tSC=##class(%ZEN.Mobile.RSS.Application).%DeleteExtent()
        If $$$ISERR(tSC) Quit
       
        #; Create an App
        Set tSC=##class(%ZEN.Mobile.RSS.API).%CreateApplication("MyApp","MyApp Description",.tApp)
        If $$$ISERR(tSC) Quit
        
        #; List It
        Set tSC=##class(%ZEN.Mobile.RSS.API).%ListApplications(.tAppNames)
        If $$$ISERR(tSC) Quit
        
        Write !
        
        #; Get the App's subscriptions
        Kill tSubURLs
        Set tSC=tApp.ListSubscriptions(.tSubURLs)
        If $$$ISERR(tSC) Quit
        
        #; Write them out
        If $Data(tSubURLs) {
            Write ! ZW tSubURLs Write !
        } else {
            Write !,"No Subscriptions",!
        }
        
        #; Subscribe to a Feed (National Public Radio - A worthy cause)
        Set tSC=tApp.Subscribe(pFeedURL,"NPR News")
        If $$$ISERR(tSC) Quit
        
        #; Get the App's subscriptions
        Kill tSubURLs
        Set tSC=tApp.ListSubscriptions(.tSubURLs)
        If $$$ISERR(tSC) Quit
        
        #; Write them out
        If $Data(tSubURLs) {
            Write ! ZW tSubURLs Write !
        } else {
            Write !,"No Subscriptions",!
        }
       
        #; Update the subscriptions
        Set tSC=tApp.UpdateAllSubscriptions(.tItemsUpdated)
        If $$$ISERR(tSC) Quit
        
        Write !,"Filed ",tItemsUpdated," items"
        
        #; Update one subscription without purge
        Set tSC=tApp.UpdateOneSubscription(pFeedURL,0,.tTimeTaken,.tItemsUpdated)
        If $$$ISERR(tSC) Quit
        
        Write !!,"Updated 1 Subscription without purge - took ",tTimeTaken," for ",tItemsUpdated," Items Updated"
             
        #; Update one subscription with purge
        Set tSC=tApp.UpdateOneSubscription(pFeedURL,1,.tTimeTaken,.tItemsUpdated)
        If $$$ISERR(tSC) Quit
        
        Write !!,"Updated 1 Subscription with purge - took ",tTimeTaken," for ",tItemsUpdated," Items Updated"
             
        Write !!,"Displaying 1 Subscription"
        
        Set tFeed=tApp.GetSubscription(pFeedURL)
        If $IsObject(tFeed) { 
            
            Write !!,tFeed.Title," ",tFeed.Link," ",tFeed.Description," ",tFeed.Tag
            
            Write !
            For tI=1:1:tFeed.Items.Count() {
                Set tItem=tFeed.Items.GetAt(tI)
                Write !,tItem.ChannelTitle," ",tItem.Title," ",tItem.Link,!
            }
        }
        
        Kill tFeed
       
        Set tSC=tApp.UnSubscribe(pFeedURL)
        If $$$ISERR(tSC) Quit
        
        #; Get the App's subscriptions
        Kill tSubURLs
        Set tSC=tApp.ListSubscriptions(.tSubURLs)
        If $$$ISERR(tSC) Quit
        
        #; Write them out
        If $Data(tSubURLs) {
            Write ! ZW tSubURLs Write !
        } else {
            Write !,"No Subscriptions",!
        }
      
        Quit
        
    } Catch(tE) {
        Set tSC=tE.AsStatus()
    }
    If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
    Quit
}

}
