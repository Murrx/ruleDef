package com.r00lerz.ruleDef.generator

import com.r00lerz.ruleDef.ruleDef.BiggerSmallerOperator
import com.r00lerz.ruleDef.ruleDef.BusinessRule
import com.r00lerz.ruleDef.ruleDef.CompareOperator
import com.r00lerz.ruleDef.ruleDef.DynamicValue
import com.r00lerz.ruleDef.ruleDef.EqualsOperator
import com.r00lerz.ruleDef.ruleDef.ListOperator
import com.r00lerz.ruleDef.ruleDef.NumericValue
import com.r00lerz.ruleDef.ruleDef.RegexOperator
import com.r00lerz.ruleDef.ruleDef.RuleSet
import com.r00lerz.ruleDef.ruleDef.RuleSetData
import com.r00lerz.ruleDef.ruleDef.SpecialCompareOperator
import com.r00lerz.ruleDef.ruleDef.StaticValue
import com.r00lerz.ruleDef.ruleDef.StringValue
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import com.r00lerz.ruleDef.ruleDef.Value

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class RuleDefGenerator implements IGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		for (e : resource.allContents.toIterable.filter(typeof(RuleSet))) {
			fsa.generateFile("generatedcode.sql", compile(e, e.ruleSetData));
			if (e.ruleSetData == null) {
				fsa.generateFile("ruletype.txt", e.ruleset.get(0).generateRuleType);
			}
		}
	}

	def compile(RuleSet r, RuleSetData rsd) {
		'''
			«IF rsd != null»«generateHeader(rsd)»«ENDIF»
				«FOR BusinessRule rule : r.ruleset»
					«rule.generateRuleBlock»
				«ENDFOR»
			«IF rsd != null»«generateFooter(rsd)»«ENDIF»
		'''
	}

	def generateHeader(RuleSetData rsd) {
		'''
    		CREATE OR REPLACE TRIGGER «rsd.resultSetName»
    			BEFORE DELETE OR INSERT OR UPDATE
    			ON "«rsd.entityName»"
    			FOR EACH ROW
    		DECLARE
    			l_oper			varchar2(3);
    			l_error_stack	varchar2(4000);
    		BEGIN
    			IF INSERTING THEN
    				l_oper :='INS';
    			ELSIF UPDATING THEN
    				l_oper :='UPD';
    			ELSIF DELETING THEN
    				l_oper :='DEL';
    			END IF;
    		
    	'''
	}

	def generateFooter(RuleSetData rsd) {
		'''
    			IF l_error_stack IS NOT NULL THEN
    				raise_application_error(-20800, l_error_stack);
    			END IF;
    		END «rsd.resultSetName»;
    	'''
	}

	def generateRuleBlock(BusinessRule r) {
		'''
			«IF r.name != null»--Evaluates: «r.name»«ENDIF»
			DECLARE
				l_passed boolean := true;
			BEGIN
				IF l_oper in ('INS', 'UPD')THEN
					l_passed := «r.lhs_value.printValue» «r.operator.operatorToString» «r.rhs_value.printValue»«IF r.rhs_value2 != null» AND «r.rhs_value2.printValue»«ENDIF»;
					IF NOT l_passed THEN
						l_error_stack := l_error_stack || '«r.lhs_value.valueToString» «r.operator.name» «r.rhs_value.valueToString»«IF r.rhs_value2 != null» and «r.rhs_value2.valueToString»«ENDIF».';
					END IF;
				END IF;
			END;
		'''
	}
	
	def printValue(Value value){
		if (value instanceof StringValue){
			value.quoteValue
		}else if (value instanceof DynamicValue){
			":new."+value.attribute.name
		}else{
			value.valueToString
		}
	}

	def quoteValue(Value value){
		"'" + value.valueToString + "'"
	}
	
	def dispatch valueToString(DynamicValue dynamicValue) {
		dynamicValue.entity.name + "." + dynamicValue.attribute.name
	}

	def dispatch valueToString(NumericValue numericValue) {
		numericValue.name
	}
	def dispatch valueToString(StringValue stringValue) {
		stringValue.name
	}

	def dispatch operatorToString(BiggerSmallerOperator operator) {
		switch operator {
			case operator.name == "must be bigger than": ">"
			case operator.name == "must be smaller than": "<"
			case operator.name == "must be smaller or equal to": "<="
			case operator.name == "must be bigger or equal to": ">="
		}
	}

	def dispatch operatorToString(EqualsOperator operator) {
		switch operator {
			case operator.name == "must be equal to": "="
			case operator.name == "may not be equal to": "!="
		}
	}

	def dispatch operatorToString(SpecialCompareOperator operator) {
		switch operator {
			case operator.name == "must be between": "BETWEEN"
			case operator.name == "may not be between": "NOT BETWEEN"
		}
	}

	def dispatch operatorToString(ListOperator operator) {
		//TODO implement
	}

	def dispatch operatorToString(RegexOperator operator) {
		//TODO implement
	}

	def generateRuleType(BusinessRule r) {
		switch r {
			case r.attributeRangeRule: "Attribute Range Rule"
			case r.attributeCompareRule: "Attribute Compare Rule"
			case r.tupleCompareRule: "Tuple Compare Rule"
			default: "ERROR"
		}
	}
	def isAttributeRangeRule(BusinessRule r) {
		r.operator instanceof SpecialCompareOperator
	}

	def isAttributeCompareRule(BusinessRule r) {
		r.rhs_value instanceof StaticValue && r.operator instanceof CompareOperator

	}

	def isTupleCompareRule(BusinessRule r) {
		r.rhs_value instanceof DynamicValue && r.lhs_value.entity.name == (r.rhs_value as DynamicValue).entity.name &&
			r.operator instanceof CompareOperator
	}
}
