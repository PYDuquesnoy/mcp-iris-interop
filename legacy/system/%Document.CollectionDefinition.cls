/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class generates a class corresponding to a %Document collection from a collection XData block when it
/// is compiled.
Class %Document.CollectionDefinition Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// This projection is used to keep track of when classes are
/// compiled or deleted.
Projection ClassProjection As %Document.Model.Projection.Collection [ Internal ];

/// This XData section provides the definition of the collection Class.
XData class [ XMLNamespace = "http://www.intersystems.com/pdb/collection" ]
{
}

/// Return an instance of the <class>Oasys.Model.Schema.class</class>
/// meta-data object that describes this Ledger.
/// If there are callback methods, use GenerateAfter to make sure they are compiled first.
ClassMethod %GetModel() As %Document.Model.Schema.collection [ CodeMode = objectgenerator, Final, Internal ]
{
	set tSC = $$$OK
	try {
		kill ^||%Cls(%compiledclass.Name)
		if (%class.Abstract || (%class.Name = "%Document.CollectionDefinition")) {
			do %code.WriteLine(" Quit """"")
		}
		else {
			#; optional localize logic
			#; figure out if this page should provide automatic localization
			#; For library (system) classes, localization occurs for %ZEN domain
			#; For non-library classes, check for non-%DeepSee domain
			set tLocalize = 0
			set DOMAIN = $get(%parameter("DOMAIN"))
			if (%class.System > 0) {
				set tLocalize = (DOMAIN '= "")
			}
			else {
				set tLocalize = (DOMAIN '= "") && (DOMAIN '= "PDB")
			}
				// find XDATA block named $$$OASYSXDATAclassname
			set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||collection")
			do %code.WriteLine(" set tClass = """"")

			if (tIndex '= "") {
				#; get XDATA as stream
				set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
				do tStream.Rewind()

				if (tStream.Size > 0) {

					#; render the stream into cube meta-data object (with children)
					set tReader = ##class(%XML.Reader).%New()

					set tSC = tReader.OpenStream(tStream)
					if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }

					do tReader.Correlate("collection","%Document.Model.Schema.collection")
						// there should be one and only one collection per XDATA (maybe this isn't true but it is for now)
					do tReader.Next(.tClass,.tSC)
					if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }
					if '$isobject(tClass) {
						throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"No collection element defined in %Document collection class"))
					}
					do tReader.Next(.tDummy,.tSC)
					if $isobject(tDummy) {
						throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Only one collection allowed per block in %Document collection class"))
					}
						// validate model
					set tSC = tClass.%Validate()
					if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }

						// generate code to recreate the model definition
					do tClass.%GenerateCode(%code,tLocalize)
						// dispatch to generator class to do the heavy work
					set tSC = ##class(%Document.Model.Generator.collection).%ProcessModel(%class.Name,tClass)
					if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }
				}
			}
			else {
				do %code.WriteLine(" Set tClass = """"")
			}

			do %code.WriteLine(" Quit tClass")
		}
	}
	catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
