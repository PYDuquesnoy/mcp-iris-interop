/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class displays background task info progress
Class %CSP.UI.Portal.Background.TaskInfoOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/%CSP.UI.Portal.Background.TaskInfoOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check("%Admin_Operate","USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&html<<html>>
		Do ..DrawHEAD()
		&html<<body>>
		Set abort = 0
		Set SysBGTaskId = $G(%request.Data("SysBGTaskId",1))
		If '##class(%SYS.BackgroundTask).%ExistsId(SysBGTaskId) {
			Set abort = 1
			Set err = $$$FormatText($$$Text("This system background task Id, %1, no longer exists."),SysBGTaskId)
		}
		Set tObj = ##class(%SYS.BackgroundTask).%OpenId(SysBGTaskId,,.sc)
		If '$IsObject(tObj) {
			Set abort = 1
			Set err = $$$FormatText($$$Text("Unable to open object for this system background task Id, %1."),SysBGTaskId)
		}
		If abort = 1 {
			&html<<div class="errorNote">#(..EscapeHTML(err))#</div>>
			Do ..Exit()	
		}
		If $$$ISERR(sc) { 
			&html<<div class="errorNote">#($system.Status.GetErrorText(sc))#</div>>
		} Else {
			Do ..GUIMonitor(tObj)
		}
		Do ..Exit()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $System.Status.GetErrorText(tSC)	
	}

	Quit $$$OK
}

ClassMethod Exit()
{
	Do %response.Flush()
	&html<</body>>
	&html<</html>>
}

ClassMethod DrawHEAD()
{
	&html<<head><title></title>
	<style type="text/css">
	body {
		font-family: Futura,Arial,sans-serif;
	}
	.errorNote {
		background: #FFFFFF;
		border: 1px solid #da4848;
		border-radius: 4px;
		color: #da4848;
		font-size: 12px;
		font-weight: bold;
		padding: 10px;
		text-align: left;
		display:inline-block;
	}
	progress[value] {
  		width: 400px;
  		height: 20px;
}
	</style>
	>
}

ClassMethod GUIMonitor(pObj)
{
	Try {	
		Set type=$List(pObj.GetDisplayInfo(.array),1)
		$$$THROWONERROR(sc,pObj.%Reload())
		Write "<div>",type_", ID="_pObj.%Id()_", as of ",$zdt($h,3)
		Write "<hr/>"
		Write "<table cellpadding='2'>"
		Do drawline($$$Text("Start Time"),pObj.StartTimeLogicalToDisplay(pObj.StartTime))
		Do drawline($$$Text("Namespace"),pObj.Namespace)
		Do drawline($$$Text("PID"),pObj.PID)
		Do drawline($$$Text("State"),pObj.RunningState)
		For i=1:1 {
			Quit:'$Data(array(i))
			Set qualifiers = $ListGet(array(i),3)
			If qualifiers '[ "p" {
				Do drawline($List(array(i),2),$Property(pObj,$List(array(i),1)))
			}
		}
		If pObj.ProgressTotal {
		  	Set tPercentage = $Justify(pObj.ProgressCurrent/pObj.ProgressTotal*100,0,2)
		  	Write "<tr><td>",$$$TextHTML("Progress"),"</td><td>"
		  	Set progress = tPercentage_"%"
		  	Write "<progress value='",pObj.ProgressCurrent,"' max='",pObj.ProgressTotal,"'</progress>","</td><td>",progress,"</td></tr>"
			If pObj.ProgressUnits '= "" {
				Set progress = pObj.ProgressCurrent_" / "_pObj.ProgressTotal_" "_pObj.ProgressUnits
				Write "<tr><td>&nbsp;</td><td>",progress,"</td></tr>"
			}
		} ElseIf pObj.ProgressCurrent && (pObj.ProgressUnits'="") {
			Set progress = pObj.ProgressCurrent_" "_pObj.ProgressUnits 
			Write "<tr><td>",$$$TextHTML("Progress"),"</td><td>",progress,"</td></tr>"
		}
		For i=1:1 {
			Quit:'$Data(array(i))
			Set qualifiers = $ListGet(array(i),3)
			If qualifiers [ "p" {
				Do drawline($List(array(i),2),$Property(pObj,$List(array(i),1)))
			}
		}
		Set finalstatus = $select(pObj.FinalStatus="":"",$$$ISOK(pObj.FinalStatus):$$$Text("OK"),1:$system.Status.GetErrorText(pObj.FinalStatus))
		If finalstatus '= "" {
			Write:finalstatus'="" "<tr><td>",$$$TextHTML("Final Status"),":</td><td colspan='2'>",..EscapeHTML(finalstatus),"</td></tr>"
		}		
		Write "</table>"
		Write "<hr/>"
	} Catch err {
		If $G(err) {
			Write "<div class='errorNote'>","Error in Monitor: ",err.DisplayString(),"</div>"
		}
	}
	Quit
drawline(label,value)
	Write:value'="" "<tr><td>",..EscapeHTML(label),":</td><td>",..EscapeHTML(value),"</td></tr>"
	Quit
}

}
