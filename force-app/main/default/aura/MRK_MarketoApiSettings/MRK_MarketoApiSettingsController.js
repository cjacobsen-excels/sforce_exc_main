({
    getRecord: function (component, event, helper) {
		var action = component.get("c.getMDTSetting");
        action.setParams({
            
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