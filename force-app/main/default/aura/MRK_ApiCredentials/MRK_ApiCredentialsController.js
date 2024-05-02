({
    getRecord: function (component, event, helper) {
		var action = component.get("c.getSettings");
        action.setParams({
            
        });

        action.setCallback(this, function(response) {
			var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.mrkApi", response.getReturnValue());
			}
		})
        $A.enqueueAction(action);
    },
    setRecord: function (component, event, helper) {
		var action = component.get("c.setSettings");
        action.setParams({
            "mrkCsStr": JSON.stringify(component.get("v.recordId"))
        });

        action.setCallback(this, function(response) {
			var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.mrkApi", response.getReturnValue());
			}
		})
        $A.enqueueAction(action);
	}
})