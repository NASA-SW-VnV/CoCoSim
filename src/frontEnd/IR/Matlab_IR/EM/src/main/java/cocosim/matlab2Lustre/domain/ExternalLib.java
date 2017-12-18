package cocosim.matlab2Lustre.domain;

import java.util.ArrayList;

public class ExternalLib {
	String returnDataType;
	String parametersDataType;
	String fun_name;

	public ExternalLib(String _fun_name, ArrayList<String> paramsDTList) {
		this.fun_name = getLustreEquivalent(_fun_name);
		// Can not use Switch for JavaSE 1.6
		if (fun_name.equals("min")
				||fun_name.equals("max")
				||fun_name.equals("mldivide")
				||fun_name.equals("mpower")
				||fun_name.equals("dot_times")
				||fun_name.equals("rdivide")
				||fun_name.equals("ldivide")
				||fun_name.equals("dot_power")
				||fun_name.equals("+")
				||fun_name.equals("-")
				||fun_name.equals("*")
				||fun_name.equals("/")) {


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
		}else if (fun_name.equals("||") ||fun_name.equals("or")
				||fun_name.equals("&&") ||fun_name.equals("and")
				||fun_name.equals("|")
				||fun_name.equals("&")) {

			this.returnDataType = "bool";
			this.parametersDataType = "bool, bool";

		}else if(fun_name.equals("==") ||fun_name.equals("=")
				||fun_name.equals("~=") ||fun_name.equals("<>")
				||fun_name.equals(">")
				||fun_name.equals("<")
				||fun_name.equals(">=")
				||fun_name.equals("<=")) {

			this.returnDataType = "bool";

			if (paramsDTList == null || paramsDTList.isEmpty()) {
				this.parametersDataType = "real, real";
			}else {
				if (paramsDTList.contains("real")) {
					this.parametersDataType = "real, real";
				}else {
					this.parametersDataType = "int, int";
				}				
			}

		}else if(fun_name.equals("real_to_int")){
			this.returnDataType = "int";
			this.parametersDataType = "real";
			
		}else if(fun_name.equals("int_to_real")){
			this.returnDataType = "real";
			this.parametersDataType = "int";
			
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
	public static String getLustreEquivalent(String new_name) {
		if (new_name.equals("double")
				||new_name.equals("single")) {
			return "int_to_real";

		}else if (new_name.equals("int8")
				||new_name.equals("uint8")
				||new_name.equals("int16")
				||new_name.equals("uint16")
				||new_name.equals("int32")
				||new_name.equals("uint32")) {
			return "real_to_int";

		}

		return new_name;
	}


}
