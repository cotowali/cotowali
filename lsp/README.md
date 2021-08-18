# LSP.V
Type declaration module of the Language Server Protocol 3.15 spec. For use on the [V Language Server](https://github.com/vlang/vls).

## Roadmap
### General
- [x] `initialize`
- [x] `initialized`
- [x] `shutdown`
- [x] `exit`
- [x] `$/cancelRequest`
### Window
- [x] `showMessage`
- [x] `showMessageRequest`
- [x] `logMessage`
### Telemetry
- [x] `event`
### Client
- [x] `registerCapability`
- [x] `unregisterCapability`
### Workspace
- [x] `workspaceFolders`
- [x] `didChangeWorkspaceFolder`
- [x] `didChangeConfiguration`
- [x] `configuration`
- [x] `didChangeWatchedFiles`
- [x] `symbol`
- [x] `executeCommand`
- [x] `applyEdit`
### Text Synchronization
- [x] `didOpen`
- [x] `didChange`
- [x] `willSave`
- [x] `willSaveWaitUntil`
- [x] `didSave`
- [x] `didClose`
### Diagnostics
- [x] `publishDiagnostics`
### Language Features
- [x] `completion`
- [x] `completion resolve`
- [x] `hover`
- [x] `signatureHelp`
- [x] `declaration`
- [x] `definition`
- [x] `typeDefinition`
- [x] `implementation`
- [x] `references`
- [x] `documentHighlight`
- [x] `documentSymbol`
- [x] `codeAction`
- [x] `codeLens`
- [x] `codeLens resolve`
- [x] `documentLink`
- [x] `documentLink resolve`
- [x] `documentColor`
- [x] `colorPresentation`
- [x] `formatting`
- [x] `rangeFormatting`
- [x] `onTypeFormatting`
- [x] `rename`
- [x] `prepareRename`
- [x] `foldingRange`

#### 2020-2021 Ned Palacios