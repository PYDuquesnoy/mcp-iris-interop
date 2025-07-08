/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

Class %Atelier.v1.Utils.General Extends %RegisteredObject [ Owner = {%Developer} ]
{

/// This method returns the path for the named CSP application
ClassMethod GetCSPAppPath(pName As %String, Output pPath) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    Try {
        &SQL(
            DECLARE AppCursor CURSOR FOR 
            SELECT path into :pPath FROM Security.Applications
            WHERE Name = :pName
            )
        &SQL(OPEN AppCursor)
        If SQLCODE<0 Set tSC=$$$ERROR($$$SQLError,SQLCODE,$g(%msg)) Quit
        &SQL(FETCH AppCursor)
        If SQLCODE<0 Set tSC=$$$ERROR($$$SQLError,SQLCODE,$g(%msg))
        &SQL(CLOSE AppCursor)
        If SQLCODE<0 Set tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This method parses a document header and extracts the name
ClassMethod GetNameFromDocArray(ByRef pTextArray, Output pName)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tKeywords,tName As %String
    Try {
        #; Delegate to GetMetaData API
        Set tSC=$$GetMetaDataFromDocArray^%apiSRC(.pTextArray,.tName,.tKeywords)
        If $$$ISERR(tSC) Quit
        
        #; Form the qualified name
        Set pName=tName_"."_tKeywords("type")
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This method returns a list of accessible namespaces
ClassMethod AccessibleNamespaces(Output pList As %String)
{
        #dim tList,tNS,tValue As %String
        
        #; Get the list of namespaces
        Kill pList
        Do List^%SYS.NAMESPACE(.tList,0)
        Set tNS="" For {

            Set tNS=$Order(tList(tNS),1,tValue) If tNS="" Quit

            #; Only want namespaces which are enabled (? means is remote and we don't know)
            If ($List(tValue)=1)||($List(tValue)="?") {
                Set pList(tNS)=""
            }
        }
}

/// This method takes a document name and computes a hash value
/// by applying the sha1 hash function to normalized source
ClassMethod GetDocHash(pName As %String, Output pHash As %String, Output pTextArray As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tI As %Integer
    
    Try {
        
        Set tSC=##class(%Atelier.v1.Utils.TextServices).GetTextAsArray(pName,0,.pTextArray)
        If $$$ISERR(tSC) Quit

        #; Normalize by adding delimiter
        For tI=1:1:pTextArray(0) Set pTextArray(tI)=pTextArray(tI)_$Char(10)
        
        #; Calculate the hash
        Set tSC=..CalcHash(.pTextArray,.pHash)

    } Catch(e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Given an array of normalized text lines, compute the textual hash value
ClassMethod CalcHash(ByRef pTextArray As %String, Output pHash) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tHash,tLines As %String
    #dim tI As %Integer
    Try {

        #; Clear sha1 accumulator
        If $System.Encryption.SHA1HashResult()

        #; For each line, add the lines hash to the accumulator
        For tI=1:1:pTextArray(0) Do $System.Encryption.SHA1HashInput(pTextArray(tI))

        #; Get the accumulated result and convert it to base64
        Set pHash=$System.Encryption.Base64Encode($System.Encryption.SHA1HashResult())

    } Catch(e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This method starts capturing the output from a program
ClassMethod BeginCaptureOutput(Output pCookie As %String) As %Status
{
    #dim tSC As %Status
    #dim e As %Exception.AbstractException
    
    Try {
        Set tSC=$$BeginCapture^%SYS.Capture(.pCookie)
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This method retrieves the captured output and delivers it as an array of lines
ClassMethod EndCaptureOutput(pCookie As %String, Output pText As %DynamicArray) As %Status
{
    #dim tSC As %Status
    #dim e As %Exception.AbstractException
    
    Try {
        Set tSC=$$EndCapture^%SYS.Capture(.pCookie,.pText)
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// <b>ValidateDocName</b> tests that a DocName has legal syntax
/// <p>
/// Returns a <class>%Boolean</class>:<ul>
/// <li>1 - If pDocName has legal DocName syntax
/// <li>0 - Otherwise</ul>
/// <p> 
/// Also returns the Category of the document and a Boolean of whether the
/// document needs to be transmitted as binary or not.
/// 
ClassMethod ValidateDocName(pDocName As %String, Output pStatus, Output pCategory As %String, Output pBinary As %Boolean) As %Boolean
{
        Quit $$ValidateDocName^%apiSRC(.pDocName,.pStatus,.pCategory,.pBinary)
}

/// Given a document name, return the category. The <class>%Status</class> value is from <method>ValidateDocName</method>.
ClassMethod GetDocCategory(pDocName As %String, Output pCategory As %String) As %Status
{
    #dim tSC As %Status
    Do ..ValidateDocName(pDocName,.tSC,.pCategory)
    Quit tSC
}

/// <b>NormalizeDocName</b> adds the default package name to .cls files.  It also
/// down cases the DocName type for class and routine types.
/// <p>
/// The pDocName is assumed to have been validated by ..<method>ValidateDocName</method>.
/// <p>
/// Returns the normalized DocName as a <class>%String</class>.
/// 
ClassMethod NormalizeDocName(pDocName As %String) As %String
{
        Quit $$NormalizeDocName^%apiSRC(.pDocName)
}

/// <b>ExistsDoc</b> checks that the item named by pDocName exists and returns
/// the appropriate <class>%Boolean</class> value.
/// 
ClassMethod ExistsDoc(pDocName As %String, Output pStatus) As %Boolean
{
    Quit $$ExistsDoc^%apiSRC(.pDocName,.pStatus)
}

/// <b>ValidType</b>(pType,pKeyword) checks that a Type attribute is valid.
/// If the type is valid then it is changed to upper case, inserted into the pKeywords
/// array (passsed by reference) and returned as the result of <b>ValidType</b>
/// <p>
/// If the type is invalid then <b>ValidType</b> returns "".
/// <p>
/// Note:  If the pKeywords array contains a conflicting Type value or
/// a conflicting LanguageMode value then the Type attribute is invalid.
/// 
ClassMethod ValidType(pType As %String, ByRef pKeywords As %String) As %String
{
        Quit $$ValidType^%apiSRC(.pType,.pKeywords)
}

/// <b>ValidLANG</b>(pMode,pKeyword) checks that a LanguageMode attribute
/// is valid.  If the mode is valid then it is inserted into the pKeywords
/// array (passed by reference) and returned as the result of <b>ValidLANG</b>
/// <p>
/// If the mode is invalid then <b>ValidLANG</b> returns "".
/// <p>
/// Note:  If the pKeywords array contains a conflicting Type value or
/// a conflicting LanguageMode value then the mode attribute is invalid.
/// 
ClassMethod ValidLANG(pMode As %String, ByRef pKeywords As %String) As %String
{
        Quit $$ValidLANG^%apiSRC(.pMode,.pKeywords)
}

/// This method wraps a client document with an XML wrapper which allows it to be imported into InterSystems IRIS
ClassMethod WrapRtnDocWithXML(pDocumentArray As %String, Output pWrappedDocument As %Stream) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tKeywords,tLine,tName,tValue As %String
    #dim tI,tJ As %Integer
    
    Try {
    
        #; First extract the metadata   
        Set tSC=$$GetMetaDataFromDocArray^%apiSRC(.pDocumentArray,.tName,.tKeywords)
        If $$$ISERR(tSC) Quit
        
        #; Only routine types can be wrapped in this manner
        If tKeywords("type")="CLS" Set tSC=$$$ERROR($$$GeneralError,"Document is not a Routine type") Quit
        
        #; Prepare the output stream
        Set pWrappedDocument=##class(%Stream.GlobalCharacter).%New()
        
        #; Initialize Stream as an  XML for a .mac, .inc, .int, .bas or .mvi
        Do pWrappedDocument.WriteLine("<?xml version=""1.0"" encoding=""UTF-8""?>")
        Do pWrappedDocument.WriteLine("<Export generator=""IRIS"" version="""_$$$CLASSDEFINITIONVERSION_""">")
        
        Set tLine="<Routine name="""_tName_""" type="""_tKeywords("type")_""""
        
        If $Data(tKeywords("LANG"),tValue) Set tLine=tLine_" languagemode="""_tValue_""""
        If $Data(tKeywords("GENERATED")) Set tLine=tLine_" generated=""1"""
        
        Do pWrappedDocument.WriteLine(tLine_"><![CDATA[")

        #; Write the contents of the array (after UDL ROUTINE header) to the stream
        #; Note, tKeywords("$ROUTINEline") is line number of UDL ROUTINE header
        For tJ=tKeywords("$ROUTINEline")+1:1:pDocumentArray(0) {
            Set tLine=pDocumentArray(tJ)
            For tI = $Length(tLine,"]]"_">"):-1:2 {
                Set tLine=$Piece(tLine,"]]"_">",1,tI-1)
                _"]]]]"_"><![CDATA[>"
                _$Piece(tLine,"]]"_">",tI,*)
            }
            Do pWrappedDocument.WriteLine(tLine)
        }
        
        Do pWrappedDocument.WriteLine("]]"_"></Routine>")
        Do pWrappedDocument.WriteLine("</Export>")
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Return a normalized timestamp for a document
ClassMethod TS(pDocName, ByRef pUpToDate) As %String
{
    #dim tTS As %String
    If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Do tmp.OnBeforeTimestamp(pDocName)
    Set tTS=##class(%RoutineMgr).TS(pDocName,,.pUpToDate)
    If tTS'="" {
        If tTS'["." Set tTS=tTS_"."
        Set $Piece(tTS,".",*)=$Extract($Piece(tTS,".",*)_"000",1,3)
    }
    Quit tTS
}

/// Given the name of a class, return the database to which it is mapped
ClassMethod GetDbForDoc(pDocName As %String, Output pDatabase) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim db,dblist,name,gblref,type As %String
    
    Try {
        
        Set name=$Piece(pDocName,".",1,*-1),type=$zcvt($Piece(pDocName,".",*),"l")
        
        If pDocName["/" {
            #; Special case for CSP (filesystem)
            Set pDatabase="@FS"
            Quit
            
        } elseif type="cls" {
            Set gblref=$name(^oddDEF(name))
        } elseif ((type="mac")||(type="int")||(type="inc")||(type="bas")||(type="mvb")||(type="mvi")||(type="py")) {
            Set gblref=$name(^rINDEX($ZCVT(name,"U")))
        } else {
            Set pDatabase="@OTHER"
            Quit
        }
        
        #; Get the database directory
        Set db=$$GetGlobalSourceDatabase^%SYS.SECURITY(gblref)
        
        #; Get the first name which maps to that directory
        If $$DatabasesByDirectory^%SYS.CONFIG($Piece(db,"^",2),$Piece(db,"^",3),.dblist)
        {
            Set pDatabase=$list(dblist,1)
        } else {
            Set pDatabase=""
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Given an array of hashes which represent databases, and using the database mappings for the
/// current namespace, return a list of documents of the requested type which have been modified
/// after the given hash was generated. The list is in the returned process private global.
ClassMethod GetModifiedDocuments(ByRef pHashes, pType As %String, ByRef pGbl As %String, pShowGenerated As %Boolean = 1) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
        
    #dim dbdata,dbdir,rtndirlist,clsdirlist,dirlist,dbname,hashnow,hashthen
    #dim classname,data,gen,lock,item,range,sts,showhidden,depl
    #dim docname,udocname,dbperm
    #dim SrchType,uType,rType,ClientId,EndId,rtypes
    
    New %name,%end
    
    Try {
        
        If pType'="*" {
            Set rType=pType ; return same as requested
            Set SrchType=$case($zcvt(pType,"U"),"CLS":1,"MAC":2,"INT":2,"INC":2,"BAS":2,"MVI":2,"PY":2,:0)
            If 'SrchType {
                Set tSC=$$$ERROR($$$UnknownRequestType,SrchType)
                Quit
            }
        }
    
        #; Reset
        Kill ^||ISC.ModDocs
        Set pGbl=$Name(^||ISC.ModDocs)
        Set tHide=(","_$Roles_",")'[",ISC_Internal,"
        
        #; Find the mappings for this namespace
        Do ..GetRoutineMappings(.rtndirlist)
        Do findmappings^%R($namespace,.clsdirlist,,1)
        
        #; Add an "everything" map for the default routine database
        #; since the routine mappings do not include the default
        Set dbdir="^"_##class(%SYS.Namespace).GetRoutineDest($namespace)
        If '$Data(rtndirlist(dbdir)) {
            Set rtndirlist(dbdir,"INT")=$ListBuild($ListBuild("""""",""))
            Set rtndirlist(dbdir,"INC")=rtndirlist(dbdir,"INT")
            Set rtndirlist(dbdir,"MAC")=rtndirlist(dbdir,"INT")
        }
        
        #; Merge the mappings
        Set dbdir=""
        For  Set dbdir=$Order(rtndirlist(dbdir)) Quit:dbdir=""  Merge dirlist(dbdir,"rtn")=rtndirlist(dbdir)
        For  Set dbdir=$Order(clsdirlist(dbdir),1,dbdata) Quit:dbdir=""  Set dirlist(dbdir,"cls")=dbdata
            
        #; For each db, search for modified documents
        Set dbdir="" For {
            
            Set dbdir=$order(dirlist(dbdir)) If dbdir="" Quit
            Set maphash=$Get(dirlist(dbdir,"cls"))_$Get(dirlist(dbdir,"rtn","MAC"))
            
            #; Get the dbname
            Set dbname=..GetDbNameFromDir(dbdir)
            
            #; Remember we have seen this database
            Set dbseen(dbname)=""
            
            #; Get the permissions for the database
            Set dbperm=$SYSTEM.Security.GetGlobalPermission(dbdir,$Name($$$DocJrnGblName),,0)
            
            #; Calculate the current hash for this database
            Try {
                
                #; Avoid <PROTECT> audit entry
                If dbperm'["READ" Goto nojrn
                
                Set hashnow=..Hash($lb($$$DocJrnGbl(dbdir)))_"="_..Hash(maphash)
            
                #; If the db appears in the list of passed hashes
                If $data(pHashes(dbname),hashthen) {
                    
                    #; If the hash is the same now as it was previously, nothing to do
                    If hashthen=hashnow Continue
                    If $Piece(hashthen,"=",2)'=$Piece(hashnow,"=",2) {
                        #; Difference is because of mapping change
                        #; Must return everything
                        Set hashthen=-1
                    }
                
                } Else {
                    Set hashthen=-1
                }
                
                #; Return the current hash
                Set pHashes(dbname)=hashnow
                
                #; And the database creation hash
                If $$$ISERR(..GetDbdirCrhash(dbdir,.data)) Set data=0
                Set pHashes(dbname,"crhash")=..Hash(data_maphash)
                
                #; Get last id reported to client
                Try {
                    #; We have seen Collation errors here
                    Set ClientId=$get($$$DocJrnGbl(dbdir)("hash",hashthen))
                } Catch {
                    Goto nojrn
                }
            
                #; If this hash has already been reported to any client, use it
                If '$data($$$DocJrnGbl(dbdir)("hash",hashnow),EndId) {
                    
                    #; Else start a new journal from this point
                    Try {
                        #; Avoid <PROTECT> audit entry
                        If dbperm'["WRITE" Goto noincr
                        
                        Set EndId=$increment($$$DocJrnGbl(dbdir)("id"))
                        Set $$$DocJrnGbl(dbdir)("id",EndId)=$h
                        Set $$$DocJrnGbl(dbdir)("hash",hashnow)=EndId
                    } Catch {
                        #; If we can't increment, try for existing value
noincr                  Try {
                            Set EndId=$get($$$DocJrnGbl(dbdir)("id"),ClientId+1)
                        } Catch {
                            #; No access at all, but keep going
                            Set EndId=ClientId+1
                        }
                    }
                }
                
            } Catch (e) {
                
                If $ZE'["<PROTECT" Throw e
nojrn
                #; Will have to use the index instead of the journal
                Set ClientId=""
                #; Request a calculated hash
                Set hashnow="",hashClass="",hashRtn=""
            }
            
            #; If we have a good client id, return documents modified
            #; since the last request
            If ClientId?1.N {
                Set uType=$Select(pType="*":"", 1:$zcvt(pType,"U"))
                While (ClientId < EndId) {
                    If pType="*" {
nexttype                Set uType=$O($$$DocJrnGbl(dbdir)("id",ClientId,uType))
                        If uType="" Goto nextid
                        Set SrchType=$case(uType,"CLS":1,"MAC":2,"INT":2,"INC":2,"BAS":2,"MVI":2,"PY":2,:0)
                        If 'SrchType Goto nexttype
                        Set rType=$zcvt(uType,"l") ; return lower case types
                    }
                    If SrchType=1 {
                        Set item=$Data(dirlist(dbdir,"cls"),dbdata)
                    } Else {
                        Set item=$Data(dirlist(dbdir,"rtn",$Case(uType,"MAC":uType,"INC":uType,:"INT")),dbdata)
                    }
                    If 'item {
                        #; No mapping for this type
                        If pType="*" Goto nexttype
                        Set ClientId=EndId ; terminate this loop
                        Continue
                    }
                    #; Because class (package) mappings are upper case only,
                    #; we have to look at every modified class and do the comparison
                    #; for any case. For routines we can limit the search to the
                    #; mapped ranges.
                    For item=1:1:$listlength(dbdata) {
                        Set range=$list(dbdata,item),%end=$list(range,2)
                        If %end'="" {
                            If $Extract(%end,*)=$Char(1) {
                                #; This is used for routine mappings
                                Set @("%end="_$Extract(%end,1,*-1)_"_$Char(1)")
                            } Else {
                                Set @("%end="_%end)
                            }
                        }
                        Set %name=$list(range)
                        If $Extract(%name,*)=$Char(1) {
                            Set @("%name="_$Extract(%name,1,*-1)_"_$Char(1)")
                        } Else {
                            Set @("%name="_%name)
                        }
                        If (SrchType=1) {
                            Set docname=""
                        } Else {
                            If %name'="",$data($$$DocJrnGbl(dbdir)("id",ClientId,uType,%name)) {
                                Set %name=$order($$$DocJrnGbl(dbdir)("id",ClientId,uType,%name),-1)
                            }
                            Set docname=%name
                        }
                        For {
                            Set docname=$O($$$DocJrnGbl(dbdir)("id",ClientId,uType,docname),1,data)
                            Quit:docname=""

                            If SrchType=1 {
                                #; Class
                                Set udocname=$Zcvt(docname,"U")
                                If %name]udocname Continue
                                If %end'="",%end']udocname Continue
                            
                                #; Don't show Hidden class
                                If +$listget(data,4),tHide Continue
                                
                                #; Get the generated flag
                                Set gen=+$listget(data,10)
                            
                                #; If the class is generated ignore
                                If 'pShowGenerated,gen=1 Continue
                                
                                #; Get the deployed flag
                                Set depl=+$listget(data,16)
                                
                                #; If the class is only a stub, ignore
                                If depl=2 Continue
                                
                                #; Get the server time stamp
                                Set sts=$select(data="":"",1:$listget(data,1,0))
                                
                            } Else {
                                #; Routine
                                If %end'="",%end']docname Quit
                                
                                #; Get the generated flag
                                Set gen=+$listget(data,3)
                                
                                #; If the routine is generated ignore
                                If 'pShowGenerated,gen=1 Continue
                                
                                #; Routines are not deployed
                                Set depl=0
                                
                                #; Get the server time stamp
                                Set sts=$select(data="":"",1:$listget(data,1,0))
                            }
                            
                            #; Add the name and ts to the master list (client format)
                            #; No ts means it was deleted
                            If sts'="" {
                                If (sts'[".") Set sts=sts_"."
                                Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                            }
                            
                            Set ^||ISC.ModDocs(dbname,rType,docname,"ts")=sts
                            Set ^||ISC.ModDocs(dbname,rType,docname,"gen")=gen
                            Set ^||ISC.ModDocs(dbname,rType,docname,"depl")=depl
                        }
                    }
                    If pType="*" Goto nexttype
nextid              Set ClientId=ClientId+1
                }
                
                Continue  ; with next db
            }
            
            #; No journal, so use the INDEX global(s) to return all documents.
            #; Note there is no issue with the case of class names here because
            #; both the mapping and the rINDEXCLASS are upper case only, but the
            #; class name in the index data has the user's case.
            
            If pType="*" || (SrchType=1) {
                Set tSC=..GetModifiedClassesIndex(.dirlist,dbdir,dbname,pShowGenerated,hashnow,.hashClass)
                If $$$ISERR(tSC) Quit
            }
            
            If pType="*" || (SrchType=2) {
                Set tSC=..GetModifiedRoutinesIndex(pType,.dirlist,dbdir,dbname,pShowGenerated,hashnow,.hashRtn)
                If $$$ISERR(tSC) Quit
            }
            
            If hashnow="" {
                Set hashnow=..Hash(hashClass_hashRtn)_"="_..Hash(maphash)
                
                #; If the db appears in the list of passed hashes
                #; And the hash is the same now as it was previously
                If $data(pHashes(dbname),hashthen) {
                    If hashthen=hashnow {
                        #; Then all the work was in vain
                        #; Don't return anything
                        Kill ^||ISC.ModDocs(dbname)
                        Continue
                    }
                }
                
                #; Return the current hash
                Set pHashes(dbname)=hashnow
                
                #; And the database creation hash
                If $$$ISERR(..GetDbdirCrhash(dbdir,.data)) Set data=0
                Set pHashes(dbname,"crhash")=..Hash(data_maphash)
            }
        }
        
        #; Did the client pass in a database which is no longer visible?
        #; If so, return it with a bum creation hash so the client will discard its cache.
        Set dbname=""
        For {
            Set dbname=$Order(pHashes(dbname)) Quit:dbname=""
            If '$Data(dbseen(dbname)) {
                Set pHashes(dbname)="000"
                Set pHashes(dbname,"crhash")="000"
            }
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

ClassMethod GetModifiedClassesIndex(ByRef dirlist, dbdir As %String, dbname As %String, pShowGenerated As %Boolean, hashIn As %String, ByRef hashOut As %String) As %Status [ Private ]
{
    #; This method adds classes that are mapped into 'dbdir' to the modified
    #; list in the temporary global.
    #;
    #; If the caller was unable to calculate a hash for this database, 'hashIn' will be
    #; passed as "" and this method will calculate a hash based on all observed classes.
    #; The calculated hash will be returned in 'hashOut'.
    
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    New %name,%end
            
    If '$Data(dirlist(dbdir,"cls"),dbdata) {
        #; No mapping for classes
        Set hashOut=hashIn
        Quit $$$OK
    }
    
    #; Check the permissions for the index global
    Set dbperm=$SYSTEM.Security.GetGlobalPermission(dbdir,"^rINDEXCLASS",,0)
    If dbperm'["READ" {
        #; Can do nothing
        Set hashOut=hashIn
        Quit $$$OK
    }
    
    If hashIn="" {
        #; Clear the accumulator
        Set hashOut=$System.Encryption.SHA1HashResult()
    }
    
    Set lock=$$ClassIndexLock^%SYS.cspServer2(dbdir)
    Set tHide=(","_$Roles_",")'[",ISC_Internal,"
    
    Try {
        For item=1:1:$listlength(dbdata) {
            
            Set range=$list(dbdata,item),%end=$list(range,2)
            If %end'="" Set @("%end="_%end)
        
            Set @("%name="_$list(range))
            If %name'="",$data(^|dbdir|rINDEXCLASS(%name)) Set %name=$order(^|dbdir|rINDEXCLASS(%name),-1)
            For {
                
                Set %name=$order(^|dbdir|rINDEXCLASS(%name),1,data) Quit:%name=""
                If %end'="",%end']%name Quit
                
                #; Get the actual class name
                Set classname=$list(data,2)
                
                #; Don't show Hidden class
                If +$listget(data,4),tHide Continue
                
                #; Get the generated flag
                Set gen=+$listget(data,10)
                
                #; If the class is generated ignore
                If 'pShowGenerated,gen=1 Continue
                
                #; Get the deployed flag
                Set depl=+$listget(data,16)
                
                #; If the class is only a stub, ignore
                If depl=2 Continue
                
                #; Get the server time stamp
                Set sts=$listget(data,1,0)
                
                #; Add the classname and ts to the master list (client format)
                If (sts'[".") Set sts=sts_"."
                Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                
                Set ^||ISC.ModDocs(dbname,"cls",classname,"ts")=sts
                Set ^||ISC.ModDocs(dbname,"cls",classname,"gen")=gen
                Set ^||ISC.ModDocs(dbname,"cls",classname,"depl")=depl
                
                #; Add timestamp to hash if necessary
                If hashIn="" Do $System.Encryption.SHA1HashInput(sts)
            }
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    If lock Set lock=$$ClassIndexLock^%SYS.cspServer2(dbdir,0)

    If hashIn="" {
        #; Return the accumulated hash
        Set hashOut=$System.Encryption.SHA1HashResult()
    }
    
    Quit tSC
}

ClassMethod GetModifiedRoutinesIndex(pType As %String, ByRef dirlist, dbdir As %String, dbname As %String, pShowGenerated As %Boolean, hashIn As %String, ByRef hashOut As %String) As %Status [ Private ]
{
    #; This method adds routines that are mapped into 'dbdir' to the modified
    #; list in the temporary global.
    #;
    #; If the caller was unable to calculate a hash for this database, 'hashIn' will
    #; passed as "" and this method will calculate a hash based on all observed routines.
    #; The calculated hash will be returned in 'hashOut'.
    
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #; Check the permissions for the index global
    Set dbperm=$SYSTEM.Security.GetGlobalPermission(dbdir,"^rINDEX",,0)
    If dbperm'["READ" {
        #; Can do nothing
        Set hashOut=hashIn
        Quit $$$OK
    }
    
    New %name,%end
    
    If hashIn="" {
        #; Clear the accumulator
        Set hashOut=$System.Encryption.SHA1HashResult()
    }

    Try {
        If pType="*" {
            For item="INT","INC","MAC","BAS","MVI","PY" Set rtypes(item)=""
        } Else {
            Set rtypes($zcvt(pType,"U"))=""
            Set rType=pType
        }
        Set uType=""
        For {
            Set uType=$Order(rtypes(uType)) Quit:uType=""
            If '$Data(dirlist(dbdir,"rtn",$Case(uType,"MAC":uType,"INC":uType,:"INT")),dbdata) {
                Continue
            }
            If pType="*" Set rType=$zcvt(uType,"l") ; return lower case types
            
            For item=1:1:$listlength(dbdata) {
                
                Set range=$list(dbdata,item),%end=$list(range,2)
                If %end'="" {
                    If $Extract(%end,*)=$Char(1) {
                        #; This is used for routine mappings
                        Set @("%end="_$Extract(%end,1,*-1)_"_$Char(1)")
                    } Else {
                        Set @("%end="_%end)
                    }
                }
                
                Set %name=$list(range)
                If $Extract(%name,*)=$Char(1) {
                    Set @("%name="_$Extract(%name,1,*-1)_"_$Char(1)")
                } Else {
                    Set @("%name="_%name)
                }
                If %name'="",$data(^|dbdir|rINDEX(%name)) Set %name=$order(^|dbdir|rINDEX(%name),-1)
                For {
                    
                    Set %name=$order(^|dbdir|rINDEX(%name)) Quit:%name=""
                    If %end'="",%end']%name Quit
                    
                    If $Data(^|dbdir|rINDEX(%name,uType),data) {
                    
                        #; Get the generated flag
                        Set gen=+$listget(data,3)
                        
                        #; If the routine is generated ignore
                        If 'pShowGenerated,gen=1 Continue
                        
                        #; Get the server time stamp
                        Set sts=$listget(data,1,0)
                        #; Client can't handle routines with no timestamp
                        If 'sts continue
                        
                        #; Add the routine name and ts to the master list (client format)
                        If (sts'[".") Set sts=sts_"."
                        Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                        
                        Set ^||ISC.ModDocs(dbname,rType,%name,"ts")=sts
                        Set ^||ISC.ModDocs(dbname,rType,%name,"gen")=gen
                        Set ^||ISC.ModDocs(dbname,rType,%name,"depl")=0
                
                        #; Add timestamp to hash if necessary
                        If hashIn="" Do $System.Encryption.SHA1HashInput(sts)
                    }
                }
            }
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    If hashIn="" {
        #; Return the accumulated hash
        Set hashOut=$System.Encryption.SHA1HashResult()
    }
    
    Quit tSC
}

/// Given a database name and a hash value, return a list of documents of the requested type which have been modified
/// after the given hash was generated. The current hash value will be returned in the pHash argument.
ClassMethod GetModifiedDocumentsDB(pDatabase As %String, ByRef pHash As %String, pType As %String, Output pDocs As %String, pShowGenerated As %Boolean = 1) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
        
    #dim uType,rType,SrchType As %String
    #dim dbobj As Config.Databases
    #dim dbdir,hashnow,ClientId,EndId,data,gen,sts,depl As %String
    #dim classname As %String
    #dim lock As %Integer
    
    New %name
    Set tHide=(","_$Roles_",")'[",ISC_Internal,"
    
    Try {
        
        Set dbdir=$$DatabaseByName^%SYS.CONFIG(pDatabase)
        If dbdir="" Set tSC=$$$ERROR($$$DatabaseNotThere) Quit
        If pType'="*" {
            Set rType=pType ; return same as requested
            Set SrchType=$case($zcvt(pType,"U"),"CLS":1,"MAC":2,"INT":2,"INC":2,"BAS":2,"MVI":2,"PY":2,:0)
            If 'SrchType {
                Set tSC=$$$ERROR($$$UnknownRequestType,SrchType)
                Quit
            }
        }
    
        #; Reset
        Kill pDocs
        
        #; Calculate the current hash for this database
        Try {
            Set hashnow=..Hash($lb($$$DocJrnGbl(dbdir)))
        } Catch (e) {
            Throw e
        }
        
        #; If the hash is the same now as it was previously
        #; quit with an empty list
        If pHash=hashnow Quit
        
        #; Get last id reported to client
        Try {
            Set ClientId=$select(pHash="":"",1:$get($$$DocJrnGbl(dbdir)("hash",pHash)))
        } Catch {
            #; Won't get far if we can't read it, but try to continue
            Set ClientId=""
        }
        
        #; Return the current hash
        Set pHash=hashnow
        
        #; If this hash has already been reported to any client, use it
        If '$data($$$DocJrnGbl(dbdir)("hash",hashnow),EndId) {
            
            #; Else start a new journal from this point
            Try {
                Set EndId=$increment($$$DocJrnGbl(dbdir)("id"))
                Set $$$DocJrnGbl(dbdir)("id",EndId)=$h
                Set $$$DocJrnGbl(dbdir)("hash",hashnow)=EndId
            } Catch {
                #; If we can't increment, try for existing value
                Try {
                    Set EndId=$get($$$DocJrnGbl(dbdir)("id"),ClientId+1)
                } Catch {
                    #; No access at all, but keep going
                    Set EndId=ClientId+1
                }
            }
        }
        
        #; If we have a good client id, return documents modified
        #; since the last request
        If ClientId?1.N {
            Set uType=$Select(pType="*":"", 1:$zcvt(pType,"U"))
            While (ClientId < EndId) {
                If pType="*" {
nexttype            Set uType=$O($$$DocJrnGbl(dbdir)("id",ClientId,uType))
                    If uType="" Goto nextid
                    Set SrchType=$case(uType,"CLS":1,"MAC":2,"INT":2,"INC":2,"BAS":2,"MVI":2,"PY":2,:0)
                    If 'SrchType Goto nexttype
                    Set rType=$zcvt(uType,"l") ; return lower case types
                }
                Set %name="" For {
                    Set %name=$O($$$DocJrnGbl(dbdir)("id",ClientId,uType,%name),1,data)
                    Quit:%name=""

                    If SrchType=1 {
                        #; Class
                        
                        #; Don't show Hidden class
                        If +$listget(data,4),tHide Continue
                    
                        #; Get the generated flag
                        Set gen=+$listget(data,10)
                    
                        #; If the class is generated ignore
                        If 'pShowGenerated,gen=1 Continue
                        
                        #; Get the deployed flag
                        Set depl=+$listget(data,16)
                        
                        #; If the class is only a stub, ignore
                        If depl=2 Continue
                        
                        #; Get the server time stamp
                        Set sts=$select(data="":"",1:$listget(data,1,0))
                        
                    } Else {
                        #; Routine
                        
                        #; Get the generated flag
                        Set gen=+$listget(data,3)
                        
                        #; If the routine is generated ignore
                        If 'pShowGenerated,gen=1 Continue
                        
                        #; Routines are not deployed
                        Set depl=0
                        
                        #; Get the server time stamp
                        Set sts=$select(data="":"",1:$listget(data,1,0))
                    }
                    
                    #; Add the name and ts to the master list (client format)
                    #; No ts means it was deleted
                    If sts'="" {
                        If (sts'[".") Set sts=sts_"."
                        Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                    }
                    
                    Set pDocs(rType,%name,"ts")=sts
                    Set pDocs(rType,%name,"gen")=gen
                    Set pDocs(rType,%name,"depl")=depl
                }
                If pType="*" Goto nexttype
nextid          Set ClientId=ClientId+1
            }
            Quit
        }
        
        #; No journal, so use the INDEX global(s) to return all documents
        
        If pType="*" Set SrchType=1
        
        Try {
            If SrchType=1 {
                #; Do classes
                Set lock=$$ClassIndexLock^%SYS.cspServer2(dbdir)
                If pType="*" Set rType="cls"
                Set %name=""
                For {
                    
                    Set %name=$order(^|dbdir|rINDEXCLASS(%name),1,data) Quit:%name=""
                    
                    #; Get the actual class name
                    Set classname=$list(data,2)
                    
                    #; Don't show Hidden class
                    If +$listget(data,4),tHide Continue
                    
                    #; Get the generated flag
                    Set gen=+$listget(data,10)
                    
                    #; If the class is generated ignore
                    If 'pShowGenerated,gen=1 Continue
                    
                    #; Get the deployed flag
                    Set depl=+$listget(data,16)
                    
                    #; If the class is only a stub, ignore
                    If depl=2 Continue
                    
                    #; Get the server time stamp
                    Set sts=$listget(data,1,0)
                    
                    #; Add the classname and ts to the master list (client format)
                    If (sts'[".") Set sts=sts_"."
                    Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                    
                    Set pDocs(rType,classname,"ts")=sts
                    Set pDocs(rType,classname,"gen")=gen
                    Set pDocs(rType,classname,"depl")=depl
                }
            }
            
            If (pType="*") || (SrchType=2) {
                #; Do routines
                If (pType'="*") Set uType=$zcvt(pType,"U")
                Set %name=""
                For {
                    Set %name=$order(^|dbdir|rINDEX(%name)) Quit:%name=""
                    
                    If (pType="*") {
                        Set uType=""
                        For {
                            Set uType=$order(^|dbdir|rINDEX(%name,uType),1,data) Quit:uType=""
                            If uType="OBJ" Continue
                            
                            #; Get the generated flag
                            Set gen=+$listget(data,3)
                            
                            #; If the routine is generated ignore
                            If 'pShowGenerated,gen=1 Continue
                            
                            #; Get the server time stamp
                            Set sts=$listget(data,1,0)
                            #; Client can't handle routines with no timestamp
                            If 'sts continue
                            
                            #; Add the routine name and ts to the master list (client format)
                            If (sts'[".") Set sts=sts_"."
                            Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                            
                            Set pDocs($zcvt(uType,"l"),%name,"ts")=sts
                            Set pDocs($zcvt(uType,"l"),%name,"gen")=gen
                            Set pDocs($zcvt(uType,"l"),%name,"depl")=0
                        }
                        Continue  ; next %name
                    }
                    If '$data(^|dbdir|rINDEX(%name,uType),data) Continue
                    
                    #; Get the generated flag
                    Set gen=+$listget(data,3)
                    
                    #; If the routine is generated ignore
                    If 'pShowGenerated,gen=1 Continue
                    
                    #; Get the server time stamp
                    Set sts=$listget(data,1,0)
                    #; Client can't handle routines with no timestamp
                    If 'sts continue
                    
                    #; Add the routine name and ts to the master list (client format)
                    If (sts'[".") Set sts=sts_"."
                    Set $Piece(sts,".",*)=$Extract($Piece(sts,".",*)_"000",1,3)
                    
                    Set pDocs(rType,%name,"ts")=sts
                    Set pDocs(rType,%name,"gen")=gen
                    Set pDocs(rType,%name,"depl")=0
                }
            }
        } Catch (e) {
            Set tSC=e.AsStatus()
        }
        
        If SrchType=1,lock Set lock=$$ClassIndexLock^%SYS.cspServer2(dbdir,0)
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

ClassMethod GetDbNameFromDir(pDir As %String) As %String
{
    #dim db,dblist As %String
    
    #; Get the first name which maps to that directory
    If $$DatabasesByDirectory^%SYS.CONFIG($Piece(pDir,"^",2),$Piece(pDir,"^",3),.dblist)
    {
        Set db=$list(dblist,1)
    } else {
        Set db=""
    }
    
    Quit db
}

/// Create a document object
ClassMethod CreateDocumentObject(Output pDocObject As %DynamicObject, ByRef pDocArray, pName As %String, pDocStatus As %Status, pTimeStamp As %String, pUpToDate As %Boolean) As %Status
{
    #dim tCount,tI As %Integer
    #dim tDatabase As %String
    #dim tContent As %DynamicArray
    #dim tDocument As %DynamicObject
    #dim tUtf8,tData As %String
    
    #dim tType,tCat As %String
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {

        Set tDocument = {}

        #; fill in the document name
        Set tDocument.name=pName
        
        #; This type->cat comes from ValidateDocName()
        #; We assume the name has been validated
        Set tType=$Zcvt($Piece(pName,".",*),"U")
        If pName["/" {
            Set tCat="CSP"
        } ElseIf tType="CLS" {
            Set tCat="CLS"
        } ElseIf ",MAC,INT,INC,BAS,MVB,MVI,PY,"[(","_tType_",") {
            Set tCat="RTN"
        } Else {
            Set tCat="OTH"
        }
        
        If $$$ISOK(pDocStatus) {
    
            #; Get the database
            Set tDatabase=""
            Set tSC=##class(%Atelier.v1.Utils.General).GetDbForDoc(pName,.tDatabase)
            If $$$ISERR(tSC) Quit
                
            Set tDocument.db=tDatabase
            Set tDocument.ts=pTimeStamp
            If $Data(pUpToDate) Do tDocument.%Set("upd",+pUpToDate,"boolean")
            Set tDocument.cat=tCat
            Set tDocument.status=""
            
            #; Finally the content
            If $Get(pDocArray("bin")) {
                Do tDocument.%Set("enc",1,"boolean")
            } Else {
                Do tDocument.%Set("enc",0,"boolean")
            }
            
            Set tDocument.flags=+$Get(pDocArray("flags"))
            
            Set tContent = []
            For tI=1:1:+$Get(pDocArray(0)) {
                Do tContent.%Push(pDocArray(tI))
            }
            Set tDocument.content=tContent
                            
        } else {
            
            Set tDocument.db="",tDocument.ts="",tDocument.cat=tCat
            Do tDocument.%Set("enc",0,"boolean") Set tDocument.content=""
            
            #; And error
            Set tDocument.status=$System.Status.GetErrorText(pDocStatus)
        }
        
        Set pDocObject=tDocument    

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Create a document collection object from an array of document objects
ClassMethod CreateDocumentCollection(ByRef pArray) As %Atelier.v1.Utils.LazyCollection
{
    Quit ##class(%Atelier.v1.Utils.LazyCollection).%New(.pArray)
}

/// Output a message array
ClassMethod WriteMsg(ByRef pMsgArray As %String)
{
    #dim tI As %Integer
    #dim tS As %String
    Set tI=0 For {
        Set tI=$Order(pMsgArray(tI),1,tS) If tI="" Quit
        Write tS,!
    }
}

/// Compute a hash value but replace potentially problematic characters
ClassMethod Hash(pValue As %String) As %String [ CodeMode = expression ]
{
$translate($system.Encryption.Base64Encode($system.Encryption.SHA1Hash(pValue)),"/+=","_-")
}

/// Encode a stream as BASE64
ClassMethod Base64FromStream(pStream As %Stream, Output pEncoded As %Stream) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tLen As %Integer

    Try {
    
        Set tSC=pStream.Rewind()
        If $$$ISERR(tSC) Quit

        Set pEncoded=##class(%Stream.TmpCharacter).%New()
        set tLen=5700
        while 'pStream.AtEnd {
            Set tSC=pEncoded.Write($system.Encryption.Base64Encode(pStream.Read(.tLen)))
            If $$$ISERR(tSC) Quit
            Set tLen=5700
        }
        If $$$ISERR(tSC) Quit
        
        Set tSC=pEncoded.Rewind()
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Return list of databases where the routines for a namespace are mapped.
/// It does not include the default database.
ClassMethod NamespaceDbList(pNamespace As %String, Output pDB As %String) As %Status
{
    #dim dirlist,dbdir,dbname,hash as %String
    #dim tSC As %Status = $$$OK
    
    Kill pDB
    
    #; Find the Routine mappings for this namespace
    Do findmappings^%R(pNamespace,.dirlist)
    
    Set dbdir=""
    For {
        Set dbdir=$Order(dirlist(dbdir)) Quit:dbdir=""
        Set dbname=..GetDbNameFromDir(dbdir)
        Set tSC=..GetDbdirCrhash(dbdir,.hash)
        If $$$ISERR(tSC) Set hash=0
        Set pDB(dbname,"crhash")=hash
    }
    
    Quit $$$OK
}

/// Given the database directory definition, get the creation time hash value
ClassMethod GetDbdirCrhash(pDbdir As %String, Output pHash As %String) As %Status
{
    #dim info,hash as %String
    #dim sfn
    #dim e As %Exception.AbstractException
    #dim tSC As %Status = $$$OK
    
    Try {
        Set pHash=0
        If $Extract(pDbdir,1,2)="^^" {
            #; Local db
            Set info=$ZU(49,$E(pDbdir,3,*),6)
            If info>=0 Set pHash=$Extract($Zhex(+$P(info,",",2)),*-7,*)_$Extract($Zhex(+$P(info,",",3)),*-7,*)
        } Else {
            #; Remote db
            Set sfn=$ZU(49,$Piece(pDbdir,"^",2),$Piece(pDbdir,"^",3),7)
            If sfn>0 {
                Open 63:"#"_sfn
                View 2
                Set pHash=$Extract($Zhex($View($ZU(40,0,50),0,4)),*-7,*)_$Extract($Zhex($View($ZU(40,0,49),0,4)),*-7,*)
                Close 63
            }
        }
    } Catch (e) {
        Set tSC=e.AsStatus()
        Close 63
    }
    Quit tSC
}

ClassMethod Compile(ByRef pItemArray As %String, pFlags As %String, pGetSource As %Boolean = 1, Output pResult As %DynamicObject) As %Status
{
    #dim tResultContent,tContent As %DynamicArray
    #dim tObject As %DynamicObject
    #dim tSC As %Status
    #dim e As %Exception.AbstractException
    #dim class,tTS1,tTS2,tDB,tUpdated,tTextArray,tI
    
    Set tResultContent = []

    #; Perform the compilation (and capture output)
    Try {
        
        Kill %SourceControl
            
        #; Create the source control class
        Set tSC=##class(%Api.Atelier.v1).CreateSourceControlClass()
        If $$$ISERR(tSC) Quit
        
        Set tSC=$SYSTEM.OBJ.CompileList(.pItemArray,pFlags,,.tUpdated)
        
        #; If classes were updated, return the updated Storage
        If $data(tUpdated) {
            Set class=""
            For {
                Set class=$O(tUpdated(class),1,tTS1) Quit:class=""
                Kill tTextArray

                Set tObject = {}
                Set tObject.name=class
                Set tObject.status=""
                Set tObject.content=""
                Set tDB="" Do ##class(%Atelier.v1.Utils.General).GetDbForDoc(class,.tDB)
                Set tObject.db=tDB
                
                #; The timestamp in the list is raw ($ZU(188))
                If tTS1'="" Try { Set tTS1=$$$TimeToODBC(tTS1) } Catch { Set tTS1="" }
                #; Normalize it to Atelier-style
                If tTS1'="" {
                    If tTS1'["." Set tTS1=tTS1_"."
                    Set $Piece(tTS1,".",*)=$Extract($Piece(tTS1,".",*)_"000",1,3)
                }
                Set tObject.ts=tTS1
                
                #; Return the modified source if requested
                If 'pGetSource Goto pushobj
                
                #; Lock the item
                Set tSC=##class(%RoutineMgr).LockItem(class)
                If $$$ISERR(tSC) {
                    #; Must check for actually being locked
                    If $Piece($System.Status.GetErrorCodes(tSC),",")=5864 {
                        Set tObject.status="locked"
                    } Else {
                        Set tObject.status=$System.Status.GetErrorText(tSC)
                    }
                    Set tSC=$$$OK

                } Else {
                    
                    #; Check that the timestamp hasn't changed
                    Set tTS2=##class(%Atelier.v1.Utils.General).TS(class)
                    If tTS1=tTS2 {
                        #; Get only the Storage section of the class
                        Set tSC=##class(%Atelier.v1.Utils.TextServices).GetTextAsArray(class,8,.tTextArray)
                        If $$$ISERR(tSC) {
                            Set tObject.status=$System.Status.GetErrorText(tSC)
                            Set tSC=$$$OK
                        } Else {
                            Do tObject.%Set("enc",0,"boolean")
                            Set tContent = []
                            For tI=1:1:+$Get(tTextArray(0)) {
                                Do tContent.%Push(tTextArray(tI))
                            }
                            Set tObject.content=tContent
                            Set tObject.flags=1 ; content is Storage only
                        }
                    } Else {
                        Set tObject.status="changed"
                        Set tObject.ts=tTS2
                    }
                    
                    #; Unlock it
                    Do ##class(%RoutineMgr).LockItem(class,0)
                }
pushobj
                Do tResultContent.%Push(tObject)
                Set tObject=""
            }
        }

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Set pResult = { "content":(tResultContent) }
    Quit tSC
}

/// For use via the Query API (/:namespace/action/query):
/// Returns a token for use in CSPCHD in a URL
/// May validate and extend an existing token (pToken)
ClassMethod GetCSPToken(pPage As %String, pToken As %String = "") As %String [ SqlProc ]
{
    #define SessionIdFromToken(%token) $Extract(%token,13,22)
    #dim tSessionId,tToken,AppData As %String
    #dim tSession As %CSP.Session
    
    Set (tToken,tSession) = ""
    
    // If a prior token was passed in, validate/extend it
    If (pToken '= "") {
        Set tSessionId = $$$SessionIdFromToken(pToken)
        Set tSession = ##class(%CSP.Session).%OpenId(tSessionId)
        If $IsObject(tSession) {
            Set tToken = tSession.CSPSessionCookie
        }
    }
    
    // If we don't have a token, create one.
    If (tToken = "") {
        Set tToken = ##class(%Studio.General).ConstructCSPSession(pPage)
        
        //ConstructCSPSession takes a lock on ^%StudioTemplate(sessionId); this doesn't make sense for stateless REST APIs, so release it:
        Set tSessionId = $$$SessionIdFromToken(tToken)
        Lock:tSessionId'="" -^%StudioTemplate(tSessionId)
        
        Set tSession = ##class(%CSP.Session).%OpenId(tSessionId)
    }
    
    // The session created by ConstructCSPSession has a few oddities that don't work so well in the Atelier context:
    // First, its Session Events class is intended to prevent the session from ending until the Studio session ends. This must be cleared.
    // Second, it has a short timeout (90 seconds). Since the session may end, this should be longer (say, the default instead).
    If $IsObject(tSession) {
        Set tSession.EventClass = "", tSession.AppTimeout = $$$CSPdefaulttimeout
        Do tSession.Unlock() // Also saves the session.
    }
    
    Quit tToken
}

/// Get the routine mappings and break them out into
/// lists for each routine type
ClassMethod GetRoutineMappings(Output rtndir) As %Status
{
    #dim rtn,dbdir,dbdata,range,name,end
    #dim type,next
    #dim intlist,inclist,maclist
    #dim i,int,inc,mac
    
    do findmappings^%R($namespace,.rtn,,0)
    s dbdir=""
    for {
        s dbdir=$O(rtn(dbdir),1,dbdata) q:dbdir=""
        Set (intlist,maclist,inclist)=""
        f i=1:1:$LL(dbdata) {
            Set range=$list(dbdata,i)
            set name=$list(range,1),end=$list(range,2)
            If $Length(name,",")=1 {
                If $Length(end,",")=1 {
                    #; Assume it applies to all types
                    Set (int,mac,inc)=1
                    Set next=$ListGet(dbdata,i+1)
                    If next'="" {
                        Set nextname=$list(next,1),nextend=$list(next,2)
                        If nextname=end,$Length(nextend,",")=2 {
                            #; There are type exceptions, which
                            #; may be inclusions (which are redundant)
                            #; or exclusions
                            Set type=$Piece(nextend,",",2)
                            Set i=i+1,next=$ListGet(dbdata,i+1)
                            while next'="" {  ; should be always true
                                If $list(next,1)=(nextend_$C(1)) {
                                    #; is an exclusion
                                    If type="""ROUTINE""" { Set int=0 }
                                    ElseIf type="""rMAC""" { Set mac=0 }
                                    ElseIf type="""rINC""" { Set inc=0 }
                                } ElseIf $list(next,1)=nextend,$list(next,2)=(nextend_$C(1)) {
                                    #; a redundant inclusion, so ignore it
                                } ; Else ??
                                Set nextend=$list(next,2),type=$Piece(nextend,",",2)
                                If type="" {
                                    #; the end of this range
                                    Set $list(range,2)=nextend
                                    Set i=i+1
                                    Quit
                                }
                                Set i=i+1,next=$ListGet(dbdata,i+1)
                            }
                        } ; Else no type exceptions
                    }
                    If int Set $List(intlist,*+1)=range
                    If mac Set $List(maclist,*+1)=range
                    If inc Set $List(inclist,*+1)=range
                } Else {
                    #; This begins an exclusion list
                    Set (int,mac,inc)=1 ; start with all
                    Do {
                        Set type=$Piece(end,",",2)
                        If type="""ROUTINE""" { Set int=0 }
                        ElseIf type="""rMAC""" { Set mac=0 }
                        ElseIf type="""rINC""" { Set inc=0 }
                        #; ignore type="rOBJ"
                        Set next=$ListGet(dbdata,i+1)
                        If next="" || (end_$Char(1)'=$List(next)) {
                            #; It's not a pattern I know how to deal with
                            Quit
                        }
                        Set end=$List(next,2),i=i+1
                        If $Length(end,",")'=2 {
                            #; Done with the list
                            Quit
                        }
                    } while 1
                    #; Set the excluded range
                    Set range=$ListBuild(name,name_$Char(1))
                    If int Set $List(intlist,*+1)=range
                    If mac Set $List(maclist,*+1)=range
                    If inc Set $List(inclist,*+1)=range
                    #; The remaining range is for all
                    Set range=$ListBuild(name_$Char(1),end)
                    Set $List(intlist,*+1)=range
                    Set $List(maclist,*+1)=range
                    Set $List(inclist,*+1)=range
                }
            } Else {
                #; name has a type
                #; This starts an inclusion list
                Set type=$Piece(name,",",2)
                If name_$Char(1)=end {
                    #; This is the only case I have seen
                    Set name=$Piece(name,",")
                    If $Extract(name,*-1)="*" {
                        Set $Extract(name,*-1)=""
                        Set end=$Extract(name,1,*-1)_"{"""
                    } Else {
                        Set end=name_$Char(1)
                    }
                    Set range=$ListBuild(name,end)
                    If type="""ROUTINE""" { Set $List(intlist,*+1)=range }
                    ElseIf type="""rMAC""" { Set $List(maclist,*+1)=range }
                    ElseIf type="""rINC""" { Set $List(inclist,*+1)=range }
                }
            }
        }
        If intlist'="" Set rtndir(dbdir,"INT")=$$clean(intlist)
        If maclist'="" Set rtndir(dbdir,"MAC")=$$clean(maclist)
        If inclist'="" Set rtndir(dbdir,"INC")=$$clean(inclist)
    }
    quit $$$OK
    
    #; Combine contiguous ranges into a single entry
clean(list)
    #dim list,result,l1,l2,start
    
    if $ListLength(list)<2 Quit list
    set result=""
    set l1=$List(list,1)
    set start=$List(l1,1),end=$List(l1,2)
    for i=2:1:$ListLength(list) {
        set l2=$List(list,i)
        if $List(l2,1)=end {
            set end=$List(l2,2)
        } else {
            set $List(result,*+1)=$ListBuild(start,end)
            set l1=l2
            set start=$List(l1,1),end=$List(l1,2)
        }
    }
    set $List(result,*+1)=$ListBuild(start,end)
    quit result
}

}
