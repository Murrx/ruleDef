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

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class RuleDefGenerator implements IGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {

		for(e: resource.allContents.toIterable.filter(BusinessRule)) {
			fsa.generateFile(
			"generatedcode.sql",
			e.compile)		
		}
	}
	
	def compile(BusinessRule r){ '''
    	-evaluates business rule «r.generateName»
    	DECLARE
    		l_passed boolean := true;
    	BEGIN
    		IF l_oper in ('INS', 'UPD')THEN --shoulde be replaced with dynamic code later.
    			l_passed := :new.«r.lhs_value.attribute.name» «r.operator.operatorToString» «r.rhs_value.valueToString»«IF r.rhs_value2 !=null» AND «r.rhs_value2.valueToString»«ENDIF»;
    			IF NOT l_passed THEN
    				l_error_stack := l_error_stack || '«r.lhs_value.valueToString» «r.operator.name» «r.rhs_value.valueToString»«IF r.rhs_value2 !=null» and «r.rhs_value2.valueToString»«ENDIF».';
    			END IF;
    		END IF;
    	END;
    '''
    }
    
    def dispatch valueToString(DynamicValue dynamicValue){
    	dynamicValue.entity.name + "." + dynamicValue.attribute.name
    }
    
    def dispatch valueToString(StaticValue staticValue){
    	staticValue.name
    }
    
    def dispatch operatorToString(BiggerSmallerOperator operator){
    	switch operator{
    		case operator.name == "must be bigger than" : ">"
    		case operator.name == "must be smaller than" : "<"
    		case operator.name == "must be smaller or equal to" : "<="
    		case operator.name == "must be bigger or equal to" : ">="
    	}
    }
    def dispatch operatorToString(EqualsOperator operator){
    	switch operator{
    		case operator.name == "must be equal to" : "="
    		case operator.name == "may not be equal to" : "!="
    	}
    }
    def dispatch operatorToString(SpecialCompareOperator operator){
    	switch operator{
    		case operator.name == "must be between" : "BETWEEN"
    		case operator.name == "may not be between" : "NOT BETWEEN"
    	}
    }
    def dispatch operatorToString(ListOperator operator){
    	//TODO implement
    }
    def dispatch operatorToString(RegexOperator operator){
    	//TODO implement
    }
    
    def generateName(BusinessRule r){
    	"BRG_APPNAME_"+r.lhs_value.entity.name.substring(0,3).toUpperCase+"_TRG_" +
    	switch r{
    		case r.attributeRangeRule : "ARR"
    		case r.attributeCompareRule : "ACR"
    		case r.tupleCompareRule : "TCR"
    		default : "ERROR"
    	} +
    	"_01"
    	/*TODO:
    	//DYNAMIC APP NAME
    	//Entity abbreviation
    	//Implement rule type retrieval for other rule types
    	//dynamic numbering*/
    }
    
    def isAttributeRangeRule(BusinessRule r){
    	r.operator instanceof SpecialCompareOperator
    }
    def isAttributeCompareRule(BusinessRule r){
    	r.rhs_value instanceof StaticValue &&
    	r.operator instanceof CompareOperator

    }
    def isTupleCompareRule(BusinessRule r){
    	r.rhs_value instanceof DynamicValue &&
    	r.lhs_value.entity.name == (r.rhs_value as DynamicValue).entity.name &&
    	r.operator instanceof CompareOperator
    }
}