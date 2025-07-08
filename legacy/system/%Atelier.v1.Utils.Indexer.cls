/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Atelier.v1.Utils.Indexer Extends %RegisteredObject
{

/// This general entry point serves to index all types of document
ClassMethod Index(pDocumentName As %String, pCat As %String, Output pIndex As %DynamicObject, pNS As %String = {$namespace}) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tName,tType As %String
    
    Try {
        Set tName=$Piece(pDocumentName,".",1,*-1)
        If pCat="CLS" {
            Set tSC=..IndexClass(tName,.pIndex,pNS)
        } ElseIf pCat="RTN" || (pCat="CSP") || (pCat="OTH") {
            Set tSC=$$$OK,pIndex={}
        } Else {
            Set tSC=$$$ERROR($$$GeneralError,"Type Not Indexable"),pIndex={}
        }  
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// The index will be created by examining the structures in ^oddDEF
ClassMethod IndexClass(pClassName As %String, Output pIndex As %DynamicObject, pNS As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tDepr,tDepl,tDesc,tFinal,tHidden,tSuper As %String
    #dim tI As %Integer
    
    #; This holds a cache for NormalizeClassName
    #dim tNormCache
    
    #define defClassKeyGet(%mcls,%mckey) $s($d(^|pNS|oddDEF(%mcls,%mckey))#2:^(%mckey),1:##safeexpression($$lookupdef(%literalargs,2)))
    Try {
        
        #; Create the output
        Set pIndex = {}
        
        #; Description
        Set tDesc=$$$defClassKeyGet(pClassName,$$$cCLASSdescription)
        Set pIndex.desc=[]
        
        If tDesc'="" {
            For tI=1:1:$Length(tDesc,$Char(13,10)) {
                Do pIndex.desc.%Push($Piece(tDesc,$Char(13,10),tI))
            }
        }
        
        #; Deployed
        Set tDepl=$$$defClassKeyGet(pClassName,$$$cCLASSdeployed)
        Do pIndex.%Set("depl",tDepl,"boolean")
        
        #; Set the deprecated flag
        Set tDepr=$$$defClassKeyGet(pClassName,$$$cCLASSdeprecated)
        Do pIndex.%Set("depr",tDepr,"boolean")
        
        #; Set the final flag
        Set tFinal=$$$defClassKeyGet(pClassName,$$$cCLASSfinal)
        Do pIndex.%Set("final",tFinal,"boolean")
        
        #; Set the final flag
        Set tHidden=$$$defClassKeyGet(pClassName,$$$cCLASShidden)
        Do pIndex.%Set("hidden",tHidden,"boolean")
        
        #; Set the superclass list
        Set pIndex.super=[],tSuper=$$$defClassKeyGet(pClassName,$$$cCLASSsuper)
        
        If tSuper'="" {
            For tI=1:1:$Length(tSuper,",") {
                Do pIndex.super.%Push(..NormalizeClassName($Piece(tSuper,",",tI),pClassName,.tNormCache))
            }
        }
        
        #; Ensure array exists
        Set pIndex.methods= []
        
        #; Methods
        Set tSC=..IndexMethods(pClassName,.tNormCache,.pIndex,pNS)
        If $$$ISERR(tSC) Quit
        
        #; Parameters
        Set tSC=..IndexParameters(pClassName,.tNormCache,.pIndex,pNS)
        If $$$ISERR(tSC) Quit
        
        #; Properties
        Set tSC=..IndexProperties(pClassName,.tNormCache,.pIndex,pNS)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This indexes the methods of a class
ClassMethod IndexMethods(pClassName As %String, ByRef pNormCache, ByRef pIndex As %DynamicObject, pNS As %String) As %Status [ Private ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tI As %Index
    #dim tArgList,tDepr,tDesc,tFinal,tInternal,tItemName,tOneArg,tPrivate,tReturnType,tScope As %String
    
    #dim tArg,tItem As %DynamicObject
    #dim tItemArray As %DynamicArray = []
    #dim tArgArray As %DynamicArray
    #dim tIt,tKey,tValue
    
    Try {
        
        #define defMemberKeyGet(%mcls,%mckey,%mmem,%mmkey) $s($d(^|pNS|oddDEF(%mcls,%mckey,%mmem,%mmkey))#2:^(%mmkey),1:##safeexpression($$lookupdef(%literalargs,2,4))) 
        
        #; Walk the method definitions
        Set tItemName="" For {
            
            Set tItemName=$Order(^|pNS|oddDEF(pClassName,"m",tItemName)) If tItemName="" Quit
            
            #; Add a new method to the list
            Set tItem = {} Do tItemArray.%Push(tItem)
            
            Set tItem.name=tItemName
            
            #; Description
            Set tDesc=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHdescription)
            Set tItem.desc=[]
            If tDesc'="" {
                For tI=1:1:$Length(tDesc,$Char(13,10)) {
                    Do tItem.desc.%Push($Piece(tDesc,$Char(13,10),tI))
                }
            }
            
            #; Set deprecated flag
            Set tDepr=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHdeprecated)
            Do tItem.%Set("depr",tDepr,"boolean")
         
            #; Set final flag
            Set tFinal=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHfinal)
            Do tItem.%Set("final",tFinal,"boolean")
            
            #; Set internal flag
            Set tInternal=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHinternal)
            Do tItem.%Set("internal",tInternal,"boolean")
            
            #; Set private flag   
            Set tPrivate=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHprivate)
            Do tItem.%Set("private",tPrivate,"boolean")
            
            #; Method Type
            Set tScope=+$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHclassmethod)
            Set tItem.scope=$Case(tScope,1:"class",:"instance")
            
            #; Return type
            Set tReturnType=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHreturntype)
            Set tItem.returntype=..NormalizeClassName(tReturnType,pClassName,.pNormCache)
            
            #; Deconstruct the signature
            Set tArgList=$$$defMemberKeyGet(pClassName,$$$cCLASSmethod,tItemName,$$$cMETHformalspec)
            
            Set tSC=$$parseFormal^%occName("","",tArgList,.tArgList)
            If $$$ISERR(tSC) quit
            
            Set tArgArray = []
            
            For tI=1:1:tArgList {
            
                Set tArg = {}
                Set tArg.name=tArgList(tI)
                Set tArg.type=..NormalizeClassName($Get(tArgList(tI,2)),pClassName,.pNormCache)
                
                Do tArgArray.%Push(tArg)
            }
            
            Set tItem.args=tArgArray
        }
         
        #; Now add these to the method array
        Set tIt=tItemArray.%GetIterator()
        While tIt.%GetNext(.tKey,.tValue) {
            Do pIndex.methods.%Push(tValue)
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This indexes the parameters of a class
ClassMethod IndexParameters(pClassName As %String, ByRef pNormCache, ByRef pIndex As %DynamicObject, pNS As %String) As %Status [ Private ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tI As %Index
    #dim tDesc,tDepr,tInternal,tItemName As %String
    
    #dim tItem As %DynamicObject
    #dim tItemArray As %DynamicArray = []
    
    #define defMemberKeyGet(%mcls,%mckey,%mmem,%mmkey) $s($d(^|pNS|oddDEF(%mcls,%mckey,%mmem,%mmkey))#2:^(%mmkey),1:##safeexpression($$lookupdef(%literalargs,2,4))) 
    
    Try {
        
        #; Walk the method definitions
        Set tItemName="" For {
            
            Set tItemName=$Order(^|pNS|oddDEF(pClassName,"p",tItemName)) If tItemName="" Quit
            
            #; Add a new paramter to the list
            Set tItem = {} Do tItemArray.%Push(tItem)
            
            Set tItem.name=tItemName
            
            #; Set deprecated flag
            Set tDepr=$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,tItemName,$$$cPARAMdeprecated)
            Do tItem.%Set("depr",tDepr,"boolean")
            
            #; Description
            Set tDesc=$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,tItemName,$$$cPARAMdescription)
           
            Set tItem.desc=[]
            If tDesc'="" {
                For tI=1:1:$Length(tDesc,$Char(13,10)) {
                    Do tItem.desc.%Push($Piece(tDesc,$Char(13,10),tI))
                }
            }

            #; Set internal flag   
            Set tInternal=$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,tItemName,$$$cPARAMinternal)
            Do tItem.%Set("internal",tInternal,"boolean")
        }
        
        Set pIndex.parameters=tItemArray
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This indexes the properties of a class
ClassMethod IndexProperties(pClassName As %String, ByRef pNormCache, ByRef pIndex As %DynamicObject, pNS As %String) As %Status [ Private ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tI As %Index
    #dim tDepr,tDesc,tFinal,tInternal,tItemName,tPrivate,tType As %String
    
    #dim tItem As %DynamicObject
    #dim tItemArray As %DynamicArray = []
    
    #define defMemberKeyGet(%mcls,%mckey,%mmem,%mmkey) $s($d(^|pNS|oddDEF(%mcls,%mckey,%mmem,%mmkey))#2:^(%mmkey),1:##safeexpression($$lookupdef(%literalargs,2,4))) 
    
    Try {
        
        #; Walk the property definitions
        Set tItemName="" For {
            
            Set tItemName=$Order(^|pNS|oddDEF(pClassName,"a",tItemName)) If tItemName="" Quit
            
            #; Add a new property to the list
            Set tItem = {} Do tItemArray.%Push(tItem)
            
            Set tItem.name=tItemName
            
            #; Description
            Set tDesc=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPdescription)
            Set tItem.desc=[]
            If tDesc'="" {
                For tI=1:1:$Length(tDesc,$Char(13,10)) {
                    Do tItem.desc.%Push($Piece(tDesc,$Char(13,10),tI))
                }
            }
            
            #; Set deprecated flag
            Set tDepr=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPdeprecated)
            Do tItem.%Set("depr",tDepr,"boolean")
            
            #; Set internal flag   
            Set tInternal=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPinternal)
            Do tItem.%Set("internal",tInternal,"boolean")
            
            #; Set final flag
            Set tFinal=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPfinal)
            Do tItem.%Set("final",tFinal,"boolean")
           
            #; Set private flag
            Set tPrivate=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPprivate)
            Do tItem.%Set("private",tPrivate,"boolean")            

            #; Set the type
            Set tType=$$$defMemberKeyGet(pClassName,$$$cCLASSproperty,tItemName,$$$cPROPtype)
            Set tItem.type=..NormalizeClassName(tType,pClassName,.pNormCache)
        }
        
        Set pIndex.properties=tItemArray
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

ClassMethod NormalizeClassName(pClassName As %String, pBaseClass As %String, ByRef pCache) As %String
{
    #dim tNormalizedName As %String
    #dim tSC As %Status
    
    #; If cache is not initialized, set flag to use it
    Set:'$Data(pCache) pCache=1
    
    Set tSC=$$NormalizeClassnameByDef^%occName(.tNormalizedName,pClassName,pBaseClass,.pCache)
    #;
    #; If there is an error, then the name cannot be normalized (this could be for various reasons)
    If $$$ISERR(tSC) Set tNormalizedName=pClassName
    #; The Atelier client expects to always get a name with a package, so if the system
    #; couldn't do it (because the class doesn't exist?), we will force it.
    If tNormalizedName'[".",tNormalizedName'="",pBaseClass["." {
        Set tNormalizedName=$Piece(pBaseClass,".",1,*-1)_"."_tNormalizedName
    }
    Quit tNormalizedName
}

}
