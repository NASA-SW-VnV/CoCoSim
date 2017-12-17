package cocosim.matlab2Lustre.domain;

import java.util.ArrayList;

public class ExternalLib {
	String returnDataType;
	String parametersDataType;
	String fun_name;

	public ExternalLib(String fun_name, ArrayList<String> paramsDTList) {
		this.fun_name = fun_name;
		// Can not use Switch for JavaSE 1.6
		if (fun_name.equals("min")
				||fun_name.equals("max")
				||fun_name.equals("mldivide")
				||fun_name.equals("rdivide")
				||fun_name.equals("ldivide")
				||fun_name.equals("ldivide")
				||fun_name.equals("dot_power")
				||fun_name.equals("dot_times")) {
			
			
			if (paramsDTList == null || paramsDTList.isEmpty()) {
				this.returnDataType = "real";
				this.parametersDataType = "real, real";
			}else {
				if (paramsDTList.contains("real")) {
					this.returnDataType = "real";
					this.parametersDataType = "real, real";
				}else {
					this.returnDataType = "int";
					this.parametersDataType = "int, int";
				}				
			}
		}else {
			this.returnDataType = "";
			this.parametersDataType = "";
		}
		

	}
	public String getFun_name() {
		return fun_name;
	}

	public void setFun_name(String fun_name) {
		this.fun_name = fun_name;
	}

	public String getReturnDataType() {
		return returnDataType;
	}

	public void setReturnDataType(String returnDataType) {
		this.returnDataType = returnDataType;
	}

	public String getParametersDataType() {
		return parametersDataType;
	}

	public void setParametersDataType(String parametersDataType) {
		this.parametersDataType = parametersDataType;
	}


}
