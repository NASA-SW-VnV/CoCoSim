package cocosim.matlab2Lustre.domain;


/*################################################################################
#
# Installation script for cocoSim dependencies :
# - lustrec, zustre, kind2 in the default folder /tools/verifiers.
# - downloading standard libraries PP, IR and ME from github version of CoCoSim
#
# Author: Hamza BOURBOUH <hamza.bourbouh@nasa.gov>
#
# Copyright (c) 2019 United States Government as represented by the
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
################################################################################*/
public class DataType {
	private String baseType;
	private String dim1;
	private String dim2;
	
	public DataType(String baseType, String dim1, String dim2){
		this.setBaseType(baseType);
		this.dim1 = dim1;
		this.dim2 = dim2;
	}
	public DataType(String baseType){
		this.setBaseType(baseType);
		this.dim1 = "1";
		this.dim2 = "1";
	}
	public DataType(){
		this.setBaseType("real");
		this.dim1 = "1";
		this.dim2 = "1";
	}
	public String getDim2() {
		return dim2;
	}
	public void setDim2(String dim2) {
		this.dim2 = dim2;
	}
	public String getDim1() {
		return dim1;
	}
	public void setDim1(String dim1) {
		this.dim1 = dim1;
	}
	public String getBaseType() {
		return baseType.equals("")? "real":baseType;
	}
	public void setBaseType(String baseType) {
		this.baseType = baseType;
	}
	@Override
	public boolean equals(Object obj) {
		// TODO Auto-generated method stub
		return this.baseType.equals(((DataType) obj).getBaseType());
	}
	@Override
    public String toString() {
		if (dim2.equals("1")){
			if (dim1.equals("1")){
				return getBaseType();
			}
			else
				return getBaseType()+"^"+dim1;
		}
		else
			return getBaseType()+"^"+dim1+"^"+dim2;
	}
	
	
	
}
