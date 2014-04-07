package com.r00lerz.ruleDef.generator

import com.r00lerz.ruleDef.ruleDef.BiggerSmallerOperator
import com.r00lerz.ruleDef.ruleDef.BusinessRule
import com.r00lerz.ruleDef.ruleDef.CompareOperator
import com.r00lerz.ruleDef.ruleDef.DynamicValue
import com.r00lerz.ruleDef.ruleDef.EqualsOperator
import com.r00lerz.ruleDef.ruleDef.ListOperator
import com.r00lerz.ruleDef.ruleDef.RegexOperator
import com.r00lerz.ruleDef.ruleDef.SpecialCompareOperator
import com.r00lerz.ruleDef.ruleDef.StaticValue
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import com.r00lerz.ruleDef.ruleDef.RuleSet
import com.r00lerz.ruleDef.ruleDef.Command
import org.eclipse.emf.common.util.EList

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class RuleDefGenerator implements IGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		for (e : resource.allContents.toIterable.filter(typeof(RuleSet))) {
			fsa.generateFile("generatedcode.sql", compile(e, checkCommands("<trigger>", e.commands)));
			if (!checkCommands("<trigger>", e.commands)) {
				fsa.generateFile("ruletype.txt", e.ruleset.get(0).generateRuleType);
			}
		}
	}

	def compile(RuleSet r, boolean generateTrigger) {
		'''
			«IF generateTrigger»«generateHeader»«ENDIF»
				«FOR BusinessRule rule : r.ruleset»
					«rule.generateRuleBlock»
				«ENDFOR»
			«IF generateTrigger»«generateFooter»«ENDIF»
		'''
	}

	def generateHeader() {
		'''
    		CREATE OR REPLACE TRIGGER <triggernamehere>
    			BEFORE DELETE OR INSERT OR UPDATE
    			ON <tablenamehere>
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

	def generateFooter() {
		'''
    			IF l_error_stack IS NOT NULL THEN
    				raise_application_error(-20800, l_error_stack);
    			END IF
    		END <triggernamehere>
    	'''
	}

	def generateRuleBlock(BusinessRule r) {
		'''
			«IF r.name != null»--Evaluates: «r.name.name»«ENDIF»
			DECLARE
				l_passed boolean := true;
			BEGIN
				IF l_oper in ('INS', 'UPD')THEN --shoulde be replaced with dynamic code later.
					l_passed := :new.«r.lhs_value.attribute.name» «r.operator.operatorToString» «r.rhs_value.valueToString»«IF r.
				rhs_value2 != null» AND «r.rhs_value2.valueToString»«ENDIF»;
					IF NOT l_passed THEN
						l_error_stack := l_error_stack || '«r.lhs_value.valueToString» «r.operator.name» «r.rhs_value.valueToString»«IF r.
				rhs_value2 != null» and «r.rhs_value2.valueToString»«ENDIF».';
					END IF;
				END IF;
			END;
		'''
	}

	def dispatch valueToString(DynamicValue dynamicValue) {
		dynamicValue.entity.name + "." + dynamicValue.attribute.name
	}

	def dispatch valueToString(StaticValue staticValue) {
		staticValue.name
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

	def checkCommands(String command, EList<Command> commands) {
		for (Command c : commands) {
			if (c.name == command) {
				return true
			}
		}
		return false
	}
}
