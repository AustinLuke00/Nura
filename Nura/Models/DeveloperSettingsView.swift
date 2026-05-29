// DeveloperSettingsView.swift
// Nura — 开发者设置(用于调试)

import SwiftUI
import SwiftData

struct DeveloperSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var children: [Child]
    
    @State private var showClearAlert = false
    @State private var isClearing = false
    @State private var showSuccessMessage = false
    
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
    
    // MARK: - Actions
    
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
