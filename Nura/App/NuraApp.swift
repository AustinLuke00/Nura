// NuraApp.swift
// NuraApp.swift
// Nura — App entry point with SwiftData container

import SwiftUI
import SwiftData

@main
struct NuraApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showLaunchScreen ? 0 : 1)
                
                if showLaunchScreen {
                    AnimatedLaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // 启动屏幕显示 2 秒后淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(for: [
            Child.self,
            FeedingRecord.self,
            SleepRecord.self,
            DiaperRecord.self,
            GrowthRecord.self,
            Milestone.self,
            JaundiceRecord.self,
            MedicineRecord.self,
            TemperatureRecord.self,
            BreathingRecord.self
        ])
    }
}

struct ContentView: View {
    @Query private var children: [Child]
    @State private var selectedChildId: UUID?
    @State private var selectedTab: Tab = .today
    @State private var showWelcomeSheet = false
    @State private var showDeveloperSettings = false
    @State private var developerTapCount = 0

    enum Tab { case today, review }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedChildId: $selectedChildId)
                .tabItem {
                    Label("今日", systemImage: selectedTab == .today ? "sun.max.fill" : "sun.max")
                }
                .tag(Tab.today)

            ReviewView(selectedChildId: $selectedChildId)
                .tabItem {
                    Label("回顾", systemImage: selectedTab == .review
                          ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                }
                .tag(Tab.review)
        }
        .tint(.nuraPrimary)
        .onTapGesture(count: 5) {
            // 连续点击5次任意位置打开开发者设置
            showDeveloperSettings = true
        }
        .sheet(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView()
        }
        .task {
            // Ensure selectedChildId is valid on appear
            validateSelectedChild()
        }
        .onChange(of: children) { oldValue, newValue in
            validateSelectedChild()
        }
        .onAppear {
            // 每次打开应用都检查是否有宝宝
            if children.isEmpty {
                // 延迟一小段时间以确保视图已完全加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showWelcomeSheet = true
                }
            } else {
                validateSelectedChild()
            }
        }
        .sheet(isPresented: $showWelcomeSheet) {
            WelcomeSheet()
                .interactiveDismissDisabled(children.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateSelectedChild() {
        if children.isEmpty {
            showWelcomeSheet = true
            selectedChildId = nil
        } else if selectedChildId == nil || !children.contains(where: { $0.id == selectedChildId }) {
            // 如果当前选中的宝宝不存在，选择第一个
            selectedChildId = children.first?.id
        }
    }
}

// MARK: - WelcomeSheet

struct WelcomeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var children: [Child]
    
    @State private var currentStep: WelcomeStep = .welcome
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: Child.Gender = .female
    @State private var color: Child.ChildColor = .purple
    
    enum WelcomeStep {
        case welcome
        case addChild
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if currentStep == .welcome {
                    welcomeView
                } else {
                    addChildFormView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep == .addChild && !children.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("返回") {
                            withAnimation {
                                currentStep = .welcome
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Welcome View
    
    var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo 区域
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nuraPrimary, Color.nuraPrimary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.nuraPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 8) {
                    Text("NURA")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.nuraPrimary)
                    
                    Text("记录宝宝成长的每一刻")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 功能介绍
            VStack(spacing: 20) {
                WelcomeFeatureRow(
                    icon: "sun.max.fill",
                    title: "日常记录",
                    description: "喂养、睡眠、换尿布一键记录",
                    color: .nuraWarning
                )
                
                WelcomeFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "成长追踪",
                    description: "生长曲线、里程碑智能分析",
                    color: .nuraPrimary
                )
                
                WelcomeFeatureRow(
                    icon: "heart.fill",
                    title: "温馨陪伴",
                    description: "见证宝宝每一个珍贵瞬间",
                    color: Color(hex: "F9A8D4")
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 开始按钮
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .addChild
                    }
                } label: {
                    Text("开始使用")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.nuraPrimary)
                        .cornerRadius(16)
                }
                
                if !children.isEmpty {
                    Button {
                        dismiss()
                    } label: {
                        Text("稍后添加")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Add Child Form View
    
    var addChildFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.nuraPrimary)
                    
                    Text("添加宝宝信息")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("让我们开始记录宝宝的成长故事")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // 表单
                VStack(spacing: 16) {
                    // 名字输入
                    VStack(alignment: .leading, spacing: 8) {
                        Label("宝宝名字", systemImage: "person.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        TextField("请输入宝宝的名字", text: $name)
                            .font(.system(size: 16, design: .rounded))
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    
                    // 出生日期
                    VStack(alignment: .leading, spacing: 8) {
                        Label("出生日期", systemImage: "calendar")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // 性别选择
                    VStack(alignment: .leading, spacing: 8) {
                        Label("性别", systemImage: "person.2.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            GenderButton(
                                title: "女宝宝",
                                icon: "heart.circle.fill",
                                isSelected: gender == .female
                            ) {
                                withAnimation { gender = .female }
                            }
                            
                            GenderButton(
                                title: "男宝宝",
                                icon: "star.circle.fill",
                                isSelected: gender == .male
                            ) {
                                withAnimation { gender = .male }
                            }
                        }
                    }
                    
                    // 主题颜色
                    VStack(alignment: .leading, spacing: 8) {
                        Label("主题颜色", systemImage: "paintpalette.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            ForEach(Child.ChildColor.allCases, id: \.self) { c in
                                ColorButton(color: c, isSelected: color == c) {
                                    withAnimation(.spring(response: 0.3)) {
                                        color = c
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // 保存按钮
                Button {
                    saveChild()
                } label: {
                    Text("保存并开始")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            name.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray
                                : Color.nuraPrimary
                        )
                        .cornerRadius(16)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Actions
    
    func saveChild() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let child = Child(name: trimmed, birthDate: birthDate, gender: gender, color: color)
        modelContext.insert(child)
        
        // 添加成功后延迟关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - WelcomeFeatureRow

struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - GenderButton

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .nuraPrimary : .secondary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .nuraPrimary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? Color.nuraPrimary.opacity(0.1)
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.nuraPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ColorButton

struct ColorButton: View {
    let color: Child.ChildColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.swatch)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .strokeBorder(color.swatch, lineWidth: 2)
                        .frame(width: 52, height: 52)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Welcome - No Children") {
    WelcomeSheet()
        .modelContainer(for: [Child.self], inMemory: true)
}

#Preview("ContentView") {
    ContentView()
        .modelContainer(for: [
            Child.self, FeedingRecord.self, SleepRecord.self,
            DiaperRecord.self, GrowthRecord.self, Milestone.self,
            JaundiceRecord.self
        ], inMemory: true)
}
