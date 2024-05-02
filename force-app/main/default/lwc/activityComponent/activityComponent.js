import { LightningElement, api } from "lwc";

export default class ActivityComponent extends LightningElement {
  areDetailsVisible = false;
  taskData;
  taskNotifyMsg;

  @api
  get taskDetail() {
    return;
  }
  set taskDetail(value) {
    this.taskData = JSON.parse(JSON.stringify(value));
    this.convertDate();
    this.updateTaskNotify();
  }
  get iconSVG() {
    if (this.taskData.taskSubType === "Task") {
      //return "/_slds/icons/standard-sprite/svg/symbols.svg#task";
      return "standard:task";
    }
    if (this.taskData.taskSubType === "Call") {
      //return "/_slds/icons/standard-sprite/svg/symbols.svg#log_a_call";
      return "standard:call";
    }
    if (this.taskData.taskSubType === "Email") {
      //return "/_slds/icons/standard-sprite/svg/symbols.svg#email";
      return "standard:email";
    }
    if (this.taskData.taskSubType === "Event") {
      //return "/_slds/icons/standard-sprite/svg/symbols.svg#event";
      return "standard:event";
    }
  }

  expandItem() {
    this.areDetailsVisible = !this.areDetailsVisible;
  }

  convertDate() {
    if (this.taskData.activityDate) {
      const [year, month, day] = this.taskData.activityDate.split("-");
      const date = new Date(`${year}-${month}-${day}`);
      const options = { day: "2-digit", month: "short", year: "numeric" };
      this.taskData.activityDateText = date.toLocaleDateString(
        "en-US",
        options
      );
    } else {
      this.taskData.activityDateText = "No due date";
    }
  }

  updateTaskNotify() {
    let msg;

    if (this.taskData.taskSubType === "Call") {
      msg = "You logged a call";
    } else {
      if (this.taskData.activityDate) {
        const now = new Date();
        const year = now.getFullYear();
        let month = now.getMonth() + 1;
        let day = now.getDate();
        month = month < 10 ? "0" + month : month;
        day = day < 10 ? "0" + day : day;
        let currentDate = `${year}-${month}-${day}`;
        const dateString1 = currentDate;
        const dateString2 = this.taskData.activityDate;
        const date1 = new Date(dateString1);
        const date2 = new Date(dateString2);
        if (date1 < date2) {
          if (this.taskData.taskSubType === "Task") {
            msg = "You have an upcoming task";
          } else if (this.taskData.taskSubType === "Event") {
            msg = "You have an upcoming event";
          }
        } else if (date1 > date2) {
          if (this.taskData.taskSubType === "Task") {
            msg = "You had a task";
          } else if (this.taskData.taskSubType === "Event") {
            msg = "You had an event";
          }
        }
      }
    }
    this.taskNotifyMsg = msg;
  }
}