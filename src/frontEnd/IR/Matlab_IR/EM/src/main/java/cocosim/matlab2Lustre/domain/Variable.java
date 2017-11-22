package cocosim.matlab2Lustre.domain;


/*################################################################################
#
# Installation script for cocoSim dependencies :
# - lustrec, zustre, kind2 in the default folder /tools/verifiers.
# - downloading standard libraries PP, IR and ME from github version of CoCoSim
#
# Author: Hamza BOURBOUH <hamza.bourbouh@nasa.gov>
#
# Copyright (c) 2017 United States Government as represented by the
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
################################################################################*/
public class Variable {

	private String name;
	private DataType dataType;
	private int nbOccurance;
	private boolean isVar;
	
	public Variable(String name, DataType dataType, boolean isVar, int nbOccurance){
		this.name = name;
		this.dataType = dataType;
		this.nbOccurance = nbOccurance;
		this.isVar = isVar;
	}
	public Variable(String name, DataType dataType, boolean isVar){
		this.name = name;
		this.dataType = dataType;
		this.nbOccurance = 0;
		this.isVar = isVar;
	}
	public Variable(String name, DataType dim){
		this.name = name;
		this.dataType = dim;
		this.nbOccurance = 0;
		this.isVar = true;
	}
	public Variable(String name, String baseType, String dim1, String dim2, boolean isVar){
		this.name = name;
		this.dataType = new DataType(baseType, dim1, dim2);
		this.nbOccurance = 0;
		this.isVar = isVar;
	}
	public Variable(String name, boolean isVar){
		this.name = name;
		this.dataType = new DataType();
		this.nbOccurance = 0;
		this.isVar = isVar;
	}
	public Variable(String name){
		this.name = name;
		this.dataType = new DataType();
		this.nbOccurance = 0;
		this.isVar = true;
	}

	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	
	public DataType getDataType() {
		return dataType;
	}
	public void setDataType(DataType dataType) {
		this.dataType = dataType;
	}

	public int getOccurance() {
		return nbOccurance;
	}
	public void incrementOccurance() {
		this.nbOccurance ++;
	}
	public void decrementOccurance() {
		this.nbOccurance --;
	}
	public void setOccurance(int occurance) {
		this.nbOccurance = occurance;
	}

	public boolean isVar() {
		return isVar;
	}

	public void setVar(boolean isVar) {
		this.isVar = isVar;
	}
	
	@Override
    public String toString() {
		StringBuilder buf = new StringBuilder();
		buf.append(name);
		for(int i=2; i<=nbOccurance; i++){
			buf.append(", ");
			buf.append( name + i);
		}
		buf.append( ": " + dataType.toString() + "; ");
		return buf.toString();
	}
}
