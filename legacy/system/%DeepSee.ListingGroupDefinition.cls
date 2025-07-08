/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// Subclasses of this class are used to define a DeepSee
/// "listing group" that contain auxiliary detail listings.<br/>
/// The Listings XDATA block defines the contents of a DeepSee listing group
/// as an XML document.
Class %DeepSee.ListingGroupDefinition Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, CompileAfter = (%DeepSee.Model.ListingGroup.listingGroup, %DeepSee.Generator), System = 4 ]
{

/// This projection is used to keep track of when Cubes are
/// compiled or deleted.
Projection ListingGroupProjection As %DeepSee.ListingGroupProjection [ Internal ];

/// This XData section provides the definition of the cube.
XData Listings [ XMLNamespace = "http://www.intersystems.com/deepsee/listinggroup" ]
{
}

/// Process the model for this Subject Area and generate meta data.
ClassMethod %Generate() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	Set tSC = $$$OK
	Do %code.WriteLine(" Quit $$$OK")

	Kill ^||%Cls(%compiledclass.Name)
	If (%class.Abstract || (%class.Name = "%DeepSee.ListingGroupDefinition")) {
		Quit $$$OK
	}

	// JMD1348 prevent incremental compile
#ifdef cCLASSdisableincremental
	$$$comClassKeySet(%class.Name,$$$cCLASSdisableincremental,1)
#endif

	Try {
		#; find XDATA block named SubjectArea
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Listings")
		
		
		
		// Perform initial validation of the Listings XData block. 
		// This valiation does not include checking for collisions.
		If (tIndex '= "") {
			#; get XDATA as stream 
			Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			If (tStream.Size > 0) {

				#; render the stream into cube meta-data object (with children)
				Set tReader = ##class(%XML.Reader).%New()

				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit 

				Do tReader.Correlate("listingGroup","%DeepSee.Model.ListingGroup.listingGroup")

				#; there should only be one listing group defined
				Do tReader.Next(.tListGroup,.tSC)
				If $$$ISERR(tSC) Quit 
				If '$IsObject(tListGroup) {
					Set tSC = $$$ERROR($$$GeneralError,"No <listingGroup> element defined in Listings block.")
					Quit 
				}

				#; is listing group disabled?
				If (tListGroup.disabled) {
					Write:$G(%qstruct("displaylog"),0) !,$$$FormatText($$$Text("Listing Group '%1' is disabled","%DeepSee"),tListGroup.name)
					Quit 
				}

				#; is this listing group name already used?
				Set tListGroupName = tListGroup.name
				Set tListGroupNameU = $$$UPPER(tListGroupName)
				Set tRegClass = $G($$$DeepSeeListingGroupGLVN("groups",tListGroupNameU))
				If ((tRegClass'="") && (tRegClass '= %class.Name)) {
					Set tSC = $$$ERROR($$$GeneralError,"Listing Group with given name already exists: " _ tListGroupName)
					Quit 
				}
				
				#; validate this listing group
				Set tSC = tListGroup.%Validate()
				If $$$ISERR(tSC) Quit
				
				Set tCubeList = tListGroup.targetCubes
				#; tagetCubes can contain a list of cube names!
				For p=1:1:$L(tCubeList,",") {
					Set tCubeName = $P(tCubeList,",",p)
					Set tCubeNameU = $$$UPPER(tCubeName)
					Set tBaseClass = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU))
					If (tBaseClass = "") {
						Set tSC = $$$ERROR($$$GeneralError,"Target cube does not exist: " _ tCubeName)
						Quit
					} ElseIf $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"disableListingGroups"),0) {
						Set tSC = $$$ERROR($$$GeneralError,"Target cube does not accept listing groups: " _ tCubeName)
						Quit
					}

					
				}
				If $$$ISERR(tSC) Quit 		
			}
				
		}

		#; Process the contents of the listings. 
		For p=1:1:$L(tCubeList,",") {
			Set tCubeNameU = $$$UPPER($P(tCubeList,",",p))
			Set tGroupMeta(tListGroupNameU,"cubes",tCubeNameU) = ""
			Set:tListGroup.displayName'="" tGroupMeta(tListGroupNameU,"displayName") = tListGroup.displayName
			Set tGroupMeta(tListGroupNameU,"name") = tListGroupName
			
			For n=1:1:tListGroup.listings.Count() {
				Set tListing = tListGroup.listings.GetAt(n)
				
				// Check for name collisions 
				If $D($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name)) {
					Set tSC = $$$ERROR($$$GeneralError,"Listing is already defined in target cube: "_tListing.name)
					$$$ThrowStatus(tSC)
				}
				If $D($$$DeepSeeListingGroupGLVN("cubes",tCubeNameU,"listing",tListing.name,"group")) &&
						($G($$$DeepSeeListingGroupGLVN("cubes",tCubeNameU,"listing",tListing.name,"group"))'=tListGroupNameU) {
					Set tSC = $$$ERROR($$$GeneralError,"Listing is already defined by another listing group: "_tListing.name)
					$$$ThrowStatus(tSC)		
				}

				If ('tListing.disabled) {
					Set tListingMeta(tCubeNameU,"listing",tListing.name,"group") = tListGroupNameU
					
					Set tListingMeta(tCubeNameU,"listing",tListing.name,"fieldList") = tListing.fieldList
					Set:tListing.formatList'="" tListingMeta(tCubeNameU,"listing",tListing.name,"formatList") = tListing.formatList

					Set:tListing.orderBy'="" tListingMeta(tCubeNameU,"listing",tListing.name,"orderBy") = tListing.orderBy
					Set:tListing.sql'="" tListingMeta(tCubeNameU,"listing",tListing.name,"sql") = tListing.sql
					Set:tListing.sourceClass'="" tListingMeta(tCubeNameU,"listing",tListing.name,"sourceClass") = tListing.sourceClass
					Set:(tListing.listingType'="")&&(tListing.listingType'="table") tListingMeta(tCubeNameU,"listing",tListing.name,"listingType") = tListing.listingType
					Set:tListing.displayName'="" tListingMeta(tCubeNameU,"listing",tListing.name,"displayName") = tListing.displayName
					Set:tListing.description'="" tListingMeta(tCubeNameU,"listing",tListing.name,"description") = tListing.description		// DTB139 - store description
					Set:tListing.selectMode'="" tListingMeta(tCubeNameU,"listing",tListing.name,"selectMode") = tListing.selectMode		// DP-414835 - store selectMode
					
					// Inherit the group resource if defined
					Set tResource = $S((tListing.resource'=""):tListing.resource,(tListGroup.defaultResource'=""):tListGroup.defaultResource,1:"")
					Set:tResource'="" tListingMeta(tCubeNameU,"listing",tListing.name,"resource") = tResource
				}
			}
		}
		
		// Pass information to other methods on compile
		Set ^||%Cls(%compiledclass.Name,"listingGroupName") = tListGroupName
	
		// Save the listing data to the global
		Merge $$$DeepSeeListingGroupGLVN("cubes") = tListingMeta
		Merge $$$DeepSeeListingGroupGLVN("groups") = tGroupMeta
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
		
	Quit tSC
}

/// Return the logical name of the MDX cube defined by this subject area.
ClassMethod %GetListingGroupName() As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"listingGroupName"))))
	Quit $$$OK
}

/// Return the (localized) caption for a given listing within this listing group.
ClassMethod %GetListingCaption(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tListGroupName = $G(^||%Cls(%compiledclass.Name,"listingGroupName"))
		If (%class.Abstract || (%class.Name = "%DeepSee.ListingGroupDefinition") || (tListGroupName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}
		
		Set tCubeName = $O($$$DeepSeeListingGroupGLVN("groups",$$$UPPER(tListGroupName),"cubes",""))
		If (tCubeName="") {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pListing = $$$UPPER(pListing)")

		Set n = 0
		Set k = $O($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tCaption = $G($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",k,"displayName"))
			Set:tCaption="" tCaption = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pListing) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tCaption))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Return the (localized) description for a given listing within this listing group.
ClassMethod %GetListingDescription(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tListGroupName = $G(^||%Cls(%compiledclass.Name,"listingGroupName"))
		If (%class.Abstract || (%class.Name = "%DeepSee.ListingGroupDefinition") || (tListGroupName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}
		
		Set tCubeName = $O($$$DeepSeeListingGroupGLVN("groups",$$$UPPER(tListGroupName),"cubes",""))
		If (tCubeName="") {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pListing = $$$UPPER(pListing)")

		Set n = 0
		Set k = $O($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tDescription = $G($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",k,"description"))		// DTB139 - correct description lookup
			;Set:tDescription="" tDescription = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pListing) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tDescription)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tDescription))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeListingGroupGLVN("cubes",$$$UPPER(tCubeName),"listing",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
