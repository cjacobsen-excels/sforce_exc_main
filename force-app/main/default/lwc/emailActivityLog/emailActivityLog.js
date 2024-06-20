import { LightningElement, wire, api } from "lwc";
import getTasksList from "@salesforce/apex/CustomActivityController.getTasksList";
import isNonADAmember from "@salesforce/apex/CustomActivityController.isNonADAmember";

import { NavigationMixin } from "lightning/navigation";

export default class EmailActivityLog extends NavigationMixin(
  LightningElement
) {
  areDetailsVisible = false;
  taskList = [];
  @api
  recordId;
  recLimit = 10;
  spinnerOn = true;
  previousListSize = 0;
  showViewMore = true;

  errorMessage = false;

  @wire(isNonADAmember) isNonADATeam;

  expandItem() {
    this.areDetailsVisible = !this.areDetailsVisible;
  }
  processTasks() {
    this.taskList.forEach((element) => {
      if (element.activityName) {
        element.activityName = element.activityName;
      } else {
        element.activityName = element.taskSubType;
      }
      // Convert dates to ISO format to avoid timezone issues
      if (element.activityDate) {
        element.activityDate = this.convertDateToISO(element.activityDate);
      }
    });
  }

  convertDateToISO(date) {
    let d = new Date(date);
    d.setDate(d.getDate() + 1); // Add one day to the date
    return d.toISOString().split('T')[0]; // Ensures date is in YYYY-MM-DD format and respects the UTC timezone
  }

  newTask() {
    this.openPopUp("task");
  }
  newCall() {
    this.openPopUp("call");
  }
  newEvent() {
    this.openPopUp("event");
  }
  newEmail() {
    this.openPopUp("email");
  }

  openPopUp(sourceType) {
    let pageRef = "";
    let buttonValue = sourceType;
    const querySelectorElement = `div[data-source='${buttonValue}']`;
    let pp = this.template.querySelector(querySelectorElement);
    if (pp) {
      let clsList = pp.classList;
      if (clsList.contains("slds-theme_shade")) {
        pp.classList.remove("slds-theme_shade");
        pp.classList.add("slds-box");
      }
    }

    let divSources = ["task", "call", "event", "email"];
    let indexToRemove = divSources.indexOf(sourceType);

    if (indexToRemove !== -1) {
      divSources.splice(indexToRemove, 1);
    }

    for (let divEle of divSources) {
      const remainQuerySelectorElement = `div[data-source='${divEle}']`;
      let ppClass = this.template.querySelector(remainQuerySelectorElement);
      ppClass.classList.value =
        "slds-p-around_medium slds-text-align_center slds-theme_shade";
    }
    let eType = "";
    if (buttonValue === "task") {
      eType = "Global.NewTask";
    } else if (buttonValue === "email") {
      eType = "Global.SendEmail";
    } else if (buttonValue === "event") {
      eType = "Global.NewEvent";
    } else if (buttonValue === "call") {
      eType = "Global.LogACall";
    }
    pageRef = {
      type: "standard__quickAction", 
      attributes: {
        apiName: eType
      },
      state: {
        recordId: this.recordId
      }
    };
    this[NavigationMixin.Navigate](pageRef);
  }

  getLocalDateISO() {
    const now = new Date();
    const year = now.getFullYear();
    let month = now.getMonth() + 1;
    let day = now.getDate();
    month = month < 10 ? "0" + month : month;
    day = day < 10 ? "0" + day : day;
    return `${year}-${month}-${day}`;
  }
  fetchData() {
    this.spinnerOn = true;
    getTasksList({ contactRecId: this.recordId, limitRecords: this.recLimit })
      .then((result) => {
        try {
          this.spinnerOn = false;
          this.taskList = JSON.parse(JSON.stringify(result));
          if (this.recLimit > this.taskList.length) {
            this.showViewMore = false;
          }
          console.log('****** 1 ' + this.taskList.length);
          this.processTasks();
          // console.log('****** 2 ' + this.taskList);

        } catch (ex) {console.log(ex);}
      })
      .catch((error) => {
        this.errorMessage = true;
        console.log(error);
      });
  }

  connectedCallback() {
    this.fetchData();
    if (this.taskList) {
      this.previousListSize = this.taskList.length;
    }
  }
  fetchMoreRecords() {
    this.recLimit = this.recLimit + 10;
    this.fetchData();
  }
}