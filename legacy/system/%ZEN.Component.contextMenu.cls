/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.contextMenu
Class %ZEN.Component.contextMenu Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for COMP_NAME." */
.contextMenu {
     display:none;
     position:absolute;
     background-color: white;
     border:2px outset #b0b0b0;
     padding: 2px;
     width: 150px;
  }

  .shadow {
      background-image: url(images/shadow.png);
  }
</style>
}

Method %DrawHTML()
{
	&html<<div class="contextMenu" id="#(..%MakeId("contextMenu"))#" >>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
		case "hidden":
		case "disabled":
			var div = this.getEnclosingDiv();
			var m = div.item;
			if (value) ZMS.disableMenuNode(m);
			else ZMS.enableMenuNode(m);
			var cm = ZLM.getAncestor(div,"csMenuItem");
 			if (cm) {
	 			var idx = cm.id.split('_')[1];
	 			var parentPick = zenPage.getComponent(parseInt(idx,10));
	 			if (parentPick) parentPick.setProperty("disabled",value);
 			}
			break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	this.invokeSuper('onloadHandler',arguments);
    ZMS.initialize();
	var div = this.getEnclosingDiv();
	for (var k=div.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="contextMenu") {
           ZMS.estimateContextMenuSize(k);
           ZMS.setContextMenuSize(k);
           div.item=k;
           if (this.hidden || this.disabled) this.setProperty("disabled",true);
          return;
		}
	}
	div.style.display = "none";
}

ClientMethod onRefreshContents() [ Language = javascript ]
{
	// After a refresh there should be a new master menu layout as a
	// child of the enclosing div but there may also be a fully initialized
	// menu hanging off of the mouse trap (due to an artifact of zen, these
	// two DOM object will have overlapping Ids and must be manually resolved
	var pObj = this.parent;
	var pDiv = pObj.getEnclosingDiv();
	var eDiv = this.getEnclosingDiv();
	eDiv.style.display = "none";
	var newMenu = null;
	// Find and save the new blueprint
	for (var k=eDiv.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="contextMenu") {
			newMenu = k;
			eDiv.removeChild(k);
		}
	}
	// Uninstall any prior menu
	if (!this.uninstalled) {
		ZLM.setLocalAttribute(pDiv,"oncontextmenu","");
		var mDiv = document.getElementById("contextMenu_"+this.index);
		if (mDiv) {
			if (mDiv.parentNode && mDiv.parentNode!=eDiv) {
				if (mDiv.shadowDiv) mDiv.parentNode.removeChild(mDiv.shadowDiv);
				mDiv.shadowDiv = null;
				mDiv.parentNode.removeChild(mDiv);
			}
		}
	}
	// Put back our new master copy and make sure its node are properly initialized
	eDiv.appendChild(newMenu);
	this.reinitChildren(newMenu);
	// Reinstall the new menu
    ZMS.estimateContextMenuSize(newMenu);
    ZMS.setContextMenuSize(newMenu);
    eDiv.item=newMenu;
    if (this.hidden || this.disabled) this.setProperty("disabled",true);
	if (this.uninstalled) {
		this.uninstalled = false;
		this.uninstall();
	}
}

/// Reinitialize a csMenuItem child of this menu that has been refreshed
/// from the server.  This needs to be done here (as opposed to in the 
/// csMenuItem's own update hander because update event propagate DOWN the 
/// DOM tree and contextMenu needs its children to be refreshed first, before 
/// it can update itself.
ClientMethod reinitChildren(menuDiv) [ Language = javascript ]
{
	for (var div = menuDiv.firstChild;div!=null;div=div.nextSibling) {
		// each DIV should be the enclosing div of a csMenu Item or Separator
		for (var k=div.firstChild;k!=null;k=k.nextSibling) {
			if (k.nodeType==1 && k.className=="csMenuItem") {
				var item = zenPage.getComponent(parseInt(div.getAttribute("zen"),10));
				if (item) item.initializeClientSideProjection();
			}
		}
	}
}

/// Remove this context menu from its parent context, severing its
/// ties to local event handling.  Note that this call does not remove 
/// the base logical menu structure from the client-side DOM (allowing it to 
/// be reinstalled at a later time)
ClientMethod uninstall() [ Language = javascript ]
{
	if (this.uninstalled) return;
	alert("Uninstall...");
	var pDiv = this.parent.getEnclosingDiv();
	var eDiv = this.getEnclosingDiv();
	ZLM.setLocalAttribute(pDiv,"oncontextmenu","");
	var mDiv = document.getElementById("contextMenu_"+this.index);
	if (mDiv) {
		if (mDiv.parentNode && mDiv.parentNode!=eDiv) {
			if (mDiv.shadowDiv) mDiv.parentNode.removeChild(mDiv.shadowDiv);
			mDiv.shadowDiv = null;
			mDiv.parentNode.removeChild(mDiv);
			eDiv.appendChild(mDiv);
		}
	}
	this.uninstalled = true;
}

/// Reconnect a previously uninstalled context menu to a new parent context, 
/// enabling its ties to local event handling. The parameter passed must be a
/// decendant of Zen.Component.group to ensure proper handling.  
ClientMethod reinstall(pGroup) [ Language = javascript ]
{
	if (!this.uninstalled) return;
	this.uninstalled = false;
	
	var pDiv = pGroup.getEnclosingDiv();
	var eDiv = this.getEnclosingDiv();
	if (eDiv.parentNode) eDiv.parentNode.removeChild(eDiv);
	pDiv.insertBefore(eDiv,pDiv.firstChild);
	for (var k=eDiv.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="contextMenu") {
           ZMS.estimateContextMenuSize(k);
           ZMS.setContextMenuSize(k);
           eDiv.item=k;
           if (this.hidden || this.disabled) this.setProperty("disabled",true);
          return;
		}
	}
}

}
