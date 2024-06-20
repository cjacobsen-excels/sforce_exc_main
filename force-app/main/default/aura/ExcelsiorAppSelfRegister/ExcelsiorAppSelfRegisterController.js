({
    initialize: function(component, event, helper) {
        helper.getExtraFields(component, event, helper);
        var vfURL = $A.get("$Label.c.VF_Host");
        window.addEventListener('message', $A.getCallback(function(event){
            let myButton = component.find("submitButton");
            if(event.origin !== vfURL) {
                return;
            }
            if(event.data.name === 'grecaptchaVerified') {
                component.set('v.recaptchaResponse', event.data.detail.response);
                myButton.set('v.disabled', false);
            }
            else if(event.data.name === 'grecaptchaExpired' || event.data.name === 'grecaptchaError') {
                myButton.set('v.disabled', true);
            }
            
        }),false);

    },
    
    handleSelfRegister: function (component, event, helpler) {
        helpler.handleSelfRegister(component, event, helpler);
    },
    
    setStartUrl: function (component, event, helpler) {
        var startUrl = event.getParam('startURL');
        if(startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },
    
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    
    onKeyUp: function(component, event, helpler){
        //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helpler.handleSelfRegister(component, event, helpler);
        }
    },
    
    setSelectedAcademicValue : function(component,event,helper) {
        let academicCmp = component.find("academic");
        let extraFieldsArr = component.get("v.extraFields");
        if(academicCmp) {
            extraFieldsArr = helper.setSelectedPicklistValue(extraFieldsArr,academicCmp,helper);
        }
        component.set("v.extraFields",extraFieldsArr);
    },
    setSelectedLevelValue : function(component,event,helper) {
        let levelCmp = component.find("level");
        let extraFieldsArr = component.get("v.extraFields");
        if(levelCmp) {
            extraFieldsArr = helper.setSelectedPicklistValue(extraFieldsArr,levelCmp,helper);
        }
        component.set("v.extraFields",extraFieldsArr);
    }
})