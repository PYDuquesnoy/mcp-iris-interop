/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract class to contain functionality common to the three portal pages used in editing rules,
/// <class>EnsPortal.RuleEditor</class>, <class>EnsPortal.ConstraintEditor</class> and <class>EnsPortal.ExpressionEditor</class>.
/// The methods in this class are intended for reuse across all three pages.
Class EnsPortal.Util.RuleSVGCommon [ Abstract, System = 4 ]
{

/// Method to correctly add a click handler to the element in <var>el</el>. <var>handlerMethodname</var> specifies
/// the method of zenPage to invoke when a click or double click occurs. The specified method is expected to accept
/// two arguments, the event and then a boolean flag to indicate whether the click was a double-click or not.
/// The code to determine whether the click is a double-click is moved to the actual click code as it is very
/// browser-dependent as to whether the browser:
/// <ol><li>supports the ondblclick event handler for the target element,</li>
/// <li>accurately reports the number of clicks in event.detail, or</li>
/// <li>supports the use of anonymous functions in event handler assignments.</li></ol>
ClientMethod addClickHandler(el, handlerMethodName) [ Language = javascript ]
{
	if ((!el) || (!handlerMethodName) || (handlerMethodName == '') || (typeof this[handlerMethodName] != 'function')) return;
	if (zenIsHTML5) {
		if (!this._browserFlags) this.updateBrowserFlags();
		if ((this._browserFlags.IE10) || !zenIsIE) { // IE10 doesn't report event.detail, but it supports ondblclick (along with Chrome/FF/Safari)
			el.onclick = function(evt) { zenPage[handlerMethodName](evt,false); };
			el.ondblclick = function(evt) { zenPage[handlerMethodName](evt,true); };
		}
		else { // IE9 doesn't trigger ondblclick, so we use function assignment and rely on event.detail
			el.onclick = function(evt) {
				if (!evt) evt = window.event;
				var isDouble = evt && (evt.detail == 2);
				zenPage[handlerMethodName](evt,isDouble);
			};
		}
	}
	else { // For older browsers, fall back to setting the "onclick" attribute on the element and rely on event.detail
		el.setAttribute('onclick','zenPage.' + handlerMethodName + '(evt,(evt ? (evt.detail == 2) : (window.event ? (window.event.detail == 2) : false)));');
	}
}

/// Helper method to work out whether the browser is IE10 or newer.
/// The <method>addClickHandler</method>() relies on this information to determine how 
/// click events should be handled by the browser.
ClientMethod updateBrowserFlags() [ Language = javascript ]
{
	if (!this._browserFlags) this._browserFlags = {};
	if (zenIsHTML5 && zenIsIE) {
		var userAgent = navigator.userAgent.toString();
		if (6 <= parseInt(userAgent.substring(userAgent.toUpperCase().indexOf('TRIDENT/') + 'Trident/'.length),10)) {
			this._browserFlags["IE10"] = true;
		}
	}
}

}
