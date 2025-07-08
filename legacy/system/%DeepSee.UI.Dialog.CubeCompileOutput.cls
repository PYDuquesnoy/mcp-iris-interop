/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This pages shows the output of a DeepSee cube definition compilation.
Class %DeepSee.UI.Dialog.CubeCompileOutput Extends %CSP.Page [ System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		Set tUse = $System.Security.Check("%DeepSee_Architect","USE")||
				$System.Security.Check("%DeepSee_ArchitectEdit","USE")

		If 'tUse {
			Quit
		}
		Set tClass = $G(%request.Data("CUBECLASS",1))
		Set tTrackingId = +$G(%request.Data("TRACKINGID",1))		// DTB946 - Use a tracking ID supplied by the parent dialog
		&html<<html><head></head>>
		&html<<body>>
		If tClass = "" {
			Write $$$TextHTML("Class name is empty. Nothing to compile.")
			&html<</body></html>>
			Quit
		}
		New %SourceControl
		Set tSC = ##class(%CSP.Portal.SourceControl.Util).CreateSourceControl(.tSourceControl,.tCreated)
		If $$$ISOK(tSC) && $get(tCreated) {
			Set %SourceControl = tSourceControl
		}
		// DTB946 - Always set the tracking global using to supplied trackingID instead of $Job
		Set ^IRIS.Temp.DeepSeeCubeCompile($Username,tClass,tTrackingId) = $H
		Write $$$FormatTextHTML($$$Text("Compiling class: %1"),tClass),"<br/>"
		Do %response.Flush()
		&html<<pre>>
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		Set tSC = $System.OBJ.Compile(tClass)
		Kill EscapeObj
		&html<</pre>>
		Write $$$Text("Complete"),"<br/>"
		Do %response.Flush()
		Set ^IRIS.Temp.DeepSeeCubeCompile($Username,tClass,tTrackingId) = "Done"
		If $$$ISERR(tSC) {
			// DTB918 - Report compile errors
			Set ^IRIS.Temp.DeepSeeCubeCompile($Username,tClass,tTrackingId,"error") = tSC
		}
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit $$$OK
}

}
