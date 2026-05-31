// DeveloperSettingsView.swift
// Nura — 开发者设置(用于调试)

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NuraBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct DeveloperSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var children: [Child]
    
    @State private var showClearAlert = false
    @State private var isClearing = false
    @State private var showSuccessMessage = false
    @State private var isImportingOrExporting = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = NuraBackupDocument()
    @State private var operationResultTitle = ""
    @State private var operationResultMessage = ""
    @State private var showOperationResult = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("开发者模式", systemImage: "hammer.fill")
                            .font(.headline)
                            .foregroundStyle(.nuraPrimary)
                        
                        Text("此页面包含开发和调试工具")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    HStack {
                        Text("已存储的宝宝")
                        Spacer()
                        Text("\(children.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("喂养记录")
                        Spacer()
                        Text("\(totalFeedingRecords)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("睡眠记录")
                        Spacer()
                        Text("\(totalSleepRecords)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("尿布记录")
                        Spacer()
                        Text("\(totalDiaperRecords)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("数据统计")
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出数据")
                        }
                    }
                    .disabled(isImportingOrExporting || children.isEmpty)

                    Button {
                        showImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("导入数据")
                        }
                    }
                    .disabled(isImportingOrExporting)
                } header: {
                    Text("数据导入导出")
                } footer: {
                    Text("导入时会按 UUID 合并数据:已有宝宝会追加缺失记录,不存在的宝宝和记录会新增。")
                }
                
                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("清除所有数据")
                        }
                    }
                    .disabled(isClearing)
                } header: {
                    Text("危险操作")
                } footer: {
                    Text("此操作将删除应用中的所有宝宝数据和记录,且无法恢复。")
                }
            }
            .navigationTitle("开发者设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("确认清除所有数据?", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有宝宝信息和记录,且无法恢复。")
            }
            .alert(operationResultTitle, isPresented: $showOperationResult) {
                Button("好") { }
            } message: {
                Text(operationResultMessage)
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                importData(from: result)
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                isImportingOrExporting = false
                switch result {
                case .success:
                    showResult(title: "导出完成", message: "数据备份已导出为 JSON 文件。")
                case .failure(let error):
                    showResult(title: "导出失败", message: error.localizedDescription)
                }
            }
            .overlay {
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                            Text("数据已清除")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color.nuraPrimary)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalFeedingRecords: Int {
        children.reduce(0) { $0 + $1.feedings.count }
    }
    
    private var totalSleepRecords: Int {
        children.reduce(0) { $0 + $1.sleeps.count }
    }
    
    private var totalDiaperRecords: Int {
        children.reduce(0) { $0 + $1.diapers.count }
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "Nura-Backup-\(formatter.string(from: Date()))"
    }
    
    // MARK: - Actions

    private func exportData() {
        isImportingOrExporting = true

        do {
            exportDocument = NuraBackupDocument(data: try DataManager.exportData(from: modelContext))
            showExporter = true
        } catch {
            isImportingOrExporting = false
            showResult(title: "导出失败", message: error.localizedDescription)
        }
    }

    private func importData(from result: Result<URL, Error>) {
        isImportingOrExporting = true

        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let summary = try DataManager.importData(data, into: modelContext)
            showResult(title: "导入完成", message: summary.message)
        } catch {
            showResult(title: "导入失败", message: error.localizedDescription)
        }

        isImportingOrExporting = false
    }

    private func showResult(title: String, message: String) {
        operationResultTitle = title
        operationResultMessage = message
        showOperationResult = true
    }
    
    private func clearAllData() {
        isClearing = true
        
        Task {
            do {
                try DataManager.clearAllData(from: modelContext)
                
                // 显示成功消息
                withAnimation {
                    showSuccessMessage = true
                }
                
                // 2秒后隐藏消息并关闭页面
                try await Task.sleep(for: .seconds(2))
                
                withAnimation {
                    showSuccessMessage = false
                }
                
                try await Task.sleep(for: .seconds(0.3))
                dismiss()
                
            } catch {
                print("❌ 清除数据失败: \(error)")
            }
            
            isClearing = false
        }
    }
}

#Preview {
    DeveloperSettingsView()
        .modelContainer(for: [Child.self], inMemory: true)
}
