package Lustre;

import java.io.FileInputStream;
import java.io.InputStream;
import java.io.PrintWriter;
import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.stream.Stream;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeProperty;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.antlr.v4.runtime.tree.TerminalNode;

import Lustre.EMParser.Func_inputContext;
import Lustre.domain.DataType;
import Lustre.domain.Variable;

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
public class EM2COCO {
	public static class LusEmitter extends EMBaseListener {
		ParseTreeProperty<String> lus = new ParseTreeProperty<String>();
		Map<String, Variable> variables = new HashMap<String, Variable>();
		HashSet<String> consts = new HashSet<>();
		ParseTreeProperty<DataType> dataType = new ParseTreeProperty<DataType>();
		ParseTreeProperty<String> id = new ParseTreeProperty<String>();

		String getLus(ParseTree ctx) { 
			String s = "";
			String tmp = lus.get(ctx);
			if (tmp != null) s = tmp;
			return s; 
		}

		void setLus(ParseTree ctx, String s) { 
			lus.put(ctx, s); 
		}

		DataType getDataType(ParseTree ctx){
			return dataType.get(ctx);
		} 
		void setDataType(ParseTree ctx, DataType d) { 
			dataType.put(ctx, d); 
		}
		String getID(ParseTree ctx){
			return id.get(ctx);
		}
		void setID(ParseTree ctx, String s) { 
			id.put(ctx, s); 
		}
		Variable getVar(String s){
			return variables.get(s);
		}
		Map<String, Variable> getVars(){
			return variables;
		}
		void setVar(String s, Variable v){
			variables.put(s, v);
		}
		public boolean isNumeric(String s) {  
			return s != null && s.matches("[-+]?\\d*\\.?\\d+");  
		}  

		void addDim(String s){
			if (!isNumeric(s))
				consts.add(s);
		}

		HashSet<String> getConsts(){
			return consts;
		}
		@Override
		public void exitEmfile(EMParser.EmfileContext ctx) {   
			StringBuilder buf = new StringBuilder();
			int n = ctx.function().size();
			for (int i=0; i < n; i++){
				EMParser.FunctionContext fctx = ctx.function(i);
				buf.append(getLus(fctx));
				buf.append("\n");
			}
			setLus(ctx, buf.toString());

		}

		@Override
		public void exitFunction(EMParser.FunctionContext ctx) {
			StringBuilder buf = new StringBuilder();
			String functionName = ctx.ID().getText();

			if (getConsts().size() > 0){
				buf.append("--dimensions as constants\n");
				String constants = String.join(", ", getConsts());
				buf.append("const "+ constants + ": int;\n");
			}

			buf.append("node "+functionName);

			if(ctx.func_input() != null) {
				Func_inputContext inputs = ctx.func_input() ;
				buf.append("(");
				int n = inputs.ID().size();
				for (int i=0;i < n; i++) {
					String input_name = inputs.ID(i).getText();
					Variable v = getVar(input_name);
					buf.append(v.toString());
				}
				buf.append(")");
			}
			else
				buf.append("()");
			buf.append("\nreturns ");
			if(ctx.func_output() != null) {
				EMParser.Func_outputContext outputs = ctx.func_output() ;
				buf.append("(");
				int n = outputs.ID().size();
				for (int i=0;i < n; i++) {
					String output_name = outputs.ID(i).getText();
					Variable v = getVar(output_name);
					buf.append(v.toString());
				}
				buf.append(")");
			}
			else
				buf.append("()");			
			buf.append(";\n");
			
			
			if (variables.values().stream().anyMatch(v -> v.isVar())){
				Stream<Variable> vars = variables.values()
						.stream()
						.filter(v -> v.isVar());
				buf.append("var ");
				vars.forEach(v -> {
					buf.append(v.toString());
					buf.append("\n");
				});
			}

			ctx.annotation().forEach(a -> buf.append(getLus(a)));
			buf.append("let\n");
			buf.append(getLus(ctx.body()));
			buf.append("tel\n");

			setLus(ctx, buf.toString());
		}

		@Override public void exitFunc_input(EMParser.Func_inputContext ctx) { 
			ctx.ID().forEach(id -> 
			setVar(id.getText(),
					new Variable(id.getText(), false)
					)
					);
		}

		@Override public void exitFunc_output(EMParser.Func_outputContext ctx) {
			ctx.ID().forEach(id -> 
			setVar(id.getText(),
					new Variable(id.getText(), false)
					)
					);
		}


		@Override public void exitBody(EMParser.BodyContext ctx) {
			if (ctx.body() != null){
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.body()));
				//buf.append("\n");
				buf.append(getLus(ctx.body_item()));
				setLus(ctx, buf.toString());
			}
			else
				setLus(ctx,getLus(ctx.body_item()));
		}

		@Override public void exitBody_item(EMParser.Body_itemContext ctx) { 
			setLus(ctx, getLus(ctx.getChild(0)));
		}

		@Override public void exitAnnotation(EMParser.AnnotationContext ctx) { 
			setLus(ctx, getLus(ctx.getChild(0)));
		}
		@Override public void exitDeclare_type(EMParser.Declare_typeContext ctx) { 
			if (ctx.DeclareType() != null){
				String var_name = ctx.ID().getText();
				String baseType = ctx.dataType().BASETYPE().getText();
				DataType dimension = new DataType(baseType);
				if (ctx.dataType().dimension(0) != null){ 
					dimension.setDim1(ctx.dataType().dimension(0).getText());
					addDim(ctx.dataType().dimension(0).getText());
				}
				if (ctx.dataType().dimension(1) != null){ 
					dimension.setDim2(ctx.dataType().dimension(1).getText());
					addDim(ctx.dataType().dimension(1).getText());
				}

				Variable v = getVar(var_name);
				if ( !variables.containsKey(var_name)){
					setVar(var_name,
							new Variable(var_name, dimension, true)
							);
				}
				else{
					setVar(var_name,
							new Variable(var_name, dimension, v.isVar(), v.getOccurance())
							);
				}

			}
		}
		@Override public void exitContract(EMParser.ContractContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("(*@contract ");
			ctx.contract_item().forEach(e -> buf.append(getLus(e)));
			buf.append("*)\n");
			setLus(ctx, buf.toString());
		}
		@Override public void exitCONTRACT_CONST(EMParser.CONTRACT_CONSTContext ctx) {
			StringBuilder buf = new StringBuilder();
			String dt = "";
			if (ctx.dataType()!=null) dt = ":" + ctx.dataType().getText();
			buf.append("const "+ ctx.ID().getText() + dt + " = " + getLus(ctx.coco_expression()) + ";");
			setLus(ctx, buf.toString());
		}
		@Override public void exitCONTRACT_VAR(EMParser.CONTRACT_VARContext ctx) {
			StringBuilder buf = new StringBuilder();
			String dt = ":" + ctx.dataType().getText();
			buf.append("var "+ ctx.ID().getText() + dt + " = " + getLus(ctx.coco_expression()) + ";");
			setLus(ctx, buf.toString());
		}
		@Override public void exitCONTRACT_ASSUME(EMParser.CONTRACT_ASSUMEContext ctx) {
			StringBuilder buf = new StringBuilder();
			buf.append("assume "+ getLus(ctx.coco_expression()) + ";");
			setLus(ctx, buf.toString());
		}
		@Override public void exitCONTRACT_GUARANTEE(EMParser.CONTRACT_GUARANTEEContext ctx) { 
			StringBuilder buf = new StringBuilder();
			buf.append("guarantee "+ getLus(ctx.coco_expression()) + ";");
			setLus(ctx, buf.toString());
		}
		@Override public void exitCONTRACT_NL(EMParser.CONTRACT_NLContext ctx) {
			setLus(ctx, "\n");
		}
		@Override public void exitCONTRACT_MODE(EMParser.CONTRACT_MODEContext ctx) { 
			setLus(ctx, getLus(ctx.coco_mode()));
		}
		@Override public void exitCoco_mode(EMParser.Coco_modeContext ctx) { 
			StringBuilder buf = new StringBuilder();
			buf.append("mode "+ ctx.ID().getText() + " (\n");
			ctx.require().forEach(r -> buf.append(getLus(r)));
			ctx.ensure().forEach(e -> buf.append(getLus(e)));
			buf.append(");\n");
			setLus(ctx, buf.toString());
		}
		@Override public void exitRequire(EMParser.RequireContext ctx) { 
			StringBuilder buf = new StringBuilder();
			buf.append("require "+ getLus(ctx.coco_expression()) + ";\n");
			setLus(ctx, buf.toString());
		}
		@Override public void exitEnsure(EMParser.EnsureContext ctx) { 
			StringBuilder buf = new StringBuilder();
			 buf.append("ensure "+ getLus(ctx.coco_expression()) + ";\n");
			setLus(ctx, buf.toString());
		}
	
		@Override public void exitCoco_expression(EMParser.Coco_expressionContext ctx) { 
			StringBuilder buf = new StringBuilder();
			if (ctx.expression() != null) 
				buf.append(getLus(ctx.expression()));
			else if (ctx.NOT() != null) 
				buf.append(" not " + getLus(ctx.coco_expression(0)));
			else if (ctx.PRE() != null) 
				buf.append(" pre " + getLus(ctx.coco_expression(0)));
			else if (ctx.INIT()!= null) 
				buf.append(getLus(ctx.coco_expression(0)) + " -> " + getLus(ctx.coco_expression(1)));
			else if (ctx.IMPLIES() != null) 
				buf.append(getLus(ctx.coco_expression(0)) + " => " + getLus(ctx.coco_expression(1)));
			else if (ctx.LUS_NEQ() != null) 
				buf.append(getLus(ctx.coco_expression(0)) + " <> " + getLus(ctx.coco_expression(1)));
			else if (ctx.LUS_AND_OR() != null) 
				buf.append(getLus(ctx.coco_expression(0)) + " " +ctx.LUS_AND_OR().getText() + " " + getLus(ctx.coco_expression(1)));
			else if (ctx.LPAREN()  != null)  {
				buf.append("(" + getLus(ctx.coco_expression(0)) + ")");
			}
			setLus(ctx, buf.toString());
		}
		
		@Override public void exitStatement(EMParser.StatementContext ctx) {
			setLus(ctx,getLus(ctx.getChild(0)));

		}

		@Override public void exitExpressionList(EMParser.ExpressionListContext ctx) {
			setLus(ctx,getLus(ctx.expression()));

		}

		@Override public void exitExpression(EMParser.ExpressionContext ctx) {
			if (ctx.expression() != null){
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.expression()));
				buf.append("\n");
				buf.append(getLus(ctx.assignment()));
				setLus(ctx, buf.toString());
				setDataType(ctx, getDataType(ctx.assignment()));// it will be called low levels
			}
			else{
				setLus(ctx,getLus(ctx.assignment()));
				setDataType(ctx, getDataType(ctx.assignment()));
			}
		}

		@Override public void exitAssignment(EMParser.AssignmentContext ctx) {
			if (ctx.notAssignment() == null){
				StringBuilder buf = new StringBuilder();
				buf.append(getLus(ctx.unaryExpression()));
				buf.append(" "+ctx.assignmentOperator().getText()+" ");
				buf.append(getLus(ctx.assignment()));
				setLus(ctx, buf.toString());

				//add variable
				DataType dt = getDataType(ctx.assignment());
				String var_name = getID(ctx.unaryExpression());
				if (var_name!=null && dt!=null){
					if ( !getVars().containsKey(var_name)){
						setVar(var_name,
								new Variable(var_name, dt, false)
								);
					}
					else{
						Variable v = getVar(var_name);
						setVar(var_name,
								new Variable(var_name, dt, v.isVar(), v.getOccurance())
								);
					}
				}

			}else{
				setLus(ctx, getLus(ctx.notAssignment()));
				setDataType(ctx, getDataType(ctx.notAssignment()));
			}

		}

		@Override public void exitNotAssignment(EMParser.NotAssignmentContext ctx) {
			setLus(ctx,getLus(ctx.relopOR()));
		}

		@Override public void exitRelopOR(EMParser.RelopORContext ctx) { 
			callExpression( ctx,  "relopOR",  "relopAND");
		}

		@Override public void exitRelopAND(EMParser.RelopANDContext ctx) { 
			callExpression( ctx,  "relopAND",  "relopelOR");
		}

		@Override public void exitRelopelOR(EMParser.RelopelORContext ctx) { 
			callExpression( ctx,  "relopelOR",  "relopelAND");
		}

		@Override public void exitRelopelAND(EMParser.RelopelANDContext ctx) {
			callExpression( ctx,  "relopelAND",  "relopEQ_NE");
		}

		@Override public void exitRelopEQ_NE(EMParser.RelopEQ_NEContext ctx) {
			callExpression( ctx,  "relopEQ_NE",  "relopGL");
		}

		@Override public void exitRelopGL(EMParser.RelopGLContext ctx) {
			callExpression( ctx,  "relopGL",  "plus_minus");
		}

		@Override public void exitPlus_minus(EMParser.Plus_minusContext ctx) {
			callExpression( ctx,  "plus_minus",  "mtimes");
		}

		@Override public void exitMtimes(EMParser.MtimesContext ctx) {
			callExpression( ctx,  "mtimes",  "mrdivide");
		}

		@Override public void exitMrdivide(EMParser.MrdivideContext ctx) {
			callExpression( ctx,  "mrdivide",  "mldivide");
		}

		@Override public void exitMldivide(EMParser.MldivideContext ctx) {
			callExpression( ctx,  "mldivide",  "mpower");
		}

		@Override public void exitMpower(EMParser.MpowerContext ctx) { 
			callExpression( ctx,  "mpower",  "times");
		}

		@Override public void exitTimes(EMParser.TimesContext ctx) {
			callExpression( ctx,  "times",  "rdivide");
		}

		@Override public void exitRdivide(EMParser.RdivideContext ctx) {
			callExpression( ctx,  "rdivide",  "ldivide");
		}

		@Override public void exitLdivide(EMParser.LdivideContext ctx) { 
			callExpression( ctx,  "ldivide",  "power");
		}

		@Override public void exitPower(EMParser.PowerContext ctx) { 
			callExpression( ctx,  "power",  "colonExpression");
		}

		@Override public void exitColonExpression(EMParser.ColonExpressionContext ctx) {
			callExpression( ctx,  "colonExpression",  "unaryExpression");
		}

		@Override public void exitUnaryExpression(EMParser.UnaryExpressionContext ctx) {
			callExpression( ctx,  "unaryExpression",  "postfixExpression");
		}

		@Override public void exitPostfixExpression(EMParser.PostfixExpressionContext ctx) { 
			if (ctx.primaryExpression() != null)
				setLus(ctx, getLus(ctx.primaryExpression()));
			else if (ctx.TRANSPOSE() != null){
				System.out.println("TRANSPOSE is not supported yet");
				StringBuilder buf = new StringBuilder();
				buf.append("transpose("+getLus(ctx.postfixExpression())+")");
				setLus(ctx, buf.toString());
			}

		}

		@Override public void exitPrimaryExpression(EMParser.PrimaryExpressionContext ctx) { 
			if (ctx.getChild(0).getText().equals("(")){
				StringBuilder buf = new StringBuilder();
				buf.append("("+getLus(ctx.expression()) + ")");
				setLus(ctx, buf.toString());
			}else if(ctx.ID() != null){
				setLus(ctx, ctx.ID().getText());
			}
			else{
				setLus(ctx, getLus(ctx.getChild(0)));
			}

		}

		@Override public void exitIgnore_value(EMParser.Ignore_valueContext ctx) {
			System.out.println("Ignore_value is not supported yet");
			setLus(ctx, "");
		}

		@Override public void exitConstant(EMParser.ConstantContext ctx) { 
			if (ctx.function_handle() != null){
				System.out.println("function_handle is not supported yet");
				setLus(ctx, "");
			}else if (ctx.indexing() != null){
				System.out.println("Indexing is not supported yet");
				setLus(ctx, ctx.getText());
			}else{
				setLus(ctx, ctx.getText());
			}
		}

	

		@Override public void exitCell(EMParser.CellContext ctx) { 
			System.out.println("Cell is not supported yet");
			setLus(ctx, ctx.getText());
		}

		@Override public void exitMatrix(EMParser.MatrixContext ctx) { 
			System.out.println("Matrix is not supported yet");
			setLus(ctx, ctx.getText());
		}

		@Override public void exitIf_block(EMParser.If_blockContext ctx) { 
			System.out.println("IF is not supported yet");
			setLus(ctx, ctx.getText());
		}

		
		
		@Override public void exitSwitch_block(EMParser.Switch_blockContext ctx) { 
			System.out.println("Switch is not supported yet");
			setLus(ctx, "");
		}


		@Override public void exitFor_block(EMParser.For_blockContext ctx) { 
			System.out.println("FOR is not supported yet");
			setLus(ctx, "");
		}

		@Override public void exitWhile_block(EMParser.While_blockContext ctx) { 
			System.out.println("While is not supported yet");
			setLus(ctx, "");
		}

		@Override public void exitNlosoc(EMParser.NlosocContext ctx) { 
			nlosoc(ctx, "nlosoc");
		}
		@Override public void exitNloc(EMParser.NlocContext ctx) { 
			nlosoc(ctx, "nloc");
		}
		@Override public void exitNlos(EMParser.NlosContext ctx) {
			nlosoc(ctx, "nlos");
		}
		@Override public void exitSoc(EMParser.SocContext ctx) {
			nlosoc(ctx, "soc");
		}

		@Override public void visitTerminal(TerminalNode node) { 
			setLus(node, node.getText());
		}


		public void callExpression(ParserRuleContext ctx, String methodName1, String methodName2){
			java.lang.reflect.Method method1;
			java.lang.reflect.Method method2;
			try {
				method1 = ctx.getClass().getMethod(methodName1);
				method2 = ctx.getClass().getMethod(methodName2);
				if (method1.invoke(ctx) != null){
					StringBuilder buf = new StringBuilder();

					String operator = null;
					if (methodName1.equals("unaryExpression")) operator = ctx.getChild(0).getText();
					else operator = ctx.getChild(1).getText();

					String leftExp = "";
					String rightExp = "";
					if (!methodName1.equals("unaryExpression")){
						leftExp = getLus((ParseTree) method1.invoke(ctx));
						rightExp = getLus((ParseTree) method2.invoke(ctx));
					}
					else 
						rightExp = getLus((ParseTree) method1.invoke(ctx));

					buf.append(leftExp+ " " + operator + " " + rightExp);
					setLus(ctx, buf.toString());
				}else
					setLus(ctx, getLus((ParseTree) method2.invoke(ctx)));

			} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}catch (SecurityException e) { 
				e.printStackTrace();
			}
			catch (NoSuchMethodException e) {
				e.printStackTrace();
			}
		}

		public void nlosoc(ParserRuleContext ctx, String type) { 
			setLus(ctx, ctx.getText());
		}

		public static String Quotes(String s) {
			if ( s==null || s.charAt(0)=='"' ) return s;
			return '"'+s+'"';
		}

	}

	public static void main(String[] args) throws Exception {
		String inputFile = null;
		String file_name = null;
		if ( args.length>0 ) {
			inputFile = args[0];
			file_name = args[0]+".lus";
		}else
			file_name = "output.lus";
		InputStream is = System.in;
		if ( inputFile!=null ) {
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
