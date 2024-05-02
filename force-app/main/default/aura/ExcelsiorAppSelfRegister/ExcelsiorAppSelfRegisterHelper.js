({
    
    handleSelfRegister: function (component, event, helpler) {
        
        let missingRequiredFields = '';
        let isNanTemp = false;
        component.set("v.showError", false);
        component.set("v.errorMessage", '');
        component.set("v.showSpinner",true);
        var regConfirmUrl = component.get("v.regConfirmUrl");
        var firstname = component.find("firstname").get("v.value");
        var lastname = component.find("lastname").get("v.value");
        var email = component.find("email").get("v.value");
		//var includePassword = component.get("v.includePasswordField");
        //var password = component.find("password").get("v.value");
        //var confirmPassword = component.find("confirmPassword").get("v.value");
        //var action = component.get("c.selfRegister");
        var extraFieldsCmp = component.get("v.extraFields");
        var extraFields = JSON.stringify(component.get("v.extraFields"));   // somehow apex controllers refuse to deal with list of maps
        var startUrl = component.get("v.startUrl");
        
        startUrl = decodeURIComponent(startUrl);
        
        
        var selfRegisterAction = component.get("c.selfRegistrationProcess");
        if(!firstname) {
            missingRequiredFields += 'First Name, ';
        }
        if(!lastname) {
            missingRequiredFields += 'Last Name, ';
        }
        if(!email) {
            missingRequiredFields += 'Email, ';
        }
        extraFieldsCmp.forEach(function extraFieldCallback(extraField) {
            if(!extraField.value) {
               missingRequiredFields +=  extraField.label + ', ';
            }
            else {
                if(extraField.fieldPath === 'Phone' && isNaN(extraField.value)) {
                    isNanTemp = true;
                    
                }
            }
        })
        if (missingRequiredFields) {
            component.set("v.showError", true);
            component.set("v.errorMessage", 'Required Fields: ' + missingRequiredFields.slice(0, missingRequiredFields.length - 2));
            component.set("v.showSpinner",false);
            return;
        }
        if(isNanTemp) {
            component.set("v.showError", true);
            component.set("v.errorMessage", 'Enter phone number in correct format');
            component.set("v.showSpinner",false);
            return;
        }
        
        selfRegisterAction.setParams({firstname:firstname,lastname:lastname,email:email,extraFields:extraFields, 
                                      startUrl:startUrl,regConfirmUrl:regConfirmUrl,
                                      recaptchaResponse : component.get("v.recaptchaResponse")});
        selfRegisterAction.setCallback(this, function(response)	{
            component.set("v.showSpinner",false);
            let myButton = component.find("submitButton");
            var message = {
                name : 'grecaptchaReset'
            }
            var vfOrigin = $A.get("$Label.c.VF_Host");
            var vfWindow = component.find("googleRecaptchaVfFrame").getElement().contentWindow;
            vfWindow.postMessage(message, vfOrigin);
            myButton.set('v.disabled', true);  
            
            let responseState = response.getState();
            if(responseState === 'SUCCESS') {
                let responseVal = response.getReturnValue();
                if(responseVal.successMessage) {
                    component.set("v.showError", false);
                    component.set("v.successMessage", responseVal.successMessage); 
                }
                else {
                    component.set("v.showError", true);
                    component.set("v.errorMessage", responseVal.errorMessage); 
                }
            }
            else if(responseState === 'ERROR'){
                component.set("v.showError", true);
                component.set("v.errorMessage", response.getError()[0].message);
            }
        });
        $A.enqueueAction(selfRegisterAction);
        
    },
    
    getExtraFields : function (component, event, helpler) {
        var action = component.get("c.getExtraFields");
        var self = this;
        action.setParam("extraFieldsFieldSet", component.get("v.extraFieldsFieldSet"));
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                rtnValue.forEach(function extraFieldCallback(rtnVal) {
                	if(rtnVal.fieldPath != 'Phone') {
                    	rtnVal.value = self.getPicklistValuesJS(component,rtnVal.fieldPath,'User');		    
                    }
                })
                
                component.set('v.extraFields',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },

    setBrandingCookie: function (component, event, helpler) {        
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    },
    
    getPicklistValuesJS : function(component,fieldName,objectName) {
      let getPicklistValueAction = component.get("c.getPicklistvalues");
        getPicklistValueAction.setParams({objectName:objectName, field_apiname : fieldName, nullRequired : false});
        getPicklistValueAction.setCallback(this, function(response)	{
            let responseState = response.getState();
            if(responseState === 'SUCCESS') {
                if(fieldName == 'Academic_Area_of_Interest__c') {
                    component.set("v.academicAreaOfInterestOptions", response.getReturnValue());
                }
                else if(fieldName == 'Level_of_Interest__c') {
					component.set("v.levelOfInterestOptions", response.getReturnValue());                    
                }
                let extraFieldArr = component.get("v.extraFields");
                let idx = extraFieldArr.findIndex(x=>x.fieldPath == fieldName);
                if(idx != -1) {
                    extraFieldArr[idx].value = response.getReturnValue()[0];
                    return extraFieldArr[idx].value;
                }
                
            }
        });
        $A.enqueueAction(getPicklistValueAction);
    },
    
    setSelectedPicklistValue : function(extraFieldsArr,cmpName,helper) {
        let idx = extraFieldsArr.findIndex(extraField=>extraField.label === cmpName.get("v.label"));
        if(idx != -1) {
            extraFieldsArr[idx].value = cmpName.get("v.value");
        }
        return extraFieldsArr;
    }
	    
})