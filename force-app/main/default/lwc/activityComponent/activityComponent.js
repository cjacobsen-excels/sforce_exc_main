import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ActivityComponent extends NavigationMixin(LightningElement) {
    areDetailsVisible = false;
    taskData;
    taskNotifyMsg;

    @api
    get taskDetail() {
        return this.taskData;
    }
    set taskDetail(value) {
        this.taskData = JSON.parse(JSON.stringify(value));
        this.convertDate();
        this.updateTaskNotify();
    }

    get iconSVG() {
        switch (this.taskData.taskSubType) {
            case 'Task':
                return 'standard:task';
            case 'Call':
                return 'standard:call';
            case 'Email':
                return 'standard:email';
            case 'Event':
                return 'standard:event';
            default:
                return 'standard:default';
        }
    }

    expandItem() {
        this.areDetailsVisible = !this.areDetailsVisible;
    }

    convertDate() {
        if (this.taskData.activityDate) {
            const [year, month, day] = this.taskData.activityDate.split('-');
            const date = new Date(`${year}-${month}-${day}`);
            const options = { day: '2-digit', month: 'short', year: 'numeric' };
            this.taskData.activityDateText = date.toLocaleDateString('en-US', options);
        } else {
            this.taskData.activityDateText = 'No due date';
        }
    }

    updateTaskNotify() {
        let msg;
        const { taskOwner, taskSubType, activityDate } = this.taskData;

        if (taskOwner === undefined || taskOwner === null) {
            msg = 'Owner information is missing';
        } else {
            if (taskSubType === 'Call') {
                msg = `${taskOwner} logged a call`;
            } else if (activityDate) {
                const now = new Date();
                const currentDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
                const date1 = new Date(currentDate);
                const date2 = new Date(activityDate);

                if (date1 < date2) {
                    if (taskSubType === 'Task') {
                        msg = `${taskOwner} has an upcoming task`;
                    } else if (taskSubType === 'Event') {
                        msg = `${taskOwner} has an upcoming event`;
                    }
                } else if (date1 > date2) {
                    if (taskSubType === 'Task') {
                        msg = `${taskOwner} had a task`;
                    } else if (taskSubType === 'Event') {
                        msg = `${taskOwner} had an event`;
                    }
                }
            }
        }

        this.taskNotifyMsg = msg;
    }

    navigateToTask() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.taskData.taskId,
                actionName: 'view'
            }
        });
    }
}