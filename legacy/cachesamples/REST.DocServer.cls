/// Provide a REST interface to the document server service
/// This UrlMap maps http requests to the classmethod to which it should be dispatched
/// 
/// Example usages. In these examples please replace the host name and port with appropriate
/// values for your situation.
/// <ol>
/// <li> Get the text of the class Samples/Sample.Person
/// </BR></BR>curl http://localhost:57772/csp/samples/docserver/class/samples/Sample.Person
/// </BR></BR></li>
/// <li>
/// Get a list of namespaces on the target server (plain/text)
/// </BR></BR>curl http://localhost:57772/csp/samples/docserver/namespaces
/// </BR></BR></li>
/// 
/// <li> Get a list of namespaces on the target server (jason format)
/// </BR></BR>curl -H "Accept:application/json" http://localhost:57772/csp/samples/docserver/namespaces
/// </BR></BR></li>
/// <li>
/// Display the contents of the http request ( shows how to manage cookies)
/// Set the UseSession Parameter to 1 to enable CSP SESSIONS
/// </BR></BR>curl -v -b cookie.txt -c cookie.txt http://localhost:57772/csp/samples/docserver/request
/// </BR></BR></li>
/// <li>
/// Echo the contents of a file sent to the server
/// </BR></BR>curl -v -X POST --data-binary @class.txt --header "Content-Type:text/plain" http://localhost:57772/csp/samples/docserver/echo 
/// </BR></BR></li>
/// <li>
/// Send the contents of a file representing the text of a class definition. Return a JSON encoded set of descriptors which define how the
/// text should be syntax colored.
/// </BR></BR>curl -v -X POST --data-binary @class.txt --header "Content-Type:text/plain" -H "Accept:application/json" http://localhost:57772/csp/samples/docserver/colorclass
/// </BR></BR></li>
/// <li>
/// Get a list of embedded languages for syntax coloring:
/// </BR></BR>curl -H "Accept:application/json" http://localhost:57772/csp/samples/docserver/languages
/// </BR></BR></li>
/// </ol>
Class REST.DocServer Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/class/:namespace/:classname" Method="GET" Call="GetClass"/>
<Route Url="/namespaces" Method="GET" Call="REST.DocServer:GetNamespaces"/>
<Route Url="/request" Method="GET" Call="Request"/>
<Route Url="/request" Method="POST" Call="Request"/>
<Route Url="/echo" Method="POST" Call="Echo"/>
<Route Url="/colorclass" Method="POST" Call="ColorClass"/>
<Route Url="/languages" Method="GET" Call="GetColorLanguages"/>
</Routes>
}

/// This method returns the class text for the named cache class
ClassMethod GetClass(pNamespace As %String, pClassname As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tStream As %Stream.Character
    
    Try {
        Set tSC=##class(%Compiler.UDL.TextServices).GetTextAsStream(pNamespace,pClassname,.tStream)
        If $$$ISERR(tSC) Quit
        
        #; Looks good
        Do tStream.OutputToDevice()
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// This method returns a list of namespaces for this server
ClassMethod GetNamespaces() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tList,tNS,tFilteredList,tValue As %String
    
    #; Get the list of namespaces
    Do List^%SYS.NAMESPACE(.tList)
    Set tNS="" For  {
    
        Set tNS=$Order(tList(tNS),1,tValue) If tNS="" Quit
    
        #; Only want namespaces which are enabled and are not remote
        If $List(tValue,1)=1&&$List(tValue,2)=0 {
            Set tFilteredList(tNS)=""
        }
    }
    
    #; If we have been asked for json
    If $Get(%request.CgiEnvs("HTTP_ACCEPT"))="application/json" {
        
        #; Set the response header to JSON
        Set %response.ContentType="application/json"
        
        #; Create a JSON proxy
        Set tProxy = ##class(%ZEN.proxyObject).%New()
        
        #; And a list to hold the namespaces
        Set tList=##class(%Library.ListOfDataTypes).%New()
        
        #; Add the namespaces to the list
        Set tNS="" For  {
            Set tNS=$Order(tFilteredList(tNS)) If tNS="" Quit
            Do tList.Insert(tNS)
        }
        
        #; Set the namespace property
        Set tProxy.namespaces=tList
        
        #; Output the JSON
        Do tProxy.%ToJSON()
        
    } else {
        
        Set tNS="" For  {
            Set tNS=$Order(tFilteredList(tNS)) If tNS="" Quit
            Write tNS,!
        }
    }
    Quit tSC
}

/// Return a dump of the request object
ClassMethod Request() As %Status
{
	Set %response.ContentType="text/plain"
	Do $System.OBJ.Dump(%request)
    Quit $$$OK
}

/// Return the posted data
ClassMethod Echo() As %Status
{
    Set %response.ContentType=%request.ContentType
    
    Quit %request.Content.OutputToDevice()
}

/// Given the source of a class as the request content (POST) return a representation of the
/// coloring for the class. If the client accepts json, then a json representation is returned as
/// an array. Each element of the array represents a line of source code. The element is itself an
/// array of coloring descriptors. Each descriptor is an object with containing the start (p)osition on
/// the line (zero based), the (c)ount of characters, the (l)anguage index and the (s)ymbol index. If
/// the client does not accept json then the tradicional CSV representation is returned.
/// 
/// Example:-
/// 
/// Input:
/// class ABC
/// {
///    Property XYZ;
/// }
/// 
/// Output:
/// [
///    [
///        {"p":0, "c":5, "l":3, "s":4},
///        {"p":5, "c":1, "l":3, "s":1},
///        {"p":6, "c":3, "l":3, "s":5}
///    ],
///    [
///        {"p":0, "c":1, "l":3, "s":8}
///    ],
///    [
///        {"p":0, "c":4, "l":3, "s":1},
///        {"p":4, "c":8, "l":3, "s":4},
///        {"p":12, "c":1, "l":3, "s":1},
///        {"p":13, "c":3, "l":3, "s":11},
///        {"p":16, "c":1, "l":3, "s":8}
///    ],
///    [
///        {"p":0, "c":1, "l":3, "s":8}
///    ]
/// ]
ClassMethod ColorClass() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tRet As %Boolean
    #dim tMode As %String
    #dim e As %Exception.AbstractException
    
    Try {
        
        Kill %objlasterror
        Set tSyntaxColor=##class(%SyntaxColor).%New()
        If '$IsObject(tSyntaxColor) {
            If $Data(%objlasterror) {
                Set tSC=%objlasterror
            } else {
                Set tSC=$$$ERROR($$$FailedToNewClass,"%SyntaxColor")
            }
        }
        If $$$ISERR(tSC) Quit
        
        Kill %objlasterror
        Set tStream=##Class(%Stream.TmpCharacter).%New()
        If '$IsObject(tStream) {
            If $Data(%objlasterror) {
                Set tSC=%objlasterror
            } else {
                Set tSC=$$$ERROR($$$FailedToNewClass,"%Stream.TmpCharacter")
            }
        }
        If $$$ISERR(tSC) Quit
        
        #; Invoke the colorizer according to format required
        If $Get(%request.CgiEnvs("HTTP_ACCEPT"))="application/json" {
            
            #; Set the response header to JSON
            Set %response.ContentType="application/json"
        
            Set tMode="KME"
        } else {
            
            Set tMode="ACME"
        }
            
        Set tRet=tSyntaxColor.Color(%request.Content,tStream,"CLS",tMode)
        If tRet=0 { 
            Set tSC=$$$ERROR($$$GeneralError,tSyntaxColor.DLLResultCode)
            Quit
        }

        #; Return the results
        Set tSC=tStream.OutputToDevice()
        
    } catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// This method is used to retrieve a list of languages
ClassMethod GetColorLanguages() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tLanguages As %String
    #dim tList As %Library.ListOfDataTypes
    #dim tI As %Integer
    
    Try {
        Kill %objlasterror
        Set tSyntaxColor=##class(%SyntaxColor).%New()
        If '$IsObject(tSyntaxColor) {
            
            If $Data(%objlasterror) {
                Set tSC=%objlasterror
            } else {
                Set tSC=$$$ERROR($$$FailedToNewClass,"%SyntaxColor")
            }
        }
        
        If $$$ISERR(tSC) Quit
        
        If tSyntaxColor.Languages(.tLanguages)'=1 ZT "ZF"
        
        #; If we have been asked for json
        If $Get(%request.CgiEnvs("HTTP_ACCEPT"))="application/json" {
            
            #; Set the response header to JSON
        	Set %response.ContentType="application/json"

            #; Create a JSON proxy
            Set tProxy = ##class(%ZEN.proxyObject).%New()
            
            #; And a list to hold the languages
            Set tList=##class(%Library.ListOfDataTypes).%New()
            
            #; Add the languages to the list
            For tI=1:1:$ListLength(tLanguages) {
             
                Set tLang=##class(%ZEN.proxyObject).%New()
                   
                Set tLang.Index = (tI-1)
                Set tLang.Name = ($List(tLanguages,tI))
                
                Do tList.Insert(tLang)
            }
            
            #; Set the languages property
            Set tProxy.languages=tList
            
            #; Output the JSON
            Do tProxy.%ToJSON()
            
        } else {
            For tI=1:1:$ListLength(tLanguages) Write !,tI," ",$List(tLanguages,tI)
        }
            
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

}

