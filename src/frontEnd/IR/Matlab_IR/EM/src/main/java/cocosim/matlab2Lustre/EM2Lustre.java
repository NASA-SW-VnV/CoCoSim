package cocosim.matlab2Lustre;

import java.io.FileInputStream;
import java.io.InputStream;
import java.io.PrintWriter;
import java.lang.reflect.InvocationTargetException;
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
		ParseTreeProperty<String> lus = new ParseTreeProperty<String>();
		Map<String, Variable> variables = new HashMap<String, Variable>();
		HashSet<String> consts = new HashSet<>();
		ParseTreeProperty<DataType> dataType = new ParseTreeProperty<DataType>();
		ParseTreeProperty<String> id = new ParseTreeProperty<String>();

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

		public boolean isNumeric(String s) {
			return s != null && s.matches("[-+]?\\d*\\.?\\d+");
		}

		void addDim(String s) {
			if (!isNumeric(s))
				consts.add(s);
		}

		HashSet<String> getConsts() {
			return consts;
		}

		@Override
		public void exitEmfile(EMParser.EmfileContext ctx) {
			StringBuilder buf = new StringBuilder();
			int n = ctx.function().size();
			for (int i = 0; i < n; i++) {
				EMParser.FunctionContext fctx = ctx.function(i);
				buf.append(getLus(fctx));
				buf.append("\n");
			}
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
				// buf.append("\n");
				buf.append(getLus(ctx.body_item()));
				setLus(ctx, buf.toString());
			} else
				setLus(ctx, getLus(ctx.body_item()));
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
				if (!variables.containsKey(var_name)) {
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
				buf.append("\n");
				buf.append(getLus(ctx.assignment()));
				setLus(ctx, buf.toString());
				setDataType(ctx, getDataType(ctx.assignment()));// it will be
																// called low
																// levels
			} else {
				setLus(ctx, getLus(ctx.assignment()));
				setDataType(ctx, getDataType(ctx.assignment()));
			}
		}

		@Override
		public void exitAssignment(EMParser.AssignmentContext ctx) {
			if (ctx.notAssignment() == null) {
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.unaryExpression()));
				buf.append(" " + ctx.assignmentOperator().getText() + " ");
				buf.append(getLus(ctx.assignment()));
				setLus(ctx, buf.toString());

				// add variable
				DataType dt = getDataType(ctx.assignment());
				String var_name = getID(ctx.unaryExpression());
				if (var_name != null && dt != null) {
					if (!getVars().containsKey(var_name)) {
						setVar(var_name, new Variable(var_name, dt, false));
					} else {
						Variable v = getVar(var_name);
						setVar(var_name, new Variable(var_name, dt, v.isVar(), v.getOccurance()));
					}
				}

			} else {
				setLus(ctx, getLus(ctx.notAssignment()));
				setDataType(ctx, getDataType(ctx.notAssignment()));
			}

		}

		@Override
		public void exitNotAssignment(EMParser.NotAssignmentContext ctx) {
			setLus(ctx, getLus(ctx.relopOR()));
		}

		@Override
		public void exitRelopOR(EMParser.RelopORContext ctx) {
			callExpression(ctx, "relopOR", "relopAND");
		}

		@Override
		public void exitRelopAND(EMParser.RelopANDContext ctx) {
			callExpression(ctx, "relopAND", "relopelOR");
		}

		@Override
		public void exitRelopelOR(EMParser.RelopelORContext ctx) {
			callExpression(ctx, "relopelOR", "relopelAND");
		}

		@Override
		public void exitRelopelAND(EMParser.RelopelANDContext ctx) {
			callExpression(ctx, "relopelAND", "relopEQ_NE");
		}

		@Override
		public void exitRelopEQ_NE(EMParser.RelopEQ_NEContext ctx) {
			callExpression(ctx, "relopEQ_NE", "relopGL");
		}

		@Override
		public void exitRelopGL(EMParser.RelopGLContext ctx) {
			callExpression(ctx, "relopGL", "plus_minus");
		}

		@Override
		public void exitPlus_minus(EMParser.Plus_minusContext ctx) {
			callExpression(ctx, "plus_minus", "mtimes");
		}

		@Override
		public void exitMtimes(EMParser.MtimesContext ctx) {
			callExpression(ctx, "mtimes", "mrdivide");
		}

		@Override
		public void exitMrdivide(EMParser.MrdivideContext ctx) {
			callExpression(ctx, "mrdivide", "mldivide");
		}

		@Override
		public void exitMldivide(EMParser.MldivideContext ctx) {
			callExpression(ctx, "mldivide", "mpower");
		}

		@Override
		public void exitMpower(EMParser.MpowerContext ctx) {
			callExpression(ctx, "mpower", "times");
		}

		@Override
		public void exitTimes(EMParser.TimesContext ctx) {
			callExpression(ctx, "times", "rdivide");
		}

		@Override
		public void exitRdivide(EMParser.RdivideContext ctx) {
			callExpression(ctx, "rdivide", "ldivide");
		}

		@Override
		public void exitLdivide(EMParser.LdivideContext ctx) {
			callExpression(ctx, "ldivide", "power");
		}

		@Override
		public void exitPower(EMParser.PowerContext ctx) {
			callExpression(ctx, "power", "colonExpression");
		}

		@Override
		public void exitColonExpression(EMParser.ColonExpressionContext ctx) {
			callExpression(ctx, "colonExpression", "unaryExpression");
		}

		@Override
		public void exitUnaryExpression(EMParser.UnaryExpressionContext ctx) {
			callExpression(ctx, "unaryExpression", "postfixExpression");
		}

		@Override
		public void exitPostfixExpression(EMParser.PostfixExpressionContext ctx) {
			if (ctx.primaryExpression() != null)
				setLus(ctx, getLus(ctx.primaryExpression()));
			else if (ctx.TRANSPOSE() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("transpose"));
				buf.append(",\n");

				String operator = ctx.TRANSPOSE().getText();
				buf.append(Quotes("operator") + ":" + Quotes(operator));
				buf.append(",\n");

				buf.append(Quotes("leftExp") + ":" + getLus(ctx.postfixExpression()));
				buf.append("\n}");

				setLus(ctx, buf.toString());
			}

		}

		@Override
		public void exitPrimaryExpression(EMParser.PrimaryExpressionContext ctx) {
			if (ctx.getChild(0).getText().equals("(")) {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("parenthesedExpression"));
				buf.append(",\n");
				buf.append(Quotes("expression") + ":" + getLus(ctx.expression()));
				buf.append("\n}");
				setLus(ctx, buf.toString());
			} else if (ctx.ID() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("ID"));
				buf.append(",\n");
				buf.append(Quotes("name") + ":" + Quotes(ctx.ID().getText()));
				buf.append("\n}");
				setLus(ctx, buf.toString());
			} else {
				setLus(ctx, getLus(ctx.getChild(0)));
			}

		}

		@Override
		public void exitIgnore_value(EMParser.Ignore_valueContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("ignore_value"));
			buf.append(",\n");
			buf.append(Quotes("value") + ":" + Quotes(ctx.getText()));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitConstant(EMParser.ConstantContext ctx) {
			if (ctx.function_handle() != null) {
				setLus(ctx, getLus(ctx.function_handle()));
			} else if (ctx.indexing() != null) {
				setLus(ctx, getLus(ctx.indexing()));
			} else {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("constant"));
				buf.append(",\n");
				String dataType = ConstantDataType(ctx);
				buf.append(Quotes("dataType") + ":" + Quotes(dataType));
				buf.append(",\n");
				buf.append(Quotes("value") + ":" + Quotes(ctx.getText()));
				buf.append("\n}");
				setLus(ctx, buf.toString());
			}
		}

		public String ConstantDataType(EMParser.ConstantContext ctx) {
			String t = "";
			if (ctx.Integer() != null)
				t = "Integer";
			else if (ctx.Float() != null)
				t = "Float";
			else if (ctx.String() != null)
				t = "String";
			return t;
		}

		@Override
		public void exitFunction_handle(EMParser.Function_handleContext ctx) {
			if (ctx.func_input() != null) {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("function_handle"));
				buf.append(",\n");
				buf.append(Quotes("input_params") + ":" + getLus(ctx.func_input()));
				if (ctx.expression() != null) {
					buf.append(Quotes("expression") + ":" + getLus(ctx.expression()));
					buf.append(",\n");
				}
				buf.append("\n}");
				setLus(ctx, buf.toString());
			} else {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("function_handle"));
				buf.append(",\n");
				buf.append(Quotes("ID") + ":" + Quotes(ctx.ID().getText()));
				buf.append("\n}");
				setLus(ctx, buf.toString());
			}
		}

		@Override
		public void exitIndexing(EMParser.IndexingContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("indexing"));
			buf.append(",\n");
			buf.append(Quotes("ID") + ":" + Quotes(ctx.getChild(0).getText()));
			buf.append(",\n");
			int i = 1;
			int child = 1;
			int n = ctx.children.size();
			while (i < n) {
				String type = ctx.getChild(i++).getText();
				if (type.equals(".")) {
					buf.append(Quotes("child" + (child++)) + ":");
					if (ctx.getChild(i).getText().equals("(")) {
						i++;
						buf.append("{");
						buf.append("\n");
						buf.append(Quotes("type") + ":" + Quotes("DotPARENIndex"));
						buf.append(",\n");
						buf.append(Quotes("expression") + ":" + getLus(ctx.getChild(i++)));
						buf.append("\n}");
						i++;// consume ")"
						if (i < n - 1)
							buf.append(",\n");
					} else {
						buf.append("{");
						buf.append("\n");
						buf.append(Quotes("type") + ":" + Quotes("DotID"));
						buf.append(",\n");
						buf.append(Quotes("name") + ":" + Quotes(ctx.getChild(i++).getText()));
						buf.append("\n}");
						if (i < n - 1)
							buf.append(",\n");
					}
				} else if (type.equals("(")) {
					buf.append(Quotes("child" + (child++)) + ":");
					buf.append("{");
					buf.append("\n");
					buf.append(Quotes("type") + ":" + Quotes("PARENIndex"));
					buf.append(",\n");
					if (ctx.getChild(i).getText().equals(")"))
						buf.append(Quotes("parameter_list") + ":" + "[]");
					else
						buf.append(Quotes("parameter_list") + ":" + getLus(ctx.getChild(i++)));
					buf.append("\n}");
					i++;// consume ")"
					if (i < n - 1)
						buf.append(",\n");
				} else if (type.equals("{")) {
					buf.append(Quotes("child" + (child++)) + ":");
					buf.append("{");
					buf.append("\n");
					buf.append(Quotes("type") + ":" + Quotes("BRACEIndex"));
					buf.append(",\n");
					if (ctx.getChild(i).getText().equals("}"))
						buf.append(Quotes("parameter_list") + ":" + "[]");
					else
						buf.append(Quotes("parameter_list") + ":" + getLus(ctx.getChild(i++)));
					buf.append("\n}");
					i++;// consume "}"
					if (i < n - 1)
						buf.append(",\n");
				}
			}

			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFunction_parameter_list(EMParser.Function_parameter_listContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("[");
			int n = ctx.function_parameter().size();
			for (int i = 0; i < n; i++) {
				EMParser.Function_parameterContext pctx = ctx.function_parameter(i);
				buf.append(getLus(pctx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("]");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFunction_parameter(EMParser.Function_parameterContext ctx) {
			if (ctx.COLON() == null)
				setLus(ctx, getLus(ctx.getChild(0)));
			else {
				StringBuilder buf = new StringBuilder();
				buf.append("{");
				buf.append("\n");
				buf.append(Quotes("type") + ":" + Quotes("COLON"));
				buf.append(",\n");
				buf.append(Quotes("value") + ":" + Quotes(ctx.COLON().getText()));
				buf.append("\n}");
				setLus(ctx, buf.toString());
			}

		}

		@Override
		public void exitCell(EMParser.CellContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("cell"));
			buf.append(",\n");
			buf.append(Quotes("rows") + ":[");
			int n = ctx.horzcat().size();
			for (int i = 0; i < n; i++) {
				EMParser.HorzcatContext vctx = ctx.horzcat(i);
				buf.append(getLus(vctx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("]\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitHorzcat(EMParser.HorzcatContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("[");
			int n = ctx.expression().size();
			for (int i = 0; i < n; i++) {
				EMParser.ExpressionContext ectx = ctx.expression(i);
				buf.append(getLus(ectx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("]\n");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitMatrix(EMParser.MatrixContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("matrix"));
			buf.append(",\n");
			buf.append(Quotes("rows") + ":[");
			int n = ctx.horzcat().size();
			for (int i = 0; i < n; i++) {
				EMParser.HorzcatContext vctx = ctx.horzcat(i);
				buf.append(getLus(vctx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("]\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitIf_block(EMParser.If_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("if_block"));
			buf.append(",\n");
			buf.append(Quotes("condition") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n],\n");
			buf.append(Quotes("elseif_blocks") + ":[");
			int n = ctx.elseif_block().size();
			for (int i = 0; i < n; i++) {
				EMParser.Elseif_blockContext tctx = ctx.elseif_block(i);
				buf.append(getLus(tctx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("\n],\n");
			if (ctx.else_block() == null)
				buf.append(Quotes("else_block") + ":{}");
			else
				buf.append(Quotes("else_block") + ":" + getLus(ctx.else_block()));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitElseif_block(EMParser.Elseif_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("elseif_block"));
			buf.append(",\n");
			buf.append(Quotes("condition") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitElse_block(EMParser.Else_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("else_block"));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitSwitch_block(EMParser.Switch_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("switch_block"));
			buf.append(",\n");
			buf.append(Quotes("expression") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("case_blocks") + ":[");
			int n = ctx.case_block().size();
			for (int i = 0; i < n; i++) {
				EMParser.Case_blockContext tctx = ctx.case_block(i);
				buf.append(getLus(tctx));
				if (i < n - 1)
					buf.append(",");
			}
			buf.append("\n],\n");
			if (ctx.otherwise_block() == null)
				buf.append(Quotes("otherwise_block") + ":{}");
			else
				buf.append(Quotes("otherwise_block") + ":" + getLus(ctx.otherwise_block()));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitCase_block(EMParser.Case_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("case_block"));
			buf.append(",\n");
			buf.append(Quotes("expression") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitOtherwise_block(EMParser.Otherwise_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("else_block"));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitFor_block(EMParser.For_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("for_block"));
			buf.append(",\n");
			buf.append(Quotes("index") + ":" + Quotes(ctx.ID().getText()));
			buf.append(",\n");
			buf.append(Quotes("index_expression") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitWhile_block(EMParser.While_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("while_block"));
			buf.append(",\n");
			buf.append(Quotes("condition") + ":" + getLus(ctx.notAssignment()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitTry_catch_block(EMParser.Try_catch_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("try_catch_block"));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n],\n");
			if (ctx.catch_block() == null)
				buf.append(Quotes("catch_block") + ":{}");
			else
				buf.append(Quotes("catch_block") + ":" + getLus(ctx.catch_block()));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitCatch_block(EMParser.Catch_blockContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("catch_block"));
			buf.append(",\n");
			if (ctx.ID() == null)
				buf.append(Quotes("id") + ":{}");
			else
				buf.append(Quotes("id") + ":" + getLus(ctx.ID()));
			buf.append(",\n");
			buf.append(Quotes("statements") + ":[" + getLus(ctx.body()));
			buf.append("\n]");

			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitReturn_exp(EMParser.Return_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("return_exp"));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitBreak_exp(EMParser.Break_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("break_exp"));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitContinue_exp(EMParser.Continue_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("continue_exp"));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitGlobal_exp(EMParser.Global_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("global_exp"));
			buf.append(",\n");
			buf.append(Quotes("IDs") + ":[");
			for (int i = 0; i < ctx.ID().size(); i++) {
				TerminalNode id = ctx.ID(i);
				buf.append(Quotes(id.getText()));
				if (i < ctx.ID().size() - 1)
					buf.append(",");
			}
			buf.append("]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitPersistent_exp(EMParser.Persistent_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("persistent_exp"));
			buf.append(",\n");
			buf.append(Quotes("IDs") + ":[");
			for (int i = 0; i < ctx.ID().size(); i++) {
				TerminalNode id = ctx.ID(i);
				buf.append(Quotes(id.getText()));
				if (i < ctx.ID().size() - 1)
					buf.append(",");
			}
			buf.append("]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		@Override
		public void exitClear_exp(EMParser.Clear_expContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes("clear_exp"));
			buf.append(",\n");
			buf.append(Quotes("IDs") + ":[");
			for (int i = 0; i < ctx.ID().size(); i++) {
				TerminalNode id = ctx.ID(i);
				buf.append(Quotes(id.getText()));
				if (i < ctx.ID().size() - 1)
					buf.append(",");
			}
			buf.append("]");
			buf.append("\n}");
			setLus(ctx, buf.toString());
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
			setLus(node, node.getText());
		}

		public void callExpression(ParserRuleContext ctx, String methodName1, String methodName2) {
			java.lang.reflect.Method method1;
			java.lang.reflect.Method method2;
			try {
				method1 = ctx.getClass().getMethod(methodName1);
				method2 = ctx.getClass().getMethod(methodName2);
				if (method1.invoke(ctx) != null) {
					StringBuilder buf = new StringBuilder();

					String operator = null;
					if (methodName1.equals("unaryExpression"))
						operator = ctx.getChild(0).getText();
					else
						operator = ctx.getChild(1).getText();

					String leftExp = "";
					String rightExp = "";
					if (!methodName1.equals("unaryExpression")) {
						leftExp = getLus((ParseTree) method1.invoke(ctx));
						rightExp = getLus((ParseTree) method2.invoke(ctx));
					} else
						rightExp = getLus((ParseTree) method1.invoke(ctx));

					buf.append(leftExp + " " + operator + " " + rightExp);
					setLus(ctx, buf.toString());
				} else
					setLus(ctx, getLus((ParseTree) method2.invoke(ctx)));

			} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (SecurityException e) {
				e.printStackTrace();
			} catch (NoSuchMethodException e) {
				e.printStackTrace();
			}
		}

		public void nlosoc(ParserRuleContext ctx, String type) {
			StringBuilder buf = new StringBuilder();
			buf.append("{");
			buf.append("\n");
			buf.append(Quotes("type") + ":" + Quotes(type));
			buf.append(",\n");
			String tokenName = ctx.getText().replaceAll("\\n", "\\\\n");
			buf.append(Quotes("name") + ":" + Quotes(tokenName));
			buf.append("\n}");
			setLus(ctx, buf.toString());
		}

		public static String Quotes(String s) {
			if (s == null || s.charAt(0) == '"')
				return s;
			return '"' + s + '"';
		}

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
		ANTLRInputStream input = new ANTLRInputStream(is);
		EMLexer lexer = new EMLexer(input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		EMParser parser = new EMParser(tokens);
		parser.setBuildParseTree(true);
		ParseTree tree = parser.emfile();
		// show tree in text form
		System.out.println(tree.toStringTree(parser));

		ParseTreeWalker walker = new ParseTreeWalker();
		LusEmitter converter = new LusEmitter();
		walker.walk(converter, tree);
		String result = converter.getLus(tree);
		System.out.println(result);

		try (PrintWriter out = new PrintWriter(file_name)) {
			out.println(result);
		}
	}
}
