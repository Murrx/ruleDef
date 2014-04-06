package com.r00lerz.ruleDef;

import java.util.List;

import org.eclipse.xtext.validation.Issue;

@SuppressWarnings("serial")
public class RuleDefException extends Exception{
	
	private List<Issue> issues;
	
	public RuleDefException() {
	}
	
	public RuleDefException(List<Issue> issues) {
		this.issues = issues;
	}
	
	public List<Issue> getIssues(){
		return issues;
	}

}
