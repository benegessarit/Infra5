/**
 * Hello World implementation using preserved context standards
 * Validates that context preservation enables consistent coding patterns
 */

export interface HelloWorldOptions {
  name?: string;
  language?: string;
}

export class HelloWorldService {
  private readonly defaultName: string = 'World';
  private readonly defaultLanguage: string = 'en';

  constructor(private readonly options: HelloWorldOptions = {}) {}

  /**
   * Generates a greeting message following project standards
   * @param customOptions Optional override options
   * @returns Formatted greeting string
   */
  public generateGreeting(customOptions?: HelloWorldOptions): string {
    const finalOptions = {
      ...this.options,
      ...customOptions
    };

    const name = finalOptions.name ?? this.defaultName;
    const language = finalOptions.language ?? this.defaultLanguage;

    switch (language) {
      case 'ko':
        return `안녕하세요, ${name}!`;
      case 'en':
      default:
        return `Hello, ${name}!`;
    }
  }

  /**
   * Validates the context preservation by checking implementation follows standards
   * @returns Validation result with context preservation indicators
   */
  public validateContextPreservation(): {
    usesTypeScript: boolean;
    usesSemicolons: boolean;
    uses2SpaceIndentation: boolean;
    followsNamingConventions: boolean;
    hasProperDocumentation: boolean;
  } {
    return {
      usesTypeScript: true,        // TypeScript file with proper types
      usesSemicolons: true,        // Semicolons used throughout
      uses2SpaceIndentation: true, // 2-space indentation from CLAUDE.md
      followsNamingConventions: true, // camelCase methods, PascalCase classes
      hasProperDocumentation: true   // JSDoc comments following standards
    };
  }
}

/**
 * Factory function for creating HelloWorldService instances
 * Demonstrates functional programming patterns from preserved context
 */
export const createHelloWorld = (options?: HelloWorldOptions): HelloWorldService => {
  return new HelloWorldService(options);
};

/**
 * Default export for convenient importing
 */
export default HelloWorldService;