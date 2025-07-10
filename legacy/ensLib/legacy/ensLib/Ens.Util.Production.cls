/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.Production Extends %RegisteredObject [ System = 4 ]
{

/// Default whether to exclude source control for Production configuration in the management portal
Parameter DEFAULTSCEXCLUDE = 0;

/// This method returns true if productions in the namespace are excluded from Source Control in 
/// the Production configuration portal page.<br>
/// It will throw system errors such as Protect.
ClassMethod IsExcludedFromPortalSourceControl() As %Boolean
{
	Return +$Get(^EnsPortal.Settings("All","ProductionConfig","ExcludeFromSourceControl"),..#DEFAULTSCEXCLUDE)
}

/// This method sets the flag to control if productions
/// in the current namespace are excluded from Portal Source control.<br>
/// Protected by Use Privilege on resource %Admin_Manage. Throws $$$InsufficientPrivilegeForOperation if privilege not held. <br>
/// Throws $$$InvalidArgument if <parameter>exclude</parameter> is not 1 or 0.<br>
/// It will throw system errors such as Protect.
ClassMethod SetExcludeFromPortalSourceControl(exclude As %Boolean = "")
{
	If '$SYSTEM.Security.Check("%Admin_Manage","U") {

		$$$ThrowStatus($$$ERROR($$$InsufficientPrivilegeForOperation))

	}

	If (exclude'=1) && (exclude'=0) {

		$$$ThrowStatus($$$ERROR($$$InvalidArgument))

	}

	Set ^EnsPortal.Settings("All","ProductionConfig","ExcludeFromSourceControl") = exclude

	Quit
}

/// This method compares the class XData definition with that that would be
/// be generated from the current runtime data for the production.
/// It returns 1 if different. <br>
/// It returns 0 if not different. <br>
/// It returns 10 if an error is being returned. <br>
ClassMethod IsRuntimeDifferentFromClass(pClassName, Output pSC As %Status) As %Integer
{
	#dim ex As %Exception.AbstractException

	#dim tDifferent = 1

	Try {

		/*	Generate a Production object (and its item objects) based on current XData
			This object must not be saved
		*/
		#dim tCurrentClassAsRuntimeProduction As Ens.Config.Production
		Set pSC = ##Class(Ens.Util.XML.Reader).ObjectFromXData(.tCurrentClassAsRuntimeProduction,pClassName,"ProductionDefinition","Ens.Config.Production")
		If $$$ISERR(pSC) Quit
		Set tCurrentClassAsRuntimeProduction.Name=pClassName

		#dim tActiveRuntimeProduction As Ens.Config.Production
		Set tActiveRuntimeProduction = ##class(Ens.Config.Production).%OpenId(pClassName,0,.pSC)
		If $$$ISERR(pSC) Quit

		/*	Generate stream versions of the 2 production objects
			Use same XMLExport settings as Ens.Config.Production::SaveToClass()
		*/
		#dim tClassRuntimeStream = ##class(%Stream.TmpCharacter).%New()
		#dim tActiveRuntimeStream = ##class(%Stream.TmpCharacter).%New()

		Set pSC = tCurrentClassAsRuntimeProduction.XMLExportToStream(tClassRuntimeStream,,"literal,indent")
		If $$$ISERR(pSC) Quit

		Set pSC = tActiveRuntimeProduction.XMLExportToStream(tActiveRuntimeStream,,"literal,indent")
		If $$$ISERR(pSC) Quit

		#; Ought to be same LineTerminator
		If (tClassRuntimeStream.Size'=tActiveRuntimeStream.Size) Quit

		While 'tClassRuntimeStream.AtEnd {

			If tClassRuntimeStream.Read() '= tActiveRuntimeStream.Read() {
				#; rewind to indicate difference if on last Read
				If tClassRuntimeStream.AtEnd Do tClassRuntimeStream.Rewind()
				Quit
			}

		}

		#;If both streams are at the end then we take as the same.
		If tClassRuntimeStream.AtEnd  && tActiveRuntimeStream.AtEnd Set tDifferent = 0

	} Catch ex {Set pSC = ex.AsStatus()}

	If $$$ISERR(pSC) Set tDifferent = 10

	Return tDifferent
}

}
