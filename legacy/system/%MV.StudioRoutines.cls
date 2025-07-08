/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include LANG11

Class %MV.StudioRoutines Extends %Studio.AbstractDocument [ ServerOnly = 1, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentDescription = "MultiValue Basic Routine ", DocumentExtension = "mvb", DocumentNew = 0, DocumentType = "mvb");

ClassMethod ItemList(Idx As %Integer, Ext As %String, ByRef Work As %String, Start As %String, End As %String, Directory As %String, Sort As %Integer, System As %Boolean, Flat As %Boolean, ShowGenerated As %Boolean, ByRef NewFormat As %Boolean) As %Status
{
	Set NewFormat=1
	#; dont continue unless we are requesting MVB files
	#; zw Work,Start,End,Directory,Ext
	If 'Flat,$ZCVT(Ext,"l")'="mvb" Quit $$$OK
	#; If MV has never been initialized, don't look for MV files
	If '$D($$$SYSTEMFileName) Quit $$$OK
	// See if we have a VOC, can't have any MV files without a VOC
	If '$D($$$VOCFileName){ Quit $$$OK}
	Do MVEnableInit^%SYS.MV()
	// The FileName and Program Name will be separated with "~"
	Set DELIM="~"
	Set SECTDELIM="|"
	// create some objects
	Set vocObj = $$$NewFileVariable
	Set voclistObj = $$$NewSelectList
	Set fileObj = $$$NewFileVariable
	Set listObj = $$$NewSelectList
	#;
	#; 
	If Directory'="" {
  		#; w "<<diag>>List Directory "_Directory,!
		#;
		#; list of all items in a specific file
		#;
  		Set Directory = $CHANGE(Directory,SECTDELIM,",")
		$$$MVIOPEN(rc,fileObj,"",Directory,0)
		#; If this isn't a MV file just Quit
		Quit:rc $$$OK
		$$$MVISELECT(rc,fileObj,listObj,"") 
		Quit:rc $$$OK
		For {
			$$$MVREADNEXT(rc,id,listObj) Quit:rc
			Set:id'=$char(0) ca(Directory,id)=id_".mvb"
		}
	} Else {
		#; start at the VOC
		#;
		$$$MVIOPEN(rc,vocObj,"","VOC",0)
		if rc {w "Failed to open VOC for list "_rc Quit $$$OK }
		
		$$$MVISELECT(rc,vocObj,voclistObj,"")
		if rc {w "Failed to select VOC for list "_rc Quit $$$OK }
		For {
			$$$MVREADNEXT(rc,file,voclistObj)
			Quit:rc
			$$$MVREAD(rc,VOCItem,vocObj,file,0,0)
			Continue:rc
			// see if this is a file 
			If $CASE($E($MV(VOCItem,1),1),"F":1,"Q":1,:0),$Find($MV(VOCItem,6),"B")
			{
				// VOC Item is a F or Q pointer
				Kill fileArray
				Set fileArray(file)=file
				If 'Flat,file'=$$$DEFAULTPROGRAMFILE {
					Set ^||%RoutineList(Idx,0,file_$char(0)_$i(%insertidx))=$listbuild(file,DELIM,15,"","","")
				}
				If $E($MV(VOCItem,4),1) = "M" {
					For i=1:1:99 {
						Set dsect=$MV(VOCItem,7,i)
						Quit:dsect=""
						Set fileArray(file_SECTDELIM_dsect)=file_","_dsect
						Set:'Flat ^||%RoutineList(Idx,0,file_SECTDELIM_dsect_$char(0)_$i(%insertidx))=$listbuild(file_SECTDELIM_dsect,DELIM,15,"","","")
					}
				}
				If Flat {
					Set filekey=""
					For {
						Set filekey = $O(fileArray(filekey),1,file)
						Quit:filekey=""
						// list of all items in file
						$$$MVIOPEN(rc,fileObj,"",file,0)
						#; If this isn't a MV file just Quit 
						Continue:rc 
						$$$MVISELECT(rc,fileObj,listObj,"") Continue:rc 
						For {
							$$$MVREADNEXT(rc,id,listObj) Quit:rc
							Set:id'=$char(0) ca(filekey,id)=filekey_DELIM_id_".mvb"
						}
					}
				}
			}
		}		
		#; process top level "BP" routines
		$$$MVIOPEN(rc,fileObj,"",$$$DEFAULTPROGRAMFILE,0)
		If 'rc {
			$$$MVISELECT(rc,fileObj,listObj,"") 
			For {
				$$$MVREADNEXT(rc,id,listObj) Quit:rc
				Set:id'=$char(0) ca($$$DEFAULTPROGRAMFILE,id)=id_".mvb"
			}
		}
	}
	// apply filters and generate %RoutineList
	Set filekey = ""
	For {
		Set filekey=$order(ca(filekey))
		Quit:filekey=""
		Set Dir= $S(filekey=$$$DEFAULTPROGRAMFILE:"",1:filekey_DELIM)
		Set id = ""
		For {
			Set id=$order(ca(filekey,id))
			Quit:id=""
			Set i="" 
			For {
				Set i=$order(Work(i),1,work)
				Quit:i=""
				If work'=$ListBuild("","","") {
					Set pattern=$list(work),start=$list(work,2),end=$list(work,3)
					If start=""||(start']id),end=""||($extract(id,1,$length(end))']end),pattern=""||(id?@pattern) {
			 			Set ^||%RoutineList(Idx,1,Dir_id_$char(0)_$i(%insertidx))=$listbuild(ca(filekey,id),DELIM,11,"","","")
					}
				} else {
		 			Set ^||%RoutineList(Idx,1,Dir_id_$char(0)_$i(%insertidx))=$listbuild(ca(filekey,id),DELIM,11,"","","")
				}
			}
		}
	}
 	Quit $$$OK
}

ClassMethod OpenProgramFile(ByRef sourceFileObj, ByRef prog As %String, name As %String, createFlg As %Boolean) As %Status
{
  	#; w "<<diag>>Openfile "_name,!
	// See if we have a VOC, can't have any MV files without a VOC
 	If '$D($$$VOCFileName),'createFlg Quit $$$MVFIOENoFile
	Do MVEnableInit^%SYS.MV()
	// The FileName and Program Name will be separated with "~"
	Set DELIM="~"
	Set SECTDELIM="|"
	// Must be in format File~Program.mvb
	// If the filename is missing use the name BP
	If $L(name,DELIM)<2 {
		Set file 	= $$$DEFAULTPROGRAMFILE
		Set prog	= name
	} elseIf $L(name,SECTDELIM)>1 {
		Set sectname	= $P(name,SECTDELIM,2,9)
		Set file 	=  $P(name,SECTDELIM,1)_","_$P(sectname,DELIM,1)
		Set prog	= $P(sectname,DELIM,2)
	} else {
		Set file 	=  $P(name,DELIM,1)
		Set prog	= $P(name,DELIM,2)
	}
	set $$$MVBfilename = file
	$$$MVIOPEN(rc,sourceFileObj,"",$$$MVBfilename,0)
	If rc,createFlg {
	    #;
	    #; Create the $$$MVBfilename file
	    #;
	    W !,"Creating file "_$$$MVBfilename
	    Do InternalCreateFile^%SYS.MV($$$MVBfilename,$$$MVFIOTypeInode,"B")
	    $$$MVIOPEN(rc,sourceFileObj,"",$$$MVBfilename,0)
	}
	Set prog = $P(prog,$s(prog[".MVB":".MVB", prog[".mvb":".mvb", 1:" "), 1)
	If $$$FileVarOptions(sourceFileObj)["X" {
		Set prog = prog_".mvb"
	}
	Quit:rc rc ; failed to open the file
	Quit 0
}

/// Delete the routine 'name' which includes the routine extension
ClassMethod Delete(name As %String) As %Status
{
	#; w "<<diag>>delete"_name,!
	Set prog="",sourceFileObj=$$$NewFileVariable
	Set status=..OpenProgramFile(.sourceFileObj,.prog,name,0) Quit:status $$$ERROR($$$FileNotFound,name)
	If name["." {Set ext=$ZCvt($Piece(name,".",$Length(name,".")),"U")} Else {Set ext="mvb"}
	If prog["~" {Set progx=prog} Else {Set progx=$$$DEFAULTPROGRAMFILE_"~"_prog}
	#; find the MVI code
	If ($D($$$OBJFileName($$$MVBfilename,prog),rtn)#10) {
		Kill ^ROUTINE(rtn)
		Kill ^rINDEX(rtn,"MVI")
		Kill ^rOBJ(rtn)
	}
	Do RemoveMap^%qarmac(progx,ext)
	$$$MVDELETE(rc,sourceFileObj,prog,0) Quit:rc $$$OK
	Quit $$$OK
}

///   Return the timestamp of routine 'name' in %TimeStamp format. This is used to determine if the routine has
///   been updated on the server and so needs reloading from Studio. So the format should be $zdatetime($horolog,3),
///   or "" if the routine does not exist.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
	#; w "<<diag>>TimeStamp "_name,!
	Set prog="",sourceFileObj=$$$NewFileVariable 
	Set rc=..OpenProgramFile(.sourceFileObj,.prog,name,0) Quit:rc ""
	If $$$FileVarStorageType(sourceFileObj)=$$$MVFIOTypeDir {
		Quit $ZUTIL(140,2,$$$FileVarGlobal(sourceFileObj),0)
	}
	Quit "2000-01-01 12:01:00"
}

/// Return 1 if the routine 'name' exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	#; w "<<diag>>Checkexists "_name,!
	Set prog="",sourceFileObj=$$$NewFileVariable 
	Set rc=..OpenProgramFile(.sourceFileObj,.prog,name,0) Quit:rc 0
	$$$MVREAD(rc,src,sourceFileObj,prog,1,0) Quit:rc 0
	Quit 1
}

/// Load the document
Method Load() As %Status
{
	#; The FileName and Program Name will be separated with "~"
	#; w !,"<<diag>>Load "_..Name,!
	Set ..LineTerminator=$c(10) 
	Set name = ..Name,prog="",sourceFileObj=$$$NewFileVariable 
	Set status=..OpenProgramFile(.sourceFileObj,.prog,name,1) Quit:status $$$ERROR($$$FileNotFound,name)
	#; w "<<diag>>prog= "_prog,!
	// Read the program source or file 
	$$$MVREAD(rc,src,sourceFileObj,prog,0,0) Quit:rc'=0 $$$OK
	#; w "<<diag>>loading "_prog,!
	Do ..Clear()
	For i=1:1:$L(src,$$$MVam)	Do ..WriteLine($MV(src,i))
	Quit $$$OK
}

/// Save the routine stored in Code
Method Save() As %Status
{
	Set name = ..Name,prog="",sourceFileObj=$$$NewFileVariable
	#; w "<<diag>>Save "_name,!
	Do MVEnableInit^%SYS.MV()
	Set ..Code.LineTerminator=$c(10) 
	Set status=..OpenProgramFile(.sourceFileObj,.prog,name,1) Quit:status $$$ERROR($$$FileNotFound,name)
	#; Start with src'="" so blank first line(s) will not be lost. See CDS1169.
	Set source=..Code,src="x"
	Do source.Rewind()
	While '(source.AtEnd) {
		Set $MV(src,-1::1) = $ZSTRIP(source.ReadLine(),"*",$Char(13)) 
	}
	$$$MVWRITE(rc,sourceFileObj,prog,$E(src,3,*),0,0) Quit:'rc $$$OK
	Write !,"Error saving program ",..Name,! 
	Write:rc=5001 "Unable to write to directory file",!
	Quit $$$ERROR($$$CannotWriteToTarget)
}

/// Compile the routine
Method CompileDocument(ByRef qstruct As %String) As %Status
{
	Set name = ..Name,prog="",sourceFileObj=$$$NewFileVariable
	Set status=..OpenProgramFile(.sourceFileObj,.prog,name,0) Quit:status $$$ERROR($$$FileNotFound,name)
	W !,"Compiling "_$$$MVBfilename_" "_prog,!
	#; The compile routine maintains the proper error counter, so we don't want ERROR() to increment it
	If '$$MVRoutineCompile^%SYS.MV($$$MVBfilename,prog,1) Quit $$$ERROR($$$CompileFailed,,,,,,,,,0)
	// Check to see if this is cataloged
	If $Find("!$-*",$E(prog)) {
	    W "WARNING : """_prog_""" is globally cataloged - you must recatalog it to use updated code",!
	    Quit $$$OK
	}
	// setup needed info to catalog
	Set file=$$$FileVarTargetFileName(sourceFileObj),
		acc=$$$FileVarTargetAccount(sourceFileObj)
    Set sec=$$$FileVarSectionName(sourceFileObj)
    #; Add section name if present
    Set:sec'="" file=file_","_sec
    #;
	If '($D($$$SYSTEMFileName(acc),accountrecord)#2) {
		w "ERROR : accountname error",! 
		Quit '$$$OK
	}
	// name is [filename~]prog.mvb 
	// prog is the name of the item in the file as stored in the source file
	// OBJFileNameEnv sub 3 is the item name as found in the source file
	Set env=$MV(accountrecord,$$$DTypeNameSpace),
		rou=$G($$$OBJFileNameEnv(env,file,prog))
	If $$$FileVarOptions(sourceFileObj)["X" {
	    Set catName = $E(prog,1,*-4)	
	} else {
	    Set catName=prog
	}
	Lock +$$$VOCFileName(catName)
	If $D($$$VOCFileName(catName),VOCEntry)'=1 {
		// not yet cataloged - catalog locally
		Set VOCEntry = "V"_$$$MVam_rou_$$$MVvm_env_$$$MVam_"B",
			$MV(VOCEntry,7)="L",
			$MV(VOCEntry,8)=prog,
			$MV(VOCEntry,9)=$$$MVBfilename,
			$MV(VOCEntry,10)=$G($$$NAMESPACENames($namespace)),
			$$$VOCFileName(catName)=VOCEntry
	} Else {
		If $E($MV(VOCEntry,1))="V",$E($MV(VOCEntry,3))="B" {
			#; item already exists in VOC and it's a cat pointer
			#; verify it is the same file and item
			If $MV(VOCEntry,8) = prog,
			   $MV(VOCEntry,9) = $$$MVBfilename,
			   $MV(VOCEntry,10) = $G($$$NAMESPACENames($namespace)) {
				If $Find($MV(VOCEntry,7),"L") {
					#; If routine name has changed (#pragma), recatalog
					If $MV(VOCEntry,2,1)'=rou {
						Set $MV(VOCEntry,2,1)=rou, $$$VOCFileName(catName)=VOCEntry
					}
				} Else {
					#; item already cataloged but not Locally
					W "WARNING : """_catName_""" already cataloged without L option - you must recatalog it to use updated code",!
				}
			} else {
				W "WARNING : Catalog pointer """_catName_""" points to a different program "_$MV(VOCEntry,8)_" "_$MV(VOCEntry,9)_" "_$MV(VOCEntry,10),!
			}
		} else {
			W "WARNING : """_catName_""" already exists in VOC and is not a catalog pointer",!
		}
	}
	Lock -$$$VOCFileName(catName)
	Quit $$$OK
}

/// Return other document types that this is related to
ClassMethod GetOther(name As %String) As %String
{
  	#; w "<<diag>>get other "_name,!
	Set DELIM="~"
	Set SECTDELIM="|"
	Set prog="",sourceFileObj=$$$NewFileVariable 
	If $ZCVT($E(name,*-2,*),"l")="mvb" {
		Set rc=..OpenProgramFile(.sourceFileObj,.prog,name,0) Quit:rc 0
		#; find the MVI code
		Quit:'($D($$$OBJFileName($$$MVBfilename,prog),rtn)#10) ""
		Quit rtn_".mvi"
	} ElseIf $ZCVT($E(name,*-2,*),"l")="mvi" {
		Set name=$E(name,1,*-4),srclist=$G($$$ROUTINEFileName(name))
		Quit:srclist="" ""
		#; Make sure it is a MVB program, not a compiled PROC, I-type,
		#; or Query
		Quit:$LG(srclist)'="B" ""
		Set file = $Change($LI(srclist,2),",",SECTDELIM)
		$$$MVIOPEN(rc,sourceFileObj,"",file,0)
		Set file= $S(file=$$$DEFAULTPROGRAMFILE:"",1:file_DELIM)_$LI(srclist,3)
		If $$$FileVarOptions(sourceFileObj)'["X" {
			Set file = file_".mvb"
		}
		Quit file
	} Else { Quit "" }
}

}
