/*
* generated by Xtext
*/
package com.r00lerz.ruleDef;

/**
 * Initialization support for running Xtext languages 
 * without equinox extension registry
 */
public class RuleDefStandaloneSetup extends RuleDefStandaloneSetupGenerated{

	public static void doSetup() {
		new RuleDefStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
}

