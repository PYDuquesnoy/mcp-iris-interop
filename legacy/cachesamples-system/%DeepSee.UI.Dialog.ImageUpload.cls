/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This dialog lets the user upload an image into the "covers" directory.<br/>
Class %DeepSee.UI.Dialog.ImageUpload Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Image Upload";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Name of image file.
Property fileName As %ZEN.Datatype.string(ZENURL = "FILE");

XData Style
{
<style type="text/css">

body {
	font-family: arial;
}

#preview {
	max-width: 500px;
	max-height: 500px;
	overflow: auto;
}

#preview img {
	max-width: 500px;
	max-height: 500px;
}

a.imageLink {
	padding: 8px;
}

.imagePreview {
	border: 1px solid gray;
	box-shadow: 4px 4px 4px black;
}

a.imageLink img {
	border: 1px solid #F0F0F0;
}
a.imageLink:hover img {
	border: 1px solid #404040;
	box-shadow: 4px 4px 4px #808080;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<!-- edit form -->
<vgroup>

<form id="theForm" enctype="multipart/form-data" cellStyle="padding:3px;">
<fileUpload id="ctrlUpload" label="File to upload" name="File" size="30" onchange="zenPage.changeImage();" accept="image/*"/>
<hidden id="ctrlName" name="Name"/>
<submit id="ctrlSave" caption="Save" controlStyle="font-size:12pt;width:100px;" disabled="true"/>
</form>

<image id="preview"/>
<label label="For book covers the ideal image is 134 pixels wide by 190 pixels tall"/>


</vgroup>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Image Upload")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Upload images to the server")
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()

	If (..fileName'="") {
		Set tImage = ..%GetComponentById("preview")
		Set tImage.src = "covers/"_..fileName
	}
	Quit tSC
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return true;
}

/// User has selected a new image.
ClientMethod changeImage() [ Language = javascript ]
{
	var file = zen('ctrlUpload').getValue();
	if (file==''){ //special case to handle the file name reset on clicking cancel in Chromium-based browsers
		zen('ctrlSave').setProperty('disabled',true);
		zen('ctrlName').setValue(file);
		return;
	}
	// pull off the file name (different for each browser)
	file = file.toString().replace(/\\/g,'/');
	var t = file.split('/');
	file = t[t.length-1]; 
	var ext = file.substr(file.lastIndexOf('.')+1).toLowerCase()
	var allowedTypes=['tiff', 'jfif', 'bmp', 'gif', 'svg', 'png', 'jpeg', 'svgz', 'jpg', 'webp', 'ico', 'xbm', 'dib', 'pjp', 'apng', 'tif', 'pjpeg', 'avif']
	
	if (allowedTypes.includes(ext)){
		zen('ctrlSave').setDisabled(file=='');
		zen('ctrlName').setValue(file);
	}
	else{
		alert('Invalid file type: "'+ext+'". The file must be of one of the following types: '+allowedTypes.join(', '));
	}
}

/// This callback is called when a form on this page is submitted.
/// <var>pSubmit</var> is a <class>%ZEN.Submit</class> object
/// containing details of the form submit.<br/>
/// Subclasses override this method.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK
	Try {
		// copy image to "covers" directory
		Set tStream = pSubmit.%GetStream("File")
		Set tName = $$$LOWER(pSubmit.%GetValue("Name"))
		Set tExt = $ZCVT($P(tName, ".",*),"L")
		Set tAllowedTypes = $lb("tiff", "jfif", "bmp", "gif", "svg", "png", "jpeg", "svgz", "jpg", "webp", "ico", "xbm", "dib", "pjp", "apng", "tif", "pjpeg", "avif")
		If $LF(tAllowedTypes, tExt){
			If $IsObject(tStream)&&(tName'="") {
				Set tFileName = ##class(%File).NormalizeDirectory(tName,..%GetImageDirectory())
				Set tLocalFile = ##class(%File).%New(tFileName)
				Set tSC = tLocalFile.Open("WUNK\RAW\")
				If $$$ISERR(tSC) Quit
				
				Set tSC = tLocalFile.CopyFrom(tStream)
				If $$$ISERR(tSC) Quit
				Do tLocalFile.Close()
			}

			// show the saved image
			Set %response.Context("FILE") = tName
		}
		Else{
			Set tSC=$$$ERROR($$$InvalidFileType, """"_tExt_""". Valid file types are: "_$ListToString(tAllowedTypes, ", "))
		}
		
		// remember popup info
		Set %response.Context("$ZEN_POPUP") = 1
		Set %response.Context("$ZEN_SOFTMODAL") = 1
		Set %response.Context("$ZEN_POPUPPARENT") = +$G(%request.Data("$ZEN_POPUPPARENT",1))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the physical directory in which cover images files are stored.
ClassMethod %GetImageDirectory() As %String [ CodeMode = expression ]
{
$SYSTEM.CSP.GetFileName("/csp/broker/covers/")
}

}
