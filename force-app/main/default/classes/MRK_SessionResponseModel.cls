public class MRK_SessionResponseModel {
    public String Message;
	public HttpRequest reqMessage;
	public HttpResponse resMessage;
    public String ErrorCode;
    public String Status;
    public String StatusReason;
    public Integer statusCode;
	public Exception ex;

	public Boolean isSuccess() {
        Boolean isSuccess = false;

        if(this.statusCode == 200) {
            isSuccess = true;
        }

        return isSuccess;
    }
}