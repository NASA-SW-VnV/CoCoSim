package cocosim.matlab2Lustre.domain;

import java.util.ArrayList;

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
	private boolean isOutput;
	private boolean isInput;

	public Variable(String name, DataType dataType, boolean isVar, int nbOccurance){
		this.name = name;
		this.dataType = dataType;
		this.nbOccurance = nbOccurance;
		this.isVar = isVar;
		this.isOutput = false;
		this.isInput = false;
	}
	public Variable(String name, DataType dataType, boolean isVar){
		this.name = name;
		this.dataType = dataType;
		this.nbOccurance = 0;
		this.isVar = isVar;
		this.isOutput = false;
		this.isInput = false;
	}
	public Variable(String name, DataType dim){
		this.name = name;
		this.dataType = dim;
		this.nbOccurance = 0;
		this.isVar = true;
		this.isOutput = false;
		this.isInput = false;
	}
	public Variable(String name, String baseType, String dim1, String dim2, boolean isVar){
		this.name = name;
		this.dataType = new DataType(baseType, dim1, dim2);
		this.nbOccurance = 0;
		this.isVar = isVar;
		this.isOutput = false;
		this.isInput = false;
	}
	public Variable(String name, boolean isVar){
		this.name = name;
		this.dataType = new DataType();
		this.nbOccurance = 0;
		this.isVar = isVar;
		this.isOutput = false;
		this.isInput = false;
	}
	public Variable(String name){
		this.name = name;
		this.dataType = new DataType();
		this.nbOccurance = 0;
		this.isVar = true;
		this.isOutput = false;
		this.isInput = false;
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
	public boolean needToBeDeclaredInVars() {

		return (this.isVar()) ||  (this.getOccurance() >= 1);
	}
	public boolean isOutput() {
		return isOutput;
	}
	public void setOutput(boolean isOutput) {
		this.isOutput = isOutput;
	}
	public boolean isInput() {
		return isInput;
	}
	public void setInput(boolean isInput) {
		this.isInput = isInput;
	}

	@Override
	public String toString() {
		StringBuilder buf = new StringBuilder();
		int start_idx = 1;
		int last_idx = getOccurance();
		if (isOutput)
			last_idx = getOccurance() - 1;
		if (this.isVar()) {
			buf.append(name);
			if (last_idx >= 1) buf.append(", ");
		}
		int dim1 = Integer.parseInt(getDataType().getDim1());
		int dim2 = Integer.parseInt(getDataType().getDim2());
		String dt = getDataType().getBaseType() ;
		if (dim1 == 1 && dim2 == 1) {
			ArrayList<String> vars = new ArrayList<>();
			for(int i=start_idx; i<=last_idx; i++){
				vars.add( name + "__" + i);
			}
			buf.append(String.join(", ", vars));
		}
		else {
			ArrayList<String> vars = new ArrayList<>();
			for(int i=start_idx; i<=last_idx; i++){
				for(int j=1; j <= dim1; j++) {
					for(int k=1; k <= dim2; k++) {
						vars.add( name + "_"+ j + "_" + k + "__" + i);
					}
				}
			}
			buf.append(String.join(", ", vars));
			
		}
		if (!buf.toString().equals(""))
			buf.append( ": " + dt + "; ");
		return buf.toString();
	}
	public Object toString(boolean isNotVar) {
		if (isNotVar) {
			StringBuilder buf = new StringBuilder();
			buf.append(name);
			buf.append( ": " + dataType.toString() + "; ");
			return buf.toString();
		}

		return toString();
	}
	public Object LastOccurenceName() {
		StringBuilder buf = new StringBuilder();
		buf.append(name);
		if (getOccurance()>=1)
			buf.append("__"+getOccurance());
		buf.append( ": " + dataType.toString() + "; ");
		return buf.toString();

	}
	
}
