package cocosim.matlab2Lustre;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.Predicate;
import java.util.stream.Stream;

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
		//Variables Map, for every variable in script/function 
		Map<String, Variable> variables = new HashMap<String, Variable>();
		//For Arrays variables
		HashSet<String> dimensions_consts = new HashSet<>();
		//DataType Map, for every ctx get its dataType
		ParseTreeProperty<DataType> dataType = new ParseTreeProperty<DataType>();
		//Variable name of a ctx.
		ParseTreeProperty<String> id = new ParseTreeProperty<String>();

		//External lustre functions
		HashSet<String> external_fun = new HashSet<>();
		HashSet<String> unsupported_expr = new HashSet<>();


		public HashSet<String> getUnsupported_expr() {
			return unsupported_expr;
		}

		public void setUnsupported_expr(HashSet<String> unsupported_expr) {
			this.unsupported_expr = unsupported_expr;
		}

		public void addUnsupported_expr(String unsupported_expr) {
			this.unsupported_expr.add(unsupported_expr);
		}
		public HashSet<String> getExternal_fun() {
			return external_fun;
		}

		public void setExternal_fun(HashSet<String> external_fun) {
			this.external_fun = external_fun;
		}

		public void addExternal_fun(String external_fun) {
			this.external_fun.add(external_fun);
		}
		String getLus(ParseTree ctx) {
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
			return dataType.get(ctx);
		}

		void setDataType(ParseTree ctx, DataType d) {
			dataType.put(ctx, d);
		}

		String getID(ParseTree ctx) {
			return id.get(ctx);
		}

		void setID(ParseTree ctx, String s) {
			id.put(ctx, s);
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
		
		public void print_debug() {
			variables.values().stream().forEach(v -> System.out.println(v));
			
		}
		@Override
		public void exitEmfile(EMParser.EmfileContext ctx) {
			print_debug();
			
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


			if (variables.values().stream().anyMatch(v -> v.isVar()))
			{
				Stream<Variable> vars = variables.values().stream().filter(v -> v.isVar());
				buf.append("var ");
				vars.forEach(new Consumer<Variable>() {
					@Override
					public void accept(Variable v) {
						buf.append(v.toString());
						buf.append("\n");
					}
				});
			}

			buf.append("--let\n");
			buf.append(getLus(ctx.body()));
			buf.append("--tel\n");

			setLus(ctx, buf.toString());
		}


		@Override
		public void exitFunction(EMParser.FunctionContext ctx) {
			final StringBuilder buf = new StringBuilder();
			String functionName = ctx.ID().getText();

			if (getConsts().size() > 0) {
				buf.append("--dimensions as constants\n");
				String constants = String.join(", ", getConsts());
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
					buf.append(v.toString());
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
					buf.append(v.toString());
				}
				buf.append(")");
			} else
				buf.append("()");
			buf.append(";\n");

			if (variables.values().stream().anyMatch(new Predicate<Variable>() {
				@Override
				public boolean test(Variable v) {
					return v.isVar();
				}
			})) {
				Stream<Variable> vars = variables.values().stream().filter(new Predicate<Variable>() {
					@Override
					public boolean test(Variable v) {
						return v.isVar();
					}
				});
				buf.append("var ");
				vars.forEach(new Consumer<Variable>() {
					@Override
					public void accept(Variable v) {
						buf.append(v.toString());
						buf.append("\n");
					}
				});
			}

			buf.append("let\n");
			buf.append(getLus(ctx.body()));
			buf.append("tel\n");

			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFunc_input(EMParser.Func_inputContext ctx) {
			ctx.ID().forEach(new Consumer<TerminalNode>() {
				@Override
				public void accept(TerminalNode id) {
					setVar(id.getText(), new Variable(id.getText(), false));
				}
			});
		}

		@Override
		public void exitFunc_output(EMParser.Func_outputContext ctx) {
			ctx.ID().forEach(new Consumer<TerminalNode>() {
				@Override
				public void accept(TerminalNode id) {
					setVar(id.getText(), new Variable(id.getText(), false));
				}
			});
		}

		@Override
		public void exitBody(EMParser.BodyContext ctx) {
			if (ctx.body() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.body()));
				buf.append("\n");
				buf.append(getLus(ctx.body_item()));
				buf.append("\n");
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
				DataType dimension = new DataType(baseType);
				if (ctx.dataType().dimension(0) != null) {
					dimension.setDim1(ctx.dataType().dimension(0).getText());
					addDim(ctx.dataType().dimension(0).getText());
				}
				if (ctx.dataType().dimension(1) != null) {
					dimension.setDim2(ctx.dataType().dimension(1).getText());
					addDim(ctx.dataType().dimension(1).getText());
				}

				Variable v = getVar(var_name);
				if (!this.getVars().containsKey(var_name)) {
					setVar(var_name, new Variable(var_name, dimension, true));
				} else {
					setVar(var_name, new Variable(var_name, dimension, v.isVar(), v.getOccurance()));
				}

			}
		}

		@Override
		public void exitStatement(EMParser.StatementContext ctx) {
			setLus(ctx, getLus(ctx.getChild(0)));

		}

		@Override
		public void exitExpressionList(EMParser.ExpressionListContext ctx) {
			setLus(ctx, getLus(ctx.expression()));

		}

		@Override
		public void exitExpression(EMParser.ExpressionContext ctx) {
			if (ctx.expression() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.expression()));
				buf.append(getLus(ctx.assignment()));
				buf.append(";");
				setLus(ctx, buf.toString());
				setDataType(ctx, getDataType(ctx.assignment()));// it will be
				// called by low level contexts

			} else {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.assignment()));
				buf.append(";");
				setLus(ctx,  buf.toString());
				setDataType(ctx, getDataType(ctx.assignment()));
			}

		}

		@Override
		public void exitAssignment(EMParser.AssignmentContext ctx) {
			if (ctx.notAssignment() == null) {
				StringBuilder buf = new StringBuilder();

				// add variable

				DataType unaryExpression_dt = getDataType(ctx.unaryExpression());
				DataType assignment_dt = getDataType(ctx.assignment());
				String leftExp = getLus(ctx.unaryExpression());
				String rightExp = getLus(ctx.assignment());
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
								rightExp = fixConstant(unaryExpression_dt, rightExp);
								conversion_fun = "";
							}
						}
				}


				String var_name = getID(ctx.unaryExpression());
				if (var_name != null) {
					if (!getVars().containsKey(var_name)) {
						setVar(var_name, new Variable(var_name, unaryExpression_dt, false));
					} else {
						Variable v = getVar(var_name);
						setVar(var_name, new Variable(var_name, unaryExpression_dt, v.isVar(), v.getOccurance() + 1));
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
			} else {
				setLus(ctx, getLus(ctx.notAssignment()));
				setDataType(ctx, getDataType(ctx.notAssignment()));
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
			callExpression(ctx, "rdivide", "ldivide", operator, "dot_rdivide");
		}

		@Override
		public void exitLdivide(EMParser.LdivideContext ctx) {
			String operator = "";
			if (ctx.ldivide() != null) {
				this.addExternal_fun("dot_ldivide");
				operator = ctx.getChild(1).getText();
			}
			callExpression(ctx, "ldivide", "power", operator, "dot_ldivide");
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
				this.addUnsupported_expr(ctx.getText());
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
				this.addUnsupported_expr(ctx.getText());
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
				setDataType(ctx, getIDDataType(ctx.ID().getText()));
				setLus(ctx, ctx.ID().getText());

			} else if (ctx.ignore_value()  != null) {
				String msg = "because of ~";
				this.addUnsupported_expr(ctx.getText() + msg);
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
				this.addUnsupported_expr(ctx.getText());

			} else if (ctx.function_handle() != null) {
				setLus(ctx, getLus(ctx.function_handle()));
				setDataType(ctx, getDataType(ctx.function_handle()));

			} 
		}



		@Override
		public void exitFunction_handle(EMParser.Function_handleContext ctx) {
			// we do not support annonymous functions. 
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitIndexing(EMParser.IndexingContext ctx) {
			StringBuilder buf = new StringBuilder();

			buf.append(ctx.getChild(0).getText());
			int i = 1;
			int n = ctx.children.size();
			while (i < n) {
				String type = ctx.getChild(i++).getText();
				if (!type.equals("(")) {
					this.addUnsupported_expr(ctx.getText());
					return;
				} else {
					buf.append("(");
					if (!ctx.getChild(i).getText().equals(")"))
						buf.append(getLus(ctx.getChild(i++)));
					buf.append(")");
					i++;// consume ")"
					if (i < n - 1){
						this.addUnsupported_expr(ctx.getText());
						return;
					}
				} 
			}

			setLus(ctx, buf.toString());
			setDataType(ctx, getIDDataType(ctx.getChild(0).getText()));
//			System.out.println("DataType of "+ctx.getText()+" is " + getDataType(ctx));
		}

		@Override
		public void exitFunction_parameter_list(EMParser.Function_parameter_listContext ctx) {
			StringBuilder buf = new StringBuilder();
			int n = ctx.function_parameter().size();
			for (int i = 0; i < n; i++) {
				EMParser.Function_parameterContext pctx = ctx.function_parameter(i);
				if (pctx.COLON() == null) 
					buf.append(getLus(pctx));
				else {
					this.addUnsupported_expr(ctx.getText());
					return;
				}
				if (i < n - 1)
					buf.append(",");
			}
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFunction_parameter(EMParser.Function_parameterContext ctx) {
			if (ctx.notAssignment() != null) {
				setLus(ctx, getLus(ctx.getChild(0)));
			}

		}

		@Override
		public void exitCell(EMParser.CellContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitHorzcat(EMParser.HorzcatContext ctx) {

		}

		@Override
		public void exitMatrix(EMParser.MatrixContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitIf_block(EMParser.If_blockContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitElseif_block(EMParser.Elseif_blockContext ctx) {

		}

		@Override
		public void exitElse_block(EMParser.Else_blockContext ctx) {

		}

		@Override
		public void exitSwitch_block(EMParser.Switch_blockContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitCase_block(EMParser.Case_blockContext ctx) {

		}

		@Override
		public void exitOtherwise_block(EMParser.Otherwise_blockContext ctx) {

		}

		@Override
		public void exitFor_block(EMParser.For_blockContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitWhile_block(EMParser.While_blockContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitTry_catch_block(EMParser.Try_catch_blockContext ctx) {
			setLus(ctx, getLus(ctx.body()));
		}

		@Override
		public void exitCatch_block(EMParser.Catch_blockContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitReturn_exp(EMParser.Return_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitBreak_exp(EMParser.Break_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitContinue_exp(EMParser.Continue_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitGlobal_exp(EMParser.Global_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitPersistent_exp(EMParser.Persistent_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
		}

		@Override
		public void exitClear_exp(EMParser.Clear_expContext ctx) {
			this.addUnsupported_expr(ctx.getText());
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
			return s != null && s.matches("\\d+");
		}
		public boolean isReal(String s) {
			return s != null && s.matches("\\d*\\.\\d+");
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
					if (!methodName1.equals("unaryExpression")) {
						leftExp = getLus((ParseTree) method1.invoke(ctx));
						rightExp = getLus((ParseTree) method2.invoke(ctx));

					} else {
						rightExp = getLus((ParseTree) method1.invoke(ctx));
					}

					DataType method1_dt = getDataType((ParseTree) method1.invoke(ctx));
					DataType method2_dt = getDataType((ParseTree) method2.invoke(ctx));
					String conversion_fun = getConvFun(method1_dt, method2_dt);

					if (isNumeric(rightExp) && !conversion_fun.equals("")) {
						rightExp = fixConstant(method1_dt, rightExp);
						conversion_fun = "";
					}
					if (!conversion_fun.equals(""))
						rightExp = conversion_fun + "(" + rightExp + ")";
					if (external_fun.equals(""))
						buf.append(leftExp + " " + operator + " " + rightExp);
					else
						buf.append(external_fun + "(" + leftExp + ", "
								+ rightExp + ")");

					setLus(ctx, buf.toString());
					setDataType(ctx, getDataType((ParseTree) method1.invoke(ctx)));
				} else {
					setLus(ctx, getLus((ParseTree) method2.invoke(ctx)));
					setDataType(ctx, getDataType((ParseTree) method2.invoke(ctx)));
				}


			} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (SecurityException e) {
				e.printStackTrace();
			} catch (NoSuchMethodException e) {
				e.printStackTrace();
			}
		}

		private String fixConstant(DataType left_dt, String rightExp) {

			String outport_dt = toLustre_dt(left_dt.getBaseType());
			String new_exp = rightExp;
			switch (outport_dt) {
			case "int":
				System.out.println("RightExp: " + rightExp);
				System.out.println("isReal(rightExp): " + isReal(rightExp));
				if (isReal(rightExp)){

					new_exp = rightExp.replaceAll("\\.\\d*", "");;
				}

				break;

			case "real":
				System.out.println("RightExp: " + rightExp);
				System.out.println("isInt(rightExp): " + isInt(rightExp));
				if (isInt(rightExp)){

					new_exp = rightExp + ".0";
				}

				break;
			case "bool":
				double d = Double.parseDouble(rightExp);
				System.out.println("RightExp: " + rightExp);
				System.out.println("parseDouble(rightExp): " + d);
				
				if (d > 0)
					new_exp = "true";
				else
					new_exp = "false";
				break;

			default:
				break;
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
			String conv_fun = "";
			switch (outport_dt) {
			case "int":
				if (lus_in_dt.equals("bool")){
					this.addExternal_fun( "bool_to_int");
					conv_fun = "bool_to_int";
				}
				else if (lus_in_dt.equals("real")){
					this.addExternal_fun( "real_to_int");
					conv_fun = "real_to_int";
				}

				break;

			case "real":
				if (lus_in_dt.equals("bool")){
					this.addExternal_fun( "bool_to_real");
					conv_fun = "bool_to_real";
				}
				else if (lus_in_dt.equals("int")){
					this.addExternal_fun( "int_to_real");
					conv_fun = "int_to_real";
				}

				break;
			case "bool":
				if (lus_in_dt.equals("int")){
					this.addExternal_fun( "int_to_bool");
					conv_fun = "int_to_bool";
				}
				else if (lus_in_dt.equals("real")){
					this.addExternal_fun( "real_to_bool");
					conv_fun = "real_to_bool";
				}

				break;

			default:
				break;
			}

			return conv_fun;
		}
		private DataType getIDDataType(String v_name) {
			if (this.getVars().containsKey(v_name)) {
				Variable v = this.getVar(v_name);
				return v.getDataType();
			}
			return null;

		}
		private String toLustre_dt(String baseType) {
			// TODO Auto-generated method stub
			String res;
			switch (baseType) {
			case "int":
			case "int8": 
			case "uint8":
			case "int16" :
			case "uint16": 
			case "int32": 
			case "uint32":
				res = "int";
				break;
			case "single":
			case "double": 
			case "real":
				res = "real";
				break;
			case "boolean":
			case "bool":
				res = "bool";
				break;
			default:
				res = "real";
				break;
			}
			return res;
		}

	}
	private static String ToLustre(String matlabCode) {
		try {
			InputStream stream = new ByteArrayInputStream(matlabCode.getBytes(StandardCharsets.UTF_8.name()));
			return ToLustre(stream);
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}
	public static String ToLustre(InputStream string) {
		ANTLRInputStream input = null;
		try {
			input = new ANTLRInputStream(string);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "";
		}
		EMLexer lexer = new EMLexer( input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		EMParser parser = new EMParser(tokens);
		parser.setBuildParseTree(true);
		ParseTree tree = parser.emfile();
		// show tree in text form
		//System.out.println(tree.toStringTree(parser));

		ParseTreeWalker walker = new ParseTreeWalker();
		LusEmitter converter = new LusEmitter();
		walker.walk(converter, tree);
		String result = converter.getLus(tree);
		System.out.println(result);
		return result;

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
			is = new FileInputStream(inputFile);
		}

		String result = ToLustre(is);
		if (args.length > 0) 
			try (PrintWriter out = new PrintWriter(file_name)) {
				out.println(result);
			}
	}



}
