/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a utility class that provides an API for serializing objects
/// to a wire protocol for interchange with remote systems.
Class %Net.Serializer [ Abstract, System = 3 ]
{

/// This method performs automatic validation of an object's attribute values. 
/// It is called by <METHOD>%Save</METHOD> before persistent objects are stored to the database.
/// <p><METHOD>%ValidateObject</METHOD> does the following:
/// <ol>
/// <li>It tests if any required property values are missing.</li>
/// <li>If specified (if the <i>PROPERTYVALIDATION</i> class parameter is set to <i>ValidateOnSave</i>), 
/// it tests property validation.</li>
/// <li>If present, it will call a user-supplied <METHOD>%OnValidateObject</METHOD> method.</li>
/// </ol>
/// 
/// <p>If any of these tests fail, <METHOD>%ValidateObject</METHOD> immediately returns an error value. 
/// <METHOD>%Save</METHOD> (if it is the caller of <METHOD>%ValidateObject</METHOD>) will stop its operation, 
/// rollback any transactions it has started, and also return.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// Serialize this object instance to a special wire format.
Method %Serialize(ByRef ref) As %Status [ CodeMode = objectgenerator, Internal ]
{
	k ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name)
	Set $ZT="Trap",tSC=$$$OK
	Do {
		d %code.WriteLine("	i $d(ref(""""_$this)) q $$$OK")
		d %code.WriteLine("	Set ref(""""_$this)=$this")

		Do %code.WriteLine(" Set tSC=$$$OK")
		//Do %code.WriteLine(" w ""Serialization of "",$this,!")
		Do %code.WriteLine(" i $zobjexport($this_"""",3)")
		
        #; get list of client property objects in alpha-order
        #; sort by datatype v. object valued properties
		For n = 1:1:%compiledclass.Properties.Count() {
			Set tProp = %compiledclass.Properties.GetAt(n)
			
			#; get normalized type of property
			Set tType = tProp.Type
		
			#; figure out the classtype for the property
			#; first normalize the type name
			If ((tType '[ ".") && (tType '[ "%")) {
				#; assume this type belongs to our package
				Set tType = $P(tProp.parent.Name,".",1,$L(tProp.parent.Name,".")-1) _ "." _ tType
			}
			Set tType = $$$NormalizeClassname(tType)
			
			#; put property into appropriate list
			#; at each node we encode additional info about the property
			#; M: multidimensional
			#; L: list collection
			#; A: array collection
			If ($$$classIsDataType(tType)) {  //skip collections for now
				if ('+tProp.Calculated)/*!(tProp.Collection'="")*/ Set tDTProperties(tProp.Name) = $S(+tProp.MultiDimensional:"M",1:"")_$S(tProp.Collection="list":"L",tProp.Collection="array":"A",1:"")
			}
			Else {
				Set tObjProperties(tProp.Name) = $S(tProp.Collection="list":"L",tProp.Collection="array":"A",1:"")
			}
		}
		
		#; cache the serialization data so we can use it again in %Deserialize
		Merge ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"DTProperties") = tDTProperties
		Merge ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"ObjProperties") = tObjProperties
		

		#; walk down list of datatype properties
		Set tName = $O(tDTProperties(""))
		While (tName '= "") {
			#; flag can be M,A,L
			Set tFlag = tDTProperties(tName)

			#; generate CODE here!!!
			If (tFlag [ "L") {
				//Do %code.WriteLine(" Write .." _ tName _"),!")
				Do %code.WriteLine(" i $zobjexport(.." _ tName _".Count(),3)")
				Do %code.WriteLine(" for ii=1:1:.." _ tName _".Count()  i $zobjexport(.." _ tName _".GetAt(ii),3)")

			}
			elseif  (tFlag [ "A"){
				 Do %code.WriteLine(" i $zobjexport(.." _ tName _".Count(),3)")
				 Do %code.WriteLine(" s key="""" for ii=1:1:.." _ tName _".Count() s key=.." _ tName _".Next(key) i $zobjexport(key,3)!1 i $zobjexport(.." _ tName _".GetAt(key),3)")

			}

			ElseIf (tFlag [ "M") {
				//Do %code.WriteLine(" Write $G(.." _ tName _"),!")
				Do %code.WriteLine(" i $zobjexport($G(.." _ tName _"),3)")

			}
			else {
				//Do %code.WriteLine(" Write .." _ tName _",!")
				Do %code.WriteLine(" i $zobjexport(.." _ tName _",3)")

			}

			#; next property
			Set tName = $O(tDTProperties(tName))
		}
				#; walk down list of object properties
		Set tName = $O(tObjProperties(""))
		While (tName '= "") {
			#; flag can be M,A,L
			Set tFlag = tObjProperties(tName)

			#; generate CODE here!!!
			If (tFlag [ "L") {
				Do %code.WriteLine(" s objlcoll(""" _ tName _""")=.." _ tName _".Count()")
				Do %code.WriteLine(" i $zobjexport(.." _ tName _".Count(),3)")
				Do %code.WriteLine(" for ii=1:1:.." _ tName _".Count() s objlcoll(""" _ tName _""",ii)=.." _ tName _".GetAt(ii) i $zobjexport(.." _ tName _".GetAt(ii)_"""",3)")
			}
			elseif  (tFlag [ "A"){
			}

			else {
			
			//Do %code.WriteLine(" Write .." _ tName _",!")
			Do %code.WriteLine(" i $zobjexport(.." _ tName _"_"""",3)")
			}

			
			#; next property
			Set tName = $O(tObjProperties(tName))
		}
		Do %code.WriteLine(" i $zobjexport(-2,3)") //Mark the object end

				#; walk down list of object properties
		Set tName = $O(tObjProperties(""))
		While (tName '= "") {
			#; flag can be M,A,L
			Set tFlag = tObjProperties(tName)

			#; generate CODE here!!!
			If (tFlag [ "L") {
				Do %code.WriteLine(" for ii=1:1:objlcoll(""" _ tName _""") d objlcoll(""" _ tName _""",ii).%Serialize(.ref)")
			}
			elseif  (tFlag [ "A"){
			}
			else {
			Do %code.WriteLine(" if .."_tName_"'="""" d .."_tName_".%Serialize(.ref)")
			}
			
			
			#; next property
			Set tName = $O(tObjProperties(tName))
		}
		


		Do %code.WriteLine(" Quit tSC")

	} While(0)

Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Deserialize wire data back into an object instance.
Method %Deserialize(ByRef tref, current As %Integer) As %Status [ CodeMode = objectgenerator, GenerateAfter = %Serialize, Internal ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Do %code.WriteLine(" Set tSC=$$$OK")
		Do %code.WriteLine(" Set tref(current)=$this")

		#; get the cached info on properties
		Merge tDTProperties = ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"DTProperties")
		Merge tObjProperties = ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"ObjProperties")
		


		#; walk down list of datatype properties
		Set tName = $O(tDTProperties(""))
		While (tName '= "") {
			#; flag can be M,A,L
			Set tFlag = tDTProperties(tName)
			
			If (tFlag [ "L") {
				Do %code.WriteLine(" s count=$zobjexport(12)")
				Do %code.WriteLine(" f ii=1:1:count d .." _ tName _".InsertAt($zobjexport(12),ii)")
			}
						elseif  (tFlag [ "A"){
				Do %code.WriteLine(" s count=$zobjexport(12)")
				Do %code.WriteLine(" f ii=1:1:count s key=$zobjexport(12) d .." _ tName _".SetAt($zobjexport(12),key)")

			}
			else {
			
				Do %code.WriteLine(" s .." _ tName _"=$zobjexport(12)")
			}

			#; next property
			Set tName = $O(tDTProperties(tName))
		}
		#; walk down list of object properties
		Set tName = $O(tObjProperties(""))
		While (tName '= "") {
			Set tFlag = tObjProperties(tName)
			#; flag can be M,A,L
			If (tFlag [ "L") {
				Do %code.WriteLine(" s count=$zobjexport(12)")
				Do %code.WriteLine(" s tref(current,"""_tName_",L"") =count")
				Do %code.WriteLine(" f ii=1:1:count s tref(current,"""_tName_",L"",ii)=$zobjexport(12)")

						
		

			}
			elseif  (tFlag [ "A"){
			}

			else {
				#; generate CODE here!!!
				//Do %code.WriteLine(" Write .." _ tName _",!")
				d %code.WriteLine(" s tref(current,"""_tName_""")=$zobjexport(12)")
				Do %code.WriteLine(" s .." _ tName _"=""""")
				
			}

			
			
			#; next property
			Set tName = $O(tObjProperties(tName))
		

		}
		
		Do %code.WriteLine(" i $zobjexport(12)'=-2 s tSC=$$$ERROR($$$ObjectScriptError,""serialization mismatch"")") //Mark the object end


		Do %code.WriteLine(" Quit tSC")
	} While(0)


Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
