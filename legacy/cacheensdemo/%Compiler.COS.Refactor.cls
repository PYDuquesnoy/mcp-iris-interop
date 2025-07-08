/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occCPT, %occCPTCOSdefs, %occCPTSR)

Class %Compiler.COS.Refactor Extends %Compiler.COS.Traveler [ System = 4 ]
{

Property className As %String;

Property propName As %String;

Property methName As %String;

Property type As %String;

Property lhs As %String;

Property lnum As %Integer;

Property pair As %ObjectHandle;

Property changed As %Boolean;

Property scname As %String;

Property tcname As %String;

Property cmname As %Binary;

Property smname As %String;

Property tmname As %String;

Property ssqlname As %String;

Property tsqlname As %String;

Property sqlTableNameList As %String;

Property ctind As %Integer;

Method oneClassold() As %Status
{
	i '..ctind s ..ctind=$increment(^||CacheRf)
	kill ^||CacheRf(..ctind)
	s classname=..className
	//s ^||CacheXF(classname)=ctind
    s sc=$$$OK
	s method="" 
	while('$$$ISERR(sc))  {
		s method=$$$defMemberNext(classname,$$$cCLASSmethod,method)
		
		q:method=""
		//w method,! 
		Set codemode=$$$defMemberKeyGet(classname,$$$cCLASSmethod,method,$$$cMETHcodemode)
		i codemode="expression" continue  //change to macro !!
		//i codemode'=$$$cMETHCODEMODEGENERATOR&&(codemode'=$$$cMETHCODEMODEOBJECTGENERATOR) q
		Set taggenerator=$$$defMemberKeyGet(classname,$$$cCLASSmethod,method,$$$cMETHtaggenerator)
		#; If we already have a generator routine defined use this, to save regenerating the generator
		//i taggenerator'="" q
		Set language=$$$defMemberKeyGet(classname,$$$cCLASSmethod,method,$$$cMETHlanguage)
		If language=$$$cMETHLANGUAGEBASIC Set basic=1 continue
		If language=$$$cMETHLANGUAGEMVBASIC Set mvbasic=1 continue
		Set procedureblock=$$$defMemberKeyGet(classname,$$$cCLASSmethod,method,$$$cMETHprocedureblock)
		s codesize=0
		Set implementation=$$$defMemberKeyGet(classname,$$$cCLASSmethod,method,$$$cMETHimplementation) 
		//w implementation,!
		i implementation=0 continue
		s code=""
		f ii=1:1:implementation {
		 	s code=code_$$$comMemberArrayGet(classname,$$$cCLASSmethod,method,$$$cMETHimplementation,ii)_$c(10,13)
		}
		s ..methName=method
		
		s sc=..rf(code,"",.generated)
		//w code,!
	}
	q sc
}

Method oneClass(ByRef tempName As %String, bsave As %Boolean = 1, ByRef storagechanged As %Boolean, bNewSlot As %Boolean = 0, bDeleteStorage As %Boolean = 0) As %Status
{
	i '..ctind s ..ctind=$increment(^||CacheRf)
	kill ^||CacheRf(..ctind)
	s classname=..className
	if '($system.OBJ.IsUpToDate(classname)) quit $$$ERROR($$$StudioRefNotUpToDate,classname)
	if ($$$defClassKeyGet(classname,$$$cCLASSdeployed)=1)  quit $$$ERROR($$$StudioRefDeployed,classname)
	if '(##class(%Dictionary.ClassDefinition).%Exists($lb(classname))) quit $$$ERROR($$$StudioRefNotOpen,classname)
    s sc=$$$OK
    if (classname=..scname){
	    s tempName=..tcname
	    s cd=##class(%Dictionary.ClassDefinition).%Open($lb(tempName))
	    if cd'="" {
		     quit $$$ERROR($$$StudioRefNameExists,tempName)
	    }
	    
    }
    else {
	    s ii=1
	    while (1) {
	    	s tempName=classname_"q"_ii
	    	s cd=##class(%Dictionary.ClassDefinition).%Open($lb(tempName))
	    	if cd="" quit
	    	s ii=ii+1
	    }
    }
    m ^oddDEF(tempName)=^oddDEF(classname)
    s classname=tempName

   
    s cd=##class(%Dictionary.ClassDefinition).%Open($lb(classname))
    //if (..scname=classname && ..tmname
    //StudioRefGenerated
    
    s cd.Name=classname
    if cd="" quit $$$ERROR("Class not found")
     if cd.GeneratedBy'="" quit $$$ERROR($$$StudioRefGenerated,classname)
    //if (cmname=..className) {
	//    for ii=1:1:cd.Properties.Count()  {
	//		s property=cd.Propertiess.GetAt(ii)
	//		if (property.Name = ..smname) s property.Name=..tmname
    //	}
    //}
    if bDeleteStorage{
    	d cd.Storages.Clear()
    	s cd.StorageStrategy=""
    }
    if ..scname '="" {
	    s super=cd.Super
	    s brf=..ChangeCSList(.super, ..scname, ..tcname, 1, ..className)
	    if brf {
				s cd.Super=super
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,super,0,1,"Super")

		}
	    s compileAfter=cd.CompileAfter
	    s brf=..ChangeCSList(.compileAfter, ..scname, ..tcname, 1, ..className)
	    if brf {
				s cd.CompileAfter=compileAfter
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,compileAfter,0,1,"CompileAfter")

		}

    }
	for ii=1:1:cd.Methods.Count()  {
		s method=cd.Methods.GetAt(ii)
		if method.Language="javascript" continue
		kill ^||CacheRfCode
		s ..methName=method.Name
		s bSignature=0
		if (..methName = ..smname)&&($listfind(..cmname,..className)) {
			//s ..methName=..tmname
			s dm=##class(%Dictionary.CompiledMethod).%Open($lb(..className_"||"_..tmname))
			if dm'="" {
				 s sc= $$$ERROR($$$StudioRefNameExists,..tmname)
			}

			s method.Name=..tmname
			if ..tsqlname'="" s method.SqlName=..tsqlname
			d method.%Delete(method.%Oid())
			s bSignature=1
		}

		if method.ReturnType'="",..NormalizeClName(method.ReturnType,..className)=..scname{
			s method.ReturnType=..tcname
			s bSignature=1
		}
		d parseFormal^%occName("","",method.FormalSpec,.tArgs)
		for jj=1:1:tArgs {
			if (..scname'="")&&((..NormalizeClName($g(tArgs(jj,2)),..className))=..scname) {
				s tArgs(jj,2)=..tcname
				s bSignature=1
			}
		}
		if bSignature {
			d assembleFormal^%occName(.tArgs,.str)
			s method.FormalSpec=str
			s signature=""
				
	
	If method.ClientMethod {
		s signature=signature_"Client " 
	}
	
	
	If method.ClassMethod {
		s signature=signature_"Class"
	}
	
	s signature=signature_"method "_method.Name_"("
	
	
	
	if method.FormalSpec'="" {
	
	Set tAllArgs="" For tI=1:1:tArgs {
		
		Set tOneArg=""
		
		#; Add the modifier if present
		Set tMod=$Get(tArgs(tI,1)) Set tOneArg=tOneArg_$Case(tMod,"&":"ByRef ","*":"Output ",:"")
		
		#; Now the name
		Set tOneArg=tOneArg_tArgs(tI)
		
		#; Type
		Set tType=$Get(tArgs(tI,2)) 
		If tType'="" {
			
			Set tOneArg=tOneArg_" As "_tType
			If $Data(tArgs(tI,2))>1 {
				
				Set tOneArg=tOneArg_"("
				
				Set tTypeParms=""
				Set tOneTypeParm="" For {
					
					Set tOneTypeParm=$Order(tArgs(tI,2,tOneTypeParm),1,tTypeValue) If tOneTypeParm="" Quit
					
					Set tTypeParms=tTypeParms_tOneTypeParm
					If tTypeValue'="" {
						Set tTypeParms=tTypeParms_"="_tTypeValue
					}
					Set tTypeParms=tTypeParms_","
				}
				
				#; Remove Trailing comma
				Set $Extract(tTypeParms,$length(tTypeParms))=""
				
				Set tOneArg=tOneArg_tTypeParms_")"
			}
		}
		
		Set tDef=$Get(tArgs(tI,3))
		If tDef'="" 
		{
			If '(($Extract(tDef)="""")||$isvalidnum(tDef)||(tDef="NULL")) 
			{
				#; Not a literal value, must wrap in {}
				Set tDef="{"_tDef_"}"
			}
			Set tOneArg=tOneArg_" = "_tDef
		}
		
		Set tAllArgs=tAllArgs_tOneArg_","
	}
	
	#; Remove Trailing comma
	Set $Extract(tAllArgs,$length(tAllArgs))=""
	s signature=signature_tAllArgs
	}
	
	s signature=signature_") "
	
	#; ReturnType
	
	If method.ReturnType'="" {
		
		s signature=signature_"As "_method.ReturnType
	
	
		If method.ReturnTypeParams'="" {
			s signature=signature_"("_method.ReturnTypeParams_")"
		}
	}
	s linen=$increment(^||CacheRfQ(..ctind))			

	if ..methName=..smname {
		s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..methName,..tmname,0,1,signature)
	}
	else {
		s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..methName,..methName,0,1,signature)
	}
	
	#; Write the method keywords
 // !!!!!!!!!!!!!!!!!

		}
		s code=method.Implementation.Read($$$MaxLocalLength)
		if method.CodeMode="expression" s code=" w "_code
		s sc=..rf(code,"",.generated)
		if 'sc s sc=$$$ERROR($$$StudioRefParse,..className,..methName) q
		if method.CodeMode="expression" s ^||CacheRfCode(1)=$e(^||CacheRfCode(1),4,*)
		for jj=1:1:$g(^||CacheRfCode) {
			d method.Implementation.Write(^||CacheRfCode(jj)_$c(13,10))
		}
		//w code,!
	}
	if 'sc quit sc
	//s cd.Name=cd.Name_"q"
	for ii=1:1:cd.Properties.Count()  {
		s prop=cd.Properties.GetAt(ii)
		if ..scname'="",..NormalizeClName(prop.Type,..className)=..scname {
			set prop.Type=..tcname
			s linen=$increment(^||CacheRfQ(..ctind))
			s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,prop.Name,prop.Name,0,1,"Property "_prop.Name_" As "_prop.Type)

		}
		elseif $listfind(..cmname,..className)&&(prop.Name = ..smname) {
			//s prop1=prop.%ConstructClone()
			s dp=##class(%Dictionary.CompiledProperty).%Open($lb(..className_"||"_..tmname))
			//w !,..cmname," ",..tmname," ",..className
			if dp'="" {
				//w !,"oxox"
				 s sc= $$$ERROR($$$StudioRefNameExists,..tmname)
				 quit
			}
			d prop.%Delete(prop.%Oid())
	
			s prop.Name=..tmname
			s prop.SqlFieldName=..tsqlname
			s linen=$increment(^||CacheRfQ(..ctind))
			s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,prop.Name,0,1,"Property "_prop.Name_" As "_prop.Type)
   
     }
     elseif prop.Relationship {
	     s comprop=##class(%Dictionary.CompiledProperty).%Open($lb(..className_"||"_prop.Name))
	     if $listfind(..cmname,comprop.Type) && (prop.Inverse=..smname) {
		     s prop.Inverse=..tmname
		     s linen=$increment(^||CacheRfQ(..ctind))
			s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,prop.Name,0,1,"Property "_prop.Name_" As "_prop.Type)

	     }
     }
     if ..smname'="",$listfind(..cmname,..className),prop.SqlComputeCode'=""{
	     s code=prop.SqlComputeCode
		s code=" "_code
		kill ^||CacheRfCode
		s sc=..rf(code,"",.generated,,1)
		if 'sc s sc=$$$ERROR($$$StudioRefParse,..className,..methName) q
		s prop.SqlComputeCode=$e(^||CacheRfCode(1),2,*)
		
     }
	}
	if 'sc quit sc
	for ii=1:1:cd.Queries.Count()  {
		if 'sc quit
		s pChanged=0
		s qd=cd.Queries.GetAt(ii)
		if (qd.Name=..smname)&&($listfind(..cmname,..className)) {
			s dq=##class(%Dictionary.CompiledQuery).%Open($lb(..className_"||"_..tmname))
			if dq'="" {
				 s sc= $$$ERROR($$$StudioRefNameExists,..tmname)
				 quit
			}

			
			d qd.%Delete(qd.%Oid())
			s qd.Name=..tmname
			s ..changed=1
			
			if ..tsqlname'="" s qd.SqlName=..tsqlname
		}
		if qd.SqlQuery'="" {
			s sql=1
			s sql(1)=qd.SqlQuery
			
			if ((..tcname="")) {d ..RenameSqlFieldLbst( .sql , .nuq , $s(..ssqlname'="":..ssqlname,1:..smname), $s(..tsqlname'="":..tsqlname,1:..tmname), ..sqlTableNameList, .pChanged, ..className )}
			else {
				s sourcetschname=$$TableFromClass^%occClass(..scname)
				if ..tsqlname'="" {
				s ttanme=..tsqlname
				}
				else {
					s ttname=$$$ClassShortName(..tcname)
				}
				Set schema=$$DetermineSchemaName^%occClass(..tcname)
				Set schematable=$$quoter2^%occClass(schema)_"."_$$quoter2^%occClass(ttname)
				//RenameSqlTable(ByRef sql As %String, ByRef nuq As %String, sntn As %String, nust As %String, ByRef pChanged As %Boolean, pClassname As %String = "") As %Library.Status [ PublicList = (backgrnd, err, mcurs, mtag, mtc, SQLCODE) ]
			
				d ..RenameSqlTable( .sql , .nuq , sourcetschname,schematable,  .pChanged, ..className)

			}

			
			if pChanged||..changed {
			// d e.SetAnnotation(nodePtr,3,nuq(1))
				s qd.SqlQuery=nuq(1)
				set ..changed=1
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,"Query cnanged")


			}

		}
		}
	

	  for ii=1:1:cd.ForeignKeys.Count()  {
		    s brf=0
			s fk=cd.ForeignKeys.GetAt(ii)
			if (..scname'="")&&(..NormalizeClName((fk.ReferencedClass),..className)=..scname) {
				s fk.ReferencedClass=..tcname
				s brf=1
			}
			if ($listfind(..cmname,..className)) {
				for jj=1:1:$l(fk.Properties,",") {
						s tempstr=fk.Properties 
						if $p(tempstr,",",jj)=..smname {
							s $p(tempstr,",",jj)=..tmname
							s fk.Properties=tempstr
							s brf=1
							}
					}
			}
	  

			if brf {
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,fk.Name,0,1,"Foreign Key "_fk.Name_" on "_fk.Properties)

			}
	  }

 for ii=1:1:cd.Indices.Count()  {
		    s brf=0
			s index=cd.Indices.GetAt(ii)
			d ParseDelimitedString^%occStorageUtil(index.Properties,",",.indexprop)
			k newprop
			For ptr=1:1:indexprop {
				Kill array 
				Do ParseDelimitedString^%occStorageUtil(indexprop(ptr),":",.array)
				if ($listfind(..cmname,..className)&&($p(array(1),"(",1)=..smname)) {
					s $p(array(1),"(",1)=..tmname
					s brf=1
				}
 elseif($find(array(1),".")) {
					
					s dl=$l(array(1),".")
					//s dpt=$p(array(1),".",1,dl-1) 
					s dm=$p(array(1),".",dl)
					//we need to handle multilevel
					s dclname=..className
					for jj=1:1:(dl-1) {
						if dclname="" quit
						s dpt=$p(array(1),".",1,dl-1)
						s dp=##class(%Dictionary.CompiledProperty).%Open($lb(dclname_"||"_dpt))
						i dp="" {
							s dclname=""
							quit
						} s dclname=dp.Type
					}

 // s dp=##class(%Dictionary.CompiledProperty).%Open($lb(..className_"||"_dpt))
 if dclname'="" {
						if ($listfind(..cmname,dclname)&&(dm=..smname)) {
						s array(1)=dpt_"."_..tmname
						s brf=1
						}
}      
				}
				s newprop($increment(newprop))=$$DelimitedString^%occStorageUtil(.array,":")
			}
			if brf s index.Properties=$$DelimitedString^%occStorageUtil(.newprop,",")
			k indexdata
			d ParseDelimitedString^%occStorageUtil(index.Data,",",.indexdata)
			for jj=1:1:indexdata {
				if ($listfind(..cmname,..className)&&(indexdata(jj)=..smname)) {
					s indexdata(jj)=..tmname
					s brf=1
				}
				
			}
			if brf {
				s index.Data=$$DelimitedString^%occStorageUtil(.indexdata,",")
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,index.Name,0,1,"Index "_index.Name_" on "_index.Properties)

			}

   }
   // params
   do {
   		    s brf=0
			s param=##class(%Dictionary.ParameterDefinition).%OpenId(tempName_"||"_"EXTENTQUERYSPEC")
			if param="" quit
			for str=param.Default,param.Expression {
			d ParseDelimitedString^%occStorageUtil(str,",",.paramprop)
			if str= "" continue
			
			For ptr=1:1:paramprop {
				
				if ($listfind(..cmname,..className)&&(paramprop(ptr)=..smname)) {
					s paramprop(ptr)=..tmname
					s brf=1
				}
				elseif($find(paramprop(ptr),".")) {
					
					s dl=$l(paramprop(ptr),".")
					//s dpt=$p(array(1),".",1,dl-1) 
					s dm=$p(paramprop(ptr),".",dl)
					//we need to handle multilevel
					s dclname=..className
					for jj=1:1:(dl-1) {
						if dclname="" quit
						s dpt=$p(paramprop(ptr),".",1,dl-1)
						s dp=##class(%Dictionary.CompiledParameter).%Open($lb(dclname_"||"_dpt))
						i dp="" {
							s dclname=""
							quit
						} 
						s dclname=dp.Type
					}
					//s dp=##class(%Dictionary.CompiledProperty).%Open($lb(..className_"||"_dpt))
					if dclname'="" {
						if ($listfind(..cmname,dclname)&&(dm=..smname)) {
						s paramprop(ptr)=dpt_"."_..tmname
						s brf=1
						}
					}      
				}
				
			}
			
			 
			if brf {
				if str=(param.Default) s param.Default=$$DelimitedString^%occStorageUtil(.paramprop,",") 
				if str=(param.Expression) s param.Expression=$$DelimitedString^%occStorageUtil(.paramprop,",") 
				s linen=$increment(^||CacheRfQ(..ctind))
				s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..smname,index.Name,0,1,"Parameter EXTENTQUERYSPEC  "_index.Properties)

			}
			}
   } while(0)


   //end params
	if bsave {
		s sc=cd.%Save()
		if sc,$g(param)'="" s sc=param.%Save() 
				if ..tmname'="",$listfind(..cmname,..className) {
						//w "^^^ ",..className," ",..smname,",",..tmname, " ",$li(..cmname),!
	    
		}

	}
	s storagechanged=0
	if ##class(%Dictionary.CompiledProperty).%Exists($lb(..className_"||"_..smname)),$listfind(..cmname,..className) {
		set sc=..RefactorStorageProperty(classname,..smname,..tmname,bNewSlot,.storagechanged,bsave)
	
	}
	if 'bsave,storagechanged {
		s linen=$increment(^||CacheRfQ(..ctind))
		s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,"","_storage",0,1,"Storage changed ")
	}
	if 'bsave {
		k ^oddDEF(tempName)
	}

	q sc
}

Method rf(ByRef source As %RawString, pPackage As %RawString = "", ByRef code As %RawString, ByRef warning As %Status = 1, sqlContext As %Integer = 0) As %Status
{
	k ^||CacheRf
	//s ^||CacheRfQ(..ctind)=0
	s ..lnum=0
	set $ZTrap = "Catch"
	set ret=$$$OK
	do {
			#; First task is to produce the parse tree. The only setting that is relevant is DELIMIDENT
		set settings = ""
			#;	instantiate a parse tree object
		set parseTree = ##class(%Compiler.COS.ParseTree).Parse(.source,settings,.status,,sqlContext)
		if ($$$ISERR(status)) || ('$IsObject(parseTree)) { continue}

		
			#; instantiate me
		//set visitor = ..%New()
		Set ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)		

		set ..compileParameter("PACKAGE") = pPackage
			#; set the class context for deferred statements
		set ..importPackages = pPackage
			#;		And and the visitor to the accept method for tree traversal
		set status = parseTree.accept(##this)
		if $$$queueCounter(..errorQueue) {
				#; This line dequeues the errorQueue and adds each element to the status if the element is an error message - $$$ISERR.
			$$$dequeue(..errorQueue,error) while $$$queuePointer(..errorQueue)'="" { if $$$ISERR(error) { set status = $$$ADDSC(status,error) } $$$dequeue(..errorQueue,error) }
		}
		if $$$ISERR(status) { continue }
		set status = ..finalizeCode(.source,.code)
			#; Now check for any errors reported during symbol resolution and code dequeue
		if $$$queueCounter(..errorQueue) {
				#; This line dequeues the errorQueue and adds each element to the status if the element is an error message - $$$ISERR.
			$$$dequeue(..errorQueue,error) while $$$queuePointer(..errorQueue)'="" { if $$$ISERR(error) { set status = $$$ADDSC(status,error) } $$$dequeue(..errorQueue,error) }
		}
		if $$$queueCounter(..warningQueue) {
				#; This line dequeues the warningQueue and adds each element to the status if the element is an error message - $$$ISERR.
			$$$dequeue(..warningQueue,error) while $$$queuePointer(..warningQueue)'="" { if $$$ISERR(error) { set warning = $$$ADDSC(warning,error) } $$$dequeue(..warningQueue,error) }
		}
	} while 0
	quit status
Catch	set $ZTrap = ""
	QUIT $$$ERROR($$$ObjectScriptError,$ZE)
}

///  LvnRef(9): ann name Name:1, ann enum LvnType:2, optional child Subscripts:1
///  LOCAL/GLOBAL VARIABLES
///  enum LvnType: Private:1, Public:2, Parameter:3
Method v9(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
 if '$g(parentPtr) quit
	if visit {
		set tVarName = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("this is code that I generated for v9  -lvnref: "_tVarName_", type is: "_tVarType)
		set type = ..flo.getSymbolType(..flo.defaultContext,tVarName)
		s ^||CacheRf(nodePtr,"type")=$s(type="":-1,1:type)

		//$$$pushoperand(..opStack,tVarName,type,0,tVarName)
		set parentType = $$$CPTNODEtype(parseTree.treePtr,parentPtr)
		if (parentType=14) {
			//s ..lhs=tVarName
			s ^||CacheRf(parentPtr,"lhsname")=$s(tVarName="":-1,1:tVarName)
			//$$$pushoperand(..opStack,tVarName,type,0,"")
		}
		if (parentType=5) {
			 s op = $Get($$$CPTNODEannotation(parseTree.treePtr,parentPtr,1))
			 if (op="") {
				 //$$$pushoperand(..opStack,tVarName,type,0,"")
				 //s ..type=type
				 s ^||CacheRf(parentPtr,"type")=$s(type="":-1,1:type)
			 }
		}

		if ((parentType=12) || (parentType=32)) {
			s ^||CacheRf(parentPtr,"type")=$s(type="":-1,1:type)
			
		}
		//s ..type=type
		//if (..lhs = "") {
		//	s ..lhs=tVarName
		//}
	}
	quit
}

Method v10(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set tVarName = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("this is code  generated for v10  reset type for a binary operator ")
		
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$pushoperand(..opStack,"",type,0,"")
	}
	quit
}

Method v2(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		//b
		set tVarName = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("line # "_(1+..lnum)_" node "_nodePtr)
		s ..lnum=..lnum+1
		d ..pair.GenerateEditedLine(nodePtr,.out1)
		s line=out1.Read($$$MaxLocalLength,.sc)
		//i $increment(^||CacheRfCode)
		//s ^||CacheRfCode(^||CacheRfCode)=line
		//w !,"v2 line node ",tVarName,tVarType,!

		if (..changed) {
					
		//**************
		//s t=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
		//b
		//w "line #"_..lnum,! //!!!!!!!!!
		//s ^||CacheRf(ctind,"class",..className,..methName,..lnum,"original")=
		//d ..pair.GenerateOriginalLine(nodePtr,.out)
		//w out.Read(100,.sc)
		//b
		//d ..pair.GenerateEditedLine(nodePtr,.out1)
		//w out1.Read(100,.sc)
		//s linen=$increment(^||CacheRf(..ctind))
		//s ^||CacheRf(..ctind,linen,"class",..className,..methName,..lnum,0)=out.Read(,.sc)
		s linen=$increment(^||CacheRfQ(..ctind))
		s ^||CacheRfQ(..ctind,linen)=$lb("class",..className,..methName,..methName,..lnum,1,line)

		s ..changed=0

		}
		
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$pushoperand(..opStack,"",type,0,"")
	}
	else{
	}
	quit
}

Method v1(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set tVarName = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("block ; treePtr "_parseTree.treePtr)
		
		d ..pair.GenerateEditedLine(nodePtr,.out1)
		s line=out1.Read($$$MaxLocalLength,.sc)
		i $increment(^||CacheRfCode)
		s ^||CacheRfCode(^||CacheRfCode)=line


		

		
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$pushoperand(..opStack,"",type,0,"")
	}
	else{
	}
	quit
}

Method v62(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set tVar1 = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVar2 = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		set tVar3 = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,3),"<<NOT SPECIFIED>>")
		set tVar4 = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,4),"<<NOT SPECIFIED>>")
		
		if (tVar1="sql") &&((..tsqlname'="")||(..smname'=""))&&(..tcname="") {
			s sql=1
			s sql(1)=tVar3
			s pChanged=0
			d ..RenameSqlFieldLbst( .sql , .nuq , $s(..ssqlname'="":..ssqlname,1:..smname),$s(..tsqlname'="":..tsqlname,1:..tmname), ..sqlTableNameList, .pChanged, ..className )
				if ..pair="" s ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
			 	if pChanged {Set e=##class(%CPT.Tree.Editor).%New(..pair.EditedTreeIndex)
				// d e.SetAnnotation(nodePtr,3,nuq(1))
				d e.SetAnnotation(nodePtr,3,nuq(1))
				set ..changed=1
			 	//i $increment(^||CacheRfCode)!!!
				//s ^||CacheRfCode(^||CacheRfCode)="xxx" 

			}
		}
		if (tVar1="sql") &&(..tcname'="") {
			s sql=1
			s sql(1)=tVar3
			s pChanged=0
			s sourcetschname=$$TableFromClass^%occClass(..scname)
			if ..tsqlname'="" {
				s ttanme=..tsqlname
			}
			else {
				s ttname=$$$ClassShortName(..tcname)
			}
			Set schema=$$DetermineSchemaName^%occClass(..tcname)
			Set schematable=$$quoter2^%occClass(schema)_"."_$$quoter2^%occClass(ttname)
			//RenameSqlTable(ByRef sql As %String, ByRef nuq As %String, sntn As %String, nust As %String, ByRef pChanged As %Boolean, pClassname As %String = "") As %Library.Status [ PublicList = (backgrnd, err, mcurs, mtag, mtc, SQLCODE) ]
			
			d ..RenameSqlTable( .sql , .nuq , sourcetschname,schematable,  .pChanged, ..className)
				if ..pair="" s ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
			 	if pChanged {Set e=##class(%CPT.Tree.Editor).%New(..pair.EditedTreeIndex)
				d e.SetAnnotation(nodePtr,3,nuq(1))
				set ..changed=1
			 	}
		}



		

		
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$pushoperand(..opStack,"",type,0,"")
	}
	else{
	}
	quit
}

Method v5(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set op = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("v5 node  "_nodePtr)
		
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$popoperand(..opStack,value,opType,opPriority,opToken)
		//$$$pushoperand(..opStack,"",type,0,"")
	
		//if (op'="<<NOT SPECIFIED>>") {
		//	s ^||CacheRf(parentPtr,"type")=""
		//}
		//else {
			s ^||CacheRf(parentPtr,"type")=$g(^||CacheRf(nodePtr,"type"))
		//}
	}
	
	quit
}

Method replaceMemberName(parseTree As %Compiler.Util.ParseTree, newname As %Binary, nodePtr As %Integer)
{
	//w !,"replace mn"
		if ..pair="" s ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
		Set e=##class(%CPT.Tree.Editor).%New(..pair.EditedTreeIndex)
		//Set sourceextent=$$$CPTNODESRCEXT(parseTree.treePtr,nodePtr)
		d e.SetAnnotation(nodePtr,1,newname)
}

Method replaceClassName(parseTree As %Compiler.Util.ParseTree, newname As %Binary, nodePtr As %Integer, parentPtr As %Integer, ann As %String)
{
		if ..pair="" s ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
		Set e=##class(%CPT.Tree.Editor).%New(..pair.EditedTreeIndex)
		Set sourceextent=$$$CPTNODESRCEXT(parseTree.treePtr,nodePtr)
		set p=e.CreateNode(35,sourceextent,$lb($lb(1,ann)),"")
		set p1=e.CreateNode(41,sourceextent,"","")
		d e.LinkChild(p,1,p1)
		//b
		for ii=1:1:$l(newname,".") {
			set c=e.CreateNode(36,sourceextent,$lb($lb(1,$p(newname,".",ii))),"")
			d e.LinkChild(p1,ii,c)
		}
		//set c=e.CreateNode(36,sourceextent,$lb($lb(1,"kk")),"")
		//d e.LinkChild(p1,2,c)
		d e.UnlinkChild(parentPtr,1)
		d e.LinkChild(parentPtr,1,p)
		
		d e.DeleteNode(nodePtr,1)
}

Method v35(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set ann = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		s className=$e($g(^||CacheRf(nodePtr,"type")),2,*)
		do ..flo.queueCode("the classname is "_className)
		s ^||CacheRf(parentPtr,"type")=className
		s ^||CacheRf(parentPtr,"class")=1
		//b
		if className'="",(..NormalizeClName(className,..className)=..scname){
			d ..replaceClassName(parseTree , ..tcname , nodePtr , parentPtr, ann)
			set ..changed=1
		}
				//s t=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)


		//$$$pushoperand(..opStack,valuel,typer,0,"")
	}
	else {
		//s ..className = ""
	}
	quit
}

Method v97(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set ann = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		if ..smname'="",$listfind(..cmname,..className) {
			s fname=$list(ann,1)
			s sname=$s(..ssqlname'="":..ssqlname,1:..smname)
			s tname=$s(..tsqlname'="":..tsqlname,1:..tmname)
			if fname=sname{
					s $list(ann,1)=tname
					if ..pair="" s ..pair=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)
					Set e=##class(%CPT.Tree.Editor).%New(..pair.EditedTreeIndex)
					d e.SetAnnotation(nodePtr,1,ann)
					s ..changed=1

				
			}
		}
		
			//set ..changed=1
		
				//s t=##class(%CPT.Tree.Pair).%New(parseTree.treePtr)


		//$$$pushoperand(..opStack,valuel,typer,0,"")
	}
	else {
		//s ..className = ""
	}
	quit
}

Method v36(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		
		//do ..flo.queueCode("the classname is "_..className)

		//s ..className=..className_"."_Name ;;xx
		s ^||CacheRf(parentPtr,"type")=$g(^||CacheRf(parentPtr,"type"))_"."_Name
	}
	else {
		
	}
	quit
}

Method v41(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		//set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		
		//do ..flo.queueCode("the classname is "_..className)
		s (^||CacheRf(parentPtr,"type"))=$g(^||CacheRf(nodePtr,"type"))
		// s ..className=..className_"."_Name ;;xx
	}
	else {
		
	}
	quit
}

Method v13(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		//set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		
		do ..flo.queueCode("visiting "_nodePtr)

		if ($g(^||CacheRf(nodePtr,"lhsname"))'="") {
			s ^||CacheRf(parentPtr,"lhsname")=$g(^||CacheRf(nodePtr,"lhsname"))
		}
		if ($g(^||CacheRf(nodePtr,"type"))'="") {
			s ^||CacheRf(parentPtr,"type")=$g(^||CacheRf(nodePtr,"type"))
		}
	}
	else {
		
	}
	quit
}

Method v14(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		//set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		
		do ..flo.queueCode("visiting "_nodePtr)

		//s ..methName=Name ;;xx
		s ^||CacheRf(parentPtr,"lhsname")=$g(^||CacheRf(nodePtr,"lhsname"))
	}
	else {
		
	}
	quit
}

Method v37(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	set nodeTypeName = "DotDotBase"
	if visit {
		do ..flo.queueCode("visiting node: "_nodePtr_" type: "_$$$CPTNODEtype(parseTree.treePtr,nodePtr) _ "::" _ nodeTypeName)
		set sourceLocation = $Get($$$CPTNODEsourcelocation(parseTree.treePtr,nodePtr)) set sourceLine = $ListGet(sourceLocation,1), sourceOffset = $ListGet(sourceLocation,2)
		//$$$queue(..errorQueue,$$$ERROR($$$GeneralError,$Select(sourceLine:"Line: "_sourceLine_" Offset: "_sourceOffset_": ",1:"")_"Node type: 'DotDotBase'(37) is not implemented."))
	}
	else { 
	   s ^||CacheRf(nodePtr,"type")=..className
	   do ..flo.queueCode("descending through node: "_nodePtr_" type: "_$$$CPTNODEtype(parseTree.treePtr,nodePtr) _ "::" _ nodeTypeName) }
	quit
}

Method v34(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		if $g(^||CacheRf(nodePtr,"hasParam")){
			do ..flo.queueCode("node" _nodePtr_"the method name is "_Name)

			//s ..methName=Name ;;xx
			s ^||CacheRf(parentPtr,"method")=Name
		}
		else{
			do ..flo.queueCode("node" _nodePtr_"the property name is "_Name)
			s ^||CacheRf(parentPtr,"property")=Name

		}
		//w "v34:",$g(^||CacheRf(parentPtr,"type")),":",Name,!
		s normName=..NormalizeClName($g(^||CacheRf(parentPtr,"type")),..className)
		if normName'="",($listfind(..cmname,(normName))&&(Name=..smname)) {
			
			d ..replaceMemberName(parseTree , ..tmname , nodePtr )
			set ..changed=1

		}
	}
	else {
		
	}
	quit
}

Method v33(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		do ..flo.queueCode("node " _nodePtr)

		//s ..methName=Name ;;xx
		if $g(^||CacheRf(nodePtr,"method"))'="" s ^||CacheRf(parentPtr,"method")=^||CacheRf(nodePtr,"method")
		if $g(^||CacheRf(nodePtr,"property"))'="" s ^||CacheRf(parentPtr,"property")=^||CacheRf(nodePtr,"property")
	}
	else {
				s ^||CacheRf(nodePtr,"type")=$g(^||CacheRf(parentPtr,"type"))

		
	}
			//w "v33:",$g(^||CacheRf(parentPtr,"type")),":",Name,!

	quit
}

Method v11(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		
		
		//do ..flo.queueCode("the type of "_..lhs_" name is "_..type) ;;xx
		//do ..flo.addSymbol(,,..lhs,"",..type) ;;xx
		do ..flo.queueCode("visiting "_nodePtr)

		
	}
	else {
		//s ..lhs=""
		
	}
	quit
}

Method v38(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		
		
		//do ..flo.queueCode("the type of "_..lhs_" name is "_..type) ;;xx
		//do ..flo.addSymbol(,,..lhs,"",..type) ;;xx
		do ..flo.queueCode("visiting "_nodePtr)
		s ^||CacheRf(parentPtr,"hasParam")=1

		
	}
	else {
		//s ..lhs=""
		
	}
	quit
}

Method v12(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		
		
		//do ..flo.queueCode("the type of "_..lhs_" name is "_..type) ;;xx
		//do ..flo.addSymbol(,,..lhs,"",..type) ;;xx
		do ..flo.queueCode("node "_nodePtr_" the type of "_$g(^||CacheRf(nodePtr,"lhsname"),"<<Error>>")_" name is "_$g(^||CacheRf(nodePtr,"type"),"<<NO TYPE>>"))
		if ($g(^||CacheRf(nodePtr,"lhsname"))'="") do ..flo.addSymbol(,,^||CacheRf(nodePtr,"lhsname"),"",$g(^||CacheRf(nodePtr,"type")))

		
	}
	else {
		//s ..lhs=""
		
	}
	quit
}

Method v32(parseTree As %Compiler.Util.ParseTree, visit As %Integer, nodePtr As %Integer, parentPtr As %Integer)
{
	if visit {
		set Name = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,1),"<<NOT SPECIFIED>>")
		//set tVarType = $Get($$$CPTNODEannotation(parseTree.treePtr,nodePtr,2),"<<NOT SPECIFIED>>")
		
		//do ..flo.queueCode("the classname is "_..className)
	    
		if ( ($g(^||CacheRf(nodePtr,"method"))'="") && ($g(^||CacheRf(nodePtr,"type"))'="")) {
			if (^||CacheRf(nodePtr,"method")="%OpenId") || (^||CacheRf(nodePtr,"method")="%Open") || (^||CacheRf(nodePtr,"method")="%New") {
				s returntype=^||CacheRf(nodePtr,"type")
			}
			else{
				set returntype = $$$comMemberKeyGet(^||CacheRf(nodePtr,"type"),$$$cCLASSmethod,^||CacheRf(nodePtr,"method"),$$$cMETHreturntype)
			}
			
			
			do ..flo.queueCode("the method reference  is "_^||CacheRf(nodePtr,"type")_"."_^||CacheRf(nodePtr,"method"))
			
			///if (..methName="%OpenId") { //put proper class dictionary invocation
			
				//s ..type=returntype
				s ^||CacheRf(parentPtr,"type")=returntype
			//}
		}
		elseif ( ($g(^||CacheRf(nodePtr,"property"))'="") && ($g(^||CacheRf(nodePtr,"type"))'="")) {
			
			set returntype = $$$comMemberKeyGet(^||CacheRf(nodePtr,"type"),$$$cCLASSproperty,^||CacheRf(nodePtr,"property"),$$$cPROPtype)
		
			
			do ..flo.queueCode("the property reference  is "_^||CacheRf(nodePtr,"type")_"."_^||CacheRf(nodePtr,"property"))
			
			///if (..methName="%OpenId") { //put proper class dictionary invocation
			
				//s ..type=returntype
				s ^||CacheRf(parentPtr,"type")=returntype
			//}
		}
		else {
			s ^||CacheRf(parentPtr,"type")=""
		}
	}
	else {
		//s ..className=""
		k ^||CacheRf(nodePtr,"method")
		k ^||CacheRf(nodePtr,"property")
		//s ^||CacheRf(nodePtr,"type")=$g(^||CacheRf(parentPtr,"type"))
		//s ..propName=""
		//s ..methName=""
		
	}
	quit
}

Query ChangeMultClassName(oldName As %String, newName As %String, projectName As %String) As %Query(ROWSPEC = "CLASSNAME:%String,ERROR:%Integer,MESSAGE:%String") [ SqlProc ]
{
}

ClassMethod ChangeMultClassNameExecute(ByRef qHandle As %Binary, oldName As %String, newName As %String, projectName As %String) As %Status
{
	k ^||CacheXR
	set resultSet=##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
    set status=resultSet.Execute(projectName)
    s sc=$$$OK
    while (resultSet.Next() '=0)
    {
	    k ^||CacheRfQ  //change when one pass is implemented!!!
        set type=resultSet.Get("Type")
        set name =resultSet.Get("Name")
        if name="" continue
        if type'="CLS" continue
        k ^||CacheRfQ
  		s rfo=##class(%Compiler.COS.Refactor).%New()
  		s rfo.scname=..NormalizeClName(oldName,name)
  		s rfo.tcname=..NormalizeClName(newName,name)
  		s rfo.className=name
  		s rfo.cmname=""
  		s sc= rfo.oneClass(.tempName,0)
  	    //if 'sc q
  	   s Errtxt=$system.Status.GetErrorText(sc)
	  	s Errnum=+$system.Status.GetErrorCodes(sc)

  		//s qHandle=$lb(rfo.ctind,"")
		s ll=$o(^||CacheRfQ(rfo.ctind,""))
  		if (ll'="")||'sc {
	  		i $increment(^||CacheXR)
	  		s ^||CacheXR(^||CacheXR)=$lb(name,Errnum,Errtxt)
	  
        }
        elseif(rfo.scname=name) {
	        i $increment(^||CacheXR)
	  		s ^||CacheXR(^||CacheXR)=$lb(name,0,"")

        }
        //k ^||CacheRfQ
        k rfo


        
    }
    do resultSet.Close()
    s qHandle=""
    Quit $$$OK
}

ClassMethod ChangeMultClassNameClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ChangeMultClassNameExecute ]
{
	 k ^||CacheXR
	 Quit $$$OK
}

ClassMethod ChangeMultClassNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ChangeMultClassNameExecute ]
{
 s AtEnd=0,Row=""
	s ll=$o( ^||CacheXR(qHandle))
	if ll="" {
		s AtEnd=1
		Quit $$$OK
	}
	//S Row=$lb(^||CacheXR(ll))
	S Row=^||CacheXR(ll)
	s qHandle=ll
	//w $lg(Row,1)_"|"_$lg(Row,2)
	Quit $$$OK
}

ClassMethod GetSubclasses(classname As %String) As %Binary
{
		s ret=$lb(classname)
		set rs=##class(%ResultSet).%New()
		set rs.ClassName="%Dictionary.ClassDefinitionQuery"
		set rs.QueryName="SubclassOf"
		set sc=rs.Execute(classname)  If 'sc Do DisplayError^%apiOBJ(sc) Quit
		while rs.%Next() { s ret=ret_$lb(rs.%GetData(1)) }
		quit ret
}

ClassMethod GetTableList(classnamelist As %Binary) As %Binary
{
		s ret=classnamelist
		for ii=1:1:$ll(ret) {
			s name =$list(ret,ii)
			 s cd=##class(%Dictionary.ClassDefinition).%Open($lb(name))
	    if cd '="" {
		    if cd.SqlTableName'=""{
			    s i=0,pos=0
			    while(1) {
				    s i=$find(cd.SqlTableName,".",i)
				    if i=0 quit
				    s pos=i
			    }
		    	s $li(ret,ii)=$lb($e(cd.SqlTableName,1,pos-1)_cd.SqlTableName)
		    }
	    }
		}
		quit ret
}

Query ChangeMultMemberName(oldName As %String, newName As %String, memclassName As %String, projectName As %String, sqlName As %String) As %Query(ROWSPEC = "CLASSNAME:%String,ERROR:%Integer,MESSAGE:%String") [ SqlProc ]
{
}

ClassMethod ChangeMultMemberNameExecute(ByRef qHandle As %Binary, oldName As %String, newName As %String, memclassName As %String, projectName As %String, sqlName As %String = "") As %Status
{
	k ^||CacheXR
	//w "SQLNAME ",sqlName,!
	set resultSet=##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
    set status=resultSet.Execute(projectName)
    if (memclassName'=""){
	   		
		    s pd=##class(%Dictionary.PropertyDefinition).%Open($lb(memclassName_"||"_oldName),4)
		    if pd'="" {
			    s sfn=pd.SqlFieldName
			    if sfn'="" {
				    s ssqlname=sfn
			    }
			    else {
				    s ssqlname=pd.Name
			    }
			    if sqlName '="" {
				    s tsqlname=sqlName
			    }
			    else {
				    s tsqlname=newName
			    }
		    }
		    //SqlFieldName
    }


	s classlist=..GetSubclasses(memclassName)
	s tablelist=..GetTableList(classlist)
	s sc=$$$OK
    while (resultSet.Next() '=0)
    {
	    k ^||CacheRfQ  //change when one pass is implemented!!!
        set type=resultSet.Get("Type")
        set name =resultSet.Get("Name")
        if type'="CLS" continue
        k ^||CacheRfQ
  		s rfo=##class(%Compiler.COS.Refactor).%New()
  		s rfo.smname=oldName
  		s rfo.tmname=newName
 		s rfo.cmname=classlist
 		s rfo.sqlTableNameList=tablelist
 		s rfo.ssqlname=$g(ssqlname)
 		s rfo.tsqlname=$g(tsqlname)
 		//s rfo.cmname=$lb(memclassName)
 		//s origin=..GetMemberOrigin(oldName,name)
 		//if origin=memclassName s rfo.cmname=rfo.cmname_$lb(name)
  		s rfo.className=name
  		s sc= rfo.oneClass(.tempName,0)
  		//i 'sc {
	  		s Errtxt=$system.Status.GetErrorText(sc)
	  		s Errnum=+$system.Status.GetErrorCodes(sc)
  		//}
  		//s qHandle=$lb(rfo.ctind,"")
		s ll=$o(^||CacheRfQ(rfo.ctind,""))
  		if (ll'="")||'sc {
	  		i $increment(^||CacheXR)
	  		s ^||CacheXR(^||CacheXR)=$lb(name,Errnum,Errtxt)
	  
        }

	// k ^||CacheRfQ
	k rfo


        
    }
	do resultSet.Close()
    s qHandle=""
    Quit $$$OK
}

ClassMethod ChangeMultMemberNameClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ChangeMultClassNameExecute ]
{
	 k ^||CacheXR
	 Quit $$$OK
}

ClassMethod ChangeMultMemberNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ChangeMultClassNameExecute ]
{
 s AtEnd=0,Row=""
	s ll=$o( ^||CacheXR(qHandle))
	if ll="" {
		s AtEnd=1
		Quit $$$OK
	}
	//S Row=$lb(^||CacheXR(ll))
	S Row=^||CacheXR(ll)
	s qHandle=ll
	//w $lg(Row,1)_"|"_$lg(Row,2)
	Quit $$$OK
}

ClassMethod NormalizeClName(clname As %String, context As %String) As %String
{
	if clname="" quit ""
	if $g(context)="" quit clname
	s sc= $$NormalizeClassnameByCom^%occName(.res,clname,context)
	 
	Quit res
}

ClassMethod ChangeCSList(ByRef cslist As %String, oldName As %String, newName As %String, bNormalize As %Boolean, context As %String = "") As %Boolean
{
	s res=0
	
	for ii=1:1:$l(cslist,",") {
		s el=$p(cslist,",",ii)
		if el="" continue
		if bNormalize s sc= $$NormalizeClassnameByCom^%occName(.res,el,$g(context)) s el=res
		if el=oldName {
			s $p(cslist,",",ii)=newName
			s res=1
		}
	}
	 
	Quit res
}

/// The method <b>ChangeClName </b> is used for changing a class name.
/// Arguments: oldName - existing class name,
///            newName - new class name,
///            className - class to be processed,
///            tempName - name of generated clas,s
///            storagechanged - indicate whether storage was modified.
/// In order to replace encounters of the class A to the class B in the class C, the call should be ChangeClName(A, B, C, .tempName, .storagechanged)
/// As a result of this call a new class (with a name returned in tempName) will be created (but not compiled).
ClassMethod ChangeClName(oldName As %String, newName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean, bDeleteStorage As %Boolean = 0) As %Status
{
 k ^||CacheRfQ
 s sc=$$$OK
  s rfo=##class(%Compiler.COS.Refactor).%New()
  s rfo.scname=..NormalizeClName(oldName,className)
  s rfo.tcname=..NormalizeClName(newName,className)
  s rfo.className=className
  s rfo.cmname=""
  s sc= rfo.oneClass(.tempName,1, .storagechanged,0, bDeleteStorage)
  i rfo.ctind'="" k ^||CacheRfQ(rfo.ctind)

  //s qHandle=$lb(rfo.ctind,"")
  k rfo
	//k ^oddDEF(classname_"q")
	Quit sc
}

Query ChangeClassName(oldName As %String, newName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean) As %Query(ROWSPEC = "TYPE:%String,CLASSNAME:%String,OLDMEMBERNAME:%String,NEWMEMBERNAME:%String,LINENUMBER:%Integer,OPERATION:%Integer,LINECONTENT:%String") [ SqlProc ]
{
}

ClassMethod ChangeClassNameExecute(ByRef qHandle As %Binary, oldName As %String, newName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean) As %Status
{
 k ^||CacheRfQ
  s rfo=##class(%Compiler.COS.Refactor).%New()
  s rfo.scname=..NormalizeClName(oldName,className)
  s rfo.tcname=..NormalizeClName(newName,className)
  
  s rfo.className=className
  s rfo.cmname=""
  s sc= rfo.oneClass(.tempName,1, .storagechanged)
  s qHandle=$lb(rfo.ctind,"")
  k rfo

	Quit sc
}

ClassMethod ChangeClassNameClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ChangeClassNameExecute ]
{
	i $g(qhandle)'="",$lg(qHandle,1)'="" k ^||CacheRfQ($li(qHandle,1))
	//k ^oddDEF(classname_"q")
	Quit $$$OK
}

ClassMethod ChangeClassNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ChangeClassNameExecute ]
{
	s AtEnd=0,Row=""
	//s ^||CacheRf(..ctind,linen,"class",..className,..methName,..lnum,"changed")=out1.Read(,.sc)
	s ll=$o(^||CacheRfQ($li(qHandle,1),$li(qHandle,2)))
	if ll="" {
		s AtEnd=1
		Quit $$$OK
	}
	S Row=^||CacheRfQ($li(qHandle,1),ll)
	s $li(qHandle,2)=ll
	//w $lg(Row,1)_"|"_$lg(Row,2)
	Quit $$$OK
}

/// The method <b>ChangeMemName </b> is used for changing a member name (either a property or a method).
/// Arguments: oldName - existing member name,
///            newName - new member name,
///            memclassName -  the class name of a property that is being changed,
///            className - class to be processed,
///            tempName - name of generated clas,s
///            storagechanged - indicate whether storage was modified.
/// In order to replace encounters of the member Z.A to  Z.B in the class C, the call should be ChangeMemName(A, B, Z, C, .tempName, .storagechanged)
/// As a result of this call a new class (with a name returned in tempName) will be created (but not compiled).
ClassMethod ChangeMemName(oldName As %String, newName As %String, memclassName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean, sqlName = "", bNewSlot As %Boolean = 0) As %Status
{
	//memclassname is the class name of a property that is being changed
 k ^||CacheRfQ
 s sc=$$$OK
 //w "SQLNAME* ",sqlname,!
  //s ^qq="here"
      if (memclassName'=""){
	   		
		    s pd=##class(%Dictionary.PropertyDefinition).%Open($lb(memclassName_"||"_oldName),4)
		    if pd'="" {
			    s sfn=pd.SqlFieldName
			    if sfn'="" {
				    s ssqlname=sfn
			    }
			    else {
				    s ssqlname=""
			    }
			    if sqlName '="" {
				    s tsqlname=sqlName
			    }
			    else {
				    s tsqlname="" //newName
			    }
		    }
		    //SqlFieldName
    }

	s tsqlname=sqlName //always!!
	s classlist=..GetSubclasses(memclassName)
	s tablelist=..GetTableList(classlist)

  s rfo=##class(%Compiler.COS.Refactor).%New()
  s rfo.smname=oldName
  s rfo.tmname=newName
  s rfo.sqlTableNameList=tablelist
  s rfo.ssqlname=$g(ssqlname)
  s rfo.tsqlname=$g(tsqlname)
  s rfo.cmname=classlist

  //s rfo.cmname=$lb(memclassName)
  //s origin=..GetMemberOrigin(oldName,className)
  //if origin=memclassName s rfo.cmname=rfo.cmname_$lb(className)
  s rfo.className=className
  s sc= rfo.oneClass(.tempName,1, .storagechanged,bNewSlot,0)
  //s qHandle=$lb(rfo.ctind,"")
  i rfo.ctind'="" k ^||CacheRfQ(rfo.ctind)

  k rfo

	//k ^oddDEF(classname_"q")
	Quit sc
}

Query ChangeMemberName(oldName As %String, newName As %String, memclassName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean, sqlName As %String) As %Query(ROWSPEC = "TYPE:%String,CLASSNAME:%String,OLDMEMBERNAME:%String,NEWMEMBERNAME:%String,LINENUMBER:%Integer,OPERATION:%Integer,LINECONTENT:%String") [ SqlProc ]
{
}

ClassMethod ChangeMemberNameExecute(ByRef qHandle As %Binary, oldName As %String, newName As %String, memclassName As %String, className As %String, ByRef tempName As %String, ByRef storagechanged As %Boolean, sqlName As %String = "") As %Status
{
	//memclassname is the class name of a property that is being changed
 k ^||CacheRfQ
 //w "SQLNAME ",sqlName,!
  //s ^qq="here"
    if (memclassName'=""){
	   		
		    s pd=##class(%Dictionary.PropertyDefinition).%Open($lb(memclassName_"||"_oldName),4)
		    if pd'="" {
			    s sfn=pd.SqlFieldName
			    if sfn'="" {
				    s ssqlname=sfn
			    }
			    else {
				    s ssqlname=pd.Name
			    }
			    if sqlName '="" {
				    s tsqlname=sqlName
			    }
			    else {
				    s tsqlname=newName
			    }
		    }
		    //SqlFieldName
    }


	s classlist=..GetSubclasses(memclassName)
	s tablelist=..GetTableList(classlist)

  s rfo=##class(%Compiler.COS.Refactor).%New()
  s rfo.smname=oldName
  s rfo.tmname=newName
  s rfo.sqlTableNameList=tablelist
  s rfo.ssqlname=$g(ssqlname)
  s rfo.tsqlname=$g(tsqlname)
  s rfo.cmname=classlist

  //s rfo.cmname=$lb(memclassName)
  //s origin=..GetMemberOrigin(oldName,className)
  //if origin=memclassName s rfo.cmname=rfo.cmname_$lb(className)
  s rfo.className=className
  s sc= rfo.oneClass(.tempName,1, .storagechanged)
  s qHandle=$lb(rfo.ctind,"")
  k rfo
  Quit sc
}

ClassMethod ChangeMemberNameClose(ByRef qHandle As %Binary) As %Status
{
	i $g(qhandle)'="",$lg(qHandle,1)'="" k ^||CacheRfQ($li(qHandle,1))
	//k ^oddDEF(classname_"q")
	Quit $$$OK
}

ClassMethod ChangeMemberNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	s AtEnd=0,Row=""
	//s ^||CacheRf(..ctind,linen,"class",..className,..methName,..lnum,"changed")=out1.Read(,.sc)
	s ll=$o(^||CacheRfQ($li(qHandle,1),$li(qHandle,2)))
	if ll="" {
		s AtEnd=1
		Quit $$$OK
	}
	S Row=^||CacheRfQ($li(qHandle,1),ll)
	s $li(qHandle,2)=ll
	//w $lg(Row,1)_"|"_$lg(Row,2)
	Quit $$$OK
}

ClassMethod GetMemberOrigin(memberName As %String, className As %String) As %String
{
	set prop=##class(%Dictionary.CompiledProperty).%OpenId(className_"||"_memberName)
	if prop'="" quit prop.Origin
	set meth=##class(%Dictionary.CompiledMethod).%OpenId(className_"||"_memberName)
	if meth'="" quit meth.Origin
	quit ""
}

///  RefactorStorageProperty takes a classname, property name, and a new property name and changes the name of the property to the new name everywhere in the storage definition.
///  The pNewSlot argument means if pNewSlot=1, don't overwrite the current property storage data location, but provide a new data slot with the new name.
///  The pChanged argument is passed by reference and will be set to 1 if any change is made to any Storage defined for this class.  It will be 0 if no changes are made.
///  Returns %Status value
ClassMethod RefactorStorageProperty(pClassname As %String, pPropName As %String, pNewName As %String, pNewSlot As %Boolean = 0, ByRef pChanged As %Boolean, pSave As %Boolean = 1) As %String [ PublicList = (%ROWCOUNT, %ROWID, SQLCODE, %msg, pPropName, tStorageId, pClassname, tDSDId, tDataAttribute, tDataValueName, tPropDefName, tDVDId, tSPDId) ]
{
	
	#dim tQuestion as iMart.Article
	#dim tSC as %Library.Status = $$$OK
	#dim tDVD As %Dictionary.StorageDataValueDefinition
	#dim tSPD As %Dictionary.StoragePropertyDefinition
	
	&sql(declare storage cursor for select %ID into :tStorageId from %Dictionary.StorageDefinition where parent->name = :pClassname)
	&sql(declare storprop cursor for select %ID, Name into :tSPDId, :tPropDefName from %Dictionary.StoragePropertyDefinition where parent = :tStorageId and Name = :pPropName)
	&sql(declare datadef cursor for select %ID, Attribute into :tDSDId, :tDataAttribute from %Dictionary.StorageDataDefinition where parent = :tStorageId)
	&sql(declare datavaldef cursor for select %ID, Value into :tDVDId, :tDataValueName from %Dictionary.StorageDataValueDefinition where parent = :tDSDId and Value = :pPropName)
	try {
		new %ROWCOUNT,%ROWID,SQLCODE,%msg,tDSDId,tPropDefName,tDataAttribute,tDataValueName,tDVDId,tSPDId,tStorageId
		set pChanged=0
		&sql(open storage)
		if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
		for  {	// for each Storage definition in the class
			if 'pSave&&pChanged quit
			&sql(fetch storage)
			if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
			quit:SQLCODE=100
			
			&sql(open storprop)
			if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
			
			for  {	// For each Property Definition in the Storage
				&sql(fetch storprop)
				if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
				quit:SQLCODE=100
				
					#; Copy the StoragePropertyDefinition entry, including any ChildExtentSize, selectivity, or StreamLocation settings.
				set name1=$p(tSPDId,"||",1),name2=$p(tSPDId,"||",2),name3=$p(tSPDId,"||",3)
				$$$defStorageSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,pNewName,"")
				set tChildExtentSize=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYchildextentsize)
				if tChildExtentSize'="" { 
					if pSave $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,pNewName,$$$cSTORAGEPROPERTYchildextentsize,tChildExtentSize)
					set:'pChanged pChanged=1
				}
				set tSelectivity=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYselectivity)
				if tSelectivity'="" { 
					if pSave $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,pNewName,$$$cSTORAGEPROPERTYselectivity,tSelectivity)
					set:'pChanged pChanged=1
				}
				set tStreamLocation=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3,$$$cSTORAGEPROPERTYstreamlocation)
				if tStreamLocation'="" { 
					if pSave $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,pNewName,$$$cSTORAGEPROPERTYstreamlocation,tStreamLocation)
					set:'pChanged pChanged=1
				}
					#; If this is a replacement of the field, delete the old metadata
				if 'pNewSlot&&pSave { $$$defStorageSubMemberKill(name1,$$$cCLASSstorage,name2,$$$cSDEFproperty,name3) set:'pChanged pChanged=1 }
			}
			&sql(close storprop)
			if SQLCODE<0 set tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)))
			quit:$$$ISERR(tSC)

			&sql(open datadef)
			if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
			
			for  {	// For each Storage Data Definition in the Storage

				&sql(fetch datadef)
				if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
				quit:SQLCODE=100

					// If the StorageDataDefinition Attribute is defined to be this property, replace it
				if $$$defStorageSubMemberKeyGet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,$p(tDSDId,"||",3),$$$cSDEFDATAattribute)=pPropName {
					if pNewSlot {	// define new Data Definition for the new attribute name, leae old Data Definition in place
						if pSave {
							set tNewDataDefName=pNewName
							for i=1:1 {
								quit:'$$$defStorageSubMemberDefined($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,tNewDataDefName)
								set tNewDataDefName=pNewName_i
							}
							$$$defStorageSubMemberKeySet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,tNewDataDefName,$$$cSDEFDATAattribute,pNewName)
							$$$defStorageSubMemberKeySet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,tNewDataDefName,$$$cSDEFDATAstructure,$$$defStorageSubMemberKeyGet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,$p(tDSDId,"||",3),$$$cSDEFDATAstructure))
							$$$defStorageSubMemberKeySet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,tNewDataDefName,$$$cSDEFDATAsubscript,pNewName)
						}
					}
					else {	// replace attribute name only
						if pSave $$$defStorageSubMemberKeySet($p(tDSDId,"||",1),$$$cCLASSstorage,$p(tDSDId,"||",2),$$$cSDEFdata,$p(tDSDId,"||",3),$$$cSDEFDATAattribute,pNewName)
					}
					set:'pChanged pChanged=1
				}

				&sql(open datavaldef)
				if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
			
				for  {	// For each Storage Data Value Definition in the Storage
					&sql(fetch datavaldef)
					if SQLCODE<0 set tSC=$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)) quit
					quit:SQLCODE=100
				
					if pNewSlot {	// add field, leaving old Name/Value pair alone
						set name1=$p(tDVDId,"||",1),name2=$p(tDVDId,"||",2),name3=$p(tDVDId,"||",3)
						set name4=$o($$$defStorageSubSubMemberRaw(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,""),-1)+1	// Get next Name value for Data Value Definition
						if pSave $$$defStorageSubSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,"")
						if pSave $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALvalue,pNewName)
						set:'pChanged pChanged=1
					}
					else {	// replace field name
						if pSave $$$defStorageSubSubMemberKeySet($p(tDVDId,"||",1),$$$cCLASSstorage,$p(tDVDId,"||",2),$$$cSDEFdata,$p(tDVDId,"||",3),$$$cSDEFDATAvalue,$p(tDVDId,"||",4),$$$cSDEFDATAVALvalue,pNewName)
						set:'pChanged pChanged=1
					}
					quit:$$$ISERR(tSC)
				}
				&sql(close datavaldef)
				if SQLCODE<0 set tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)))
				quit:$$$ISERR(tSC)
			}
			&sql(close datadef)
			if SQLCODE<0 set tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)))
			quit:$$$ISERR(tSC)
		}
		&sql(close storage)
		if SQLCODE<0 set tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$$sqlcode^%qarTune(SQLCODE)_"::"_$g(%msg)))
		quit:$$$ISERR(tSC)
	}
	catch(ex) {
		set tSC=ex.AsStatus()
			#; Attempt to close cursors, don't care about errors (probably not-open errors)
		&sql(close storprop)
		&sql(close datavaldef)
		&sql(close datadef)
		&sql(close storage)
	}
	QUIT tSC
}

///  In the SQL text array (by ref) .sql(1:sql)=line, find all occurrences, if
///  any, of field ffn from the table specified by sch=$LB(schema) and
///  tab=$LB(table), and replace them with nuf in the result array (by ref)
///  .nuq(1:nuq)=line , returns %Status
ClassMethod RenameSqlField(ByRef sql As %String, ByRef nuq As %String, ffn As %String, nuf As %String, sch As %String, tab As %String) As %Library.Status [ PublicList = mtc ]
{
	#dim tSC as %Library.Status = $$$OK
	QUIT tSC
}

///  In the SQL text array (by ref) .sql(1:sql)=line, find all occurrences, if
///  any, of field ffn from the tables specified by lbst=$LB(schema.table), and
///  replace them with nuf in the result array (by ref) .nuq(1:nuq)=line ,
///  pChanged=0/1 (by ref) indicates whether anything changed, return %Status.
///  pClassname is the class name the sql statement came from, if any, and its
///  package name is used as the packages argument to comp^%qaqqt
ClassMethod RenameSqlFieldLbst(ByRef sql As %String, ByRef nuq As %String, ffn As %String, nuf As %String, lbst As %String, ByRef pChanged As %Boolean, pClassname As %String = "") As %Library.Status [ PublicList = (backgrnd, err, mcurs, mtag, mtc, SQLCODE) ]
{
	TRY {
		KILL nuq MERGE nuq=sql  ;  return array
		s pChanged=0
		n backgrnd,err,mcurs,%msg,mtag,mtc,SQLCODE
		s backgrnd=1
		s tPackage=$s(pClassname'="":$lb($$$ClassPackageName(pClassname)),1:"")
		d comp^%qaqqt("query",.sql,"findname",,,,,,,tPackage)  ;  AK862
		#;  returns list of all locations of field name FLD:
		#;  mtc(0,"namapf",SCH.TAB.FLD)=$LB(line1,pos1,line2,pos2,...)
		s ffn=$$$UPPER(ffn)
		f ii=1:1:$ll(lbst) {  ;  loop over the different tables, and
			s loc=$g(mtc(0,"namapf",$$$UPPER($lg(lbst,ii))_"."_ffn))
			#;  sort entries in loc(1000000*line+pos)=$LB(line,pos)
			f jj=1:2:$ll(loc) s line=$li(loc,jj),pos=$li(loc,jj+1),loc(line*1000000+pos)=$lb(line,pos)
		}
		QUIT:$d(loc)<9  ;  nothing to replace
		#;  replace all occurances, going backwards from the end
		s jj="" f  s jj=$o(loc(jj),-1,loc) QUIT:'jj  s $e(nuq($li(loc,1)),$li(loc,2),$li(loc,2)+$l(ffn)-1)=nuf
		s pChanged=1
	}
	CATCH { }  ;  If error, ignore and report nothing has changed (behavior asked for by Misha T. 10/17/2012)
	QUIT $$$OK
}

///  In the SQL text array (by ref) .sql(1:sql)=line, find all occurrences,
///  if any, of [schema.]table sntn=schema.table, and replace them with the
///  new schema.table nust in the result array (by ref) .nuq(1:nuq)=line ,
///  pChanged=0/1 (by ref) indicates whether anything changed, return %Status.
///  pClassname is the class name the sql statement came from, if any, and its
///  package name is used as the packages argument to comp^%qaqqt
ClassMethod RenameSqlTable(ByRef sql As %String, ByRef nuq As %String, sntn As %String, nust As %String, ByRef pChanged As %Boolean, pClassname As %String = "") As %Library.Status [ PublicList = (backgrnd, err, mcurs, mtag, mtc, SQLCODE) ]
{
	TRY {
		KILL nuq MERGE nuq=sql  ;  return array
		s pChanged=0
		n backgrnd,err,mcurs,%msg,mtag,mtc,SQLCODE
		s backgrnd=1
		s tPackage=$s(pClassname'="":$lb($$$ClassPackageName(pClassname)),1:"")
		d comp^%qaqqt("query",.sql,"findname",,,,,,,tPackage)
		#;  returns list of all locations of scheme/table names SCH/TAB:
		#;  mtc(0,"namaps",SCH.TAB)=locs  ;  schema name SCH usage
		#;  mtc(0,"namapt",SCH.TAB)=locs  ;  table name TAB usage
		#;  locs=$LB(line1,pos1,line2,pos2,...)  ;  2 entries per usage
		s sntn=$$$UPPER(sntn)
		f st=1,2 {  ;  for the schema name and the table name,
			s loc=$g(mtc(0,"namap"_$e("st",st),sntn))
			#;  sort entries in loc(1000000*line+pos)=$LB(line,pos)
			f jj=1:2:$ll(loc) s line=$li(loc,jj),pos=$li(loc,jj+1),loc(line*1000000+pos)=$lb(line,pos,st)
		}
		QUIT:$d(loc)<9  ;  nothing to replace
		#;  replace all occurances, going backwards from the end
		s jj="" f  s jj=$o(loc(jj),-1,loc) QUIT:'jj  s $e(nuq($li(loc,1)),$li(loc,2),$li(loc,2)+$l($p(sntn,".",$li(loc,3)))-1)=$p(nust,".",$li(loc,3))
		s pChanged=1
	}
	CATCH { }  ;  If error, ignore and report nothing has changed
	QUIT $$$OK
}

}
