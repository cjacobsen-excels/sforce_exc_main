({
	doInit: function (component, event, helper) {
		component.set("v.spinner", true);
		var action = component.get("c.getContactFromUser");
        action.setParams({
        });
        action.setCallback(this, function(response) {
            var returnVal = response.getReturnValue();
			var objParent = {};
			objParent.contact = returnVal.contact;
			objParent.relatedListItems = [];
			for (var i = 0; i < returnVal.relatedListItems.length; i++) {
				var obj = {};
				var rli = returnVal.relatedListItems[i];
				obj.Fields = rli.Fields;
				obj.Layout_Order = rli.Layout_Order;
				obj.Related_Field_Api_Name = rli.Related_Field_Api_Name;
				obj.Sobject_Api_Name = rli.Sobject_Api_Name;
				obj.Sorted_By = rli.Sorted_By;
				obj.Show_New = rli.Show_New;
				obj.Columns = [];
				for (var j = 0; j < returnVal.relatedListItems[i].Columns.length; j++) {
					var col = {};
					var lab = {};
					var exiCol = returnVal.relatedListItems[i].Columns[j];
					col.label = exiCol.label;
					col.fieldName = exiCol.fieldName;
					col.type = exiCol.type;
					col.target = exiCol.target;

					lab.label = exiCol.typeAttributes;
					col.typeAttributes = lab;

					obj.Columns.push(col);

					console.log(col);
				}

				console.log("obj " + obj.Fields);
				objParent.relatedListItems.push(obj);
			}
			component.set("v.data", objParent);
			component.set("v.spinner", false);
        })
        $A.enqueueAction(action);
	}
})