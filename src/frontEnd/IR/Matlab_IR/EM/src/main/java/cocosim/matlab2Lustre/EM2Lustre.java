package cocosim.matlab2Lustre;

import com.google.common.base.Joiner;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeProperty;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.antlr.v4.runtime.tree.TerminalNode;

import cocosim.emgrammar.EMBaseListener;
import cocosim.emgrammar.EMLexer;
import cocosim.emgrammar.EMParser;
import cocosim.emgrammar.EMParser.Func_inputContext;
import cocosim.matlab2Lustre.domain.DataType;
import cocosim.matlab2Lustre.domain.ExternalLib;
import cocosim.matlab2Lustre.domain.Variable;

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
public class EM2Lustre {
	public static class LusEmitter extends EMBaseListener {
		//Lustre Map, for every ctx get its Lustre
		ParseTreeProperty<String> lus = new ParseTreeProperty<String>();
		String lus_body = "";

		//Variables Map, for every variable in script/function 
		Map<String, Variable> variables = new HashMap<String, Variable>();
		//For Arrays variables
		HashSet<String> dimensions_consts = new HashSet<String>();
		//DataType Map, for every ctx get its dataType
		ParseTreeProperty<DataType> dataType = new ParseTreeProperty<DataType>();

		//Position of a ParseTree in assignement. 
		//True if ParseTree is in left of an assignement
		//False if ParseTree is in right of an assignement.
		ParseTreeProperty<Boolean> ctx_position = new ParseTreeProperty<Boolean>();
		//root tree
		ParseTree tree;


		//External lustre functions
		HashSet<String> external_fun = new HashSet<String>();
		HashSet<ParseTree> unsupported_ctx = new HashSet<ParseTree>();




		public LusEmitter(ParseTree tree) {
			this.tree  = tree;
		}


		public String getLus_body() {
			return lus_body;
		}

		public void setLus_body(String lus_body) {
			this.lus_body = lus_body;
		}
		public ParseTree getTree() {
			return tree;
		}
		public void setTree(ParseTree tree) {
			this.tree = tree;
		}

		public ParseTreeProperty<Boolean> getCtx_position() {
			return ctx_position;
		}
		public Boolean getCtx_position(ParseTree ctx) {
			return ctx_position.get(ctx);
		}
		public void setCtx_position(ParseTreeProperty<Boolean> ctx_position) {
			this.ctx_position = ctx_position;
		}
		public void setCtx_position(ParseTree ctx, Boolean ctx_position) {
			this.ctx_position.put(ctx, ctx_position);
		}

		public HashSet<ParseTree> getUnsupported_ctx() {
			return unsupported_ctx;
		}

		public void setUnsupported_expr(HashSet<ParseTree> unsupported_expr) {
			this.unsupported_ctx = unsupported_expr;
		}

		public void addUnsupported_ctx(ParseTree unsupported_expr) {
			this.unsupported_ctx.add(unsupported_expr);
		}
		public HashSet<String> getExternal_fun() {
			return external_fun;
		}
		public String getExternal_fun_str() {
			Joiner j =  Joiner.on(", ").skipNulls();
			return j.join(getExternal_fun());
		}
		public void setExternal_fun(HashSet<String> external_fun) {
			this.external_fun = external_fun;
		}

		public void addExternal_fun(String external_fun) {
			this.external_fun.add(external_fun);
		}
		public String getLus(ParseTree ctx) {
			String s = "";
			String tmp = lus.get(ctx);
			if (tmp != null)
				s = tmp;
			return s;
		}

		void setLus(ParseTree ctx, String s) {
			lus.put(ctx, s);
		}

		DataType getDataType(ParseTree ctx) {

			return dataType.get(ctx)!=null? dataType.get(ctx): new DataType("");
		}

		void setDataType(ParseTree ctx, DataType d) {
			dataType.put(ctx, d);
		}


		Variable getVar(String s) {
			return variables.get(s);
		}

		Map<String, Variable> getVars() {
			return variables;
		}

		void setVar(String s, Variable v) {
			variables.put(s, v);
		}



		void addDim(String s) {
			if (!isNumeric(s))
				dimensions_consts.add(s);
		}

		HashSet<String> getConsts() {
			return dimensions_consts;
		}

		//		public void print_debug() {
		//			variables.values().stream().forEach(new Consumer<Variable>() {
		//				@Override
		//				public void accept(Variable v) {
		//					System.out.println(v);
		//				}
		//			});
		//			
		//		}

		public String getVariablesStr() {
			StringBuilder buf = new StringBuilder();
			for (Variable v : getVars().values()) {
				if (v.needToBeDeclaredInVars()) {
					buf.append(v.toString());
					buf.append("\n");
				}
			}
			return buf.toString();
		}
		public String getInputsStr() {
			StringBuilder buf = new StringBuilder();
			for (Variable v : getVars().values()) {
				if (v.isInput()) {
					buf.append(v.toString(true));
					buf.append("\n");
				}
			}
			return buf.toString();
		}
		public String getOutputsStr() {
			StringBuilder buf = new StringBuilder();
			for (Variable v : getVars().values()) {
				if (v.isOutput()) {
					buf.append(v.LastOccurenceName());
					buf.append("\n");
				}
			}
			return buf.toString();
		}
		@Override
		public void exitEmfile(EMParser.EmfileContext ctx) {
			//print_debug();

			StringBuilder buf = new StringBuilder();
			if(ctx.script() == null) {
				int n = ctx.function().size();
				for (int i = 0; i < n; i++) {
					EMParser.FunctionContext fctx = ctx.function(i);
					buf.append(getLus(fctx));
					buf.append("\n");
				}
			}else {
				buf.append(getLus(ctx.script()));
			}

			setLus(ctx, buf.toString());


		}
		@Override
		public void exitScript(EMParser.ScriptContext ctx) {
			final StringBuilder buf = new StringBuilder();

			String variables_str = getVariablesStr();
			if (!variables_str.equals("")) {
				buf.append("var ");
				buf.append(variables_str);
			}


			buf.append("let\n");
			buf.append(getLus(ctx.body()));
			buf.append("tel\n");

			setLus_body(getLus(ctx.body()));
			setLus(ctx, buf.toString());
		}


		@Override
		public void exitFunction(EMParser.FunctionContext ctx) {
			final StringBuilder buf = new StringBuilder();
			String functionName = ctx.ID().getText();

			if (getConsts().size() > 0) {
				buf.append("--dimensions as constants\n");
				Joiner joiner = Joiner.on(", ").skipNulls();
				String constants = joiner.join(getConsts());
				buf.append("const " + constants + ": int;\n");
			}

			buf.append("node " + functionName);

			if (ctx.func_input() != null) {
				Func_inputContext inputs = ctx.func_input();
				buf.append("(");
				int n = inputs.ID().size();
				for (int i = 0; i < n; i++) {
					String input_name = inputs.ID(i).getText();
					Variable v = getVar(input_name);
					buf.append(v.toString(true));
				}
				buf.append(")");
			} else
				buf.append("()");
			buf.append("\nreturns ");
			if (ctx.func_output() != null) {
				EMParser.Func_outputContext outputs = ctx.func_output();
				buf.append("(");
				int n = outputs.ID().size();
				for (int i = 0; i < n; i++) {
					String output_name = outputs.ID(i).getText();
					Variable v = getVar(output_name);
					buf.append(v.LastOccurenceName());
				}
				buf.append(")");
			} else
				buf.append("()");
			buf.append(";\n");

			String variables_str = getVariablesStr();
			if (!variables_str.equals("")) {
				buf.append("var ");
				buf.append(variables_str);
			}



			buf.append("let\n");
			buf.append(getLus(ctx.body()));
			buf.append("tel\n");

			setLus_body(getLus(ctx.body()));
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFunc_input(EMParser.Func_inputContext ctx) {
			for (TerminalNode id : ctx.ID()) {

				if (getVars().containsKey(id.getText())) {
					Variable v = getVar(id.getText());	
					v.setInput(true);
				}
				else {
					Variable v = new Variable(id.getText(), false);
					v.setInput(true);
					setVar(id.getText(), v);
				}
			}

		}

		@Override
		public void exitFunc_output(EMParser.Func_outputContext ctx) {
			for (TerminalNode id : ctx.ID()) {
				if (getVars().containsKey(id.getText())) {
					Variable v = getVar(id.getText());	
					v.setOutput(true);
				}
				else {
					Variable v = new Variable(id.getText(), false);
					v.setOutput(true);
					setVar(id.getText(), v);
				}
			}

		}

		@Override
		public void exitBody(EMParser.BodyContext ctx) {
			if (ctx.body() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.body()));

				buf.append(getLus(ctx.body_item()));

				setLus(ctx, buf.toString());
			} else {
				setLus(ctx, getLus(ctx.body_item()));

			}

		}

		@Override
		public void exitBody_item(EMParser.Body_itemContext ctx) {
			setLus(ctx, getLus(ctx.getChild(0)));
		}

		@Override
		public void exitAnnotation(EMParser.AnnotationContext ctx) {
			setLus(ctx, getLus(ctx.getChild(0)));
		}

		@Override
		public void exitDeclare_type(EMParser.Declare_typeContext ctx) {
			if (ctx.DeclareType() != null) {
				String var_name = ctx.ID().getText();
				String baseType = ctx.dataType().BASETYPE().getText();
				DataType dt = new DataType(baseType);
				if (ctx.dataType().dimension(0) != null) {
					dt.setDim1(ctx.dataType().dimension(0).getText());
					addDim(ctx.dataType().dimension(0).getText());
				}
				if (ctx.dataType().dimension(1) != null) {
					dt.setDim2(ctx.dataType().dimension(1).getText());
					addDim(ctx.dataType().dimension(1).getText());
				}

				Variable v = getVar(var_name);
				if (v == null) {
					setVar(var_name, new Variable(var_name, dt, true));
				} else {
					v.setDataType(dt);
				}

			}
		}

		public boolean checkAllChildrenAreSupported(ParseTree ctx) {
			if (getUnsupported_ctx().contains(ctx))
				return false;

			int n = ctx.getChildCount();
			for (int i=0; i < n; i++) {
				if(!checkAllChildrenAreSupported(ctx.getChild(i)))
					return false;
			}
			return true;
		}
		@Override
		public void exitStatement(EMParser.StatementContext ctx) {
			if (checkAllChildrenAreSupported(ctx)) {
				setLus(ctx, getLus(ctx.getChild(0)) + "\n");
			}
			else
				setLus(ctx, "--Unsupported expression: "+ ctx.getText().replaceAll("\\n", " ") + "\n");

		}



		@Override
		public void exitExpression(EMParser.ExpressionContext ctx) {
			if (ctx.notAssignment() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.notAssignment()));
				buf.append(";");
				setLus(ctx,  buf.toString());
				setDataType(ctx, getDataType(ctx.notAssignment()));

			} else {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.assignment()));
				buf.append(";");
				setLus(ctx,  buf.toString());
				setDataType(ctx, getDataType(ctx.assignment()));
			}

		}
		public void setCtx_positionAllChildren(ParseTree ctx, Boolean b) {
			setCtx_position(ctx, b);
			int n = ctx.getChildCount();
			for (int i=0; i < n; i++) {
				setCtx_positionAllChildren(ctx.getChild(i),  b);
			}
		}
		public String getUnaryExpressionID(EMParser.UnaryExpressionContext ctx) {
			if (ctx.postfixExpression() == null)
				return null;

			EMParser.PostfixExpressionContext ptx = ctx.postfixExpression();
			while (ptx.postfixExpression() != null) {
				ptx = ptx.postfixExpression();
			}
			EMParser.PrimaryExpressionContext primary_ctx = ptx.primaryExpression();
			if (primary_ctx == null)
				return null;

			if (primary_ctx.ID() != null) {
				return primary_ctx.ID().getText();
			}
			EMParser.IndexingContext ictx = primary_ctx.indexing();
			if ( ictx != null)
				return ictx.getChild(0).getChild(0).getText();

			return null;
		}
		@Override
		public void enterAssignment(EMParser.AssignmentContext ctx) {
			setCtx_positionAllChildren(ctx.unaryExpression(), true);
			setCtx_positionAllChildren(ctx.notAssignment(), false);

		}
		@Override
		public void exitAssignment(EMParser.AssignmentContext ctx) {

			StringBuilder buf = new StringBuilder();


			DataType unaryExpression_dt = getDataType(ctx.unaryExpression());
			DataType assignment_dt = getDataType(ctx.notAssignment());
			String leftExp = getLus(ctx.unaryExpression());
			String rightExp = getLus(ctx.notAssignment());
			String conversion_fun = "";
			if (unaryExpression_dt == null)
				if (assignment_dt != null)
					unaryExpression_dt = assignment_dt;
				else
					unaryExpression_dt = new DataType("real");
			else {
				if (assignment_dt != null)
					if (!unaryExpression_dt.equals(assignment_dt)) {
						conversion_fun = getConvFun(unaryExpression_dt, assignment_dt);
						if (isNumeric(rightExp) && !conversion_fun.equals("")) {
							rightExp = fixConstant(unaryExpression_dt.getBaseType(), rightExp);
							conversion_fun = "";
						}else
							if (!conversion_fun.equals(""))
								this.addExternal_fun(conversion_fun);
					}
			}



			if (!conversion_fun.equals("")){
				buf.append(leftExp);
				buf.append(" " + ctx.assignmentOperator().getText() + " ");
				buf.append(conversion_fun + "(" + rightExp+ ")");
			}
			else {
				buf.append(leftExp);
				buf.append(" " + ctx.assignmentOperator().getText() + " ");
				buf.append(rightExp);
			}

			setLus(ctx, buf.toString());

			//increment variable occurance
			String ID = getUnaryExpressionID(ctx.unaryExpression());
			if (ID != null) {
				Variable v = getVar(ID);
				if (v != null)
					v.incrementOccurance();
				else
					setVar(ID, new Variable(ID, unaryExpression_dt, true, 0));
			}



		}

		@Override
		public void exitNotAssignment(EMParser.NotAssignmentContext ctx) {
			setLus(ctx, getLus(ctx.relopOR()));
			setDataType(ctx, getDataType(ctx.relopOR()));
		}

		@Override
		public void exitRelopOR(EMParser.RelopORContext ctx) {
			callExpression(ctx, "relopOR", "relopAND", "or", "");
		}

		@Override
		public void exitRelopAND(EMParser.RelopANDContext ctx) {
			callExpression(ctx, "relopAND", "relopelOR", "and", "");
		}

		@Override
		public void exitRelopelOR(EMParser.RelopelORContext ctx) {
			callExpression(ctx, "relopelOR", "relopelAND", "or", "");
		}

		@Override
		public void exitRelopelAND(EMParser.RelopelANDContext ctx) {
			callExpression(ctx, "relopelAND", "relopEQ_NE", "and", "");
		}

		@Override
		public void exitRelopEQ_NE(EMParser.RelopEQ_NEContext ctx) {
			String operator = "";
			if (ctx.relopEQ_NE() != null)
				operator = ctx.getChild(1).getText();

			String lus_operator = "";
			if (operator.equals("=="))
				lus_operator = "=";
			else
				lus_operator = "<>";
			callExpression(ctx, "relopEQ_NE", "relopGL", lus_operator, "");
		}

		@Override
		public void exitRelopGL(EMParser.RelopGLContext ctx) {
			String operator = "";
			if (ctx.relopGL() != null)
				operator = ctx.getChild(1).getText();
			callExpression(ctx, "relopGL", "plus_minus", operator, "");
		}

		@Override
		public void exitPlus_minus(EMParser.Plus_minusContext ctx) {
			String operator = "";
			if (ctx.plus_minus() != null) {
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "plus_minus", "mtimes", operator, "");

		}

		@Override
		public void exitMtimes(EMParser.MtimesContext ctx) {
			String operator = "";
			if (ctx.mtimes() != null)
				operator = ctx.getChild(1).getText();
			callExpression(ctx, "mtimes", "mrdivide", operator, "");
		}

		@Override
		public void exitMrdivide(EMParser.MrdivideContext ctx) {
			String operator = "";
			if (ctx.mrdivide() != null)
				operator = ctx.getChild(1).getText();
			callExpression(ctx, "mrdivide", "mldivide", operator, "");
		}

		@Override
		public void exitMldivide(EMParser.MldivideContext ctx) {
			//type `help mldivide` in Matlab 
			String operator = "";
			if (ctx.mldivide() != null) {
				this.addExternal_fun("mldivide");
				operator = ctx.getChild(1).getText();
			}

			callExpression(ctx, "mldivide", "mpower", operator, "mldivide");
		}

		@Override
		public void exitMpower(EMParser.MpowerContext ctx) {
			String operator = "";
			if (ctx.mpower() != null) {
				this.addExternal_fun("mpower");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "mpower", "times", operator, "mpower");
		}

		@Override
		public void exitTimes(EMParser.TimesContext ctx) {
			String operator = "";
			if (ctx.times() != null) {
				this.addExternal_fun("dot_times");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "times", "rdivide", operator, "dot_times");
		}

		@Override
		public void exitRdivide(EMParser.RdivideContext ctx) {
			String operator = "";
			if (ctx.rdivide() != null) {
				this.addExternal_fun("dot_rdivide");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "rdivide", "ldivide", operator, "rdivide");
		}

		@Override
		public void exitLdivide(EMParser.LdivideContext ctx) {
			String operator = "";
			if (ctx.ldivide() != null) {
				this.addExternal_fun("dot_ldivide");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "ldivide", "power", operator, "ldivide");
		}

		@Override
		public void exitPower(EMParser.PowerContext ctx) {
			String operator = "";
			if (ctx.power() != null) {
				this.addExternal_fun("dot_power");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "power", "colonExpression", operator, "dot_power");
		}

		@Override
		public void exitColonExpression(EMParser.ColonExpressionContext ctx) {
			String operator = "";
			if (ctx.colonExpression() != null) {
				this.addUnsupported_ctx(ctx);
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "colonExpression", "unaryExpression", operator, "");
		}

		@Override public void enterUnaryExpression(EMParser.UnaryExpressionContext ctx) { 

		}
		@Override
		public void exitUnaryExpression(EMParser.UnaryExpressionContext ctx) {
			String operator = "";
			if (ctx.unaryExpression() != null) {
				operator = ctx.getChild(0).getText();
			}
			callExpression(ctx, "unaryExpression", "postfixExpression", operator, "");
		}

		@Override
		public void exitPostfixExpression(EMParser.PostfixExpressionContext ctx) {
			if (ctx.primaryExpression() != null) {
				setLus(ctx, getLus(ctx.primaryExpression()));
				setDataType(ctx, getDataType(ctx.primaryExpression()));
			}
			else if (ctx.TRANSPOSE() != null) {
				this.addUnsupported_ctx(ctx);
				setLus(ctx, getLus(ctx.postfixExpression()));
				DataType d = getDataType(ctx.postfixExpression());
				if (d != null)
					setDataType(ctx, new DataType(d.getBaseType(), d.getDim2(), d.getDim1()));
				else
					setDataType(ctx, d);
			}

		}

		@Override
		public void exitPrimaryExpression(EMParser.PrimaryExpressionContext ctx) {
			if (ctx.getChild(0).getText().equals("(")) {
				StringBuilder buf = new StringBuilder();
				buf.append("(");
				buf.append(getLus(ctx.expression()));
				buf.append(")");
				setLus(ctx, buf.toString());
				setDataType(ctx, getDataType(ctx.expression()));
			} else if (ctx.ID() != null) {
				setDataType(ctx, getIDDataType(ctx.ID().getText(), null));
				String IDText = getIDText(ctx.ID().getText(), getCtx_position(ctx), "");
				setLus(ctx, IDText);

			} else if (ctx.ignore_value()  != null) {
				//				String msg = "because of ~";
				this.addUnsupported_ctx(ctx);
				setLus(ctx, getLus(ctx.ignore_value()));
			} 
			else {
				setLus(ctx, getLus(ctx.getChild(0)));
				setDataType(ctx, getDataType(ctx.getChild(0)));
			}

		}

		@Override
		public void exitIgnore_value(EMParser.Ignore_valueContext ctx) {
			setLus(ctx, ctx.getText());
		}

		@Override
		public void exitConstant(EMParser.ConstantContext ctx) {
			if (ctx.Integer() != null) {
				setLus(ctx, ctx.getText());
				setDataType(ctx, new DataType("int"));

			} else if (ctx.Float() != null) {
				setLus(ctx, ctx.getText());
				setDataType(ctx, new DataType("real"));

			} else if (ctx.String() != null) {
				this.addUnsupported_ctx(ctx);

			} else if (ctx.function_handle() != null) {
				setLus(ctx, getLus(ctx.function_handle()));
				setDataType(ctx, getDataType(ctx.function_handle()));

			} 
		}



		@Override
		public void exitFunction_handle(EMParser.Function_handleContext ctx) {
			// we do not support annonymous functions. 
			this.addUnsupported_ctx(ctx);
		}

		//		public boolean isArrayAccess(EMParser.IndexingContext ctx, Boolean left) {
		//			if (!getVars().containsKey(ctx.ID(0).getText()) && !left)
		//				return false;
		//			if (ctx.function_parameter_list(0) == null)
		//				return false;
		//			EMParser.Function_parameter_listContext fpl = ctx.function_parameter_list(0);
		//			if (fpl.function_parameter() != null)
		//				for (EMParser.Function_parameterContext fp : fpl.function_parameter()) {
		//					if ( !isNumeric(fp.getText()))
		//						return false;
		//				}
		//			return true;
		//		}
		@Override
		public void exitIndexing(EMParser.IndexingContext ctx) {
			this.addUnsupported_ctx(ctx);
		}
		public ArrayList<String> getParametersDataType(EMParser.Function_parameter_listContext ctx){
			ArrayList<String> params = new ArrayList<String>();
			int n = ctx.function_parameter().size();

			for (int i = 0; i < n; i++) {
				EMParser.Function_parameterContext pctx = ctx.function_parameter(i);
				if(pctx.notAssignment() == null){
					return new ArrayList<String>();
				}
				params.add(i, getDataType(pctx.notAssignment()).getBaseType());

			}
			return  params;
		}
		public String getParamsConverted(String paramsDTexpected, 
				ArrayList<String> params_dt,
				ArrayList<String> params, 
				String sep) {

			StringBuilder buf = new StringBuilder();

			String[] paramsDTSplited = paramsDTexpected.split(", ");
			ArrayList<String> expected_params_dt = new ArrayList<String>();
			int paramsDTLength = paramsDTSplited.length;
			String first_dt = (paramsDTLength>=1)? paramsDTSplited[0]:"real";

			int n = params.size();
			for(int i=0; i < paramsDTLength; i++) {
				expected_params_dt.add(i, paramsDTSplited[i]);
			}
			if (paramsDTLength < n)
				for(int i=paramsDTLength; i< n; i++) 
					expected_params_dt.add(i, first_dt);



			for (int i = 0; i < n; i++) {					
				String leftdt = expected_params_dt.get(i);
				String rightdt = params_dt.get(i)!=null? params_dt.get(i):leftdt;
				String conversion_fun = "";
				String rightExp = params.get(i);
				if (leftdt != null && !leftdt.equals("")) {
					if (rightdt != null && !rightdt.equals("") )
						if (!leftdt.equals(rightdt)) {
							conversion_fun = getConvFun(leftdt, rightdt);
							if (isNumeric(rightExp) && !conversion_fun.equals("")) {
								rightExp = fixConstant(leftdt, rightExp);
								conversion_fun = "";
							}else
								if (!conversion_fun.equals(""))
									this.addExternal_fun(conversion_fun);
						}
				}

				if (conversion_fun.equals(""))
					buf.append(rightExp);
				else
					buf.append(conversion_fun + "(" + rightExp + ")");

				if (i < n - 1)
					buf.append(sep);
			}
			return  buf.toString();

		}
		public String getFunction_parameter_list(
				EMParser.Function_parameter_listContext ctx,
				String paramsDT,
				String sep) {			

			int n = ctx.function_parameter().size();
			//construct params and their dataTypes
			ArrayList<String> params_dt = new ArrayList<String>();
			ArrayList<String> params = new ArrayList<String>();
			for (int i = 0; i < n; i++) {
				EMParser.Function_parameterContext pctx = ctx.function_parameter(i);
				if(pctx.notAssignment() == null){
					this.addUnsupported_ctx(ctx);
					return "";
				}
				params_dt.add(i, getDataType(pctx.notAssignment()).getBaseType());	
				params.add(i,  getLus(pctx.notAssignment()));
			}

			//Construct parameters list

			return  getParamsConverted(paramsDT, 
					params_dt,
					params, 
					sep) ;
		}
		@Override
		public void exitFunction_parameter_list(EMParser.Function_parameter_listContext ctx) {
			//not used. Parent context call a customizable function getFunction_parameter_list
			//setLus(ctx, getFunction_parameter_list(ctx, "real", ", "));
		}

		@Override
		public void exitFunction_parameter(EMParser.Function_parameterContext ctx) {
			if (ctx.notAssignment() != null) {
				setLus(ctx, getLus(ctx.getChild(0)));
			}

		}

		@Override
		public void exitCell(EMParser.CellContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitHorzcat(EMParser.HorzcatContext ctx) {

		}

		@Override
		public void exitMatrix(EMParser.MatrixContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitIf_block(EMParser.If_blockContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitElseif_block(EMParser.Elseif_blockContext ctx) {

		}

		@Override
		public void exitElse_block(EMParser.Else_blockContext ctx) {

		}

		@Override
		public void exitSwitch_block(EMParser.Switch_blockContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitCase_block(EMParser.Case_blockContext ctx) {

		}

		@Override
		public void exitOtherwise_block(EMParser.Otherwise_blockContext ctx) {

		}

		@Override
		public void exitFor_block(EMParser.For_blockContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitWhile_block(EMParser.While_blockContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitTry_catch_block(EMParser.Try_catch_blockContext ctx) {
			setLus(ctx, getLus(ctx.body()));
		}

		@Override
		public void exitCatch_block(EMParser.Catch_blockContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitReturn_exp(EMParser.Return_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitBreak_exp(EMParser.Break_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitContinue_exp(EMParser.Continue_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitGlobal_exp(EMParser.Global_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitPersistent_exp(EMParser.Persistent_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitClear_exp(EMParser.Clear_expContext ctx) {
			this.addUnsupported_ctx(ctx);
		}

		@Override
		public void exitNlosoc(EMParser.NlosocContext ctx) {
			nlosoc(ctx, "nlosoc");
		}

		@Override
		public void exitNloc(EMParser.NlocContext ctx) {
			nlosoc(ctx, "nloc");
		}

		@Override
		public void exitNlos(EMParser.NlosContext ctx) {
			nlosoc(ctx, "nlos");
		}

		@Override
		public void exitSoc(EMParser.SocContext ctx) {
			nlosoc(ctx, "soc");
		}

		@Override
		public void visitTerminal(TerminalNode node) {
			//			System.out.println("--Terminal "+ node.getText() 
			//			+ " has been visited " + " with Parent "+ node.getParent().getClass());
			setLus(node, node.getText());
		}

		/*  Finishing all rules     */

		public boolean isNumeric(String s) {
			return s != null && s.matches("[-+]?\\d*\\.?\\d+");
		}
		public boolean isInt(String s) {
			return s != null && s.matches("[-+]?\\d+");
		}
		public boolean isReal(String s) {
			return s != null && s.matches("[-+]?\\d*\\.\\d+");
		}
		public void callExpression(ParserRuleContext ctx, 
				String methodName1, 
				String methodName2,
				String operator,
				String external_fun) {
			java.lang.reflect.Method method1;
			java.lang.reflect.Method method2;
			try {
				method1 = ctx.getClass().getMethod(methodName1);
				method2 = ctx.getClass().getMethod(methodName2);
				if (method1.invoke(ctx) != null) {
					StringBuilder buf = new StringBuilder();



					String leftExp = "";
					String rightExp = "";
					ExternalLib lib = null;
					if (!methodName1.equals("unaryExpression")) {
						leftExp = getLus((ParseTree) method1.invoke(ctx));
						rightExp = getLus((ParseTree) method2.invoke(ctx));
						DataType method1_dt = getDataType((ParseTree) method1.invoke(ctx));
						DataType method2_dt = getDataType((ParseTree) method2.invoke(ctx));
						ArrayList<String> params_dt = new ArrayList<>();
						params_dt.add(0, method1_dt.getBaseType());
						params_dt.add(1, method2_dt.getBaseType());
						ArrayList<String> params = new ArrayList<>();
						params.add(0, leftExp);
						params.add(1, rightExp);
						if (!external_fun.equals("")) {
							lib =  new ExternalLib(external_fun, params_dt);
							String parametersDT = lib.getParametersDataType();
							String parametersConverted = getParamsConverted(parametersDT, 
									params_dt,
									params, 
									", ");
							buf.append(external_fun + "(" + parametersConverted +  ")");

						}else {
							lib =  new ExternalLib(operator, params_dt);
							String parametersDT = lib.getParametersDataType();
							String parametersConverted = getParamsConverted(parametersDT, 
									params_dt,
									params, 
									" " + operator + " ");

							buf.append(parametersConverted);

						}

					} else {
						rightExp = getLus((ParseTree) method1.invoke(ctx));
						DataType method1_dt = getDataType((ParseTree) method1.invoke(ctx));
						ArrayList<String> params_dt = new ArrayList<>();
						params_dt.add(0, method1_dt.getBaseType());
						ArrayList<String> params = new ArrayList<>();
						params.add(0, rightExp);
						lib =  new ExternalLib(operator, params_dt);
						String parametersDT = lib.getParametersDataType();
						String parametersConverted = getParamsConverted(parametersDT, 
								params_dt,
								params, 
								"");

						buf.append( operator + parametersConverted);
					}


					setLus(ctx, buf.toString());
					if (lib.getReturnDataType().equals(""))
						setDataType(ctx, getDataType((ParseTree) method1.invoke(ctx)));
					else
						setDataType(ctx, new DataType(lib.getReturnDataType()));


				} else {
					setLus(ctx, getLus((ParseTree) method2.invoke(ctx)));
					setDataType(ctx, getDataType((ParseTree) method2.invoke(ctx)));
				}


			} catch (IllegalAccessException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			catch ( IllegalArgumentException  e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			catch ( InvocationTargetException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}catch (SecurityException e) {
				e.printStackTrace();
			} catch (NoSuchMethodException e) {
				e.printStackTrace();
			}
		}

		private String fixConstant(String outport_dt, String rightExp) {

			String new_exp = rightExp;
			if (outport_dt.equals("int")) {
				if (isReal(rightExp)){

					new_exp = rightExp.replaceAll("\\.\\d*", "");;
				}
			}else if (outport_dt.equals("real")) {
				if (isInt(rightExp)){

					new_exp = rightExp + ".0";
				}
			}else if (outport_dt.equals("bool")) {
				double d = Double.parseDouble(rightExp);
				if (d > 0)
					new_exp = "true";
				else
					new_exp = "false";
			}


			return new_exp;
		}

		public void nlosoc(ParserRuleContext ctx, String type) {

		}

		public String getConvFun(DataType left, DataType right) {
			String outport_dt = "";
			String lus_in_dt = "";
			if (right == null)
				lus_in_dt = "real";
			else {
				if (left == null)
					outport_dt = "real";
				else {
					outport_dt = toLustre_dt(left.getBaseType());
					lus_in_dt = toLustre_dt(right.getBaseType());
				}
			}
			return getConvFun(outport_dt, lus_in_dt);
		}
		public String getConvFun(String outport_dt, String lus_in_dt) {

			String conv_fun = "";
			if (outport_dt.equals("int")) {
				if (lus_in_dt.equals("bool")){
					conv_fun = "bool_to_int";
				}
				else if (lus_in_dt.equals("real")){
					conv_fun = "real_to_int";
				}


			}else if (outport_dt.equals("real")) {
				if (lus_in_dt.equals("bool")){
					conv_fun = "bool_to_real";
				}
				else if (lus_in_dt.equals("int")){
					conv_fun = "int_to_real";
				}


			}else if (outport_dt.equals("bool")) {
				if (lus_in_dt.equals("int")){
					conv_fun = "int_to_bool";
				}
				else if (lus_in_dt.equals("real")){
					conv_fun = "real_to_bool";
				}
			}


			return conv_fun;
		}

		private String getIDText(String var_name, Boolean position, String postfix) {

			if (var_name == null )
				return "";
			if (position == null)
				return var_name;
			String new_name = var_name;
			if (!postfix.equals(""))
				new_name = var_name + postfix;

			if (getVars().containsKey(var_name)) {
				Variable v = getVar(var_name);
				int occ = v.getOccurance();
				if (position) {
					occ++;
				}
				return occ==0? new_name:new_name + "__" + occ;
			}else {
				new_name = ExternalLib.getLustreEquivalent(new_name);
				addExternal_fun(new_name);
			}

			return new_name;
		}

		private DataType getIDDataType(String v_name, ArrayList<String> arrayList) {
			if (this.getVars().containsKey(v_name)) {
				Variable v = this.getVar(v_name);
				return v.getDataType();
			}
			ExternalLib lib = new ExternalLib(v_name, arrayList);
			return new DataType(lib.getReturnDataType());

		}
		private String getIDParametersDataType(String v_name,  ArrayList<String> arrayList) {
			if (this.getVars().containsKey(v_name)) {
				//Array acces, parameters should be integers.
				return "int";
			}
			ExternalLib lib = new ExternalLib(v_name, arrayList);
			return lib.getParametersDataType();

		}
		private String toLustre_dt(String baseType) {
			// TODO Auto-generated method stub
			String res = baseType;
			if (baseType.contains("int")) {
				res = "int";
			}else if(baseType.equals("single") 
					|| baseType.equals("double") 
					|| baseType.equals("real") ) {
				res = "real";
			}else if(baseType.equals("boolean") 
					|| baseType.equals("bool") ) {
				res = "bool";
			}

			return res;
		}
		public String getUnsupported_exp() {
			HashSet<ParseTree> U = getUnsupported_ctx();
			StringBuilder buf = new StringBuilder();
			for (ParseTree p : U) {
				ParseTree parent = p.getParent();
				while(parent != null) {
					if (parent.getClass().toString().endsWith("StatementContext"))
						buf.append(parent.getText().replaceAll("\n", " ") + ";");
					parent = parent.getParent();
				}

			}

			return buf.toString();
		}

	}
	public static LusEmitter StringToLustre(String matlabCode) {
		try {
			InputStream stream = new ByteArrayInputStream(matlabCode.getBytes(StandardCharsets.UTF_8.name()));
			return InputStreamToLustre(stream);
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}
	public static ParseTree getParseTree(InputStream string) {
		ANTLRInputStream input = null;
		try {
			input = new ANTLRInputStream(string);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}
		EMLexer lexer = new EMLexer( input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		EMParser parser = new EMParser(tokens);
		parser.setBuildParseTree(true);
		ParseTree tree = parser.emfile();
		// show tree in text form
		//System.out.println(tree.toStringTree(parser));
		return tree;
	}
	public static LusEmitter InputStreamToLustre(InputStream stream) {
		ANTLRInputStream input = null;
		try {
			input = new ANTLRInputStream(stream);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}
		EMLexer lexer = new EMLexer( input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		EMParser parser = new EMParser(tokens);
		parser.setBuildParseTree(true);
		ParseTree tree = parser.emfile();
		ParseTreeWalker walker = new ParseTreeWalker();
		LusEmitter converter = new LusEmitter(tree);
		walker.walk(converter, tree);	


		return converter;

	}
	public static void main(String[] args) throws Exception {
		String inputFile = null;
		String file_name = null;
		if (args.length > 0) {
			inputFile = args[0];
			file_name = args[0] + ".lus";
		} else
			file_name = "output.lus";
		InputStream is = System.in;
		if (inputFile != null) {
			try {
				is = new FileInputStream(inputFile);
			}catch (FileNotFoundException e) {
				// TODO Auto-generated catch block
				System.out.println("File '"+ inputFile+"' Not Found.");
			}
		}
		StringBuilder buf = new StringBuilder();
		buf.append("%@DeclareType x: real;\n");
		buf.append("x == 1 > x + 2\n");
		LusEmitter converter = InputStreamToLustre(is);
		//		LusEmitter converter = StringToLustre(buf.toString());
		if (args.length > 0) {
			try {
				PrintWriter out = new PrintWriter(file_name);
				out.println(converter.getLus(converter.getTree()));
				System.out.println("Inputs are: ");
				System.out.println(converter.getInputsStr());
				System.out.println("Outputs are: ");
				System.out.println(converter.getOutputsStr());
				System.out.println("Variables are: ");
				System.out.println(converter.getVariablesStr());
				System.out.println("Lustre Fun is: ");
				System.out.println(converter.getLus_body());//.getLus(converter.getTree()));
				System.out.println("External Functions are: ");
				System.out.println(converter.getExternal_fun_str());
				System.out.println("Unsupported expressions are: ");
				System.out.println(converter.getUnsupported_exp());
				out.close();
			}catch (FileNotFoundException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}



}
