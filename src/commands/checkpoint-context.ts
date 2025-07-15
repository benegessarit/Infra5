// Context preservation for Resonance TDD cycle commands
// Tracks 3-tier documentation loaded during planning phase

interface DocEntry {
  path: string;
  checksum: string;
  lastModified: string;
  content?: string | null;
}

interface ContextMetadata {
  capturedAt: string;
  autoLoadedDocs: {
    tier1: DocEntry[];
    tier2: DocEntry[];
    tier3: DocEntry[];
  };
  commandContext: {
    command: string;
    args?: string;
    workingDirectory?: string;
  };
  documentationSystem: {
    version: string;
    autoLoadEnabled: boolean;
  };
}

interface CheckpointWithContext {
  projectMeta?: any;
  contextMetadata?: ContextMetadata;
  contextResets?: number;
  currentContext?: any;
  [key: string]: any;
}

interface DocInput {
  path: string;
  tier: 1 | 2 | 3;
}

interface ChangeDetectionResult {
  changed: Array<{
    path: string;
    oldChecksum: string;
    newChecksum: string;
  }>;
  missing: string[];
  total: number;
}

interface LoadResult {
  loaded: DocEntry[];
  warnings: string[];
  missing: string[];
}

// Proper checksum calculation using Node.js built-in crypto
import { createHash } from 'crypto';

function calculateChecksum(content: string): string {
  if (content.length === 0) return 'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'; // Empty string SHA256
  
  const hash = createHash('sha256');
  hash.update(content, 'utf8');
  return `sha256:${hash.digest('hex')}`;
}

export async function saveCheckpointWithContext(
  checkpoint: CheckpointWithContext,
  docsLoaded: DocInput[],
  readTool: any
): Promise<CheckpointWithContext> {
  const contextMetadata: ContextMetadata = {
    capturedAt: new Date().toISOString(),
    autoLoadedDocs: {
      tier1: [],
      tier2: [],
      tier3: []
    },
    commandContext: {
      command: checkpoint.contextMetadata?.commandContext?.command || 'unknown',
      workingDirectory: process.cwd()
    },
    documentationSystem: {
      version: '3-tier',
      autoLoadEnabled: true
    }
  };

  // Process each loaded document
  const errors: string[] = [];
  
  for (const doc of docsLoaded) {
    try {
      const result = await readTool({ file_path: doc.path });
      const content = typeof result === 'string' ? result : result.content || '';
      
      const docEntry: DocEntry = {
        path: doc.path,
        checksum: calculateChecksum(content),
        lastModified: new Date().toISOString(),
        content: null // Don't store content to keep checkpoint size manageable
      };

      const tierKey = `tier${doc.tier}` as keyof typeof contextMetadata.autoLoadedDocs;
      contextMetadata.autoLoadedDocs[tierKey].push(docEntry);
    } catch (error) {
      const errorMsg = `Failed to load critical document ${doc.path}: ${error instanceof Error ? error.message : String(error)}`;
      errors.push(errorMsg);
    }
  }
  
  // Fail fast if any critical documents couldn't be loaded
  if (errors.length > 0) {
    throw new Error(`Context preservation failed - unable to load ${errors.length} documents:\n${errors.join('\n')}`);
  }

  return {
    ...checkpoint,
    contextMetadata
  };
}

export async function loadCheckpointAndRestoreContext(
  checkpoint: CheckpointWithContext,
  readTool: any,
  options: { gracefulMissing?: boolean } = {}
): Promise<LoadResult> {
  const result: LoadResult = {
    loaded: [],
    warnings: [],
    missing: []
  };

  if (!checkpoint.contextMetadata) {
    result.warnings.push('No context metadata found in checkpoint (backward compatibility)');
    return result;
  }

  const allDocs = [
    ...checkpoint.contextMetadata.autoLoadedDocs.tier1,
    ...checkpoint.contextMetadata.autoLoadedDocs.tier2,
    ...checkpoint.contextMetadata.autoLoadedDocs.tier3
  ];

  for (const doc of allDocs) {
    try {
      await readTool({ file_path: doc.path });
      result.loaded.push(doc);
    } catch (error) {
      if (options.gracefulMissing) {
        result.warnings.push(`Missing file: ${doc.path}`);
        result.missing.push(doc.path);
      } else {
        throw error;
      }
    }
  }

  return result;
}

export async function detectDocumentationChanges(
  checkpoint: CheckpointWithContext,
  filesystem: Map<string, { content: string; lastModified: string }>
): Promise<ChangeDetectionResult> {
  const result: ChangeDetectionResult = {
    changed: [],
    missing: [],
    total: 0
  };

  if (!checkpoint.contextMetadata) {
    return result;
  }

  const allDocs = [
    ...checkpoint.contextMetadata.autoLoadedDocs.tier1,
    ...checkpoint.contextMetadata.autoLoadedDocs.tier2,
    ...checkpoint.contextMetadata.autoLoadedDocs.tier3
  ];

  for (const doc of allDocs) {
    result.total++;
    
    const currentFile = filesystem.get(doc.path);
    if (!currentFile) {
      result.missing.push(doc.path);
      continue;
    }

    const currentChecksum = calculateChecksum(currentFile.content);
    if (currentChecksum !== doc.checksum) {
      result.changed.push({
        path: doc.path,
        oldChecksum: doc.checksum,
        newChecksum: currentChecksum
      });
    }
  }

  return result;
}

export async function promptForContextRefresh(
  changes: ChangeDetectionResult,
  promptFn: (message: string) => Promise<boolean>
): Promise<boolean> {
  if (changes.changed.length === 0 && changes.missing.length === 0) {
    return false;
  }

  let message = 'Documentation has changed since checkpoint was created:\n';
  
  if (changes.changed.length > 0) {
    message += `\nChanged files:\n${changes.changed.map(c => `  - ${c.path}`).join('\n')}`;
  }
  
  if (changes.missing.length > 0) {
    message += `\nMissing files:\n${changes.missing.map(f => `  - ${f}`).join('\n')}`;
  }
  
  message += '\n\nWould you like to refresh the context with current documentation?';
  
  return await promptFn(message);
}

export async function refreshContextInCheckpoint(
  checkpoint: CheckpointWithContext,
  shouldRefresh: boolean,
  readTool: any
): Promise<CheckpointWithContext> {
  if (!shouldRefresh || !checkpoint.contextMetadata) {
    return checkpoint;
  }

  const allDocs = [
    ...checkpoint.contextMetadata.autoLoadedDocs.tier1.map(d => ({ ...d, tier: 1 as const })),
    ...checkpoint.contextMetadata.autoLoadedDocs.tier2.map(d => ({ ...d, tier: 2 as const })),
    ...checkpoint.contextMetadata.autoLoadedDocs.tier3.map(d => ({ ...d, tier: 3 as const }))
  ];

  const docsToRefresh = allDocs.map(d => ({ path: d.path, tier: d.tier }));
  
  return await saveCheckpointWithContext(checkpoint, docsToRefresh, readTool);
}

export async function generateCycleLogReport(checkpoint: CheckpointWithContext): Promise<string> {
  let report = '# Cycle Execution Report\n\n';
  
  if (checkpoint.contextMetadata) {
    report += '## Documentation Context Loaded\n\n';
    
    const { tier1, tier2, tier3 } = checkpoint.contextMetadata.autoLoadedDocs;
    
    if (tier1.length > 0) {
      report += '### Tier 1 (Foundational):\n';
      tier1.forEach(doc => {
        report += `- ${doc.path}\n`;
      });
      report += '\n';
    }
    
    if (tier2.length > 0) {
      report += '### Tier 2 (Component):\n';
      tier2.forEach(doc => {
        report += `- ${doc.path}\n`;
      });
      report += '\n';
    }
    
    if (tier3.length > 0) {
      report += '### Tier 3 (Feature):\n';
      tier3.forEach(doc => {
        report += `- ${doc.path}\n`;
      });
      report += '\n';
    }

    report += `Context captured at: ${checkpoint.contextMetadata.capturedAt}\n`;
    report += `Command: ${checkpoint.contextMetadata.commandContext.command}\n\n`;
  }
  
  return report;
}

export class CommandHandler {
  private command: string;
  private loadedContext: any = null;
  private capturedDocs: DocInput[] = [];

  constructor(command: string) {
    this.command = command;
  }

  async captureContext(docPaths: string[]): Promise<void> {
    // Classify documents by tier based on path patterns
    this.capturedDocs = docPaths.map(path => {
      if (path.includes('CLAUDE.md') || path.includes('project-structure') || path.includes('docs-overview')) {
        return { path, tier: 1 as const };
      } else if (path.includes('CONTEXT.md')) {
        return { path, tier: 2 as const };
      } else {
        return { path, tier: 3 as const };
      }
    });
  }

  async saveCheckpoint(): Promise<CheckpointWithContext> {
    const mockReadTool = async ({ file_path }: { file_path: string }) => {
      return `Mock content for ${file_path}`;
    };

    return await saveCheckpointWithContext({
      projectMeta: { planRef: 'test-plan.md' },
      contextMetadata: {
        capturedAt: new Date().toISOString(),
        autoLoadedDocs: { tier1: [], tier2: [], tier3: [] },
        commandContext: { command: this.command },
        documentationSystem: { version: '3-tier', autoLoadEnabled: true }
      }
    }, this.capturedDocs, mockReadTool);
  }

  async loadCheckpoint(checkpoint: CheckpointWithContext): Promise<void> {
    const mockReadTool = async ({ file_path }: { file_path: string }) => {
      return `Mock content for ${file_path}`;
    };

    const result = await loadCheckpointAndRestoreContext(checkpoint, mockReadTool);
    this.loadedContext = checkpoint.contextMetadata?.autoLoadedDocs;
  }

  getLoadedContext(): any {
    return this.loadedContext;
  }
}

export {
  DocEntry,
  ContextMetadata,
  CheckpointWithContext,
  DocInput,
  ChangeDetectionResult,
  LoadResult
};