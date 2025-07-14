import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { 
  CheckpointWithContext, 
  ContextMetadata, 
  DocEntry, 
  saveCheckpointWithContext,
  loadCheckpointAndRestoreContext,
  detectDocumentationChanges,
  CommandHandler
} from '../src/commands/checkpoint-context';

describe('Context preservation between cycle-plan and cycle-start', () => {
  let mockReadTool: jest.MockedFunction<any>;
  let mockFilesystem: Map<string, { content: string; lastModified: string }>;

  beforeEach(() => {
    mockReadTool = jest.fn();
    mockFilesystem = new Map();
    jest.clearAllMocks();
  });

  describe('Basic Context Preservation', () => {
    it('should save loaded documentation metadata in checkpoint during cycle-plan', async () => {
      // Given: cycle-plan loads 3-tier documentation
      const docsLoaded = [
        { path: '/CLAUDE.md', tier: 1 as const },
        { path: '/docs/ai-context/project-structure.md', tier: 1 as const },
        { path: '/cycles/CONTEXT.md', tier: 2 as const }
      ];

      const checkpoint: CheckpointWithContext = {
        projectMeta: {
          planRef: 'cycles/2025-07-13/test-plan.md',
          expectedPhases: ['RED', 'GREEN', 'REFACTOR']
        },
        contextMetadata: {
          capturedAt: new Date().toISOString(),
          autoLoadedDocs: {
            tier1: [],
            tier2: [],
            tier3: []
          },
          commandContext: {
            command: 'cycle-plan',
            workingDirectory: '/Users/test/project'
          },
          documentationSystem: {
            version: '3-tier',
            autoLoadEnabled: true
          }
        }
      };

      // When: checkpoint is created with context
      const result = await saveCheckpointWithContext(checkpoint, docsLoaded, mockReadTool);

      // Then: checkpoint includes contextMetadata with file paths and checksums
      expect(result.contextMetadata.autoLoadedDocs.tier1).toHaveLength(2);
      expect(result.contextMetadata.autoLoadedDocs.tier2).toHaveLength(1);
      expect(result.contextMetadata.autoLoadedDocs.tier1[0]).toMatchObject({
        path: '/CLAUDE.md',
        checksum: expect.stringMatching(/^sha256:[a-f0-9]+$/),
        lastModified: expect.any(String)
      });
    });

    it('should reload exact same documentation context in cycle-start', async () => {
      // Given: checkpoint with contextMetadata from cycle-plan
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          capturedAt: '2025-07-13T10:30:00Z',
          autoLoadedDocs: {
            tier1: [
              {
                path: '/CLAUDE.md',
                checksum: 'sha256:abc123',
                lastModified: '2025-07-13T09:00:00Z',
                content: null
              }
            ],
            tier2: [
              {
                path: '/cycles/CONTEXT.md',
                checksum: 'sha256:def456',
                lastModified: '2025-07-13T09:30:00Z',
                content: null
              }
            ],
            tier3: []
          },
          commandContext: {
            command: 'cycle-plan',
            workingDirectory: '/Users/test/project'
          },
          documentationSystem: {
            version: '3-tier',
            autoLoadEnabled: true
          }
        }
      };

      // When: cycle-start reads checkpoint
      const loadedDocs = await loadCheckpointAndRestoreContext(checkpoint, mockReadTool);

      // Then: same documentation files are loaded in same order
      expect(mockReadTool).toHaveBeenCalledTimes(2);
      expect(mockReadTool).toHaveBeenCalledWith({ file_path: '/CLAUDE.md' });
      expect(mockReadTool).toHaveBeenCalledWith({ file_path: '/cycles/CONTEXT.md' });
      expect(loadedDocs).toHaveLength(2);
    });
  });

  describe('Context metadata format', () => {
    it('should track tier-1 foundational docs', () => {
      const metadata: ContextMetadata = {
        capturedAt: new Date().toISOString(),
        autoLoadedDocs: {
          tier1: [
            { path: '/CLAUDE.md', checksum: 'sha256:123', lastModified: '2025-07-13T09:00:00Z' },
            { path: '/docs/ai-context/project-structure.md', checksum: 'sha256:456', lastModified: '2025-07-13T09:00:00Z' },
            { path: '/docs/ai-context/docs-overview.md', checksum: 'sha256:789', lastModified: '2025-07-13T09:00:00Z' }
          ],
          tier2: [],
          tier3: []
        },
        commandContext: { command: 'cycle-plan' },
        documentationSystem: { version: '3-tier', autoLoadEnabled: true }
      };

      // Verify CLAUDE.md, project-structure.md, docs-overview.md tracked
      const tier1Paths = metadata.autoLoadedDocs.tier1.map(doc => doc.path);
      expect(tier1Paths).toContain('/CLAUDE.md');
      expect(tier1Paths).toContain('/docs/ai-context/project-structure.md');
      expect(tier1Paths).toContain('/docs/ai-context/docs-overview.md');
    });

    it('should track tier-2 component docs loaded during planning', () => {
      const metadata: ContextMetadata = {
        capturedAt: new Date().toISOString(),
        autoLoadedDocs: {
          tier1: [],
          tier2: [
            { path: '/cycles/CONTEXT.md', checksum: 'sha256:abc', lastModified: '2025-07-13T10:00:00Z' },
            { path: '/tests/CONTEXT.md', checksum: 'sha256:def', lastModified: '2025-07-13T10:00:00Z' }
          ],
          tier3: []
        },
        commandContext: { command: 'cycle-plan' },
        documentationSystem: { version: '3-tier', autoLoadEnabled: true }
      };

      // Verify component CONTEXT.md files tracked when accessed
      expect(metadata.autoLoadedDocs.tier2).toHaveLength(2);
      expect(metadata.autoLoadedDocs.tier2[0].path).toMatch(/CONTEXT\.md$/);
    });

    it('should track tier-3 feature-specific docs', () => {
      const metadata: ContextMetadata = {
        capturedAt: new Date().toISOString(),
        autoLoadedDocs: {
          tier1: [],
          tier2: [],
          tier3: [
            { path: '/docs/CONTEXT-tier3-feature.md', checksum: 'sha256:xyz', lastModified: '2025-07-13T11:00:00Z' }
          ]
        },
        commandContext: { command: 'cycle-plan' },
        documentationSystem: { version: '3-tier', autoLoadEnabled: true }
      };

      // Verify feature-level CONTEXT.md files tracked
      expect(metadata.autoLoadedDocs.tier3).toHaveLength(1);
      expect(metadata.autoLoadedDocs.tier3[0].path).toContain('tier3');
    });

    it('should include file metadata for change detection', () => {
      const docEntry: DocEntry = {
        path: '/CLAUDE.md',
        checksum: 'sha256:abcdef123456',
        lastModified: '2025-07-13T09:00:00Z',
        content: null
      };

      // Each file entry includes: path, checksum, lastModified, tier
      expect(docEntry).toHaveProperty('path');
      expect(docEntry).toHaveProperty('checksum');
      expect(docEntry).toHaveProperty('lastModified');
      expect(docEntry.checksum).toMatch(/^sha256:[a-f0-9]+$/);
    });
  });

  describe('Context refresh for changed documentation', () => {
    it('should detect when documentation has changed since checkpoint', async () => {
      // Given: checkpoint with old doc timestamps
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          capturedAt: '2025-07-13T10:00:00Z',
          autoLoadedDocs: {
            tier1: [{
              path: '/CLAUDE.md',
              checksum: 'sha256:oldchecksum',
              lastModified: '2025-07-13T09:00:00Z'
            }],
            tier2: [],
            tier3: []
          },
          commandContext: { command: 'cycle-plan' },
          documentationSystem: { version: '3-tier', autoLoadEnabled: true }
        }
      };

      // Mock current file state with newer content
      mockFilesystem.set('/CLAUDE.md', {
        content: 'new content',
        lastModified: '2025-07-13T12:00:00Z'
      });

      // When: cycle-start checks current docs
      const changes = await detectDocumentationChanges(checkpoint, mockFilesystem);

      // Then: identifies changed files
      expect(changes.changed).toHaveLength(1);
      expect(changes.changed[0]).toMatchObject({
        path: '/CLAUDE.md',
        oldChecksum: 'sha256:oldchecksum',
        newChecksum: expect.stringMatching(/^sha256:[a-f0-9]+$/)
      });
    });

    it('should prompt user about documentation changes', async () => {
      const mockPrompt = jest.fn().mockResolvedValue(true);
      const changes = {
        changed: [{ path: '/CLAUDE.md', oldChecksum: 'old', newChecksum: 'new' }],
        missing: [],
        total: 1
      };

      // When: docs have changed
      const shouldRefresh = await promptForContextRefresh(changes, mockPrompt);

      // Then: shows which docs changed and asks to refresh
      expect(mockPrompt).toHaveBeenCalledWith(
        expect.stringContaining('Documentation has changed')
      );
      expect(mockPrompt).toHaveBeenCalledWith(
        expect.stringContaining('/CLAUDE.md')
      );
      expect(shouldRefresh).toBe(true);
    });

    it('should preserve checkpoint but load fresh docs when requested', async () => {
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          autoLoadedDocs: {
            tier1: [{ path: '/CLAUDE.md', checksum: 'old', lastModified: '2025-07-13T09:00:00Z' }],
            tier2: [],
            tier3: []
          }
        },
        // Other checkpoint data preserved
        currentContext: { whatImDoing: 'existing work' }
      };

      // When: user chooses to refresh
      const refreshedCheckpoint = await refreshContextInCheckpoint(checkpoint, true, mockReadTool);

      // Then: loads new docs but keeps checkpoint data intact
      expect(refreshedCheckpoint.currentContext.whatImDoing).toBe('existing work');
      expect(mockReadTool).toHaveBeenCalledWith({ file_path: '/CLAUDE.md' });
      expect(refreshedCheckpoint.contextMetadata.autoLoadedDocs.tier1[0].checksum).not.toBe('old');
    });
  });

  describe('Context preservation through resets', () => {
    it('should maintain context metadata through multiple context resets', async () => {
      // Given: contextResets > 0 in checkpoint
      const checkpoint: CheckpointWithContext = {
        contextResets: 3,
        contextMetadata: {
          capturedAt: '2025-07-13T10:00:00Z',
          autoLoadedDocs: {
            tier1: [{ path: '/CLAUDE.md', checksum: 'sha256:abc', lastModified: '2025-07-13T09:00:00Z' }],
            tier2: [],
            tier3: []
          }
        }
      };

      // When: recovering from reset
      const loadedDocs = await loadCheckpointAndRestoreContext(checkpoint, mockReadTool);

      // Then: context metadata still available and docs reloaded
      expect(checkpoint.contextMetadata).toBeDefined();
      expect(mockReadTool).toHaveBeenCalledWith({ file_path: '/CLAUDE.md' });
      expect(loadedDocs).toHaveLength(1);
    });

    it('should handle missing documentation files gracefully', async () => {
      // Given: doc file deleted after checkpoint
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          autoLoadedDocs: {
            tier1: [{ path: '/CLAUDE.md', checksum: 'sha256:abc', lastModified: '2025-07-13T09:00:00Z' }],
            tier2: [],
            tier3: []
          }
        }
      };

      mockReadTool.mockRejectedValue(new Error('File not found'));

      // When: attempting to reload
      const result = await loadCheckpointAndRestoreContext(checkpoint, mockReadTool, { gracefulMissing: true });

      // Then: warns user and continues with available docs
      expect(result.warnings).toContain('Missing file: /CLAUDE.md');
      expect(result.loaded).toHaveLength(0);
      expect(result.missing).toHaveLength(1);
    });
  });

  describe('Context flow across all cycle commands', () => {
    it('should preserve context from cycle-plan through cycle-check', async () => {
      // Simulate flow: plan → start → check
      const planHandler = new CommandHandler('cycle-plan');
      const startHandler = new CommandHandler('cycle-start');
      const checkHandler = new CommandHandler('cycle-check');

      // Plan phase captures context
      await planHandler.captureContext(['/CLAUDE.md', '/docs/overview.md']);
      const planCheckpoint = await planHandler.saveCheckpoint();

      // Start phase loads context
      await startHandler.loadCheckpoint(planCheckpoint);
      const startContext = startHandler.getLoadedContext();

      // Check phase verifies context
      await checkHandler.loadCheckpoint(planCheckpoint);
      const checkContext = checkHandler.getLoadedContext();

      // Verify context flows correctly
      expect(startContext).toEqual(planCheckpoint.contextMetadata.autoLoadedDocs);
      expect(checkContext).toEqual(planCheckpoint.contextMetadata.autoLoadedDocs);
    });

    it('should include context in cycle-log documentation', async () => {
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          autoLoadedDocs: {
            tier1: [{ path: '/CLAUDE.md' }],
            tier2: [{ path: '/cycles/CONTEXT.md' }],
            tier3: []
          }
        }
      };

      // When: cycle-log generates report
      const report = await generateCycleLogReport(checkpoint);

      // Then: includes which docs were loaded during cycle
      expect(report).toContain('Documentation Context Loaded');
      expect(report).toContain('Tier 1: /CLAUDE.md');
      expect(report).toContain('Tier 2: /cycles/CONTEXT.md');
    });
  });

  describe('Performance with many documentation files', () => {
    it('should efficiently track 50+ documentation files', async () => {
      const manyDocs = Array.from({ length: 60 }, (_, i) => ({
        path: `/docs/file-${i}.md`,
        tier: (i % 3 + 1) as 1 | 2 | 3
      }));

      const startTime = Date.now();
      const checkpoint = await saveCheckpointWithContext({}, manyDocs, mockReadTool);
      const duration = Date.now() - startTime;

      // Verify no significant performance degradation
      expect(duration).toBeLessThan(1000); // Should complete within 1 second
      const totalDocs = 
        checkpoint.contextMetadata.autoLoadedDocs.tier1.length +
        checkpoint.contextMetadata.autoLoadedDocs.tier2.length +
        checkpoint.contextMetadata.autoLoadedDocs.tier3.length;
      expect(totalDocs).toBe(60);
    });

    it('should use checksums to avoid re-reading unchanged files', async () => {
      const checkpoint: CheckpointWithContext = {
        contextMetadata: {
          autoLoadedDocs: {
            tier1: [{ 
              path: '/CLAUDE.md', 
              checksum: 'sha256:existing',
              lastModified: '2025-07-13T09:00:00Z',
              content: 'cached content'
            }],
            tier2: [],
            tier3: []
          }
        }
      };

      // Mock file hasn't changed
      mockFilesystem.set('/CLAUDE.md', {
        content: 'same content that produces sha256:existing',
        lastModified: '2025-07-13T09:00:00Z'
      });

      // When checking for changes
      const changes = await detectDocumentationChanges(checkpoint, mockFilesystem);

      // Only changed files are re-processed
      expect(changes.changed).toHaveLength(0);
      expect(mockReadTool).not.toHaveBeenCalled(); // Didn't need to re-read
    });
  });
});

// Type definitions that would be in the implementation
interface CheckpointWithContext {
  projectMeta?: any;
  contextMetadata?: ContextMetadata;
  contextResets?: number;
  currentContext?: any;
  [key: string]: any;
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

interface DocEntry {
  path: string;
  checksum: string;
  lastModified: string;
  content?: string | null;
}

// Mock function declarations (would be in implementation)
declare function saveCheckpointWithContext(checkpoint: any, docsLoaded: any[], readTool: any): Promise<any>;
declare function loadCheckpointAndRestoreContext(checkpoint: any, readTool: any, options?: any): Promise<any>;
declare function detectDocumentationChanges(checkpoint: any, filesystem: any): Promise<any>;
declare function promptForContextRefresh(changes: any, promptFn: any): Promise<boolean>;
declare function refreshContextInCheckpoint(checkpoint: any, shouldRefresh: boolean, readTool: any): Promise<any>;
declare function generateCycleLogReport(checkpoint: any): Promise<string>;
declare class CommandHandler {
  constructor(command: string);
  captureContext(docs: string[]): Promise<void>;
  saveCheckpoint(): Promise<any>;
  loadCheckpoint(checkpoint: any): Promise<void>;
  getLoadedContext(): any;
}