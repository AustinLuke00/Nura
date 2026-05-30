// ChildSwitcherView.swift
// Nura — Horizontal child selector used across all tabs

import SwiftUI
import SwiftData

// MARK: - ChildSwitcherView

struct ChildSwitcherView: View {
    @Query private var children: [Child]
    @Binding var selectedChildId: UUID?
    @State private var showAddChild = false
    @State private var showChildPicker = false

    var selectedChild: Child? {
        guard let id = selectedChildId else { return children.first }
        // Ensure the child still exists and hasn't been deleted
        return children.first(where: { $0.id == id }) ?? children.first
    }

    var body: some View {
        Button(action: { showChildPicker = true }) {
            HStack(spacing: 6) {
                if let child = selectedChild {
                    ChildAvatar(child: child, size: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(child.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(child.stageDisplay)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20))
                        .foregroundStyle(.nuraPrimary)
                    Text("添加宝宝")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(UIColor.tertiarySystemFill))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showChildPicker) {
            ChildPickerSheet(selectedChildId: $selectedChildId, showAddChild: $showAddChild)
        }
        .sheet(isPresented: $showAddChild) {
            AddChildSheet()
        }
    }
}

// MARK: - ChildPickerSheet

struct ChildPickerSheet: View {
    @Query private var children: [Child]
    @Binding var selectedChildId: UUID?
    @Binding var showAddChild: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var childToDelete: Child?
    @State private var showDeleteConfirmation = false
    @State private var childToEdit: Child?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(children) { child in
                        Button(action: {
                            withAnimation {
                                selectedChildId = child.id
                            }
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                ChildAvatar(child: child, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(child.name)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text(child.stageDisplay)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedChildId == child.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.nuraPrimary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                childToDelete = child
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                childToEdit = child
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.nuraPrimary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddChild = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.nuraPrimary)
                            Text("添加新宝宝")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.nuraPrimary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("选择宝宝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(item: $childToEdit) { child in
            EditChildSheet(child: child)
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation, presenting: childToDelete) { child in
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteChild(child)
            }
        } message: { child in
            Text("确定要删除 \(child.name) 的所有信息吗？包括所有喂养、睡眠、尿布等记录都会被永久删除。")
        }
    }
    
    private func deleteChild(_ child: Child) {
        // 如果删除的是当前选中的宝宝，先切换到其他宝宝
        if selectedChildId == child.id {
            if let otherChild = children.first(where: { $0.id != child.id }) {
                selectedChildId = otherChild.id
            } else {
                selectedChildId = nil
            }
        }
        
        // Give SwiftUI a moment to update the UI with the new selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 删除宝宝（级联删除会自动删除所有关联记录）
            modelContext.delete(child)
            
            // 如果没有宝宝了，关闭当前页面
            if children.count <= 1 {
                dismiss()
            }
        }
    }
}

// MARK: - EditChildSheet

struct EditChildSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var child: Child

    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: Child.Gender
    @State private var color: Child.ChildColor
    @State private var emergencyContactName: String
    @State private var emergencyContactPhone: String

    init(child: Child) {
        self.child = child
        _name = State(initialValue: child.profileType == .pregnancy ? "" : child.name)
        _birthDate = State(initialValue: child.birthDate)
        _gender = State(initialValue: child.gender)
        _color = State(initialValue: child.color)
        _emergencyContactName = State(initialValue: child.emergencyContactName ?? "")
        _emergencyContactPhone = State(initialValue: child.emergencyContactPhone ?? "")
    }

    private var latestSelectableDate: Date {
        Calendar.current.date(byAdding: .month, value: 10, to: Date()) ?? Date()
    }

    private var saveDisabled: Bool {
        child.profileType == .baby && name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("档案类型") {
                    Label(child.profileType == .pregnancy ? "孕妇信息" : "宝宝信息",
                          systemImage: child.profileType == .pregnancy ? "heart.circle.fill" : "figure.child")
                }

                Section("基本信息") {
                    if child.profileType == .baby {
                        TextField("宝宝名字", text: $name)
                    }
                    DatePicker(
                        child.profileType == .pregnancy ? "预产期" : "出生日期",
                        selection: $birthDate,
                        in: child.profileType == .pregnancy ? Date.distantPast...latestSelectableDate : Date.distantPast...Date(),
                        displayedComponents: .date
                    )
                }

                if child.profileType == .pregnancy {
                    Section("紧急联系人") {
                        TextField("联系人姓名", text: $emergencyContactName)
                        TextField("联系电话", text: $emergencyContactPhone)
                            .keyboardType(.phonePad)
                    }
                } else {
                    Section("性别") {
                        Picker("性别", selection: $gender) {
                            Text("女").tag(Child.Gender.female)
                            Text("男").tag(Child.Gender.male)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("主题颜色") {
                        HStack(spacing: 12) {
                            ForEach(Child.ChildColor.allCases, id: \.self) { c in
                                ZStack {
                                    Circle().fill(c.swatch).frame(width: 36, height: 36)
                                    if color == c {
                                        Circle().strokeBorder(.white, lineWidth: 3).frame(width: 36, height: 36)
                                        Circle().strokeBorder(c.swatch, lineWidth: 1.5).frame(width: 42, height: 42)
                                    }
                                }
                                .onTapGesture { withAnimation { color = c } }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(child.profileType == .pregnancy ? "编辑孕妇信息" : "编辑宝宝信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(saveDisabled)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .tint(.nuraPrimary)
    }

    private func save() {
        if child.profileType == .baby {
            child.name = name.trimmingCharacters(in: .whitespaces)
            child.gender = gender
            child.color = color
        }
        child.birthDate = birthDate
        child.emergencyContactName = emergencyContactName.trimmingCharacters(in: .whitespaces).nilIfEmpty
        child.emergencyContactPhone = emergencyContactPhone.trimmingCharacters(in: .whitespaces).nilIfEmpty
        dismiss()
    }
}

// MARK: - ChildChip

struct ChildChip: View {
    var child: Child
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            ChildAvatar(child: child, size: 24)
            Text(child.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            if isSelected {
                Text(child.ageDisplay)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(child.color.swatch.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            isSelected
                ? child.color.swatch.opacity(0.15)
                : Color(UIColor.tertiarySystemFill)
        )
        .foregroundStyle(isSelected ? child.color.swatch : Color.secondary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isSelected ? child.color.swatch.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - AddChildButton

struct AddChildButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nuraPrimary)
                .frame(width: 36, height: 36)
                .background(Color.nuraPrimaryLight)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ChildAvatar

struct ChildAvatar: View {
    var child: Child
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle().fill(child.color.swatch)
            Text(child.initial)
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - EmergencyContactFields

struct EmergencyContactFields: View {
    @Binding var name: String
    @Binding var phone: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("紧急联系人", systemImage: "phone.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                TextField("联系人姓名", text: $name)
                    .font(.system(size: 16, design: .rounded))
                    .padding()
                Divider().padding(.leading, 16)
                TextField("联系电话", text: $phone)
                    .font(.system(size: 16, design: .rounded))
                    .keyboardType(.phonePad)
                    .padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - AddChildSheet

struct AddChildSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: Child.Gender = .female
    @State private var color: Child.ChildColor = .purple
    @State private var profileType: Child.ProfileType = .baby
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""

    private var latestSelectableDate: Date {
        Calendar.current.date(byAdding: .month, value: 10, to: Date()) ?? Date()
    }

    private var saveDisabled: Bool {
        profileType == .baby && name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("信息类型", selection: $profileType) {
                        Label("宝宝信息", systemImage: "figure.child").tag(Child.ProfileType.baby)
                        Label("孕妇信息", systemImage: "heart.circle.fill").tag(Child.ProfileType.pregnancy)
                    }
                    .pickerStyle(.segmented)
                }

                Section("基本信息") {
                    if profileType == .baby {
                        TextField("宝宝名字", text: $name)
                    }
                    DatePicker(
                        profileType == .pregnancy ? "预产期" : "出生日期",
                        selection: $birthDate,
                        in: profileType == .pregnancy ? Date()...latestSelectableDate : Date.distantPast...Date(),
                        displayedComponents: .date
                    )
                    Text(profileType == .pregnancy ? "孕妇信息只需要填写预产期。" : "宝宝信息会根据年龄自动切换婴儿或儿童界面。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if profileType == .pregnancy {
                    Section("紧急联系人") {
                        TextField("联系人姓名", text: $emergencyContactName)
                        TextField("联系电话", text: $emergencyContactPhone)
                            .keyboardType(.phonePad)
                    }
                } else {
                    Section("性别") {
                        Picker("性别", selection: $gender) {
                            Text("女").tag(Child.Gender.female)
                            Text("男").tag(Child.Gender.male)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("主题颜色") {
                        HStack(spacing: 12) {
                            ForEach(Child.ChildColor.allCases, id: \.self) { c in
                                ZStack {
                                    Circle().fill(c.swatch).frame(width: 36, height: 36)
                                    if color == c {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                            .frame(width: 36, height: 36)
                                        Circle()
                                            .strokeBorder(c.swatch, lineWidth: 1.5)
                                            .frame(width: 42, height: 42)
                                    }
                                }
                                .onTapGesture { withAnimation { color = c } }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(profileType == .pregnancy ? "添加孕妇信息" : "添加宝宝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") { addChild() }
                        .disabled(saveDisabled)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .tint(.nuraPrimary)
        .onChange(of: profileType) { _, newValue in
            if newValue == .pregnancy && birthDate < Date() {
                birthDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            } else if newValue == .baby && birthDate > Date() {
                birthDate = Date()
            }
        }
    }

    func addChild() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard profileType == .pregnancy || !trimmed.isEmpty else { return }
        let child = Child(
            name: profileType == .pregnancy ? "孕期档案" : trimmed,
            birthDate: birthDate,
            gender: gender,
            color: profileType == .pregnancy ? .pink : color,
            profileType: profileType,
            emergencyContactName: emergencyContactName.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            emergencyContactPhone: emergencyContactPhone.trimmingCharacters(in: .whitespaces).nilIfEmpty
        )
        modelContext.insert(child)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedChildId: UUID? = nil
    VStack {
        ChildSwitcherView(selectedChildId: $selectedChildId)
        Spacer()
    }
    .modelContainer(for: [Child.self], inMemory: true)
}
