// Smart context injection using full-context command patterns
// Adapts the complexity analysis from full-context.md for dynamic context loading

export interface ContextProfile {
  name: 'minimal' | 'component' | 'focused' | 'comprehensive';
  description: string;
  expectedTokens: number;
  contextFiles: string[];
  strategy: 'direct' | 'focused' | 'multi-perspective';
  agents: [number, number]; // [min, max] agent count
}

export interface TaskAnalysis {
  complexity: 'simple' | 'focused' | 'comprehensive';
  domains: string[];
  requiresMultiComponent: boolean;
  estimatedAgents: number;
  profile: ContextProfile;
}

export class SmartContextInjector {
  private readonly baseContext = [
    '/CLAUDE.md',
    '/docs/ai-context/project-structure.md', 
    '/docs/ai-context/docs-overview.md'
  ];

  private readonly profiles: Record<string, ContextProfile> = {
    minimal: {
      name: 'minimal',
      description: 'Foundation only - for simple queries and status checks',
      expectedTokens: 5000,
      contextFiles: this.baseContext,
      strategy: 'direct',
      agents: [0, 1]
    },
    component: {
      name: 'component',
      description: 'Foundation + specific component - for focused single-domain tasks',
      expectedTokens: 12000,
      contextFiles: [...this.baseContext], // Will be extended based on component detection
      strategy: 'focused',
      agents: [2, 3]
    },
    focused: {
      name: 'focused',
      description: 'Foundation + multiple components - for cross-component analysis',
      expectedTokens: 18000,
      contextFiles: [...this.baseContext], // Will be extended based on analysis
      strategy: 'focused',
      agents: [2, 3]
    },
    comprehensive: {
      name: 'comprehensive',
      description: 'Strategic selection - for system-wide changes and complex analysis',
      expectedTokens: 25000,
      contextFiles: [...this.baseContext], // Will include strategic framework components
      strategy: 'multi-perspective',
      agents: [3, 6]
    }
  };

  private readonly componentPatterns = {
    resonance: {
      keywords: ['cycle', 'checkpoint', 'TDD', 'red-green-refactor', 'resonance', 'planning', 'implementation'],
      contextFiles: ['/cycles/CONTEXT.md']
    },
    orchestration: {
      keywords: ['agent', 'parallel', 'multi-agent', 'coordination', 'orchestration', 'command', 'strategy'],
      contextFiles: ['/docs/ai-context/system-integration.md']
    },
    contextIntelligence: {
      keywords: ['context', 'documentation', 'token', 'loading', 'tier', 'injection'],
      contextFiles: ['/docs/ai-context/docs-overview.md']
    },
    testing: {
      keywords: ['test', 'validation', 'spec', 'verify', 'jest', 'playwright'],
      contextFiles: ['/tests/CONTEXT.md']
    },
    integration: {
      keywords: ['mcp', 'server', 'integration', 'external', 'api', 'service'],
      contextFiles: ['/docs/ai-context/system-integration.md']
    }
  };

  /**
   * Analyze user request using patterns from full-context command
   * Directly adapted from full-context.md Step 1 analysis logic
   */
  analyzeTaskComplexity(userRequest: string, projectStructure?: string): TaskAnalysis {
    const request = userRequest.toLowerCase();
    const detectedComponents = this.detectRelevantComponents(request);
    
    // Apply full-context decision logic
    if (this.isSimpleQuery(request, detectedComponents)) {
      return {
        complexity: 'simple',
        domains: detectedComponents,
        requiresMultiComponent: false,
        estimatedAgents: 0,
        profile: this.profiles.minimal
      };
    }
    
    if (this.isFocusedTask(request, detectedComponents)) {
      const profile = detectedComponents.length === 1 ? 
        this.buildComponentProfile(detectedComponents[0]) : 
        this.profiles.focused;
      
      return {
        complexity: 'focused',
        domains: detectedComponents,
        requiresMultiComponent: detectedComponents.length > 1,
        estimatedAgents: detectedComponents.length <= 1 ? 2 : 3,
        profile
      };
    }
    
    // Multi-perspective comprehensive analysis
    return {
      complexity: 'comprehensive',
      domains: detectedComponents,
      requiresMultiComponent: true,
      estimatedAgents: Math.min(3 + detectedComponents.length, 6),
      profile: this.profiles.comprehensive
    };
  }

  /**
   * Detect relevant components using pattern matching
   * Simplified from theoretical NLP to proven keyword patterns
   */
  private detectRelevantComponents(request: string): string[] {
    const detected: string[] = [];
    
    for (const [component, patterns] of Object.entries(this.componentPatterns)) {
      if (patterns.keywords.some(keyword => request.includes(keyword))) {
        detected.push(component);
      }
    }
    
    return detected.length > 0 ? detected : ['general'];
  }

  /**
   * Simple query detection - adapted from full-context "Direct Approach" criteria
   */
  private isSimpleQuery(request: string, components: string[]): boolean {
    // Questions about existing patterns or status
    if (request.includes('what') || request.includes('how') || request.includes('status') || request.includes('current')) {
      return components.length <= 1;
    }
    
    // Simple documentation or information requests
    if (request.includes('show') || request.includes('list') || request.includes('explain')) {
      return true;
    }
    
    return false;
  }

  /**
   * Focused task detection - adapted from full-context "Focused Investigation" criteria
   */
  private isFocusedTask(request: string, components: string[]): boolean {
    // Deep analysis of specific area
    if (components.length <= 2 && !request.includes('system-wide') && !request.includes('across')) {
      return true;
    }
    
    // Implementation tasks that don't span multiple domains
    if ((request.includes('implement') || request.includes('create') || request.includes('add')) 
        && components.length <= 2) {
      return true;
    }
    
    return false;
  }

  /**
   * Build component-specific profile by extending base context
   */
  private buildComponentProfile(component: string): ContextProfile {
    const componentPattern = this.componentPatterns[component as keyof typeof this.componentPatterns];
    
    if (!componentPattern) {
      return this.profiles.focused;
    }
    
    return {
      name: 'component',
      description: `Foundation + ${component} component`,
      expectedTokens: 12000,
      contextFiles: [...this.baseContext, ...componentPattern.contextFiles],
      strategy: 'focused',
      agents: [2, 3]
    };
  }

  /**
   * Generate context file list based on analysis
   * Returns @ prefixed file paths for direct use in commands
   */
  generateContextFiles(analysis: TaskAnalysis): string[] {
    const contextFiles = [...analysis.profile.contextFiles];
    
    // Add component-specific context files
    for (const domain of analysis.domains) {
      const pattern = this.componentPatterns[domain as keyof typeof this.componentPatterns];
      if (pattern) {
        contextFiles.push(...pattern.contextFiles.filter(f => !contextFiles.includes(f)));
      }
    }
    
    // Return with @ prefix for command usage
    return contextFiles.map(file => `@${file}`);
  }

  /**
   * Generate agent strategy description based on full-context patterns
   */
  generateAgentStrategy(analysis: TaskAnalysis): string {
    switch (analysis.profile.strategy) {
      case 'direct':
        return "Direct approach: Handle efficiently with targeted documentation reading and direct analysis";
      
      case 'focused':
        return `Focused investigation (${analysis.estimatedAgents} agents): Deep analysis of ${analysis.domains.join(', ')} with thorough exploration`;
      
      case 'multi-perspective':
        return `Multi-perspective analysis (${analysis.estimatedAgents} agents): Comprehensive understanding across ${analysis.domains.join(', ')} with dependency mapping`;
      
      default:
        return "Standard investigation approach";
    }
  }

  /**
   * Create command template using full-context patterns
   */
  generateOptimizedCommand(userRequest: string, analysis: TaskAnalysis): string {
    const contextFiles = this.generateContextFiles(analysis);
    const agentStrategy = this.generateAgentStrategy(analysis);
    
    return `
## Smart Context Analysis for: ${userRequest}

**Detected Complexity:** ${analysis.complexity}
**Framework Components:** ${analysis.domains.join(', ')}
**Strategy:** ${agentStrategy}
**Expected Tokens:** ~${analysis.profile.expectedTokens}

## Auto-Loaded Context (${analysis.profile.name} profile):
${contextFiles.join('\n')}

## Implementation Approach:
${this.generateImplementationGuidance(analysis)}

Now proceed with the user request using this optimized context loading.
`;
  }

  private generateImplementationGuidance(analysis: TaskAnalysis): string {
    switch (analysis.complexity) {
      case 'simple':
        return "Use direct analysis with loaded documentation. No sub-agents needed.";
      
      case 'focused':
        return `Launch ${analysis.estimatedAgents} focused agents for deep component analysis. Use parallel execution for efficiency.`;
      
      case 'comprehensive':
        return `Deploy ${analysis.estimatedAgents} agents with multi-perspective analysis. Ensure dependency mapping and impact assessment across all affected components.`;
      
      default:
        return "Use standard investigation approach";
    }
  }
}

// Factory function for easy integration
export function createSmartContextInjector(): SmartContextInjector {
  return new SmartContextInjector();
}

// Usage example:
export function optimizeContextForRequest(userRequest: string): {
  analysis: TaskAnalysis;
  contextFiles: string[];
  commandTemplate: string;
} {
  const injector = createSmartContextInjector();
  const analysis = injector.analyzeTaskComplexity(userRequest);
  const contextFiles = injector.generateContextFiles(analysis);
  const commandTemplate = injector.generateOptimizedCommand(userRequest, analysis);
  
  return {
    analysis,
    contextFiles,
    commandTemplate
  };
}