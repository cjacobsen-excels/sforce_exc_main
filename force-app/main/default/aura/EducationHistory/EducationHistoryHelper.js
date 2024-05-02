/**
 * Created by mnahar on 23/06/21.
 */

({

    /**
     * @description         Query and set the Education History Records for the current Application
     */
    getEducationHistory: function (component, event, helper) {
        let action = component.get("c.getEducationHistoryRecords");
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result.length > 0) {
                    for (let i = 0; i < result.length; i++) {
                        let row = result[i];
                        if (row.traa_Application__r.Name) {
                            row.ApplicationName = row.traa_Application__r.Name;
                        }
                    }
                    component.set("v.data", result);
                    component.set("v.showData", true);
                }
                component.set("v.isLoading", false);
            } else {
                let message = this.processError(response.getError());
                this.showToast(message, 'error', 'ERROR');
                component.set("v.isLoading", false);

            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description     Parse a failed action's error message and return the result
     * @param           error
     * @returns         {string}
     */
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