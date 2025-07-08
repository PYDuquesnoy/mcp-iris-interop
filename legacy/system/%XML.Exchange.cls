/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %XML.Exchange)

/// The <class>%XML.Exchange</class> class provides an interface for managing XML representations of objects.
Class %XML.Exchange Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Export all Exchange Items from the system to a directory.
ClassMethod ExportAllDir(dir As %String = "", qspec As %String = "", ByRef errorlog As %String, Charset As %String = "", ByRef exported As %GlobalCharacterStream = {##class(%GlobalCharacterStream).%New()}) As %Status
{
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	If $$$qualifierGetValue(qstruct,"displaylog") {
		Write !,$$$GetSimpleMessage("%Compiler","ExportXMLStart")_$ZDateTime($Horolog)
	}
	Set rc=$$GetAllDerivedClasses^%occLibrary("%XML.Exchange.Adaptor",.dependency)
	If $$$ISOK(rc) {
		Set class = ""
		For  {
			Set class = $Order(dependency(class))
			If class = "" Quit
			
			Set resultSet=##class(%ResultSet).%New(class_":Extent")
			Set idCol = resultSet.GetColumnName(1)
			Set rc = resultSet.Execute()
			If $$$ISOK(rc) {
				While resultSet.Next(),$Length(resultSet.Data(idCol)) {
					Set oid=$$$oidCompose(resultSet.Data(idCol),class)
					If '$$$qualifierGetValue(qstruct,"onlyfirst") {
						Kill content
						#; Run per Exchange Item to avoid <STORE> errors with large tables.
						Set content(oid)=""
						Set filename = ..GetPath(dir, oid, qspec)
						#;
						If $$$qualifierGetValue(qstruct,"overwrite")||('##class(%File).Exists(filename)) {
							Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
							Set sc=..exportItems(filename,qspec,.content,.Charset)
							If $$$ISERR(sc) Quit
							If $Length(filename),$$$qualifierGetValue(qstruct,"validate") {
								Set rc=..Load(filename,"/displaylog=0",,,1)
								If $$$ISERR(rc) Quit
							}
							Do exported.WriteLine($ListBuild(oid, filename))
						}
					} Else {
						#; When /onlyfirst is used process through ExportDir so that
						#; we can use other qualifiers such as /references.
						Set sc = ..ExportDir(oid,dir,.qspec,.errorlog,.Charset,.exported,0)
						#; One has been exported.  Move on to the next table.
						Quit
					}
				}
			}
			
			#; Continue exporting unless an internal error(rc) has occurred.
			If $$$ISERR(rc) Quit
		}
	}
	#; rc variable is used for statuses that have been encountered
	#; inside this method and therefore have not yet been reported.
	If $$$ISERR(rc) {
		Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct)
		Set sc=$$$ADDSC(sc,rc)
	}
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
	}
	Quit sc
}

/// Export all Exchange Items from a given table to a directory.
ClassMethod ExportTableDir(class As %String = "", dir As %String = "", qspec As %String = "", ByRef errorlog As %String, Charset As %String = "", ByRef exported As %GlobalCharacterStream = {##class(%GlobalCharacterStream).%New()}) As %Status
{
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	If $$$qualifierGetValue(qstruct,"displaylog") {
		Write !,$$$GetSimpleMessage("%Compiler","ExportXMLStart")_$ZDateTime($Horolog)
	}
	Set resultSet=##class(%ResultSet).%New(class_":Extent")
	Set idCol = resultSet.GetColumnName(1)
	Set sc = resultSet.Execute()
	If $$$ISOK(sc) {
		While resultSet.Next() {
			Set oid=$$$oidCompose(resultSet.Data(idCol),class)
			If '$$$qualifierGetValue(qstruct,"onlyfirst") {
				Kill content
				#; Run per Exchange Item to avoid <STORE> errors with large tables.
				Set content(oid)=""
				Set filename = ..GetPath(dir, oid, qspec)
				#;
				If $$$qualifierGetValue(qstruct,"overwrite")||('##class(%File).Exists(filename)) {
					Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
					Set sc=..exportItems(filename,qspec,.content,.Charset)
					If $$$ISERR(sc) Quit
					If $Length(filename),$$$qualifierGetValue(qstruct,"validate") {
						Set sc=..Load(filename,"/displaylog=0",,,1)
						If $$$ISERR(sc) Quit
					}
					Do exported.WriteLine($ListBuild(oid,filename))
				}
			} Else {
				#; When /onlyfirst is used process through ExportDir so that
				#; we can use other qualifiers such as /references.
				Set sc = ..ExportDir(oid,dir,.qspec,.errorlog,.Charset,.exported,0)
				#; One has been exported.  Move on to the next table.
				Quit
			}
		}
	}
	If $$$ISERR(sc) {
		Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct)
	}
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
	}
	Quit sc
}

/// Export Exchange Items to a directory.  
/// <p>The directory structure created is based on the type of Exchange Items being exported.  The file names used can be controlled by the /name qualifier.  
/// <p>Each of the <var>items</var> must be of a type that extends the %XML.Exchange.Adaptor class.
/// If exporting multiple Exchange Items pass the items("oid")="" as an array.
ClassMethod ExportDir(items As %String = "", dir As %String = "", qspec As %String = "", ByRef errorlog As %String, Charset As %String = "", ByRef exported As %GlobalCharacterStream = {##class(%GlobalCharacterStream).%New()}, header As %Boolean = 1) As %Status
{
	#include %occInclude
	
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If header Write !,$$$GetSimpleMessage("%Compiler","ExportXMLStart")_$ZDateTime($Horolog)
	}

	If dir'="" Set dir=$ZUtil(12,dir,0,1)
	If dir'="" Do ##class(%File).CreateDirectoryChain(dir)
	
	#; ExportDir uses the "include" list to keep track of items included in the directory export.
	#; Note: The "selected" list controls the contents of each file.
	$$$xmlListKill("include")
	Do ..normalizeItems("include",.items)
	
	#; Check whether other Exchange Items referenced from those specified should be included.
	If $$$qualifierGetValue(qstruct,"references") {
		Set key = ""
		For  {
			$$$xmlMemberNext("include",key,oid)
			If key = "" Quit
			
			Set obj = $ZObjClassMethod($$$oidClassName(oid),"%OpenId",$$$oidPrimary(oid),0)
			If $IsObject(obj) {
				#; TODO: Change GetReferences to directly update the list of selected items.
				Set sc = ..GetReferences(obj, .references, .qstruct)
				If $$$ISERR(sc) Quit
			}
		}
		
		#; TODO: Remove the following when GetReferences directly updates the list of selected items.
		Set oid = ""
		For {
			Set oid = $Order(references(oid))
			If oid = "" Quit
			
			If '$$$xmlMemberDefined("include",oid) $$$xmlMemberSet("include",oid)
		}
	}
	If $$$ISERR(sc) Quit sc
	
	Set key = ""
	For  {
		$$$xmlMemberNext("include",key,oid)
		If key = "" Quit
		
		$$$xmlListKill("selected")
		$$$xmlMemberSet("selected",oid)
		Set filename = ..GetPath(dir, oid, qspec)
		Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
		Set sc=..exportItems(filename,qspec,,.Charset)
		If $$$ISERR(sc) Quit
		If $Length(filename),$$$qualifierGetValue(qstruct,"validate") {
			Set sc=..Load(filename,"/displaylog=0",,,1)
			If $$$ISERR(sc) Quit
		}
		Do exported.WriteLine($ListBuild(oid, filename))
	}
	If $$$ISERR(sc) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct)
	
	$$$xmlListKill("include")
	$$$xmlListKill("selected")
	
	If header,$$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
	}
	Quit sc
}

/// Export Exchange Items to an XML file
/// <p>Each of the <var>items</var> must be of a type that extends the %XML.Exchange.Adaptor class:
/// If exporting multiple Exchange Items pass the items("oid")="" as an array.
/// <p>
/// If the output filename is empty, matching Exchange Items will be exported to the current device.
ClassMethod Export(items As %String = "", ByRef filename As %String = "", qspec As %String = "", ByRef errorlog As %String, Charset As %String = "") As %Status
{
	Set:filename'="" filename=$ZUtil(12,filename,0,1)
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	#; Do not display anything when exporting to current device
	If filename="" Set sc=$$$qualifierAmend("Export",.qstruct,"/displaylog=0",.qstruct)
	Do:filename'="" ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
	If $$$qualifierGetValue(qstruct,"displaylog") {
		Write !,$$$GetSimpleMessage("%Compiler","ExportXMLStart")_$ZDateTime($Horolog)
	}
	
	$$$xmlListKill("selected")
	Do ..normalizeItems("selected",.items)
	
	Set sc=..exportItems(filename,qspec,,.Charset)
	If $$$ISOK(sc),$Length(filename),$$$qualifierGetValue(qstruct,"validate") {
		Set sc=..Load(filename,"/displaylog=0",,,1)
	}
	If $$$ISERR(sc) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct)
	
	$$$xmlListKill("selected")
		
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(sc) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
	}
	Quit sc
}

/// Load all Exchange Items from XML files in a directory.
ClassMethod LoadDir(dir As %String = "", qspec As %String = "", ByRef errorlog As %String, recurse As %Boolean = 1, ByRef loaded As %GlobalCharacterStream = {##class(%GlobalCharacterStream).%New()}, listonly As %Boolean = 0, ByRef selectedlist As %String, header As %Boolean = 1) As %Status
{
	If dir = "" Quit $$$OK
	Set dir = ##class(%File).NormalizeDirectory(dir)
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) If $$$ISERR(sc) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct) Quit sc
	Set displaylog=$$$qualifierGetValue(qstruct,"displaylog")
	Set displayerror=$$$qualifierGetValue(qstruct,"displayerror")
	If header {
		$$$InitErrorNums
		Set zh=$ZHorolog
		If displaylog Write !,$$$GetSimpleMessage("%Compiler","LoadDir")_$ZDateTime($Horolog)
		$$$xmlListKill("dir")
		$$$xmlListKill("file")
	}
	
	If $$$xmlMemberDefined("dir",dir) $$$xmlMemberKill("dir",dir)
	Set resultset=##class(%ResultSet).%New("%File:FileSet")
	Set sc=resultset.%Execute(dir,"*.xml","",1)
	If $$$ISERR(sc) Do $System.Status.DecomposeStatus(sc,.errorlog) Quit sc
	While resultset.Next() {
		If resultset.Data("Type")="D" {
			If recurse {
				Set directory = ##class(%File).NormalizeDirectory(resultset.Data("Name"))
				Set rc = ..LoadDir(directory,.qspec,.errorlog,1,.loaded,.listonly,.selectedlist,0)
				If $$$ISERR(rc) {
					Set sc=$$$ADDSC(sc,rc)
				}
			}
		} Else {
			$$$xmlMemberSet("file",resultset.Data("Name"))
			If $$$qualifierGetValue(qstruct,"onlyfirst") Quit
		}
	}
	#; Do not quit after error to allow further directories to be processed.
	If $$$ISERR(sc) Do $System.Status.DecomposeStatus(sc,.errorlog)
	
	If header {
		#; Load all files together
		Set rc=..Load(,.qspec,.errorlog,.loaded,.listonly,.selectedlist,,0)
		
		#; Error ignored to allow other objects to be loaded.
		If $$$ISERR(rc) {
			Set sc=$$$ADDSC(sc,rc)
			If displayerror Do $System.OBJ.DisplayError(rc)
		}
		
		$$$xmlListKill("dir")
		$$$xmlListKill("file")
		if displaylog {
			Set zh=$ZHorolog-zh,zh=$FNumber(zh,"",$Select(zh>100:1,zh>10:2,1:3))
			If $$$ErrorNum=0 {
				Write $Char(13,10)_$$$FormatMessage(,"%Compiler","LoadOk",,zh)
			} Else {
				Write $Char(13,10)_$$$FormatMessage(,"%Compiler","LoadErrors",,$$$ErrorNum,zh)
			}
		}
	}
	Quit sc
}

/// Load a file from disk.
/// <p>Load Exchange Items from the file <var>file</var>. Returns an stream of Exchange Items it loaded in <var>loaded</var>, 
/// You may give it a list of files to load
/// via a single subscripted array. If you pass <var>listonly</var> as true then it will not
/// load anything but just list the Exchange Items that exist in the files that you supply it.<br>
/// If <var>selecteditems</var> is defined then this will contain a single subscripted array
/// of items to load. It will only load items that are in this list from the file/s
/// provided, so this provides a way to limit which items get loaded.<br>
/// <var>qspec</var> is a list of qualifiers which can be displayed with 'Do ##class(%XML.Exchange).ShowQualifiers()'
ClassMethod Load(ByRef filename As %String = "", qspec As %String = "", ByRef errorlog As %String, ByRef loaded As %GlobalCharacterStream = {##class(%GlobalCharacterStream).%New()}, listonly As %Boolean, ByRef selecteditems As %String, displayname As %String, header As %Boolean = 1, charset As %String = "") As %Status
{
	#; %xmlExchangeItem used to track objects being loaded via %XML.Exchange.
	#; During this process ChangeControl events will not be passed on.
	#; % variable name used so that it is available during object events
	#; and classes can act appropriately for artifact exchange.
	#;
	#; %objlasterror keeps the most recent object error encountered during
	#; the load process.
	
	#; xmlFile is the list of files to be parsed.
	#; xmlOid is the list of objects to be loaded from the files.
	#; xmlGuid is a list of objects in progress of being loaded.
	New %xmlExchangeItem, %objlasterror
	Set sc=$$$OK,fileStatus=$$$OK,rc=$$$OK,listonly=+$Get(listonly)
	If header {
		$$$InitErrorNums
		$$$xmlListKill("file")
	}
	#; If we are just listing the items in here then ignore the selected items list
	If 'listonly Do ..normalizeItems("selected",.selecteditems)
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) If $$$ISERR(sc) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct) Quit sc
	
	Do ..normalizeItems("file",.filename)
	Set key = ""
	$$$xmlMemberNext("file",key,file)
	If key="" Set sc=$$$ERROR($$$FileNameRequired) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct) Quit sc
	Set force=0
	Set display=$$$qualifierGetValue(qstruct,"displaylog")
	Set loadguids=$$$qualifierGetValue(qstruct,"loadguids")
	Set validateregistered=$$$qualifierGetValue(qstruct,"validateregistered")
	Set %xmlExchangeItem=$$$qualifierGetValue(qstruct,"bypassccr")
	Set zh=$ZHorolog
	If display,header Write !,$$$GetSimpleMessage("%Compiler","LoadStart")_$ZDateTime($Horolog)
	#; Unless the 'force' qualifier is used the load will be treated as a single transaction.
	#; If there is an error during the load then the whole transaction will be rolled back.
	If 'listonly,'force TStart
	Set reader=##class(%XML.Exchange.Reader).%New()
	#; Support multiple passes to ensure references between objects are maintained.
	For pass=1:1 {
		Set key = ""
		For {
			$$$xmlMemberNext("file",key,file) Quit:key=""
			If '##class(%File).Exists(file) {
				Set fileStatus=$$$ERROR($$$FileDoesNotExist,file)
			} Else {
				#; Reset the list of GUIDs that do not exist.
				$$$xmlSubListKill("file",file,"unknown")
				Do reader.OpenFile(file)
				While reader.Next(.obj,.rc,,.qstruct) {
					If '$IsObject(obj) Quit
					If obj.%Extends("%Library.Persistent") {
						Set oid=obj.%Oid()
						Set key = ""
						#; During ListOnly new items do not have an ObjectIdentity.  They may be identified by their GUID instead of id.
						#; Note: Both the GUID and id are checked in case the item was referenced by GUID for the first pass because an
						#;        id did not exist.  During the second pass an id may exist but the id is not included in selecteditems.
						Set item = $$$oidCompose(obj.GUID,$ClassName(obj))
						If '$$$xmlListDefined("selected")||(oid'=""&&($$$xmlMemberDefined("selected",oid)))||(item'=""&&($$$xmlMemberDefined("selected",item))) {
							If obj.GUID'="" {
								#; Track Exchange Item objects being loaded.
								#; Objects are removed once they have been saved.
								$$$xmlMemberSet("guid",obj.GUID)
								$$$xmlSubMemberKill("file",file,"unknown",obj.GUID)
							}
							If 'listonly {
								If loadguids {
									If obj.%Id()'="" {
										Set oid = obj.%Oid()
										#; The GUID will not be updated if there is an existing GUID assigned.
										#; The force qualifier indicates the GUID from the XML should override an existing GUID.
										If force,$Data(^OBJ.GUID(1,oid),guid) {
											Kill ^OBJ.GUID(0,guid)
											Kill ^OBJ.GUID(1,oid)
										}
										If '$Data(^OBJ.GUID(1,oid)) {
											Set guid = obj.%GUIDSet(oid, obj.GUID)
											If display Write !, "Loaded GUID: ", $$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, obj.%GUID(oid), .qstruct)
										}
									}
								} Else {
									#; Do not proceed with unresolved references unless the force qualifier is used.
									#; Note: When a set of items both define and referece the same GUID it must be correlated twice.
									#;       The first pass will save the object with it's GUID and the second will match the GUID.
									If 'force {
										#; Compare the GUIDs that defined by this item against the list of
										#; GUIDs that are referenced but do not exist on this system.
										#; The %Save will not proceed if there are any missing references.
										Set sc = ..GetContentGUIDs(file, obj)
										
										#; A missing GUID has been found.
										#; The object will not be saved until the reference can be resolved.
										If $$$xmlSubListDefined("file",file,"unknown") Quit
									}
									Set rc=obj.%Save()
									Set oid=obj.%Oid()

									If $$$ISERR(rc) {
										If '$$$xmlSubListDefined("file",file,"unknown") {
											Set rc=$System.Status.AppendStatus($$$ERROR($$$GeneralError,"Unable to save item $lb("_$Select(obj.%Oid()'="":$ListToString(obj.%Oid()),1:""""","""_$ClassName(obj)_"""")_"), "_obj.GUID),rc)
										} Else {
											#; Incomplete item could not be saved.  The save can fail if the missing reference is a required property.
											#; This is not treated as an error.  Subsequent passes may be able to load the item since the missing
											#; reference is defined in one of the files being processed.
											If display {
												Write !, "WARNING: Initial load failed.  ", $ClassName(obj), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, obj.GUID, .qstruct)
												Write !, $Char(9), $System.Status.GetOneStatusText(rc)
											}
											Set rc = $$$OK
											$$$DecErrorNum
										}
										Quit
									}
									If obj.GUID'="" {
										#; Remove item that has been saved.
										$$$xmlMemberKill("guid",obj.GUID)
									}
									
									#; When there are still unknown GUIDs display an alternate
									#; message indicating another pass will be performed
									#; to resolve GUID references included in this item. (Primed item ...)
									#; Note: This scenario only occurs when a set of files both
									#;       define and reference the same GUID and thus two
									#;       passes are required for the correlation to work.
									If display Write !, $Select('$$$xmlSubListDefined("file",file,"unknown"):"Loaded",1:"Primed")_" item: ", $$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, obj.%GUID(oid), .qstruct)
								}
							} Else {
								#; When running list only, instead of relying upon the object
								#; load to match GUIDs we need to check for GUIDs that would
								#; have been loaded.
								Set sc = ..GetContentGUIDs(file, obj)
								
								#; If there are any unresolved references remaining the object
								#; would not be saved unless the force qualifier is used.
								If 'force,$$$xmlSubListDefined("file",file,"unknown") Quit
								#; No save performed but display details if available.
								If display {
									Write !, "Listed item: "
									If oid = "" {
										Write $ClassName(obj), $Char(9), "%New()", $Char(9), ..GetName(oid, obj.GUID, .qstruct)
									} Else {
										Write $$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, obj.GUID, .qstruct)
									}
								}
							}
							#; During ListOnly new items do not have an ObjectIdentity.
							#; Instead they are identified by their GUID.
							Set item = $Select(oid'="":oid,1:$$$oidCompose(obj.GUID,$ClassName(obj)))
							If item'="" {
								Do loaded.WriteLine($ListBuild(item,file))
							}
						}
					} Else {
						If (validateregistered)&&('force) {
							#; Validate non-persistent classes.
							#; %XML.Exchange.Metadata uses this process to confirm class version information.
							Set rc=$System.Status.AppendStatus(obj.%ValidateObject(),rc)
						}
					}
					Set fileStatus=$$$ADDSC(fileStatus,rc)
					Set rc=$$$OK
				}
				#; Check return code from %XML.Exchange.Reader:Next loop.
				If $$$ISERR(rc) {
					#; Increment the error count for errors returned from %XML.Exchange.Reader:Next.
					$$$IncErrorNum
					Set fileStatus=$$$ADDSC(rc,fileStatus)
					If display Do $System.Status.DisplayError(rc)
					Quit
				}
				
				#; If all GUID references were resolved the file is complete.
				If '$$$xmlSubListDefined("file",file,"unknown") {
					$$$xmlMemberKill("file",file)
					#; An item has successfully been loaded during this pass.
					#; Therefore subsequent passes of other files may refer to GUIDs defined by this item.
					
					#; Disregard missing GUID details because another pass will be performed.
					Set continue = 1
				}
			}

			If $$$ISERR(fileStatus) {
				#; Add an error including the file name to identify which file has encountered the problem.
				Set fileStatus=$$$EMBEDSC($$$ERROR($$$GeneralError, "Unable to load file "_file),fileStatus)
				Do DecomposeStatus^%occSystem(fileStatus,.errorlog,.qstruct)
				Set sc=$$$ADDSC(sc,fileStatus)
				Set fileStatus=$$$OK
			}
		}
		
		#; Check to see whether another pass is required.
		If '$$$xmlListDefined("file") Quit
		
		#; After the second pass check to see whether another pass will help.
		If pass > 1 {
			
			If 'continue {
				#; All files from this pass are marked for inclusion in the next pass and
				#; therefore the next pass will have the same results as this pass.
				#;
				#; Build a list of the missing GUIDs per file and stop processing.
				Set key = ""
				For  {
					$$$xmlMemberNext("file",key,file)
					If key = "" Quit
					
					#; Note: Maximum %Status description length is 1023 and GUIDs are 36 characters.
					#;       When there are too many GUIDs to be included in a status an ellipse of
					#;       3 characters is used.
					#Define DisplayMaximum ##expression(1023 - 36 - 3)
					Set guid = "", errorText = ""
					For {
						Set guid = $Order(nextpass(file,guid))
						If guid = "" Quit
						
						#; If the error text does not have space for another GUID append an ellipse.
						If $Length(errorText) > $$$DisplayMaximum {
							Set errorText = errorText_"..."
							Quit
						}
						If errorText = "" {
							Set errorText = "GUID reference(s) missing from "_file_"; "_guid
						} Else {
							Set errorText = errorText_", "_guid
						}
					}
					Set rc = $$$ADDSC(rc, $$$ERROR($$$GeneralError,errorText))
				}
				
				#; Note: $$$ERROR will increment the error count.
				Do DecomposeStatus^%occSystem(rc,.errorlog,.qstruct)
				Set sc=$$$ADDSC(sc,rc)
				Quit
			}
		}
		If $$$ISERR(rc) Quit
		
		#; Initialise next pass.
		Kill thispass
		Merge thispass = nextpass
		Kill nextpass
	}
	If $$$ISERR(sc),$$$ErrorNum=0 $$$IncErrorNum
	If display,header {
		Set zh=$ZHorolog-zh,zh=$FNumber(zh,"",$Select(zh>100:1,zh>10:2,1:3))
		If $$$ErrorNum=0 {
			Write $Char(13,10)_$$$FormatMessage(,"%Compiler","LoadOk",,zh)
		} Else {
			Write $Char(13,10)_$$$FormatMessage(,"%Compiler","LoadErrors",,$$$ErrorNum,zh)
		}
	}
	If header,$$$ISOK(sc),$$$ErrorNum'=0 {
		If $Get(%objlasterror)'="",$$$ISERR(%objlasterror) {
			Set sc=$$$EMBEDERROR(%objlasterror,$$$ErrorDetected)
		} Else {
			Set sc=$$$ERROR($$$ErrorDetected)
		}
		Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct)
	}
	If 'listonly,'force {
		If $$$ISOK(sc) {
			TCommit
		} Else {
			TRollback 1
			If display Write !, "Transaction rolled back"
		}
	}
	$$$xmlListKill("guid")
	Quit sc
}

/// Remove contents from the list of unknown GUIDs.
ClassMethod GetContentGUIDs(file As %String, obj As %RegisteredObject) As %Status [ Internal ]
{
	#Define cardinality(%classname,%propertyname) $$$defMemberKeyGet(%classname,$$$cCLASSproperty,%propertyname,$$$cPROPcardinality)
	
	Set status = $$$OK
	If obj.GUID'="" $$$xmlSubMemberKill("file", file, "unknown", obj.GUID)

	Set className=$ClassName(obj)
	Set propertyName=""
	For	{
		Set propertyName=$$$defMemberNext(className,$$$cCLASSproperty,propertyName)
		If propertyName="" Quit
		
		If $$$cardinality(className,propertyName)=$$$cPROPCARDINALITYCHILDREN	{
			Set relationship=$Property(obj,propertyName)
			If relationship	{
				For i=1:1:relationship.Count() {
					Set child=relationship.GetAt(i)
					Set status=..GetContentGUIDs(child)
					If $$$ISERR(status) Quit
				}
			}
		}
		If $$$ISERR(status) Quit
	}
	Quit status
}

/// Takes an object referece so that it can support serial objects.
ClassMethod GetReferences(Obj As %RegisteredObject, ByRef references As %String, qstruct As %String, ReferenceDepth As %Numeric, ByRef ReferencesLimited As %Boolean = 0) As %Status [ Private ]
{
	Set sc = $$$OK, header = ($Get(ReferenceDepth)="")
	
	If Obj.%IsA("%Library.Persistent") {
		Set oid = Obj.%Oid()
		Set id = $$$oidPrimary(oid)
		Set className = $$$oidClassName(oid)
		
		#; Count the number of steps away from a the starting item.
		#; Note: This function is recursive.  The ReferenceDepth parameter
		#; should only be passed in from within this function.
		If $Increment(ReferenceDepth)
	} Else {
		Set (oid, id) = ""
		Set className = $ClassName(Obj)
		
		#; Serial objects are exported as part of the parent.
		#; Therefore do not consider this a reference step.
	}
	
	If $IsObject(Obj) {
		If $$$qualifierGetValue(qstruct,"displaylog"),header {
			Write !, "Find references: ",className, $Char(9), id, $Char(9), ..GetName(oid, , .qstruct)
		}
		Set name=""
		For  {
			Set name=$$$comMemberNext(className,$$$cCLASSproperty,name)
			If name="" Quit
			
			Set private = +$$$comMemberKeyGet(className,$$$cCLASSproperty,name,$$$cPROPprivate)
			Set proptype = $$$comMemberKeyGet(className,$$$cCLASSproperty,name,$$$cPROPtype)
			Set collection = $$$comMemberKeyGet(className,$$$cCLASSproperty,name,$$$cPROPcollection)
			If 'private {
				Set prop = $Property(Obj, name)
				If $$$classIsPersistent(proptype) {
					If $ZObjClassMethod(proptype, "%GetParameter", "GUIDENABLED") {
						If collection=$$$cPROPCOLLECTIONLIST {
							For n = 1:1:prop.Count() {
								Set oref = prop.GetAt(n)
								If $IsObject(oref) {
									Set oid = oref.XMLGetElement(oref.%Id())
									If oid'="",'$Data(references(oid)) {
										If ReferenceDepth<=$$$qualifierGetValue(qstruct,"references") {
											If $$$qualifierGetValue(qstruct,"displaylog") {
												Write !, "Included item: ",$$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, , .qstruct)
											}
										} Else {
											Set ReferencesLimited = 1
										}
									}
									#; Stop searching for references if the depth limit has been reached.
									#; Continue to search serial objects for further references.
									#; Do not search an object that has already been searched.
									If 'ReferencesLimited,(oid="")||(oid'=""&&('$Data(references(oid)))) {
										#; Child objects are part of the parent item and thefore
										#; already included in the list of references.
										#; Continue to search the child object for more references.
										Set references(oid)=""
										Set sc = ..GetReferences(oref, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
										If $$$ISERR(sc) Quit
									}
								}
							}
							If $$$ISERR(sc) Quit
						} ElseIf collection=$$$cPROPCOLLECTIONARRAY {
							Set key = ""
							For {
								Set oref = prop.GetNext(.key)
								If $IsObject(oref) {
									Set oid = oref.XMLGetElement(oref.%Id())
									If oid'="",'$Data(references(oid)) {
										If ReferenceDepth<=$$$qualifierGetValue(qstruct,"references") {
											If $$$qualifierGetValue(qstruct,"displaylog") {
												Write !, "Included item: ",$$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, , .qstruct)
											}
										} Else {
											Set ReferencesLimited = 1
										}
									}
									#; Stop searching for references if the depth limit has been reached.
									#; Continue to search serial objects for further references.
									#; Do not search an object that has already been searched.
									If 'ReferencesLimited,(oid="")||(oid'=""&&('$Data(references(oid)))) {
										#; Child objects are part of the parent item and thefore
										#; already included in the list of references.
										#; Continue to search the child object for more references.
										Set references(oid)=""
										Set sc = ..GetReferences(oref, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
										If $$$ISERR(sc) Quit
									}
								} Else {
									Quit
								}
							}
							If $$$ISERR(sc) Quit
						} Else {
							Set oref = prop
							If $IsObject(oref) {
								Set oid = oref.XMLGetElement(oref.%Id())
								If oid'="",'$Data(references(oid)) {
									If ReferenceDepth<=$$$qualifierGetValue(qstruct,"references") {
										If $$$qualifierGetValue(qstruct,"displaylog") {
											Write !, "Included item: ",$$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, , .qstruct)
										}
									} Else {
										Set ReferencesLimited = 1
									}
								}
								#; Stop searching for references if the depth limit has been reached.
								#; Continue to search serial objects for further references.
								#; Do not search an object that has already been searched.
								If 'ReferencesLimited,(oid="")||(oid'=""&&('$Data(references(oid)))) {
									Set references(oid)=""
									Set sc = ..GetReferences(oref, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
									If $$$ISERR(sc) Quit
								}
							}
						}
					}
				} ElseIf $$$classIsSerial(proptype) {
					#; Searching through serial objects for references to other items.
					If collection=$$$cPROPCOLLECTIONLIST {
						For n = 1:1:prop.Count() {
							Set oref = prop.GetAt(n)
							If $IsObject(oref) {
								Set sc = ..GetReferences(oref, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
								If $$$ISERR(sc) Quit
							}
						}
						If $$$ISERR(sc) Quit
					} ElseIf collection=$$$cPROPCOLLECTIONARRAY {
						Set key = ""
						For {
							Set oref = prop.GetNext(.key)
							If $IsObject(oref) {
								Set sc = ..GetReferences(oref, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
								If $$$ISERR(sc) Quit
							} Else {
								Quit
							}
						}
						If $$$ISERR(sc) Quit
					} Else {
						Set sc = ..GetReferences(prop, .references, .qstruct, ReferenceDepth, .ReferencesLimited)
					}
				}
			}
		}
		If $$$qualifierGetValue(qstruct,"displaylog"),header {
			If ReferencesLimited {
				Write !, "Reference check limited to "_$$$qualifierGetValue(qstruct,"references")_" step"_$Select($$$qualifierGetValue(qstruct,"references")>1:"s",1:"")_"."
			}
			#; Break up the output of included and exported items.
			Write !
		}
	}
	Quit sc
}

/// Oids potentially contain any character.  Therefore no delimited strings are supported.
ClassMethod normalizeItems(list As %String, ByRef items As %String) As %Status [ Private ]
{
	If $Data(items)#10 {
		If items'="" $$$xmlMemberSet(list, items)
		ZKill items
	}
	Set key = ""
	For {
		Set key = $o(items(key))
		If key = "" Quit
		$$$xmlMemberSet(list, key)
	}
	Quit $$$OK
}

/// Internal method to export a list of items to a file.
/// Items to be exported may be preloaded into the "selected" list.
ClassMethod exportItems(filename As %String, ByRef qspec As %String, ByRef items As %String, Charset As %String) As %Status [ Private ]
{
	#; %xmlExchangeItem is used to indicate items are being exported.
	#; During this process ChangeControl events will not be passed on.
	New %xmlExchangeItem
	Set %xmlExchangeItem = 1
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct)
	If $$$ISERR(sc) Quit sc
	Set xmlComment = $$$qualifierGetValue(qstruct,"exportcomment")
	Set writer=##class(%XML.Writer).%New()
	Set writer.Charset=Charset
	Set writer.Indent=1
	If filename'="" {
		Set sc=writer.OutputToFile(filename)
	}
	Do ..normalizeItems("selected",.items)
	#; For the duration of the item export this process will
	#; use a default concurrency setting of No Locking(0).
	Set defaultConcurrency = $$SetConcurrencyMode^%apiOBJ(0)
	If $$$ISOK(sc) {
		#; Optionally include a comment.
		If $Length(xmlComment) Set sc=writer.WriteComment(xmlComment)
		Set sc=writer.RootElement("XML.Exchange")
		If $$$ISOK(sc) {
			Set key = ""
			For  {
				$$$xmlMemberNext("selected",key,oid)
				If key = "" Quit 
								
				Set obj=$ZObjClassMethod($$$oidClassName(oid), "%Open", oid, 0)
				If $IsObject(obj) {
					#; Add extra information block.
					#; There is one block per item.
					#; Common usage is to include just one item in a file although the system supports more than one item.
					#; In the future an extra tag could be used to group the item and the associated extra details.
					Set info=##class(%XML.Exchange.Metadata).%New(obj)
					If $IsObject(info) {
						Set sc=writer.Object(info)
					} Else {
						Set sc=$System.Status.AppendStatus(%objlasterror,$$$ERROR($$$GeneralError, "Unable to gather metadata for item $lb("_$ListToString(oid,",")_")"))
						Quit
					}
					Set sc=writer.Object(obj,$$$oidClassName(oid))
				} Else {
					Set sc=$System.Status.AppendStatus(%objlasterror,$$$ERROR($$$GeneralError, "Unable to open item $lb("_$ListToString(oid,",")_")"))
					Quit
				}
				
				If $$$ISOK(sc), $$$qualifierGetValue(qstruct,"displaylog") {
					Write !,"Exported item: ",$$$oidClassName(oid), $Char(9), $$$oidPrimary(oid), $Char(9), ..GetName(oid, obj.GUID, .qstruct)
				}
			}
			If $$$ISOK(sc) {
				Set sc=writer.EndRootElement()
			}
		}
	}
	Do SetConcurrencyMode^%apiOBJ(defaultConcurrency)
	$$$xmlListKill("selected")
	Quit sc
}

/// Get full normalised path to the external file that would be exported to given a root directory.
/// Qualifiers can be used to indicate the naming convention to be used.
ClassMethod GetPath(Root As %String, Oid As %List, qspec As %String = "") As %String
{
	If Root = "" Quit ""
	
	Set sc=..qualifierParse("XML.Exchange",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	Set id = $$$oidPrimary(Oid)
	Set class = $$$oidClassName(Oid)
	Set path = Root
	Set subdir = $ClassMethod(class, "XMLExchangePath", id)
	If $$$isVMS {
		Set subdir=$Translate(subdir,"\/","..")
	} ElseIf $$$isWINDOWS {
		Set subdir=$Translate(subdir,"./","\\")
	} ElseIf $$$isUNIX {
		Set subdir=$Translate(directory,".\","//")
	}
	Set path = ##class(%File).SubDirectoryName(path,subdir,1)
	
	
	#; Build file name.
	Set filename = ..GetName(Oid,"",.qstruct)
	If filename = "" Quit ""
	Set filename = filename_".xml"
	
	Quit ##class(%File).NormalizeFilename(path_filename)
}

/// Returns the filename to be used for an item based on the selected qualifiers.
ClassMethod GetName(Oid As %List = "", Guid As %String = "", ByRef qstruct) As %String [ Private ]
{
	Set description = ""
	If $$$qualifierGetValue(qstruct,"name") [ "desc" {
		Set description = ..GetDescription(Oid)
	}
	Set guid = ""
	If $$$qualifierGetValue(qstruct,"name") [ "guid" {
		If Guid '= "" {
			Set guid = Guid
		} ElseIf Oid'="" {
			#; Get the GUID of the item.
			Set guid = $Get(^OBJ.GUID(1,Oid))
		}
	}
	#; Return name.
	Quit description_$Select(guid="":"",description="":guid,1:" "_guid)
}

/// Returns a description to be used for the element.
/// This value is based on the objects XMLExchangeName method.
ClassMethod GetDescription(Oid As %String) As %String
{
	#; Characters that should not be used in file names.
	#define InvalidChars "\/:*?""""<>| "
	#; Restrict the length of the description used in the file name.
	#define MaxDescriptionLength 64
	
	Set id = $$$oidPrimary(Oid)
	Set class = $$$oidClassName(Oid)
	
	#; Get a description of the item.
	Set description = $ClassMethod(class,"XMLExchangeName",id)
	
	#; Strip white space, control characters and invalid characters from the description.
	Set description = $Extract($ZStrip(description,"*WC",$$$InvalidChars),1,$$$MaxDescriptionLength)
	
	Quit description
}

/// This method will assign GUIDs to all Exchange Items of the system without a GUID.
ClassMethod AssignGUIDs() As %Status
{
	Write !!,"GUID allocation started "_$ZDateTime($Horolog)
	Set started = $ZHorolog
	Set sc=$$GetAllDerivedClasses^%occLibrary("%XML.Exchange.Adaptor",.dependency)
	If $$$ISOK(sc) {
		Set class = "", joblist = ""
		For  {
			Set class = $Order(dependency(class))
			If class = "" Quit
			
			If $ZObjClassMethod(class, "%GetParameter", "GUIDENABLED") {
				Job ##class(%Library.GUID).AssignGUID(class)
				Set joblist = joblist_$ListBuild($ZChild)
				Write !, class_" ("_$ZChild_")"
			}
		}
		#; Report job status.
		#; Assume all jobs running to begin with.
		Set running = $ListLength(joblist)
		For  {
			Set count = 0
			For i=1:1:$ListLength(joblist) {
				Set job = $ListGet(joblist,i)
				If job '= "" {
					If $Data(^$Job(job)) {
						If $Increment(count)
					} Else {
						Set $List(joblist,i) = ""
					}
				}
			}
			If count = 0 Quit
			If count '= running {
				Set running = count
				Write !, count_" processes running"
			}
			Hang 1
		}
	}
	Set seconds = $FNumber($ZHorolog - started,"",3)
	Set hours = seconds\3600
	Set minutes = (seconds#3600)\60
	Set seconds = seconds#60
	Set duration = $Select(hours:hours_"h ",1:"")_$Select(minutes:minutes_"m ",1:"")_$Select(seconds:seconds_"s ",1:"")
	Write !, "GUID allocation finished in "_duration_"."
	Quit sc
}

/// This method looks for inconsistencies in the GUID allocation.
/// It may optionally correct problems if possible.
/// <br>
/// The identifiable issues and their resolutions are:<ul>
///  <li> GUID entry missing OID cross reference<ul>
///        <li> If the object exists then add the OID cross reference
///        <li> If the object does not exist then remove the GUID entry </ul>
///  <li> GUID entry conflicts with OID cross reference<ul>
///        <li> Manual intervention required </ul>
///  <li> GUID entry for missing object<ul>
///        <li> Remove both the GUID entry and the OID cross reference </ul>
///  <li> GUID entry for missing class<ul>
///        <li> Remove both the GUID entry and the OID cross reference </ul>
///  <li> OID cross reference missing GUID entry<ul>
///        <li> If the object exists add the GUID entry
///        <li> If the object does not exist remove the OID cross reference </ul>
///  <li> OID cross reference conflicts with GUID entry<ul>
///        <li> Manual intervention required </ul>
/// </ul><br>
/// The method will output results as the check proceeds and show a tally
/// when the check is complete.
ClassMethod CheckGUIDs(ApplyChange As %Boolean = 0) As %Status
{
	Write !, "GUID allocation check started "_$ZDateTime($Horolog)
	Set started = $ZHorolog
	
	#; Search for GUIDs which do not have a matching OID entry.
	Set guid=""
	For  {
		Set guid=$Order(^OBJ.GUID(0,guid),1,oid)
		If guid="" Quit
		
		If '$Data(^OBJ.GUID(1,oid)) {
			Write !, "GUID entry missing OID cross reference:", !
			ZWrite ^OBJ.GUID(0,guid)
			If $Increment(issueCount),$Increment(issueCount("MissingOID"))
			If ApplyChange {
				If $ClassMethod($$$oidClassName(oid),"%ExistsId",$$$oidPrimary(oid)) {
					Set ^OBJ.GUID(1,oid)=guid ##; noalert
					Write !, "^OBJ.GUID(1,$lb("""_$ListToString(oid,""",""")_""") added"
					If $Increment(changeCount)
				} Else {
					Kill ^OBJ.GUID(0,guid)
					Write !, "^OBJ.GUID(0,"""_guid_""") removed"
					If $Increment(changeCount)
					#; Proceed to next guid.
					Continue
				}
			}
		} ElseIf $Get(^OBJ.GUID(1,oid))'=guid {
			Write !, "GUID entry conflicts with OID cross reference:", !
			ZWrite ^OBJ.GUID(0,guid)
			If $Increment(issueCount),$Increment(issueCount("ConflictingOID"))
		}
		#; Check the object exists.
		If ##class(%Dictionary.CompiledClass).%ExistsId($$$oidClassName(oid)) {
			If '$ClassMethod($$$oidClassName(oid),"%ExistsId",$$$oidPrimary(oid)) {
				Write !, "GUID entry for missing object:", !
				ZWrite ^OBJ.GUID(0,guid)
				If $Increment(issueCount),$Increment(issueCount("MissingObject"))
				If ApplyChange {
					Kill ^OBJ.GUID(0,guid)
					Write !, "^OBJ.GUID(0,"""_guid_""") removed"
					Kill ^OBJ.GUID(1,oid)
					Write !, "^OBJ.GUID(1,$lb("""_$ListToString(oid,""",""")_""") removed"
					If $Increment(changeCount)
				}
			}
		} Else {
			Write !, "GUID entry for missing class:", !
			ZWrite ^OBJ.GUID(0,guid)
			If $Increment(issueCount),$Increment(issueCount("MissingClass"))
			If ApplyChange {
				Kill ^OBJ.GUID(0,guid)
				Write !, "^OBJ.GUID(0,"""_guid_""") removed"
				Kill ^OBJ.GUID(1,oid)
				Write !, "^OBJ.GUID(1,$lb("""_$ListToString(oid,""",""")_""") removed"
				If $Increment(changeCount)
			}
		}
	}
	
	#; Search for OIDs which do not have a matching GUID entry.
	Set oid=""
	For  {
		Set oid=$Order(^OBJ.GUID(1,oid),1,guid)
		If oid="" Quit
		
		If '$Data(^OBJ.GUID(0,guid)) {
			Write !, "OID cross reference missing GUID entry:", !
			ZWrite ^OBJ.GUID(1,oid)
			If $Increment(issueCount),$Increment(issueCount("MissingGUID"))
			If ApplyChange {
				If $ClassMethod($$$oidClassName(oid),"%ExistsId",$$$oidPrimary(oid)) {
					Set ^OBJ.GUID(0,guid)=oid ##; noalert
					Write !, "^OBJ.GUID(0,"""_guid_""") added"
					If $Increment(changeCount)
				} Else {
					Kill ^OBJ.GUID(1,oid)
					Write !, "^OBJ.GUID(1,$lb("""_$ListToString(oid,""",""")_""") removed"
					If $Increment(changeCount)
				}
			}
		} ElseIf $Get(^OBJ.GUID(0,guid))'=oid {
			Write !, "OID cross reference conflicts with GUID entry:", !
			ZWrite ^OBJ.GUID(1,oid)
			If $Increment(issueCount),$Increment(issueCount("ConflictingGUID"))
		}
	}
	
	#; Calculate duration
	Set seconds = $FNumber($ZHorolog - started,"",3)
	Set hours = seconds\3600
	Set minutes = (seconds#3600)\60
	Set seconds = seconds#60
	Set duration = $Select(hours:" "_hours_"h",1:"")_$Select(minutes:" "_minutes_"m",1:"")_$Select(seconds:" "_seconds_"s",1:"")
	Write !, "GUID allocation check finished in "_duration_"."
	
	Set firstCol = 40, secondCol = 10
	Write !,$Justify(+$Get(issueCount)_" issues found", firstCol)
	Set key = ""
	For  {
		Set key = $Order(issueCount(key))
		If key = "" Quit
		Write !, $Justify(+$Get(issueCount(key))_" "_key, firstCol+secondCol)
	}
	Write !,$Justify(+$Get(changeCount)_" issues corrected", firstCol)
	Write !
}

/// Initialise Qualifier details
ClassMethod initQualifier(group As %String, ByRef qtable As %String) [ Private ]
{
	#; XML.Exchange additions in $$$QUALIFIERROOT format.
	If group = "XML.Exchange" {
		Set qtable("XML.Exchange","loadguids")=""
		Set qtable("XML.Exchange","loadguids","default")=0
		Set qtable("XML.Exchange","loadguids","description")="Use unique indices to assign GUIDs from XML." _ $Char(13,10) _
		"If the class definition of a Exchange Item contains one or more unique indices and all the properties from the XML match an existing Exchange Item the GUID from the XML will be assigned to the existing Exchange Item."
		Set qtable("XML.Exchange","loadguids","enumlist")="0,1"
		Set qtable("XML.Exchange","loadguids","negated")=0
		Set qtable("XML.Exchange","loadguids","present")=1
		Set qtable("XML.Exchange","loadguids","type")="logical"
		
		Set qtable("XML.Exchange","exportcomment")=""
		Set qtable("XML.Exchange","exportcomment","default")=""
		Set qtable("XML.Exchange","exportcomment","description")=" When exporting items include this value as an XML comment in each file."
		Set qtable("XML.Exchange","exportcomment","type")="string"
		
		Set qtable("XML.Exchange","display")=""
		Set qtable("XML.Exchange","display","alias","error")="displayerror"
		Set qtable("XML.Exchange","display","alias","log")="displaylog"
		Set qtable("XML.Exchange","display","aliaslist")="displayerror,displaylog"
		Set qtable("XML.Exchange","display","all")="all"
		Set qtable("XML.Exchange","display","description")="Alias qualifier for /displaylog and displayerror."
		Set qtable("XML.Exchange","display","enumlist")="error,log"
		Set qtable("XML.Exchange","display","negated")="none"
		Set qtable("XML.Exchange","display","none")="none"
		Set qtable("XML.Exchange","display","present")="all"
		Set qtable("XML.Exchange","display","type")="alias"

		Set qtable("XML.Exchange","displayerror")=""
		Set qtable("XML.Exchange","displayerror","default")=1
		Set qtable("XML.Exchange","displayerror","description")="Display error information."
		Set qtable("XML.Exchange","displayerror","enumlist")="0,1"
		Set qtable("XML.Exchange","displayerror","flag",0)="-d"
		Set qtable("XML.Exchange","displayerror","flag",1)="+d"
		Set qtable("XML.Exchange","displayerror","negated")=0
		Set qtable("XML.Exchange","displayerror","present")=1
		Set qtable("XML.Exchange","displayerror","type")="logical"

		Set qtable("XML.Exchange","displaylog")=""
		Set qtable("XML.Exchange","displaylog","default")=1
		Set qtable("XML.Exchange","displaylog","description")="Display log information."
		Set qtable("XML.Exchange","displaylog","enumlist")="0,1"
		Set qtable("XML.Exchange","displaylog","flag",0)="-d"
		Set qtable("XML.Exchange","displaylog","flag",1)="+d"
		Set qtable("XML.Exchange","displaylog","negated")=0
		Set qtable("XML.Exchange","displaylog","present")=1
		Set qtable("XML.Exchange","displaylog","type")="logical"
		
		Set qtable("XML.Exchange","name")=""
		Set qtable("XML.Exchange","name","default")="descandguid"
		Set qtable("XML.Exchange","name","description")="The name can be the description, GUID or the description concatenated by the GUID." _ $Char(13,10) _
		"The name is used as the file name when exporting and by the display log output."
		Set qtable("XML.Exchange","name","enumlist")="desc,guid,descandguid"
		Set qtable("XML.Exchange","name","negated")="guid"
		Set qtable("XML.Exchange","name","present")="descandguid"
		Set qtable("XML.Exchange","name","type")="enum"
		
		Set qtable("XML.Exchange","force")=""
		Set qtable("XML.Exchange","force","default")=0
		Set qtable("XML.Exchange","force","description")="Load Exchange Items that contain unresolved GUID references or replace existing GUID when used in conjunction with /loadguids."
		Set qtable("XML.Exchange","force","enumlist")="0,1"
		Set qtable("XML.Exchange","force","negated")=0
		Set qtable("XML.Exchange","force","present")=1
		Set qtable("XML.Exchange","force","type")="logical"
		
		Set qtable("XML.Exchange","references")=""
		Set qtable("XML.Exchange","references","default")=1
		Set qtable("XML.Exchange","references","description")="Recursively include referenced Exchange Items.  The value is the maximum number of steps that will be made from the specified Exchange Items."
		Set qtable("XML.Exchange","references","type")="string"
		
		Set qtable("XML.Exchange","onlyfirst")=""
		Set qtable("XML.Exchange","onlyfirst","default")=0
		Set qtable("XML.Exchange","onlyfirst","description")="Export just one Exchange Item from each table.  This qualifier can be used with the ExportAllDir or ExportTableDir methods."
		Set qtable("XML.Exchange","onlyfirst","enumlist")="0,1"
		Set qtable("XML.Exchange","onlyfirst","negated")=0
		Set qtable("XML.Exchange","onlyfirst","present")=1
		Set qtable("XML.Exchange","onlyfirst","type")="logical"
		
		Set qtable("XML.Exchange","overwrite")=""
		Set qtable("XML.Exchange","overwrite","default")=0
		Set qtable("XML.Exchange","overwrite","description")="Replace existing files with exported Exchange Items."
		Set qtable("XML.Exchange","overwrite","enumlist")="0,1"
		Set qtable("XML.Exchange","overwrite","negated")=0
		Set qtable("XML.Exchange","overwrite","present")=1
		Set qtable("XML.Exchange","overwrite","type")="logical"
		
		Set qtable("XML.Exchange","update")=""
		Set qtable("XML.Exchange","update","default")=0
		Set qtable("XML.Exchange","update","description")="Only update properties specified in the XML.  Properties not included in the XML will not be modified."
		Set qtable("XML.Exchange","update","enumlist")="0,1"
		Set qtable("XML.Exchange","update","negated")=0
		Set qtable("XML.Exchange","update","present")=1
		Set qtable("XML.Exchange","update","type")="logical"
		
		Set qtable("XML.Exchange","validate")=""
		Set qtable("XML.Exchange","validate","default")=0
		Set qtable("XML.Exchange","validate","description")="Check exported Exchange Items can be loaded."
		Set qtable("XML.Exchange","validate","enumlist")="0,1"
		Set qtable("XML.Exchange","validate","negated")=0
		Set qtable("XML.Exchange","validate","present")=1
		Set qtable("XML.Exchange","validate","type")="logical"
		
		Set qtable("XML.Exchange","validateregistered")=""
		Set qtable("XML.Exchange","validateregistered","default")=0
		Set qtable("XML.Exchange","validateregistered","description")="Check that registered objects pass validation."
		Set qtable("XML.Exchange","validateregistered","enumlist")="0,1"
		Set qtable("XML.Exchange","validateregistered","negated")=0
		Set qtable("XML.Exchange","validateregistered","present")=1
		Set qtable("XML.Exchange","validateregistered","type")="logical"
		
		Set qtable("XML.Exchange","bypassccr")=""
		Set qtable("XML.Exchange","bypassccr","default")=1
		Set qtable("XML.Exchange","bypassccr","description")="Bypass CCR."
		Set qtable("XML.Exchange","bypassccr","enumlist")="0,1"
		Set qtable("XML.Exchange","bypassccr","negated")=0
		Set qtable("XML.Exchange","bypassccr","present")=1
		Set qtable("XML.Exchange","bypassccr","type")="logical"
		
		#; Use system wide defaults when available
		If $Data($$$QUALIFIER("group","XML.Exchange")) {
			Merge qtable("XML.Exchange") = $$$QUALIFIER("group","XML.Exchange")
		}
	}
}

/// Display the list of qualifiers defined in the system.
ClassMethod ShowQualifiers(group As %String = "XML.Exchange")
{
	#; This method is based on %SYSTEM.OBJ.cls
	
	#; Get the Configuration Management qualifier table
	Do ..initQualifier(group, .qtable)
	
	#; Qualifier macros must refer to the local table.
	#def1arg QUALIFIER(%args)                   qtable(%args)
	#;
	#define QUALIFIERtype(%group,%name)         qtable(%group,%name,"type")
	#define QUALIFIERdescription(%group,%name)  qtable(%group,%name,"description")
	#define QUALIFIERaliaslist(%group,%name)    qtable(%group,%name,"aliaslist")
	#define QUALIFIERenumlist(%group,%name)     qtable(%group,%name,"enumlist")
	#define QUALIFIERdefaultvalue(%group,%name) qtable(%group,%name,"default")
	#define QUALIFIERnegatedvalue(%group,%name) qtable(%group,%name,"negated")
	#define QUALIFIERpresentvalue(%group,%name) qtable(%group,%name,"present")
	#define QUALIFIERallvalue(%group,%name)     qtable(%group,%name,"all")
	#define QUALIFIERnonevalue(%group,%name)    qtable(%group,%name,"none")
	#define QUALIFIERalias(%group,%name,%value) qtable(%group,%name,"alias",%value)
	
	If group="" Do  Quit
	. For  Set group=$Order($$$QUALIFIER(group)) Quit:group=""  Do ..ShowQualifiers(group)
	;
	If $Data($$$QUALIFIER(group))=0 Write "Qualifier Group "_group_" does not exist.",!! Quit
	;
	Write "=================",!
	Write "Qualifier Group: "_group,!
	Write "=================",!
	Set qname="" For  Set qname=$Order($$$QUALIFIER(group,qname)) Quit:qname=""  Do  Write !
	. Set type=$$$QUALIFIERtype(group,qname)
	. Write "           Name: /",qname,!
	. Write "    Description: ",$$$QUALIFIERdescription(group,qname),!
	. Write "           Type: ",type,!
	. If $Extract($Get($$$QUALIFIERflagequivalence(group,qname,1)),2,*)'="" Do
	. . Write "           Flag: ",$Extract($$$QUALIFIERflagequivalence(group,qname,1),2,*),!
	. ;
	. If type="logical" Do  Quit
	. . Write "  Default Value: ",$$$QUALIFIERdefaultvalue(group,qname),!
	. ;
	. If type="enum" Do  Quit
	. . Write "      Enum List: ",$$$QUALIFIERenumlist(group,qname),!
	. . Write "  Default Value: ",$$$QUALIFIERdefaultvalue(group,qname),!
	. . Write "  Present Value: ",$$$QUALIFIERpresentvalue(group,qname),!
	. . Write "  Negated Value: ",$$$QUALIFIERnegatedvalue(group,qname),!
	. ;
	. If type="alias" Do  Quit
	. . Write "      Enum List: ",$$$QUALIFIERenumlist(group,qname),!
	. . Write "     Alias List: ",$$$QUALIFIERaliaslist(group,qname),!
	. . Write "  Present Value: ",$Select($Data($$$QUALIFIERpresentvalue(group,qname))=0:"(none)",1:$$$QUALIFIERpresentvalue(group,qname)),!
	. . Write "  Negated Value: ",$Select($Data($$$QUALIFIERnegatedvalue(group,qname))=0:"(none)",1:$$$QUALIFIERnegatedvalue(group,qname)),!
	. . Write "      All Value: ",$$$QUALIFIERallvalue(group,qname),!
	. . Write "     None Value: ",$$$QUALIFIERnonevalue(group,qname),!
	. ;
	Quit
}

/// Parse Qualifier details
ClassMethod qualifierParse(group As %String, qspec As %String = "", ByRef qstruct As %String) [ Private ]
{
	#; This method is based on %occQualifiers.mac
	
	#; Get the Configuration Management qualifier table
	Do ..initQualifier(group, .qtable)
	
	#; Qualifier macros must refer to the local table.
	#def1arg QUALIFIER(%args)                   qtable(%args)
	#;
	#define QUALIFIERtype(%group,%name)         qtable(%group,%name,"type")
	#define QUALIFIERdescription(%group,%name)  qtable(%group,%name,"description")
	#define QUALIFIERaliaslist(%group,%name)    qtable(%group,%name,"aliaslist")
	#define QUALIFIERenumlist(%group,%name)     qtable(%group,%name,"enumlist")
	#define QUALIFIERdefaultvalue(%group,%name) qtable(%group,%name,"default")
	#define QUALIFIERnegatedvalue(%group,%name) qtable(%group,%name,"negated")
	#define QUALIFIERpresentvalue(%group,%name) qtable(%group,%name,"present")
	#define QUALIFIERallvalue(%group,%name)     qtable(%group,%name,"all")
	#define QUALIFIERnonevalue(%group,%name)    qtable(%group,%name,"none")
	#define QUALIFIERalias(%group,%name,%value) qtable(%group,%name,"alias",%value)
	
	Set sc=$$qualifierGetDefault(group,.qstruct) Quit:$$$ISERR(sc) sc
	
	For q=2:1:$Length(qspec,"/") Do  Quit:$$$ISERR(sc)
	. Set qspecone=$Piece(qspec,"/",q)
	. Set qname=$ZConvert($Piece(qspecone,"=",1),"l")
	. Kill value If qspecone["=" Set value=$Piece(qspecone,"=",2,*)
	. ;
	. Set negated=0 If $Extract(qname,1,2)="no" Do  Quit:$$$ISERR(sc)
	. . Set qname=$Extract(qname,3,*)
	. . Set sc=$$matchName(group,.qname) Quit:$$$ISERR(sc)
	. . If $Data(value) Set sc=$$$ERROR($$$GeneralError,"can not mix negated form with value: "_qspecone) Quit
	. . If $Data($$$QUALIFIERnegatedvalue(group,qname))=0 Set sc=$$$ERROR($$$GeneralError,"qualifier "_qname_" can not be negated") Quit
	. . Set negated=1
	. ;
	. Set sc=$$matchName(group,.qname) Quit:$$$ISERR(sc)
	. ;
	. If $Data(value)=0 Do  Quit:$$$ISERR(sc)
	. . If negated Set value=$$$QUALIFIERnegatedvalue(group,qname) Quit
	. . If $Data($$$QUALIFIERpresentvalue(group,qname))=0 Set sc=$$$ERROR($$$GeneralError,"qualifier "_qname_" value required") Quit
	. . Set value=$$$QUALIFIERpresentvalue(group,qname)
	. ;
	. Set type=$$$QUALIFIERtype(group,qname)
	. ;
	. If (type="logical")||(type="enum") Do  Quit
	. . If $$isOneOf($$$QUALIFIERenumlist(group,qname),value) Set qstruct(qname)=value
	. . Else  Set sc=$$$ERROR($$$GeneralError,"Value of qualifier /"_qname_" is invalid")
	. ;
	. If (type="alias") Do  Quit
	. . For i=1:1:$Length(value,",") Do  Quit:$$$ISERR(sc)
	. . . Set onevalue=$Piece(value,",",i)
	. . . If (onevalue=$$$QUALIFIERallvalue(group,qname))||(onevalue=$$$QUALIFIERnonevalue(group,qname)) Do  Quit
	. . . . Set v="" For  Set v=$Order($$$QUALIFIERalias(group,qname,v)) Quit:v=""  Do
	. . . . . Set ispresent=(onevalue=$$$QUALIFIERallvalue(group,qname))
	. . . . . Set qstruct($$$QUALIFIERalias(group,qname,v))=ispresent
	. . . If $$isOneOfMask($$$QUALIFIERenumlist(group,qname),.onevalue,.ispresent)
	. . . Else  Set sc=$$$ERROR($$$GeneralError,"Value of qualifier /"_qname_" is invalid") Quit
	. . . Set qstruct($$$QUALIFIERalias(group,qname,onevalue))=ispresent
	. ;
	. If (type="string") Do  Quit
	. . Set qstruct(qname)=value
	. Set sc=$$$ERROR($$$GeneralError,"Internal error, invalid qualifier type encountered.")
	;
	If $$$ISERR(sc) Quit sc
	Quit sc
	
qualifierGetDefault(group,qstruct)
	Set sc=$$$OK
	Set qname="" For  Set qname=$Order($$$QUALIFIER(group,qname)) Quit:qname=""  Do  Quit:$$$ISERR(sc)
	. If ($$$QUALIFIERtype(group,qname)="alias") Quit
	. Set qstruct(qname)=$Get($$$QUALIFIERdefaultvalue(group,qname))
	If $ZUtil(12)=$ZUtil(12,"") {
		If group="Compiler" Set qstruct("checksysutd")=1
		If group="Export" Set qstruct("diffexport")=1
	}
	Quit sc
	
matchName(group,qname)
	If $Data($$$QUALIFIER(group,qname)) Quit $$$OK
	Set next1=$Order($$$QUALIFIER(group,qname)),next2=$Order($$$QUALIFIER(group,next1))
	Set length=$Length(qname)
	If $Extract(next1,1,length)=qname,$Extract(next2,1,length)'=qname Set qname=next1 Quit $$$OK
	Quit $$$ERROR($$$GeneralError,"qualifier "_qname_" does not exist")

isOneOf(enumlist,value)
	Set isoneof=0
	For i=1:1:$Length(enumlist,",") If value=$Piece(enumlist,",",i) Set isoneof=1 Quit
	Quit isoneof

isOneOfMask(enumlist,value,ispositive)
	Set isoneof=0
	For i=1:1:$Length(enumlist,",") Do  Quit:isoneof
	. If value=$Piece(enumlist,",",i) Set isoneof=1,ispositive=1
	. If $Extract(value,1,2)="no",$Extract(value,3,$Length(value))=$Piece(enumlist,",",i) Set value=$Extract(value,3,$Length(value)),isoneof=1,ispositive=0
	Quit isoneof
}

}
