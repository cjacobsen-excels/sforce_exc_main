/**
 * Created by mnahar on 24/06/21.
 */

({
    fetchTermPicklist: function (component) {
        let action = component.get("c.getApplicationTerms");
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.TermPicklist", response.getReturnValue());
            } else {
                let message = this.processError(response.getError());
                this.showToast(message, 'error', 'ERROR');
            }
        });
        $A.enqueueAction(action);
    },

    fetchAreaOfInterestPicklist: function (component) {
        let action = component.get("c.getAreaOfInterest");
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.AreaOfInterestPicklist", response.getReturnValue());
                component.set("v.showArea", "true");
            } else {
                let message = this.processError(response.getError());
                this.showToast(message, 'error', 'ERROR');
            }
        });
        $A.enqueueAction(action);
    },

    fetchLevelOfInterestPicklist: function (component) {
        let action = component.get("c.getLevelOfInterest");
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.LevelOfInterestPicklist", response.getReturnValue());
                component.set("v.showLevel", "true");
            } else {
                let message = this.processError(response.getError());
                this.showToast(message, 'error', 'ERROR');
            }
        });
        $A.enqueueAction(action);
    },

    fetchAcademicPrograms: function (component) {
        let action = component.get("c.getAcademicPrograms");
        action.setParams({
            'term': component.get("v.selectedTermValue"),
            'area': component.get("v.selectedAreaValue"),
            'level': component.get("v.selectedLevelValue")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                let fieldMap = [];
                for (let key in result) {
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.availableAccounts", fieldMap);
                component.set("v.showAccounts", "true");
            } else {
                let message = this.processError(response.getError());
                this.showToast(message, 'error', 'ERROR');
            }
        });
        $A.enqueueAction(action);
    },
    
    processError: function (error) {
        let message = '';
        for (let i = 0; i < error.length; i++) {
            if (error[i].message) {
                message += error[i].message + '\n\n';
            } else {
                // Page Errors
                for (let j = 0; j < error[i].pageErrors.length; j++) {
                    message += error[i].pageErrors[j].statusCode + ': ' + error[i].pageErrors[j].message + '\n\n';
                }

                // Field Errors
                let keys = Object.keys(error[i].fieldErrors);
                for (let j = 0; j < keys.length; j++) {
                    let field = error[i].fieldErrors[keys[j]];
                    for (let k = 0; k < field.length; k++) {
                        message += keys[j] + ': ' + field[k].statusCode + ': ' + field[k].message + '\n\n';
                    }
                }
            }
        }
        return message;
    },

    showToast: function (message, type, title) {
        let resultsToast = $A.get('e.force:showToast');
        if (typeof resultsToast !== 'undefined') {
            resultsToast.setParams({
                title: title,
                message: message,
                type: type
            });
            resultsToast.fire();
        } else {
            alert(message);
        }
    },

});