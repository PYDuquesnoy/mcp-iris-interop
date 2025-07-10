/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used by the Production Configuration UI; it is not
/// for direct use within an application.
Class EnsPortal.Component.categorySelector Extends %ZEN.Portal.selector [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

Parameter DOMAIN = "Ensemble";

/// Overridden to provide free text entry field in addition to select
ClassMethod %RenderDropdown(pIndex As %Integer, pContext As %String, pSearchKey As %String, pMultiSelect As %Boolean, pSeparator As %String = ",") As %Status
{
	Set tSC = $$$OK
	Try {
		Write "<div class=""selectorModalBox"">"
		Set tSearchKey = pSearchKey
		If pMultiSelect {
			Set tSearchKey = ""
		}
		// invoke search
		Set tCaption = ""
		Set tSC = ##class(%ZEN.Portal.ContextSearch).%Search(.tCaption,.tTopResults,.tResults,pContext,tSearchKey)
		If ($$$ISERR(tSC)) {
			Do $System.Status.DecomposeStatus(tSC,.tMsg)
			Write "<div>"_ $ZCVT(tMsg(1),"O","HTML") _ "</div></div>"
			Quit
		}
		// Add text box to allow typing one or more new categories
        Write "<div style='white-space: nowrap;'>"
        Write "<input type='text' placeholder='Type to add new or select' id='userEnteredCategoryID' name='userEnteredCategory' size='32' style='font-style:italic;'/>"
        Write "<a title='Accept Typed Text' onclick=""zenPage.getComponent("_pIndex_").updateCategoryOptions(); return false;"">&nbsp;&check;</a>"
        Write "</div>"

		/* Account for after the first time manual entering of a category
			using the drop down feature and the user has yet to click Apply
			and they wish to enter more - we need to show what has been typed already
			but not yet saved.
		*/
		If ('$D(tResults))&&(pSearchKey="") {
			Write "<div onclick=""zenPage.getComponent("_pIndex_").selectItem(null);""><i>"_$$$Text("No results","%ZEN") _ "</i></div></div>"
			Quit
		}

		If (tCaption '= "") {
			Write "<div class=""selectorCaption"">"_$ZCVT(tCaption,"O","HTML")_"</div>"
		}

		Set tRowNo = 0

		// show list of results
		If ($D(tTopResults))||($D(tTextFieldList)) {
			Set n = $O(tTopResults(""))
			While (n'="") {
				Set tRowNo = tRowNo + 1
				Write "<a class=""selectorItem"" href=""#"" onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tTopResults(n),"""","&quot;"),"O","JS")_"');return false;"">"_$ZCVT(tTopResults(n),"O","HTML")_"</a>"
				Set n = $O(tTopResults(n))
			}
			Write "<div style=""margin-bottom:1px; height:2px; border-bottom:1px solid gray;"">&nbsp;</div>"
		}

		If pMultiSelect {
			For i=$length(pSearchKey, pSeparator):-1:1 {
				Set tCurrVal = $zstrip($piece(pSearchKey, pSeparator, i),"<>W")
				If tCurrVal '= "" Set tCurrentValues(tCurrVal) = ""
			}
            /* get duplicate list based on text box since
             might be out of sync with server side before apply
             due to free text entry */
            Merge tTextFieldList=tCurrentValues
		}

		// merge newly typed categories
		Set n = $O(tResults(""))
		While (n'="") {
			Set tResult = $get(tResults(n))
			If tResult'="" {
				Kill tTextFieldList(tResult)
				Set tResultsByName(tResult) = ""
			}
			If '$Data(tTextFieldList) Quit
			Set n = $O(tResults(n))
		}
		If $Data(tTextFieldList) {
			// need to merge in correct order to tResults
			Merge tResultsByName = tTextFieldList
			Kill tResults
			Set tResult = $Order(tResultsByName(""))
			Set n = 0
			While tResult'="" {
				Set tResults($i(n)) = tResult
				Set tResult = $Order(tResultsByName(tResult))
			}
		}

		// iterate through the results
        Set n = $O(tResults(""))
		While (n'="") {
			Set tFound = 0
			Set tChecked = ""
			Set tResult = $get(tResults(n))
            If tResult'="" Kill tTextFieldList(tResult)
			Set tResultHTML = $ZCVT(tResult,"O","HTML")
			If pMultiSelect { // see if this is a current value
				Set tCurrVal = $O(tCurrentValues(""))
				While (('tFound) && (tCurrVal '= "")) {
					If (tCurrVal = tResult) {
						Set tChecked = " checked=""true"""
						Set tFound = 1
					}
					Set tCurrVal = $order(tCurrentValues(tCurrVal))
				}
				Write "<a class=""selectorItem"" href=""#"" title=""" _ tResultHTML _ """ onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tResult,"""","&quot;"),"O","JS")_"');return true;""><input id=""multiSelect."_pIndex_"."_tResultHTML_""" type=""checkbox"" "_tChecked_"/>"_ tResultHTML _"</a>"
			}
			Else {
				Set tRowNo = tRowNo + 1
				Write "<a class=""selectorItem"_$S(tRowNo#2:"",1:"Odd")_""" href=""#"" title=""" _ tResultHTML _ """ onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tResult,"""","&quot;"),"O","JS")_"');return false;"">"_tResultHTML_"</a>"
			}
			Set n = $O(tResults(n))
		}

        Write "</div>"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User has requested accepted typed category
/// The options drop down is left open and hence
/// need to update if new category.
/// If typed an existing category then advise - 
/// user will need to select or deselect.
ClientMethod updateCategoryOptions() [ Language = javascript ]
{
	var newCatValue = document.getElementById('userEnteredCategoryID').value;
	// need to split on , in case user entered more than 1
	var newCats = newCatValue.split(",");
	for (var newCat of newCats) {
		if (newCat!='') {
			/* find if already defined since selecting if defined
				will lead to it being unselected. */
			var addCat = true;
			var addAfterOption = '';
			var collection = document.getElementsByClassName('selectorModalBox');
			if ((collection)&&(collection.length==1)) {
				var options = collection[0].getElementsByClassName('selectorItem');
				for (var i = 0; i < options.length; i++) {
					// find if already in list
					if (options.item(i).text == zenEscapeHTML(newCat)) {
						addCat = false;
						break;
					} else {
						// or where to insert - does this item text collates after newCat
						if (options.item(i).text.localeCompare(newCat)>0) {
							break;
						} else {
							addAfterOption = i;
						}
					}
				}
				if (addCat) {
					this.selectItem(newCat);
					/* Add to the options list in the correct place
						Create same as ObjectScript in %RenderDropdown */
					var newOption = document.createElement('a');
					newOption.setAttribute('class', 'selectorItem');
					newOption.setAttribute('href', '#');
					newOption.setAttribute('title', newCat);
					// need newCat to be $ZCVT($Replace(tResult,"""","&quot;"),"O","JS")
					newOption.setAttribute('onclick', 'zenPage.getComponent('+this.index+').selectItem(\''+zenEscapeJS(newCat)+'\');return true;');
					var newOptionInput = document.createElement('input');
					// need newCat to be newCat HTML
					newOptionInput.setAttribute('id','multiSelect.'+this.index+'.'+zenEscapeHTML(newCat));
					newOptionInput.setAttribute('type','checkbox');
					newOptionInput.setAttribute('checked',true);
					var newOptionText = document.createTextNode(zenEscapeHTML(newCat));
					newOption.appendChild(newOptionInput);
					newOption.appendChild(newOptionText);
					if ((options.length===0)||(addAfterOption===(options.length-1))) {
						// empty list or place at end
						collection[0].appendChild(newOption);
					} else {
						if (addAfterOption === '') {
							// insert as new first
							options.item(0).parentNode.insertBefore(newOption, options.item(0));
						} else {
							// insert after the addAfterOption index
							options.item(addAfterOption).parentNode.insertBefore(newOption, options.item(addAfterOption).nextSibling);
						}
					}
				} else {
					alert(zenEscapeJS(newCat)+' category already exists');
				}
				document.getElementById('userEnteredCategoryID').value = '';
			}

		}
	}
}

}
