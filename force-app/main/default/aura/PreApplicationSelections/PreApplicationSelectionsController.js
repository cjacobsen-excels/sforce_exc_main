/**
 * Created by mnahar on 24/06/21.
 */

({
    doInit: function (component, event, helper) {
        //debugger;
        helper.fetchTermPicklist(component);
    },

    onTermChange: function (component, event, helper) {
        let selectedTerm = component.find('selectTerm').get('v.value');
        if (selectedTerm !== undefined && selectedTerm !== '--None--') {
            component.set("v.selectedTermValue", selectedTerm);
            //Reset Area of Interest
            let selectedArea = component.get("v.selectedAreaValue");
            if (selectedArea !== undefined && selectedArea !== '--None--') {
                component.set("v.showArea", "true");
                component.find('selectArea').set('v.value', '--None--');
                component.set("v.showLevel", "false");
                component.set("v.showAccounts", "false");
            }
            //Get picklist values, runs only once
            let areaPicklist = component.get("v.AreaOfInterestPicklist");
            if (areaPicklist === undefined || areaPicklist.length === 0) {
                helper.fetchAreaOfInterestPicklist(component);
            }
        } else {
            component.set("v.showArea", "false");
            component.set("v.showLevel", "false");
            component.set("v.showAccounts", "false");
            component.set("v.selectedTermValue", '');
            component.set("v.selectedAreaValue", '');
            component.set("v.selectedLevelValue", '');
            component.set("v.selectedAccountValue",'');
            component.set("v.showApplyButton", false);
        }
    },

    onAreaChange: function (component, event, helper) {
        let selectedArea = component.find('selectArea').get('v.value');
        if (selectedArea !== undefined && selectedArea !== '--None--') {
            component.set("v.selectedAreaValue", selectedArea);
            //Reset Level of Interest
            let selectedLevel = component.get("v.selectedLevelValue");
            if (selectedLevel !== undefined && selectedLevel !== '--None--') {
                component.set("v.showLevel", "true");
                component.find('selectLevel').set('v.value', '--None--');
                component.set("v.showAccounts", "false");
                component.set("v.selectedAccountValue",'');
            }
            //Get picklist values, runs only once
            let levelPicklist = component.get("v.LevelOfInterestPicklist");
            if (levelPicklist === undefined || levelPicklist.length === 0) {
                helper.fetchLevelOfInterestPicklist(component);
            }
        } else {
            component.set("v.showLevel", "false");
            component.set("v.showAccounts", "false");
            component.set("v.selectedAreaValue", '');
            component.set("v.selectedLevelValue", '');
            component.set("v.selectedAccountValue", '');
            component.set("v.showApplyButton", false);
        }
    },

    onLevelChange: function (component, event, helper) {
        let selectedLevel = component.find('selectLevel').get('v.value');
        if (selectedLevel !== undefined && selectedLevel !== '--None--') {
            component.set("v.selectedLevelValue", selectedLevel);
            helper.fetchAcademicPrograms(component);
        } else {
            component.set("v.selectedLevelValue", '');
            component.set("v.showAccounts", "false");
            component.set("v.selectedAccountValue", '');
            component.set("v.showApplyButton", false);
        }
    },

    onAccountChange: function (component, event, helper) {
        let selectedAccount = component.find('selectAccount').get('v.value');
        if (selectedAccount !== undefined && selectedAccount !== '--None--') {
            component.set("v.selectedAccountValue", selectedAccount);
            component.set("v.showApplyButton", true);
        }else {
            component.set("v.showApplyButton", false);
        }
    },

    handleApply: function (component, event, helper) {
        let urlString = window.location.href;
        let baseURL = urlString.substring(0, urlString.indexOf("/s"));
        component.set("v.cbaseURL", baseURL);
        debugger;
        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": baseURL+'/s/application?programId=' +  component.get("v.selectedAccountValue")
        });
        urlEvent.fire();
    }

});