/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// For Studio temaplates make sure they stay until the Studio connection is closed.
Class %CSP.StudioTemplateEvent Extends %CSP.SessionEvents [ System = 4 ]
{

/// Handle EndSession event
ClassMethod OnEndSession()
{
	#; Do not allow this session to close if the Studio connection is still active
	Set sessionId=%session.SessionId
	Lock +^%StudioTemplate(sessionId):0 Else  Set %session.EndSession=0
	Lock -^%StudioTemplate(sessionId)
	Quit
}

}
