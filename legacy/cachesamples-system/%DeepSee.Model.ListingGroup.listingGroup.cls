/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Meta-data object for a DeepSee subjectArea.<br/>
Class %DeepSee.Model.ListingGroup.listingGroup Extends (node, %CSP.Portal.AbstractPortalModel) [ System = 3 ]
{

/// Name of the class where this model was defined
/// Only used for XML transport
Property className As %String(MAXLEN = 30000, XMLPROJECTION = "attribute");

/// Name of the cube(s) which can access listings defined in this group.<br/>
/// This may contain a csv list of cubes. 
Property targetCubes As %DeepSee.Datatype.string(MAXLEN = 30000, XMLPROJECTION = "attribute");

/// This is used as the caption text when utilities display this listing group.
Property caption As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The resource needed to view or edit this cube:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view (run queries against) this item.<br/>
/// If defined and the current user holds the WRITE privilege on this resource, then
/// the user may modify this item.<br/>
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// If defined, this will serve as the default resource for all listings
/// in this group. Resources defined in individual listings will override
/// this setting.
Property defaultResource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Listings defined for this subject area.<br/>
Relationship listings As %DeepSee.Model.ListingGroup.listing(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = listingGroup ];

/// Validate this model for logical errors.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		If (..disabled) {
			Quit
		}

		If (..name = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Listing Group must have a name")
			Quit
		}

		If (..targetCubes = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Listing Group must have at least one target cube")
			Quit
		}

		// listings
		Set tListingCount = ..listings.Count()
		For l = 1:1:tListingCount {
			Set tListing = ..listings.GetAt(l)
			If (tListing.disabled) {
				Continue
			}
			Set tBaseName = $$$UPPER(tListing.name)
			If (tBaseName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Listing must have a name: " _ l)
			}
			ElseIf ($D(tListingNames(tBaseName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Listing with duplicate name: " _ tListing.name)
			}
			Else {
				Set tListingNames(tBaseName) = ""
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tListing.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Serializes the current Registry structure into XML inside the 
/// XData block in the relevant Registry class.
Method %SaveToClass(pClassName = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pClassName '= "") {
	        Set tClassName = $$$NormalizeClassname(pClassName)
        } Else {
	        Set tSC = $$$ERROR($$$ClassNameInvalid,"Class name must be defined")
	        Quit
        }

		// Create the XML writer and prepare it for writing to the class definition
		Set tWriter = ##class(%XML.Writer).%New()
        Set tWriter.NoXMLDeclaration = 1
        Set tWriter.Indent = 1

        Set tStream = ##class(%Stream.TmpCharacter).%New()
        Set tSC = tWriter.OutputToStream(tStream)
        If $$$ISERR(tSC) Quit
        
        Set tSC = tWriter.RootObject($this)
        If $$$ISERR(tSC) Quit
        
        // Check to see if we need to create this class, or if we have saved this before.
        Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName,,.tSC)
        If $system.Status.Equals(tSC,$$$ERRORCODE($$$LoadObjectNotFound)) {
            Set tSC = $$$OK
            Set tDefinition = ##class(%Dictionary.ClassDefinition).%New()
            Do tDefinition.NameSet(tClassName)
            Do tDefinition.SuperSet("%DeepSee.ListingGroupDefinition")
        }
        ElseIf $$$ISERR(tSC) {
            Quit
        }
       
        If tDefinition.Super'["%DeepSee.ListingGroupDefinition" {
	        $$$ThrowStatus($$$ERROR($$$GeneralError,$$$Text("Class exists, but is not a valid listing group storage class","%DeepSee")_": "_tClassName))
        }
        Else {
            // Remove current XData block if the class existed already
            Set tXDataLoc = tDefinition.XDatas.FindObjectId(tClassName_"||Listings")
            If tXDataLoc'="" Do tDefinition.XDatas.RemoveAt(tXDataLoc)
        }
       
        // Create the dependsOn class list based on the targetCubes list
        If ..targetCubes'="" {
        Set tCubeClassList=""
	        For c = 1:1:$L(..targetCubes,",") {
		        Set tCubeClassNameU = $ZSTRIP($$$UPPER($P(..targetCubes,",",c)),"<>"," ")
		        Set tCubeClassList = tCubeClassList _ $S($L(tCubeClassList):",",1:"") _ $G($$$DeepSeeMetaGLVN("cubes",tCubeClassNameU)) 
	        }
	        Do tDefinition.DependsOnSet(tCubeClassList)
        }
        
        // Create the new XData block and write the stream to it
        Set tXData = ##class(%Dictionary.XDataDefinition).%New()
 
        Set tXData.Name = "Listings"
        Set tXData.parent = tDefinition
        Set tXData.XMLNamespace = "http://www.intersystems.com/deepsee/listinggroup"
        Do tStream.Rewind()
        
        Set tSC = tXData.Data.CopyFrom(tStream)
        If $$$ISERR(tSC) Quit
    
        Set tSC = tDefinition.%Save()
        If $$$ISERR(tSC) Quit  
	}
	Catch ex {
		Set tSC = ex.AsStatus() 
	}
	Quit tSC
}

/// Deserialize the XML from the Listings XData block into a listingGroup model object.
ClassMethod %LoadFromClass(pClassname As %String, Output pStatus As %Status) As %DeepSee.CubeManager.RegistryMap [ Internal ]
{
	
    Set pStatus = $$$OK
    Try { 
        If $get(pClassname)= "" {
            Set pStatus = $$$ERROR($$$ClassNameInvalid, "Class name must be defined")
            Quit
        }
        
        Set pClassname = $$$NormalizeClassname(pClassname)
        
        Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(pClassname,"Listings",,.pStatus)
	    If $$$ISERR(pStatus) Quit

        If tXData = "" {
            Set pStatus = $$$ERROR($$$LoadObjectNotFound)
            Quit
        }
        
        Set tReader = ##class(%XML.Reader).%New()
        
        Set pStatus = tReader.OpenStream(tXData.Data)
        If $$$ISERR(pStatus) Quit
        
        Do tReader.Correlate("listingGroup","%DeepSee.Model.ListingGroup.listingGroup")
      
        If 'tReader.Next(.tListGroup, .pStatus) {
            If $$$ISERR(pStatus) Quit
            Set pStatus = $$$ERROR($$$LoadObjectNotFound)
            Quit
        }
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
    }
    // If we had an error, return an empty listingGroup
    If $$$ISERR(pStatus) Set tListGroup = ##class(%DeepSee.Model.ListingGroup.listingGroup).%New()

    Quit tListGroup
}

}
